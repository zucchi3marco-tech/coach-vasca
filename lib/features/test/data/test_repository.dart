import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/date_format.dart';
import '../domain/test_ingresso.dart';

const _uuid = Uuid();

class TestRepository {
  TestRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

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

  Future<void> refreshFromRemote(String atletaId) async {
    final rows = await _client
        .from('test_ingresso')
        .select()
        .eq('atleta_id', atletaId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.testIngressoTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
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
    final row = await _client
        .from('test_ingresso')
        .insert({
          'id': id,
          'atleta_id': atletaId,
          'tipo': tipo,
          'data_test': formatDateOnly(dataTest),
          'distanza_totale_m': distanzaTotaleM,
          'tempo_totale_s': tempoTotaleS,
          if (note != null && note.isNotEmpty) 'note': note,
        })
        .select()
        .single();
    await _db
        .into(_db.testIngressoTable)
        .insertOnConflictUpdate(_companionFromMap(row));
    return _fromMap(row);
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
    await _client.from('test_ingresso').delete().eq('id', id);
    await (_db.delete(
      _db.testIngressoTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
