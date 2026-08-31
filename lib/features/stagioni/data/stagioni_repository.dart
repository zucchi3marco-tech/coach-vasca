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
import '../domain/stagione.dart';

const _uuid = Uuid();

class StagioniRepository {
  StagioniRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Stagione _fromRow(StagioniTableData row) {
    return Stagione(
      id: row.id,
      clubId: row.clubId,
      nome: row.nome,
      dataInizio: row.dataInizio,
      dataFine: row.dataFine,
      obiettivo: row.obiettivo,
      gruppo: row.gruppo,
    );
  }

  StagioniTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return StagioniTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      dataInizio: DateTime.parse(map['data_inizio'] as String),
      dataFine: DateTime.parse(map['data_fine'] as String),
      obiettivo: Value(map['obiettivo'] as String?),
      gruppo: Value(map['gruppo'] as String?),
    );
  }

  Stream<List<Stagione>> watchPerClub(String clubId) {
    final query = _db.select(_db.stagioniTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.dataInizio)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo club (non insertOrReplace): una
  /// stagione eliminata fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client
        .from('stagioni')
        .select()
        .eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.stagioniTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.stagioniTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<Stagione> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.stagioniTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Stagione> createStagione({
    required String clubId,
    required String nome,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
    String? gruppo,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'nome': nome,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      if (obiettivo != null && obiettivo.isNotEmpty) 'obiettivo': obiettivo,
      if (gruppo != null && gruppo.isNotEmpty) 'gruppo': gruppo,
    };
    try {
      final row = await _client
          .from('stagioni')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.stagioniTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.stagioniTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'stagioni',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Stagione> updateStagione({
    required String id,
    required String nome,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
    String? gruppo,
  }) async {
    final payload = {
      'nome': nome,
      'data_inizio': formatDateOnly(dataInizio),
      'data_fine': formatDateOnly(dataFine),
      'obiettivo': obiettivo,
      'gruppo': gruppo,
    };
    try {
      final row = await _client
          .from('stagioni')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.stagioniTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.stagioniTable,
      )..where((t) => t.id.equals(id))).write(
        StagioniTableCompanion(
          nome: Value(nome),
          dataInizio: Value(dataInizio),
          dataFine: Value(dataFine),
          obiettivo: Value(obiettivo),
          gruppo: Value(gruppo),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'stagioni',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteStagione(String id) async {
    try {
      await _client.from('stagioni').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'stagioni',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.stagioniTable)..where((t) => t.id.equals(id))).go();
  }
}

final stagioniRepositoryProvider = Provider<StagioniRepository>((ref) {
  return StagioniRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
