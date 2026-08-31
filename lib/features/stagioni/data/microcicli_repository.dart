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
import '../domain/microciclo.dart';

const _uuid = Uuid();

class MicrocicliRepository {
  MicrocicliRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Microciclo _fromRow(MicrocicliTableData row) {
    return Microciclo(
      id: row.id,
      mesocicloId: row.mesocicloId,
      clubId: row.clubId,
      nome: row.nome,
      numeroSettimana: row.numeroSettimana,
      ordine: row.ordine,
      dataInizio: row.dataInizio,
      dataFine: row.dataFine,
      tipo: row.tipo,
    );
  }

  MicrocicliTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return MicrocicliTableCompanion.insert(
      id: map['id'] as String,
      mesocicloId: map['mesociclo_id'] as String,
      clubId: map['club_id'] as String,
      nome: Value(map['nome'] as String?),
      numeroSettimana: Value(map['numero_settimana'] as int?),
      ordine: Value(map['ordine'] as int? ?? 1),
      dataInizio: DateTime.parse(map['data_inizio'] as String),
      dataFine: DateTime.parse(map['data_fine'] as String),
      tipo: Value(map['tipo'] as String?),
    );
  }

  Stream<List<Microciclo>> watchPerMesociclo(String mesocicloId) {
    final query = _db.select(_db.microcicliTable)
      ..where((t) => t.mesocicloId.equals(mesocicloId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String mesocicloId) async {
    final rows = await _client
        .from('microcicli')
        .select()
        .eq('mesociclo_id', mesocicloId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.microcicliTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Microciclo> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.microcicliTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Microciclo> createMicrociclo({
    required String mesocicloId,
    String? nome,
    int? numeroSettimana,
    required int ordine,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? tipo,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'mesociclo_id': mesocicloId,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      'numero_settimana': ?numeroSettimana,
      'ordine': ordine,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
    };
    try {
      final row = await _client
          .from('microcicli')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.microcicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final mesociclo = await (_db.select(
        _db.mesocicliTable,
      )..where((t) => t.id.equals(mesocicloId))).getSingle();
      await _db
          .into(_db.microcicliTable)
          .insertOnConflictUpdate(
            _companionFromMap({...payload, 'club_id': mesociclo.clubId}),
          );
      await enqueueOperation(
        _db,
        tabella: 'microcicli',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Microciclo> updateMicrociclo({
    required String id,
    String? nome,
    int? numeroSettimana,
    required int ordine,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? tipo,
  }) async {
    final payload = {
      'nome': nome,
      'numero_settimana': numeroSettimana,
      'ordine': ordine,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      'tipo': tipo,
    };
    try {
      final row = await _client
          .from('microcicli')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.microcicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.microcicliTable,
      )..where((t) => t.id.equals(id))).write(
        MicrocicliTableCompanion(
          nome: Value(nome),
          numeroSettimana: Value(numeroSettimana),
          ordine: Value(ordine),
          dataInizio: Value(dataInizio),
          dataFine: Value(dataFine),
          tipo: Value(tipo),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'microcicli',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteMicrociclo(String id) async {
    try {
      await _client.from('microcicli').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'microcicli',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.microcicliTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final microcicliRepositoryProvider = Provider<MicrocicliRepository>((ref) {
  return MicrocicliRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
