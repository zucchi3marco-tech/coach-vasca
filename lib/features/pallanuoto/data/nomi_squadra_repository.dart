import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Nome completo di ogni atleta del club, per le statistiche di partita
/// (FASE 13, punto 4): un atleta collegato non puo' leggere l'intera
/// tabella atleti oltre il proprio record, quindi i nomi dei compagni di
/// squadra passano da qui — solo id+nome, mai altri dati personali. Vale
/// anche per il coach (stessa funzione, nessun dato in piu' da esporre
/// per lui).
class NomiSquadraRepository {
  NomiSquadraRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, String>> fetchPerClub(String clubId) async {
    final risposta = await _client.rpc(
      'nomi_atleti_squadra',
      params: {'p_club_id': clubId},
    );
    final righe = (risposta as List).cast<Map<String, dynamic>>();
    return {
      for (final r in righe) r['id'] as String: r['nome_completo'] as String,
    };
  }
}

final nomiSquadraRepositoryProvider = Provider<NomiSquadraRepository>((ref) {
  return NomiSquadraRepository(ref.watch(supabaseClientProvider));
});

final nomiSquadraProvider = FutureProvider.autoDispose
    .family<Map<String, String>, String>((ref, clubId) {
      return ref.read(nomiSquadraRepositoryProvider).fetchPerClub(clubId);
    });
