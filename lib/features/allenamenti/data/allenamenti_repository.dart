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
import '../domain/allenamento.dart';

const _uuid = Uuid();

class AllenamentiRepository {
  AllenamentiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Allenamento _fromRow(AllenamentiTableData row) {
    return Allenamento(
      id: row.id,
      clubId: row.clubId,
      microcicloId: row.microcicloId,
      data: row.data,
      titolo: row.titolo,
      gruppo: row.gruppo,
      note: row.note,
    );
  }

  AllenamentiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return AllenamentiTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      microcicloId: Value(map['microciclo_id'] as String?),
      data: DateTime.parse(map['data'] as String),
      titolo: Value(map['titolo'] as String?),
      gruppo: Value(map['gruppo'] as String?),
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<Allenamento>> watchPerClub(String clubId) {
    final query = _db.select(_db.allenamentiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client
        .from('allenamenti')
        .select()
        .eq('club_id', clubId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.allenamentiTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Allenamento> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.allenamentiTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Allenamento> createAllenamento({
    required String clubId,
    required DateTime data,
    String? titolo,
    String? gruppo,
    String? note,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'data': formatDateOnly(data),
      if (titolo != null && titolo.isNotEmpty) 'titolo': titolo,
      if (gruppo != null && gruppo.isNotEmpty) 'gruppo': gruppo,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    try {
      final row = await _client
          .from('allenamenti')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.allenamentiTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.allenamentiTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'allenamenti',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Allenamento> updateAllenamento({
    required String id,
    required DateTime data,
    String? titolo,
    String? gruppo,
    String? note,
  }) async {
    final payload = {
      'data': formatDateOnly(data),
      'titolo': titolo,
      'gruppo': gruppo,
      'note': note,
    };
    try {
      final row = await _client
          .from('allenamenti')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.allenamentiTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.allenamentiTable,
      )..where((t) => t.id.equals(id))).write(
        AllenamentiTableCompanion(
          data: Value(data),
          titolo: Value(titolo),
          gruppo: Value(gruppo),
          note: Value(note),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'allenamenti',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteAllenamento(String id) async {
    try {
      await _client.from('allenamenti').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'allenamenti',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.allenamentiTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final allenamentiRepositoryProvider = Provider<AllenamentiRepository>((ref) {
  return AllenamentiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
