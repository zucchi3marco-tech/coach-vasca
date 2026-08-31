import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/tabella_passo.dart';

const _uuid = Uuid();

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
  TabellePassiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

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

  TabellaPasso _fromMap(Map<String, dynamic> map) {
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
    // Sostituzione totale (non insertOrReplace per id): una riga generata
    // offline ha un id locale provvisorio diverso da quello che assegna il
    // server, altrimenti resterebbe duplicata dopo il sync.
    await _db.transaction(() async {
      await (_db.delete(
        _db.tabellePassiTable,
      )..where((t) => t.testId.equals(testId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.tabellePassiTable, _companionFromMap(row));
        }
      });
    });
  }

  /// club_id e atleta_id sono normalmente ricalcolati dal trigger
  /// `imposta_da_test()` a partire da test_id. Offline usiamo quelli gia'
  /// in cache locale per quel test; per l'id riusiamo quello di una riga
  /// gia' esistente per la stessa zona (se c'e'), altrimenti ne generiamo
  /// uno provvisorio.
  Future<List<TabellaPasso>> upsertPerTest({
    required String testId,
    required List<RigaTabellaPasso> righe,
  }) async {
    final payload = [
      for (final riga in righe)
        {
          'test_id': testId,
          'zona': riga.zona,
          'passo_100_s': riga.passo100S,
          'percentuale_riferimento': riga.percentualeRiferimento,
        },
    ];
    try {
      final rows = await _client
          .from('tabelle_passi')
          .upsert(payload, onConflict: 'test_id,zona')
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
      return rows.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final test = await (_db.select(
        _db.testIngressoTable,
      )..where((t) => t.id.equals(testId))).getSingle();
      final righeComplete = <Map<String, dynamic>>[];
      for (final riga in payload) {
        final esistente = await (_db.select(_db.tabellePassiTable)..where(
              (t) => t.testId.equals(testId) & t.zona.equals(riga['zona'] as String),
            ))
            .getSingleOrNull();
        righeComplete.add({
          ...riga,
          'id': esistente?.id ?? _uuid.v4(),
          'atleta_id': test.atletaId,
          'club_id': test.clubId,
        });
      }
      await _db.batch((batch) {
        for (final row in righeComplete) {
          batch.insert(
            _db.tabellePassiTable,
            _companionFromMap(row),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      await enqueueOperation(
        _db,
        tabella: 'tabelle_passi',
        operazione: 'upsert',
        rigaId: testId,
        payload: payload,
      );
      _syncEngine.processQueue();
      return righeComplete.map(_fromMap).toList();
    }
  }
}

final tabellePassiRepositoryProvider = Provider<TabellePassiRepository>((
  ref,
) {
  return TabellePassiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
