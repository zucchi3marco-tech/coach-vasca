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
import '../domain/gara.dart';

const _uuid = Uuid();

/// Gare del nuoto: scrive prima su Supabase e solo se manca la rete
/// accoda l'operazione (stesso schema di partite e schemi tattici).
class GareRepository {
  GareRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Gara _fromRow(GareTableData row) {
    return Gara(
      id: row.id,
      clubId: row.clubId,
      gruppoId: row.gruppoId,
      data: row.data,
      ora: row.ora,
      luogo: row.luogo,
      nome: row.nome,
      note: row.note,
      importanza: row.importanza,
    );
  }

  GareTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return GareTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      gruppoId: Value(map['gruppo_id'] as String?),
      data: DateTime.parse(map['data'] as String),
      ora: Value(map['ora'] as String?),
      luogo: Value(map['luogo'] as String?),
      nome: map['nome'] as String,
      note: Value(map['note'] as String?),
      importanza: Value(map['importanza'] as String? ?? 'media'),
    );
  }

  Stream<List<Gara>> watchPerClub(String clubId) {
    final query = _db.select(_db.gareTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.data)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per il club (non insertOrReplace): una gara
  /// eliminata fuori dall'app resterebbe altrimenti in cache.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client.from('gare').select().eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.gareTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.gareTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<Gara> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.gareTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Gara> createGara({
    required String clubId,
    String? gruppoId,
    required DateTime data,
    String? ora,
    String? luogo,
    required String nome,
    String? note,
    String importanza = 'media',
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'gruppo_id': ?gruppoId,
      'data': formatDateOnly(data),
      if (ora != null && ora.isNotEmpty) 'ora': ora,
      if (luogo != null && luogo.isNotEmpty) 'luogo': luogo,
      'nome': nome,
      if (note != null && note.isNotEmpty) 'note': note,
      'importanza': importanza,
    };
    try {
      final row = await _client.from('gare').insert(payload).select().single();
      await _db
          .into(_db.gareTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.gareTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'gare',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Gara> updateGara({
    required String id,
    String? gruppoId,
    required DateTime data,
    String? ora,
    String? luogo,
    required String nome,
    String? note,
    String importanza = 'media',
  }) async {
    final payload = {
      'gruppo_id': gruppoId,
      'data': formatDateOnly(data),
      'ora': ora,
      'luogo': luogo,
      'nome': nome,
      'note': note,
      'importanza': importanza,
    };
    try {
      final row = await _client
          .from('gare')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.gareTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.gareTable)..where((t) => t.id.equals(id))).write(
        GareTableCompanion(
          gruppoId: Value(gruppoId),
          data: Value(data),
          ora: Value(ora),
          luogo: Value(luogo),
          nome: Value(nome),
          note: Value(note),
          importanza: Value(importanza),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'gare',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteGara(String id) async {
    try {
      await _client.from('gare').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'gare',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.gareTable)..where((t) => t.id.equals(id))).go();
  }
}

final gareRepositoryProvider = Provider<GareRepository>((ref) {
  return GareRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
