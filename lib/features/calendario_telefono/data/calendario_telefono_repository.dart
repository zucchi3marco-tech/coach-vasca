import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Il codice personale che compone l'indirizzo del calendario collegato al
/// telefono. Online-only: il codice vive sul server (funzione
/// `mio_calendario`), non ha senso averlo in locale.
class CalendarioTelefonoRepository {
  CalendarioTelefonoRepository(this._client);

  final SupabaseClient _client;

  /// Il codice di chi è collegato (48 caratteri esadecimali), creato la
  /// prima volta che lo si chiede. Con [nuovo] ne fa uno nuovo: il vecchio
  /// indirizzo smette di funzionare.
  Future<String> codice({bool nuovo = false}) async {
    final risposta = await _client.rpc(
      'mio_calendario',
      params: {'p_nuovo': nuovo},
    );
    return risposta as String;
  }

  /// Quando e da quale app ("Google Calendar", "iPhone"…) il calendario è
  /// stato letto l'ultima volta; null se nessuno l'ha ancora letto. Lo
  /// segna la funzione `calendario` a ogni lettura.
  Future<LetturaCalendario?> ultimaLettura() async {
    final utente = _client.auth.currentUser;
    if (utente == null) return null;
    final riga = await _client
        .from('calendari_collegati')
        .select('letto_at, letto_da')
        .eq('user_id', utente.id)
        .maybeSingle();
    final letto = riga?['letto_at'] as String?;
    if (letto == null) return null;
    return (
      quando: DateTime.parse(letto).toLocal(),
      app: riga?['letto_da'] as String? ?? 'un calendario',
    );
  }
}

typedef LetturaCalendario = ({DateTime quando, String app});

final calendarioTelefonoRepositoryProvider =
    Provider<CalendarioTelefonoRepository>((ref) {
      return CalendarioTelefonoRepository(ref.watch(supabaseClientProvider));
    });

/// Il codice personale del calendario: lo legge dal server alla prima
/// apertura della pagina, [cambia] ne fa uno nuovo.
class CodiceCalendarioNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() =>
      ref.read(calendarioTelefonoRepositoryProvider).codice();

  /// Fa un codice nuovo: il vecchio indirizzo smette di funzionare. Se il
  /// server non risponde l'errore sale a chi chiama e il codice che si
  /// vede resta quello di prima.
  Future<void> cambia() async {
    final nuovo = await ref
        .read(calendarioTelefonoRepositoryProvider)
        .codice(nuovo: true);
    state = AsyncData(nuovo);
  }
}

final codiceCalendarioProvider =
    AsyncNotifierProvider.autoDispose<CodiceCalendarioNotifier, String>(
      CodiceCalendarioNotifier.new,
      // Senza rete la pagina lo dice subito e offre "Riprova": i tentativi
      // automatici di Riverpod la lascerebbero minuti sullo scheletro.
      retry: (_, _) => null,
    );

/// L'ultima lettura del calendario, per dire se il collegamento è riuscito.
/// Si rilegge quando cambia il codice ("Cambia indirizzo") e con
/// `ref.invalidate` ("Controlla di nuovo").
final letturaCalendarioProvider =
    FutureProvider.autoDispose<LetturaCalendario?>((ref) async {
      await ref.watch(codiceCalendarioProvider.future);
      return ref.read(calendarioTelefonoRepositoryProvider).ultimaLettura();
    }, retry: (_, _) => null);
