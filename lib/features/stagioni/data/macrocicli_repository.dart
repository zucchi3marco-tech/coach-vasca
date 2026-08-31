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
import '../domain/macrociclo.dart';

const _uuid = Uuid();

class MacrocicliRepository {
  MacrocicliRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Macrociclo _fromRow(MacrocicliTableData row) {
    return Macrociclo(
      id: row.id,
      stagioneId: row.stagioneId,
      clubId: row.clubId,
      nome: row.nome,
      ordine: row.ordine,
      dataInizio: row.dataInizio,
      dataFine: row.dataFine,
      obiettivo: row.obiettivo,
    );
  }

  MacrocicliTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return MacrocicliTableCompanion.insert(
      id: map['id'] as String,
      stagioneId: map['stagione_id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      ordine: Value(map['ordine'] as int? ?? 1),
      dataInizio: DateTime.parse(map['data_inizio'] as String),
      dataFine: DateTime.parse(map['data_fine'] as String),
      obiettivo: Value(map['obiettivo'] as String?),
    );
  }

  Stream<List<Macrociclo>> watchPerStagione(String stagioneId) {
    final query = _db.select(_db.macrocicliTable)
      ..where((t) => t.stagioneId.equals(stagioneId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String stagioneId) async {
    final rows = await _client
        .from('macrocicli')
        .select()
        .eq('stagione_id', stagioneId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.macrocicliTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Macrociclo> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.macrocicliTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Macrociclo> createMacrociclo({
    required String stagioneId,
    required String nome,
    required int ordine,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'stagione_id': stagioneId,
      'nome': nome,
      'ordine': ordine,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      if (obiettivo != null && obiettivo.isNotEmpty) 'obiettivo': obiettivo,
    };
    try {
      final row = await _client
          .from('macrocicli')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.macrocicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final stagione = await (_db.select(
        _db.stagioniTable,
      )..where((t) => t.id.equals(stagioneId))).getSingle();
      await _db
          .into(_db.macrocicliTable)
          .insertOnConflictUpdate(
            _companionFromMap({...payload, 'club_id': stagione.clubId}),
          );
      await enqueueOperation(
        _db,
        tabella: 'macrocicli',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Macrociclo> updateMacrociclo({
    required String id,
    required String nome,
    required int ordine,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
  }) async {
    final payload = {
      'nome': nome,
      'ordine': ordine,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      'obiettivo': obiettivo,
    };
    try {
      final row = await _client
          .from('macrocicli')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.macrocicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.macrocicliTable,
      )..where((t) => t.id.equals(id))).write(
        MacrocicliTableCompanion(
          nome: Value(nome),
          ordine: Value(ordine),
          dataInizio: Value(dataInizio),
          dataFine: Value(dataFine),
          obiettivo: Value(obiettivo),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'macrocicli',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteMacrociclo(String id) async {
    try {
      await _client.from('macrocicli').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'macrocicli',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.macrocicliTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final macrocicliRepositoryProvider = Provider<MacrocicliRepository>((ref) {
  return MacrocicliRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
