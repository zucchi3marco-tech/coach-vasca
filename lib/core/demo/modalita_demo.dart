import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthResponse, AuthState, Session, Supabase, User;

import '../../features/auth/data/auth_repository.dart';

/// Modalita' demo della copia di prova: si entra senza login e l'app
/// lavora solo sulla cache locale (Drift), senza mai contattare
/// Supabase. Si attiva con `MODALITA_DEMO=true` nel file `.env`.
///
/// Ogni chiamata a Supabase fallisce subito come errore di rete
/// ([_ClientOffline]): i repository la trattano gia' come "offline",
/// quindi le letture usano i dati locali e le scritture finiscono in
/// locale + coda di sincronizzazione (che non si svuota mai). Restano
/// fuori le funzioni che esistono solo sul server: generazione AI,
/// inviti/codici atleta, notifiche push, referti.
bool get modalitaDemo => dotenv.env['MODALITA_DEMO']?.toLowerCase() == 'true';

/// Indirizzo irraggiungibile usato al posto del progetto Supabase vero,
/// cosi' nemmeno una richiesta fuori dal client HTTP (es. websocket)
/// puo' arrivare ai dati reali.
const urlSupabaseDemo = 'http://127.0.0.1:9';

/// L'allenatore della demo: sempre lo stesso id.
const idUtenteDemo = '00000000-0000-4000-8000-00000000de00';

Session _sessione(String id, String email) => Session(
  accessToken: 'demo',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

const _chiaveAccountDemo = 'demo_account_atleti';

/// Id dell'utente demo collegato in questo momento (null = nessuno):
/// letto da `AtletiRepository.fetchAtletaCollegato` al posto della
/// sessione Supabase, che in demo non esiste.
String? idUtenteDemoCorrente;

/// Login finto della demo: si parte dalla schermata di accesso e
/// qualunque email/password (o "Continua con Google") fa entrare come
/// allenatore; "Esci" torna al login. Gli account creati in
/// registrazione (es. da un codice invito atleta) restano propri: chi
/// rientra con quell'email ritrova la sua Area atleta. Nessuna chiamata
/// a Supabase.
class AuthRepositoryDemo extends AuthRepository {
  AuthRepositoryDemo() : super(Supabase.instance.client);

  final _stato = StreamController<AuthState>.broadcast();
  AuthState _ultimo = const AuthState(AuthChangeEvent.signedOut, null);

  /// Lo stato attuale seguito dai cambi successivi.
  Stream<AuthState> get cambiStato async* {
    yield _ultimo;
    yield* _stato.stream;
  }

  void _emetti(AuthState stato) {
    _ultimo = stato;
    idUtenteDemoCorrente = stato.session?.user.id;
    _stato.add(stato);
  }

  Session _entra(String id, String email) {
    final sessione = _sessione(id, email);
    _emetti(AuthState(AuthChangeEvent.signedIn, sessione));
    return sessione;
  }

  Future<Map<String, dynamic>> _account() async {
    final prefs = await SharedPreferences.getInstance();
    final testo = prefs.getString(_chiaveAccountDemo);
    return testo == null ? {} : jsonDecode(testo) as Map<String, dynamic>;
  }

  @override
  User? get currentUser => _ultimo.session?.user;

  /// Chiamato prima di entrare con un account atleta: se il database demo
  /// e' stato ricreato e l'atleta non e' piu' collegato, lo ricollega.
  Future<void> Function(String userId)? garantisciAtletaCollegato;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final chiave = email.trim().toLowerCase();
    final idAtleta = (await _account())[chiave] as String?;
    if (idAtleta != null) await garantisciAtletaCollegato?.call(idAtleta);
    _entra(idAtleta ?? idUtenteDemo, chiave);
  }

  @override
  Future<void> signInWithGoogle() async =>
      _entra(idUtenteDemo, 'allenatore@demo.local');

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final chiave = email.trim().toLowerCase();
    final account = await _account();
    final id = account[chiave] as String? ?? const Uuid().v4();
    account[chiave] = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chiaveAccountDemo, jsonEncode(account));
    final sessione = _entra(id, chiave);
    return AuthResponse(session: sessione, user: sessione.user);
  }

  @override
  Future<void> signOut() async {
    // Come una vera chiamata di rete: lascia finire la chiusura del menu
    // da cui si e' scelto "Esci", che altrimenti restava sopra il login.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _emetti(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<void> sendPasswordReset(String email) async {}
}

/// Scrive in console ogni errore di un provider: nella build compilata
/// gli errori altrimenti non si vedono, e un provider che fallisce resta
/// "in caricamento" mentre Riverpod ritenta.
final class OsservatoreErroriDemo extends ProviderObserver {
  final _inizio = <Object, Stopwatch>{};

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    _inizio[context.provider] = Stopwatch()..start();
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final cronometro = _inizio.remove(context.provider);
    if (cronometro != null && cronometro.elapsedMilliseconds > 500) {
      // ignore: avoid_print
      print(
        '[demo] lento ${cronometro.elapsedMilliseconds} ms: ${context.provider}',
      );
    }
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // ignore: avoid_print
    print('[demo] errore in ${context.provider}: $error\n$stackTrace');
  }
}

class ClientOffline extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      // "Richiesta interrotta" e' comunque un errore di rete per l'app
      // (ClientException), ma e' l'unico che il client Supabase non
      // ritenta: con un ClientException semplice ogni lettura aspettava
      // 1 + 2 + 4 secondi di tentativi (supabase 2.16 ignora
      // retryEnabled: false sulle query `from()`).
      Future.error(http.RequestAbortedException(request.url));
}
