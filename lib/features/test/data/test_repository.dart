import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/date_format.dart';
import '../domain/test_ingresso.dart';

class TestRepository {
  TestRepository(this._client);

  final SupabaseClient _client;

  Future<List<TestIngresso>> fetchTestPerAtleta(String atletaId) async {
    final rows = await _client
        .from('test_ingresso')
        .select()
        .eq('atleta_id', atletaId)
        .order('data_test', ascending: false);
    return rows.map(TestIngresso.fromMap).toList();
  }

  Future<TestIngresso> createTest({
    required String atletaId,
    required String tipo,
    required DateTime dataTest,
    required int distanzaTotaleM,
    required double tempoTotaleS,
    String? note,
  }) async {
    final row = await _client
        .from('test_ingresso')
        .insert({
          'atleta_id': atletaId,
          'tipo': tipo,
          'data_test': formatDateOnly(dataTest),
          'distanza_totale_m': distanzaTotaleM,
          'tempo_totale_s': tempoTotaleS,
          if (note != null && note.isNotEmpty) 'note': note,
        })
        .select()
        .single();
    return TestIngresso.fromMap(row);
  }

  Future<void> deleteTest(String id) {
    return _client.from('test_ingresso').delete().eq('id', id);
  }
}

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(ref.watch(supabaseClientProvider));
});
