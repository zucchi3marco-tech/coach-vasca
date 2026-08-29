import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
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
  TabellePassiRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  TabellaPasso _fromRow(TabellePassiTableData row) {
    return TabellaPasso(
      id: row.id,
      testId: row.testId,
      atletaId: row.atletaId,
      clubId: row.clubId,
      zona: row.zona,
      passo100S: row.passo100S,
      percentualeRiferimento: row.percentualeRiferimento,
    );
  }

  TabellePassiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return TabellePassiTableCompanion.insert(
      id: map['id'] as String,
      testId: map['test_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      zona: map['zona'] as String,
      passo100S: (map['passo_100_s'] as num).toDouble(),
      percentualeRiferimento: Value(
        (map['percentuale_riferimento'] as num?)?.toDouble(),
      ),
    );
  }

  Stream<List<TabellaPasso>> watchPerTest(String testId) {
    final query = _db.select(_db.tabellePassiTable)
      ..where((t) => t.testId.equals(testId))
      ..orderBy([(t) => OrderingTerm.asc(t.zona)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String testId) async {
    final rows = await _client
        .from('tabelle_passi')
        .select()
        .eq('test_id', testId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.tabellePassiTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// club_id e atleta_id sono ricalcolati dal trigger `imposta_da_test()` a
  /// partire da test_id: non serve (ne' si deve) passarli qui. Niente id
  /// generato lato client: la generazione/rigenerazione della tabella
  /// richiede comunque una connessione (upsert su test_id+zona), quindi
  /// l'id lo assegna il DB come sempre (nuovo per una riga nuova, invariato
  /// per una riga esistente che viene aggiornata).
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
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.tabellePassiTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    return rows.map(_fromRow2).toList();
  }

  TabellaPasso _fromRow2(Map<String, dynamic> map) {
    return TabellaPasso(
      id: map['id'] as String,
      testId: map['test_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      zona: map['zona'] as String,
      passo100S: (map['passo_100_s'] as num).toDouble(),
      percentualeRiferimento: (map['percentuale_riferimento'] as num?)
          ?.toDouble(),
    );
  }
}

final tabellePassiRepositoryProvider = Provider<TabellePassiRepository>((
  ref,
) {
  return TabellePassiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
