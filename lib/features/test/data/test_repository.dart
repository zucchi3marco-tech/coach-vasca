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
import '../../../core/utils/date_format.dart';
import '../domain/test_ingresso.dart';

const _uuid = Uuid();

class TestRepository {
  TestRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  TestIngresso _fromRow(TestIngressoTableData row) {
    return TestIngresso(
      id: row.id,
      atletaId: row.atletaId,
      clubId: row.clubId,
      tipo: row.tipo,
      dataTest: row.dataTest,
      distanzaTotaleM: row.distanzaTotaleM,
      tempoTotaleS: row.tempoTotaleS,
      passoMedio100S: row.passoMedio100S,
      note: row.note,
    );
  }

  TestIngressoTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return TestIngressoTableCompanion.insert(
      id: map['id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      dataTest: DateTime.parse(map['data_test'] as String),
      distanzaTotaleM: map['distanza_totale_m'] as int,
      tempoTotaleS: (map['tempo_totale_s'] as num).toDouble(),
      passoMedio100S: (map['passo_medio_100_s'] as num).toDouble(),
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<TestIngresso>> watchPerAtleta(String atletaId) {
    final query = _db.select(_db.testIngressoTable)
      ..where((t) => t.atletaId.equals(atletaId))
      ..orderBy([(t) => OrderingTerm.desc(t.dataTest)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo atleta (non insertOrReplace): un test
  /// eliminato fuori dall'app resterebbe altrimenti in cache a tempo
  /// indeterminato.
  Future<void> refreshFromRemote(String atletaId) async {
    final rows = await _client
        .from('test_ingresso')
        .select()
        .eq('atleta_id', atletaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.testIngressoTable,
      )..where((t) => t.atletaId.equals(atletaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.testIngressoTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<TestIngresso> createTest({
    required String atletaId,
    required String tipo,
    required DateTime dataTest,
    required int distanzaTotaleM,
    required double tempoTotaleS,
    String? note,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'atleta_id': atletaId,
      'tipo': tipo,
      'data_test': formatDateOnly(dataTest),
      'distanza_totale_m': distanzaTotaleM,
      'tempo_totale_s': tempoTotaleS,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    try {
      final row = await _client
          .from('test_ingresso')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.testIngressoTable)
          .insertOnConflictUpdate(_companionFromMap(row));
      return _fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // atleta_id/club_id sono normalmente ricalcolati dal trigger lato DB
      // a partire dall'atleta; offline usiamo il club_id gia' in cache
      // locale per quell'atleta, e calcoliamo qui il passo medio (colonna
      // generata) con la stessa formula usata dal DB.
      final atleta = await (_db.select(
        _db.atletiTable,
      )..where((t) => t.id.equals(atletaId))).getSingle();
      final passoMedio = _calcolaPassoMedio(tempoTotaleS, distanzaTotaleM);
      await _db
          .into(_db.testIngressoTable)
          .insertOnConflictUpdate(
            TestIngressoTableCompanion.insert(
              id: id,
              atletaId: atletaId,
              clubId: atleta.clubId,
              tipo: tipo,
              dataTest: dataTest,
              distanzaTotaleM: distanzaTotaleM,
              tempoTotaleS: tempoTotaleS,
              passoMedio100S: passoMedio,
              note: Value(note),
            ),
          );
      await enqueueOperation(
        _db,
        tabella: 'test_ingresso',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
      return TestIngresso(
        id: id,
        atletaId: atletaId,
        clubId: atleta.clubId,
        tipo: tipo,
        dataTest: dataTest,
        distanzaTotaleM: distanzaTotaleM,
        tempoTotaleS: tempoTotaleS,
        passoMedio100S: passoMedio,
        note: note,
      );
    }
  }

  double _calcolaPassoMedio(double tempoTotaleS, int distanzaTotaleM) {
    final passo = tempoTotaleS / distanzaTotaleM * 100;
    return (passo * 100).round() / 100;
  }

  TestIngresso _fromMap(Map<String, dynamic> map) {
    return TestIngresso(
      id: map['id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      dataTest: DateTime.parse(map['data_test'] as String),
      distanzaTotaleM: map['distanza_totale_m'] as int,
      tempoTotaleS: (map['tempo_totale_s'] as num).toDouble(),
      passoMedio100S: (map['passo_medio_100_s'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  Future<void> deleteTest(String id) async {
    try {
      await _client.from('test_ingresso').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'test_ingresso',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.testIngressoTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
