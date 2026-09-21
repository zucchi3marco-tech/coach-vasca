import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/gara_iscritto.dart';

const _uuid = Uuid();

/// Atleti iscritti alle gare: stesso schema della distinta di una
/// partita (riga con id proprio, unica per gara+atleta).
class GaraIscrittiRepository {
  GaraIscrittiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  GaraIscritto _fromRow(GaraIscrittiTableData row) {
    return GaraIscritto(
      id: row.id,
      garaId: row.garaId,
      atletaId: row.atletaId,
      clubId: row.clubId,
    );
  }

  GaraIscrittiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return GaraIscrittiTableCompanion.insert(
      id: map['id'] as String,
      garaId: map['gara_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
    );
  }

  Stream<List<GaraIscritto>> watchPerGara(String garaId) {
    final query = _db.select(_db.garaIscrittiTable)
      ..where((t) => t.garaId.equals(garaId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questa gara (non insertOrReplace): un
  /// iscritto rimosso fuori dall'app resterebbe altrimenti in cache.
  Future<void> refreshFromRemote(String garaId) async {
    final rows = await _client
        .from('gara_iscritti')
        .select()
        .eq('gara_id', garaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.garaIscrittiTable,
      )..where((t) => t.garaId.equals(garaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.garaIscrittiTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<void> iscrivi({
    required String garaId,
    required String atletaId,
    required String clubId,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'gara_id': garaId,
      'atleta_id': atletaId,
      'club_id': clubId,
    };
    try {
      final row = await _client
          .from('gara_iscritti')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.garaIscrittiTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.garaIscrittiTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'gara_iscritti',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> rimuovi(String id) async {
    try {
      await _client.from('gara_iscritti').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'gara_iscritti',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.garaIscrittiTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final garaIscrittiRepositoryProvider = Provider<GaraIscrittiRepository>((ref) {
  return GaraIscrittiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
