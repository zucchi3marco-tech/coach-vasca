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
import '../domain/tempo_gara.dart';

const _uuid = Uuid();

/// Storico dei tempi nuotati: a differenza dei Personal Best (un solo
/// tempo, il migliore, per stile+distanza), qui ogni tempo inserito
/// resta una voce a sé, per la curva delle prestazioni nel tempo.
/// Scrivibile sia dall'atleta a cui appartiene sia dal coach del suo
/// club (RLS lato server, stesso schema di PersonalBestRepository).
class TempiGaraRepository {
  TempiGaraRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  TempoGara _fromRow(TempiGaraTableData row) {
    return TempoGara(
      id: row.id,
      atletaId: row.atletaId,
      clubId: row.clubId,
      stile: row.stile,
      distanzaM: row.distanzaM,
      vascaM: row.vascaM,
      tempoS: row.tempoS,
      data: row.data,
      note: row.note,
      garaId: row.garaId,
    );
  }

  TempiGaraTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return TempiGaraTableCompanion.insert(
      id: map['id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stile: map['stile'] as String,
      distanzaM: map['distanza_m'] as int,
      vascaM: map['vasca_m'] as int,
      tempoS: (map['tempo_s'] as num).toDouble(),
      data: DateTime.parse(map['data'] as String),
      note: Value(map['note'] as String?),
      garaId: Value(map['gara_id'] as String?),
    );
  }

  Future<void> _salvaLocale(Map<String, dynamic> row) {
    return _db
        .into(_db.tempiGaraTable)
        .insertOnConflictUpdate(_companionFromMap(row));
  }

  Stream<List<TempoGara>> watchPerAtleta(String atletaId) {
    final query = _db.select(_db.tempiGaraTable)
      ..where((t) => t.atletaId.equals(atletaId))
      ..orderBy([(t) => OrderingTerm.asc(t.data)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// I tempi collegati a una gara (tutti gli atleti), per data.
  Stream<List<TempoGara>> watchPerGara(String garaId) {
    final query = _db.select(_db.tempiGaraTable)
      ..where((t) => t.garaId.equals(garaId))
      ..orderBy([(t) => OrderingTerm.asc(t.distanzaM)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale dei risultati di questa gara.
  Future<void> refreshFromRemotePerGara(String garaId) async {
    final rows = await _client
        .from('tempi_gara')
        .select()
        .eq('gara_id', garaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.tempiGaraTable,
      )..where((t) => t.garaId.equals(garaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(
            _db.tempiGaraTable,
            _companionFromMap(row),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  /// Sostituzione totale per questo atleta (non insertOrReplace): un
  /// tempo eliminato fuori dall'app resterebbe altrimenti "fantasma" in
  /// cache (stesso schema di PersonalBestRepository.refreshFromRemote).
  Future<void> refreshFromRemote(String atletaId) async {
    final rows = await _client
        .from('tempi_gara')
        .select()
        .eq('atleta_id', atletaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.tempiGaraTable,
      )..where((t) => t.atletaId.equals(atletaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.tempiGaraTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<void> creaTempoGara({
    required String atletaId,
    required String stile,
    required int distanzaM,
    required int vascaM,
    required double tempoS,
    required DateTime data,
    String? note,
    String? garaId,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'atleta_id': atletaId,
      'gara_id': ?garaId,
      'stile': stile,
      'distanza_m': distanzaM,
      'vasca_m': vascaM,
      'tempo_s': tempoS,
      'data': formatDateOnly(data),
      if (note != null && note.isNotEmpty) 'note': note,
    };
    try {
      final row = await _client
          .from('tempi_gara')
          .insert(payload)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final atleta = await (_db.select(
        _db.atletiTable,
      )..where((t) => t.id.equals(atletaId))).getSingle();
      await _salvaLocale({...payload, 'club_id': atleta.clubId});
      await enqueueOperation(
        _db,
        tabella: 'tempi_gara',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> aggiornaTempoGara({
    required String id,
    required String stile,
    required int distanzaM,
    required int vascaM,
    required double tempoS,
    required DateTime data,
    String? note,
  }) async {
    final payload = {
      'stile': stile,
      'distanza_m': distanzaM,
      'vasca_m': vascaM,
      'tempo_s': tempoS,
      'data': formatDateOnly(data),
      'note': note,
    };
    try {
      final row = await _client
          .from('tempi_gara')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.tempiGaraTable,
      )..where((t) => t.id.equals(id))).write(
        TempiGaraTableCompanion(
          stile: Value(stile),
          distanzaM: Value(distanzaM),
          vascaM: Value(vascaM),
          tempoS: Value(tempoS),
          data: Value(data),
          note: Value(note),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'tempi_gara',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> eliminaTempoGara(String id) async {
    try {
      await _client.from('tempi_gara').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'tempi_gara',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.tempiGaraTable)..where((t) => t.id.equals(id))).go();
  }
}

final tempiGaraRepositoryProvider = Provider<TempiGaraRepository>((ref) {
  return TempiGaraRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
