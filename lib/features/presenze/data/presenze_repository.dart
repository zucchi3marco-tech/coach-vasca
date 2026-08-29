import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/presenza.dart';

class PresenzeRepository {
  PresenzeRepository(this._client);

  final SupabaseClient _client;

  Future<List<Presenza>> fetchPerAllenamento(String allenamentoId) async {
    final rows = await _client
        .from('presenze')
        .select()
        .eq('allenamento_id', allenamentoId);
    return rows.map(Presenza.fromMap).toList();
  }

  /// club_id e' ricalcolato dal trigger `imposta_e_valida_presenza()` a
  /// partire da allenamento_id/atleta_id, con validazione incrociata che
  /// appartengano allo stesso club.
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    final row = await _client
        .from('presenze')
        .upsert(
          {
            'allenamento_id': allenamentoId,
            'atleta_id': atletaId,
            'stato': stato,
          },
          onConflict: 'allenamento_id,atleta_id',
        )
        .select()
        .single();
    return Presenza.fromMap(row);
  }
}

final presenzeRepositoryProvider = Provider<PresenzeRepository>((ref) {
  return PresenzeRepository(ref.watch(supabaseClientProvider));
});
