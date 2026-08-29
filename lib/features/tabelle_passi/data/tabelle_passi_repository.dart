import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/tabella_passo.dart';

class RigaTabellaPasso {
  const RigaTabellaPasso({
    required this.zona,
    required this.passo100S,
    required this.percentualeRiferimento,
  });

  final String zona;
  final double passo100S;
  final double percentualeRiferimento;
}

class TabellePassiRepository {
  TabellePassiRepository(this._client);

  final SupabaseClient _client;

  Future<List<TabellaPasso>> fetchPerTest(String testId) async {
    final rows = await _client
        .from('tabelle_passi')
        .select()
        .eq('test_id', testId)
        .order('zona');
    return rows.map(TabellaPasso.fromMap).toList();
  }

  /// club_id e atleta_id sono ricalcolati dal trigger `imposta_da_test()` a
  /// partire da test_id: non serve (ne si deve) passarli qui.
  Future<List<TabellaPasso>> upsertPerTest({
    required String testId,
    required List<RigaTabellaPasso> righe,
  }) async {
    final rows = await _client
        .from('tabelle_passi')
        .upsert(
          [
            for (final riga in righe)
              {
                'test_id': testId,
                'zona': riga.zona,
                'passo_100_s': riga.passo100S,
                'percentuale_riferimento': riga.percentualeRiferimento,
              },
          ],
          onConflict: 'test_id,zona',
        )
        .select();
    return rows.map(TabellaPasso.fromMap).toList();
  }
}

final tabellePassiRepositoryProvider = Provider<TabellePassiRepository>((
  ref,
) {
  return TabellePassiRepository(ref.watch(supabaseClientProvider));
});
