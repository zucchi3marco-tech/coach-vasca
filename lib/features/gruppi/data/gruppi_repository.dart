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
import '../domain/gruppo.dart';

const _uuid = Uuid();

class GruppiRepository {
  GruppiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Gruppo _fromRow(GruppiTableData row) {
    return Gruppo(
      id: row.id,
      clubId: row.clubId,
      nome: row.nome,
      ordine: row.ordine,
      sport: row.sport,
    );
  }

  GruppiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return GruppiTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      ordine: Value(map['ordine'] as int? ?? 1),
      sport: Value(map['sport'] as String?),
    );
  }

  Stream<List<Gruppo>> watchPerClub(String clubId) {
    final query = _db.select(_db.gruppiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo club (non insertOrReplace): un gruppo
  /// eliminato fuori dall'app resterebbe altrimenti in cache a tempo
  /// indeterminato.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client.from('gruppi').select().eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.gruppiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.gruppiTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<Gruppo> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.gruppiTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Gruppo> createGruppo({
    required String clubId,
    required String nome,
    required int ordine,
    String? sport,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'nome': nome,
      'ordine': ordine,
      'sport': sport,
    };
    try {
      final row = await _client
          .from('gruppi')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.gruppiTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.gruppiTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'gruppi',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Gruppo> updateGruppo({
    required String id,
    required String nome,
    required int ordine,
  }) async {
    final payload = {'nome': nome, 'ordine': ordine};
    try {
      final row = await _client
          .from('gruppi')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.gruppiTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.gruppiTable)..where((t) => t.id.equals(id))).write(
        GruppiTableCompanion(nome: Value(nome), ordine: Value(ordine)),
      );
      await enqueueOperation(
        _db,
        tabella: 'gruppi',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deleteGruppo(String id) async {
    try {
      await _client.from('gruppi').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'gruppi',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.gruppiTable)..where((t) => t.id.equals(id))).go();
  }
}

final gruppiRepositoryProvider = Provider<GruppiRepository>((ref) {
  return GruppiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
