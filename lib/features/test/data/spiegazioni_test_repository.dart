import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';

/// Le spiegazioni dei test di nuoto BVS e T30 scritte dall'allenatore
/// (tabella `spiegazioni_test`). Si cambiano di rado: si leggono e si
/// salvano solo con la rete; senza, l'app mostra quella originale.
class SpiegazioniTestRepository {
  SpiegazioniTestRepository(this._client);

  final SupabaseClient _client;

  /// Per tipo ('BVS', 'T30'), il testo scritto dall'allenatore; vuoto se
  /// non ne ha scritti o se manca la rete.
  Future<Map<String, String>> delClub(String clubId) async {
    try {
      final righe = await _client
          .from('spiegazioni_test')
          .select('tipo, testo')
          .eq('club_id', clubId);
      return {for (final r in righe) r['tipo'] as String: r['testo'] as String};
    } catch (e) {
      if (isNetworkFailure(e)) return const {};
      rethrow;
    }
  }

  /// Salva la spiegazione di [tipo]; null o vuota torna a quella
  /// originale.
  Future<void> salva({
    required String clubId,
    required String tipo,
    required String? testo,
  }) async {
    final t = testo?.trim() ?? '';
    try {
      if (t.isEmpty) {
        await _client
            .from('spiegazioni_test')
            .delete()
            .eq('club_id', clubId)
            .eq('tipo', tipo);
      } else {
        await _client.from('spiegazioni_test').upsert({
          'club_id': clubId,
          'tipo': tipo,
          'testo': t,
        }, onConflict: 'club_id,tipo');
      }
    } catch (e) {
      if (isNetworkFailure(e)) {
        throw Exception(
          'Serve la rete per salvare la spiegazione: riprova quando torna.',
        );
      }
      rethrow;
    }
  }
}

final spiegazioniTestRepositoryProvider = Provider<SpiegazioniTestRepository>(
  (ref) => SpiegazioniTestRepository(ref.watch(supabaseClientProvider)),
);

/// Le spiegazioni di BVS e T30 scritte dall'allenatore del club.
final spiegazioniTestNuotoProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>(
      (ref, clubId) =>
          ref.watch(spiegazioniTestRepositoryProvider).delClub(clubId),
    );
