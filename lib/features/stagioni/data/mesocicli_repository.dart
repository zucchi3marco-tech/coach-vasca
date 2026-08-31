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
import '../domain/mesociclo.dart';

const _uuid = Uuid();

class MesocicliRepository {
  MesocicliRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Mesociclo _fromRow(MesocicliTableData row) {
    return Mesociclo(
      id: row.id,
      macrocicloId: row.macrocicloId,
      clubId: row.clubId,
      nome: row.nome,
      ordine: row.ordine,
      dataInizio: row.dataInizio,
      dataFine: row.dataFine,
      obiettivo: row.obiettivo,
    );
  }

  MesocicliTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return MesocicliTableCompanion.insert(
      id: map['id'] as String,
      macrocicloId: map['macrociclo_id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      ordine: Value(map['ordine'] as int? ?? 1),
      dataInizio: DateTime.parse(map['data_inizio'] as String),
      dataFine: DateTime.parse(map['data_fine'] as String),
      obiettivo: Value(map['obiettivo'] as String?),
    );
  }

  Stream<List<Mesociclo>> watchPerMacrociclo(String macrocicloId) {
    final query = _db.select(_db.mesocicliTable)
      ..where((t) => t.macrocicloId.equals(macrocicloId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo macrociclo (non insertOrReplace): un
  /// mesociclo eliminato fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String macrocicloId) async {
    final rows = await _client
        .from('mesocicli')
        .select()
        .eq('macrociclo_id', macrocicloId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.mesocicliTable,
      )..where((t) => t.macrocicloId.equals(macrocicloId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.mesocicliTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<Mesociclo> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.mesocicliTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Mesociclo> createMesociclo({
    required String macrocicloId,
    required String nome,
    required int ordine,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'macrociclo_id': macrocicloId,
      'nome': nome,
      'ordine': ordine,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      if (obiettivo != null && obiettivo.isNotEmpty) 'obiettivo': obiettivo,
    };
    try {
      final row = await _client
          .from('mesocicli')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.mesocicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final macrociclo = await (_db.select(
        _db.macrocicliTable,
      )..where((t) => t.id.equals(macrocicloId))).getSingle();
      await _db
          .into(_db.mesocicliTable)
          .insertOnConflictUpdate(
            _companionFromMap({...payload, 'club_id': macrociclo.clubId}),
          );
      await enqueueOperation(
        _db,
        tabella: 'mesocicli',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Mesociclo> updateMesociclo({
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
          .from('mesocicli')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.mesocicliTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.mesocicliTable,
      )..where((t) => t.id.equals(id))).write(
        MesocicliTableCompanion(
          nome: Value(nome),
          ordine: Value(ordine),
          dataInizio: Value(dataInizio),
          dataFine: Value(dataFine),
          obiettivo: Value(obiettivo),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'mesocicli',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteMesociclo(String id) async {
    try {
      await _client.from('mesocicli').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'mesocicli',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.mesocicliTable)..where((t) => t.id.equals(id))).go();
  }
}

final mesocicliRepositoryProvider = Provider<MesocicliRepository>((ref) {
  return MesocicliRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
