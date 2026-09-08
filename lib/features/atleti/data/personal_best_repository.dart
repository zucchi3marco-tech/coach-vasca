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
import '../domain/personal_best.dart';

const _uuid = Uuid();

/// I PB li può inserire/modificare/eliminare sia l'atleta a cui
/// appartengono sia l'allenatore del suo club (RLS lato server, FASE 10).
class PersonalBestRepository {
  PersonalBestRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  PersonalBest _fromRow(PersonalBestTableData row) {
    return PersonalBest(
      id: row.id,
      atletaId: row.atletaId,
      clubId: row.clubId,
      stile: row.stile,
      distanzaM: row.distanzaM,
      tempoS: row.tempoS,
      data: row.data,
      note: row.note,
    );
  }

  PersonalBestTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return PersonalBestTableCompanion.insert(
      id: map['id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stile: map['stile'] as String,
      distanzaM: map['distanza_m'] as int,
      tempoS: (map['tempo_s'] as num).toDouble(),
      data: Value(
        map['data'] == null ? null : DateTime.parse(map['data'] as String),
      ),
      note: Value(map['note'] as String?),
    );
  }

  Future<void> _salvaLocale(Map<String, dynamic> row) {
    return _db
        .into(_db.personalBestTable)
        .insertOnConflictUpdate(_companionFromMap(row));
  }

  Stream<List<PersonalBest>> watchPerAtleta(String atletaId) {
    final query = _db.select(_db.personalBestTable)
      ..where((t) => t.atletaId.equals(atletaId))
      ..orderBy([(t) => OrderingTerm.asc(t.distanzaM)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo atleta (non insertOrReplace): un PB
  /// eliminato fuori dall'app resterebbe altrimenti "fantasma" in cache.
  Future<void> refreshFromRemote(String atletaId) async {
    final rows = await _client
        .from('personal_best')
        .select()
        .eq('atleta_id', atletaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.personalBestTable,
      )..where((t) => t.atletaId.equals(atletaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.personalBestTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<void> creaPersonalBest({
    required String atletaId,
    required String stile,
    required int distanzaM,
    required double tempoS,
    DateTime? data,
    String? note,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'atleta_id': atletaId,
      'stile': stile,
      'distanza_m': distanzaM,
      'tempo_s': tempoS,
      if (data != null) 'data': formatDateOnly(data),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    try {
      final row = await _client
          .from('personal_best')
          .insert(payload)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id lo imposta di norma il trigger lato server: offline lo
      // ricaviamo dall'atleta gia' in cache locale, cosi' il PB compare
      // subito anche senza rete (stesso schema di PresenzeRepository).
      final atleta = await (_db.select(
        _db.atletiTable,
      )..where((t) => t.id.equals(atletaId))).getSingle();
      await _salvaLocale({...payload, 'club_id': atleta.clubId});
      await enqueueOperation(
        _db,
        tabella: 'personal_best',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> aggiornaPersonalBest({
    required String id,
    required String stile,
    required int distanzaM,
    required double tempoS,
    DateTime? data,
    String? note,
  }) async {
    final payload = {
      'stile': stile,
      'distanza_m': distanzaM,
      'tempo_s': tempoS,
      'data': data == null ? null : formatDateOnly(data),
      'note': note,
    };
    try {
      final row = await _client
          .from('personal_best')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.personalBestTable,
      )..where((t) => t.id.equals(id))).write(
        PersonalBestTableCompanion(
          stile: Value(stile),
          distanzaM: Value(distanzaM),
          tempoS: Value(tempoS),
          data: Value(data),
          note: Value(note),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'personal_best',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> eliminaPersonalBest(String id) async {
    try {
      await _client.from('personal_best').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'personal_best',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.personalBestTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final personalBestRepositoryProvider = Provider<PersonalBestRepository>((ref) {
  return PersonalBestRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
