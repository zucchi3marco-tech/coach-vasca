import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/segnalazione.dart';

const _spazio = 'segnalazioni';

/// Le segnalazioni di «Scrivimi», solo in rete (come gli inviti): senza
/// linea non partono e il testo resta nella pagina. Le regole di accesso
/// sono nel database (migrazione `20261019000100_segnalazioni.sql`): chi
/// scrive vede le sue, gli amministratori dell'app tutte.
class SegnalazioniRepository {
  SegnalazioniRepository(this._client);

  final SupabaseClient _client;

  /// Prima la schermata nella cartella di chi scrive, poi la riga: se la
  /// riga non parte resta al massimo un'immagine senza segnalazione, mai
  /// una segnalazione che rimanda a una schermata che non c'è.
  Future<void> invia({
    required String clubId,
    required String testo,
    required ContestoSegnalazione contesto,
  }) async {
    final utente = _client.auth.currentUser?.id;
    if (utente == null) throw StateError('Nessun utente collegato');
    final id = const Uuid().v4();
    String? percorso;
    final schermata = contesto.schermata;
    if (schermata != null) {
      percorso = '$utente/$id.png';
      await _client.storage
          .from(_spazio)
          .uploadBinary(
            percorso,
            schermata,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
    }
    await _client.from('segnalazioni').insert({
      'id': id,
      'club_id': clubId,
      'testo': testo.trim(),
      'versione': contesto.versione,
      'pagina': contesto.pagina,
      'dispositivo': contesto.dispositivo,
      'schermo': contesto.schermo,
      'schermata': percorso,
    });
  }

  /// Le segnalazioni di chi è collegato, dalla più recente.
  Future<List<Segnalazione>> mie() async {
    final utente = _client.auth.currentUser?.id;
    if (utente == null) return const [];
    final righe = await _client
        .from('segnalazioni')
        .select()
        .eq('user_id', utente)
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final r in righe) Segnalazione.fromMap(r)];
  }

  /// Tutte le segnalazioni, per chi le legge: prima le aperte, poi le
  /// risolte, ognuna dalla più recente.
  Future<List<Segnalazione>> tutte() async {
    final righe = await _client
        .from('segnalazioni')
        .select()
        .order('stato')
        .order('created_at', ascending: false)
        .limit(300);
    return [for (final r in righe) Segnalazione.fromMap(r)];
  }

  Future<bool> sonoAmministratore() async {
    final esito = await _client.rpc<dynamic>('e_amministratore_app');
    return esito == true;
  }

  Future<Uint8List> schermata(String percorso) =>
      _client.storage.from(_spazio).download(percorso);

  /// Stato e risposta: le altre colonne il database non le cambia.
  Future<void> aggiorna(
    String id, {
    required bool risolta,
    required String? risposta,
  }) async {
    final testo = risposta?.trim();
    await _client
        .from('segnalazioni')
        .update({
          'stato': risolta ? 'risolta' : 'aperta',
          'risposta': testo == null || testo.isEmpty ? null : testo,
        })
        .eq('id', id);
  }
}

final segnalazioniRepositoryProvider = Provider<SegnalazioniRepository>(
  (ref) => SegnalazioniRepository(ref.watch(supabaseClientProvider)),
);

bool get _inDemo => dotenv.isInitialized && modalitaDemo;

/// Se chi è collegato legge le segnalazioni di tutti (la voce
/// «Segnalazioni» nel menu). In demo e senza rete no.
final sonoAmministratoreAppProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  if (_inDemo) return false;
  // Si rilegge a ogni accesso e uscita.
  final sessione = ref.watch(authStateChangesProvider).value?.session;
  if (sessione == null) return false;
  try {
    return await ref.watch(segnalazioniRepositoryProvider).sonoAmministratore();
  } catch (_) {
    return false;
  }
}, retry: (_, _) => null);

final mieSegnalazioniProvider = FutureProvider.autoDispose<List<Segnalazione>>((
  ref,
) async {
  if (_inDemo) return const [];
  return ref.watch(segnalazioniRepositoryProvider).mie();
}, retry: (_, _) => null);

final tutteSegnalazioniProvider =
    FutureProvider.autoDispose<List<Segnalazione>>(
      (ref) => ref.watch(segnalazioniRepositoryProvider).tutte(),
      retry: (_, _) => null,
    );

final schermataSegnalazioneProvider = FutureProvider.autoDispose
    .family<Uint8List, String>(
      (ref, percorso) =>
          ref.watch(segnalazioniRepositoryProvider).schermata(percorso),
      retry: (_, _) => null,
    );
