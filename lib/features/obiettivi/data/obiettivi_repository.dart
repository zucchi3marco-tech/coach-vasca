import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../domain/scheda_obiettivi.dart';

/// Schede obiettivi e risposte (tabelle `schede_obiettivi` e
/// `risposte_obiettivi`). Si scrivono di rado e da una persona alla volta:
/// solo con la rete, senza copia sul telefono. Chi vede e chi scrive cosa
/// lo decide il database (l'atleta solo le sue, l'allenatore non tocca le
/// risposte, l'atleta non tocca il ritorno).
class ObiettiviRepository {
  ObiettiviRepository(this._client);

  final SupabaseClient _client;

  Future<T> _conRete<T>(Future<T> Function() fai) async {
    try {
      return await fai();
    } catch (e) {
      if (isNetworkFailure(e)) {
        throw Exception('Serve la rete: riprova quando torna.');
      }
      rethrow;
    }
  }

  /// Le schede del club che chi legge può vedere, le più recenti prima
  /// (l'atleta vede solo le sue).
  Future<List<SchedaObiettivi>> schede(String clubId) => _conRete(() async {
    final righe = await _client
        .from('schede_obiettivi')
        .select()
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    return [for (final r in righe) SchedaObiettivi.fromMap(r)];
  });

  /// Crea la scheda e la manda agli atleti (il database li avvisa).
  Future<void> crea({
    required String clubId,
    required String? stagioneId,
    required String? gruppoId,
    required String titolo,
    required List<String> domande,
  }) => _conRete(
    () => _client.from('schede_obiettivi').insert({
      'club_id': clubId,
      'stagione_id': stagioneId,
      'gruppo_id': gruppoId,
      'titolo': titolo.trim(),
      'domande': [for (final d in domande) d.trim()],
    }),
  );

  Future<void> chiudi(String schedaId, {required bool chiusa}) => _conRete(
    () => _client
        .from('schede_obiettivi')
        .update({'chiusa': chiusa})
        .eq('id', schedaId),
  );

  Future<void> elimina(String schedaId) => _conRete(
    () => _client.from('schede_obiettivi').delete().eq('id', schedaId),
  );

  Future<List<RispostaObiettivi>> risposteDellaScheda(String schedaId) =>
      _conRete(() async {
        final righe = await _client
            .from('risposte_obiettivi')
            .select()
            .eq('scheda_id', schedaId);
        return [for (final r in righe) RispostaObiettivi.fromMap(r)];
      });

  Future<List<RispostaObiettivi>> risposteDellAtleta(String atletaId) =>
      _conRete(() async {
        final righe = await _client
            .from('risposte_obiettivi')
            .select()
            .eq('atleta_id', atletaId);
        return [for (final r in righe) RispostaObiettivi.fromMap(r)];
      });

  /// L'atleta manda (o corregge) le sue risposte.
  Future<void> rispondi({
    required SchedaObiettivi scheda,
    required String atletaId,
    required List<String> risposte,
  }) => _conRete(
    () => _client.from('risposte_obiettivi').upsert({
      'scheda_id': scheda.id,
      'atleta_id': atletaId,
      'club_id': scheda.clubId,
      'risposte': [for (final r in risposte) r.trim()],
    }, onConflict: 'scheda_id,atleta_id'),
  );

  /// L'allenatore scrive (o toglie, con un testo vuoto) le sue due righe.
  Future<void> scriviRitorno(String rispostaId, String testo) => _conRete(
    () => _client
        .from('risposte_obiettivi')
        .update({'ritorno': testo.trim().isEmpty ? null : testo.trim()})
        .eq('id', rispostaId),
  );
}

final obiettiviRepositoryProvider = Provider<ObiettiviRepository>(
  (ref) => ObiettiviRepository(ref.watch(supabaseClientProvider)),
);

final schedeObiettiviProvider = FutureProvider.autoDispose
    .family<List<SchedaObiettivi>, String>(
      (ref, clubId) => ref.watch(obiettiviRepositoryProvider).schede(clubId),
    );

final risposteSchedaProvider = FutureProvider.autoDispose
    .family<List<RispostaObiettivi>, String>(
      (ref, schedaId) =>
          ref.watch(obiettiviRepositoryProvider).risposteDellaScheda(schedaId),
    );

final risposteAtletaObiettiviProvider = FutureProvider.autoDispose
    .family<List<RispostaObiettivi>, String>(
      (ref, atletaId) =>
          ref.watch(obiettiviRepositoryProvider).risposteDellAtleta(atletaId),
    );

/// Dopo un salvataggio: si rileggono schede e risposte.
void aggiornaObiettivi(WidgetRef ref) {
  ref
    ..invalidate(schedeObiettiviProvider)
    ..invalidate(risposteSchedaProvider)
    ..invalidate(risposteAtletaObiettiviProvider);
}
