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
import '../domain/presenza.dart';

const _uuid = Uuid();

class PresenzeRepository {
  PresenzeRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Presenza _fromRow(PresenzeTableData row) {
    return Presenza(
      id: row.id,
      allenamentoId: row.allenamentoId,
      atletaId: row.atletaId,
      clubId: row.clubId,
      stato: row.stato,
      note: row.note,
    );
  }

  Presenza _fromMap(Map<String, dynamic> map) {
    return Presenza(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: map['note'] as String?,
    );
  }

  PresenzeTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return PresenzeTableCompanion.insert(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<Presenza>> watchPerAllenamento(String allenamentoId) {
    final query = _db.select(_db.presenzeTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String allenamentoId) async {
    final rows = await _client
        .from('presenze')
        .select()
        .eq('allenamento_id', allenamentoId);
    // Sostituzione totale (non insertOrReplace per id): una presenza creata
    // offline ha un id locale provvisorio diverso da quello che assegna il
    // server, altrimenti resterebbe duplicata dopo il sync.
    await _db.transaction(() async {
      await (_db.delete(
        _db.presenzeTable,
      )..where((t) => t.allenamentoId.equals(allenamentoId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.presenzeTable, _companionFromMap(row));
        }
      });
    });
  }

  /// club_id e' normalmente ricalcolato dal trigger
  /// `imposta_e_valida_presenza()` a partire da allenamento_id/atleta_id.
  /// Offline usiamo il club_id gia' in cache locale per l'allenamento; se
  /// esiste gia' una presenza locale per questo atleta la riusiamo (stesso
  /// id), altrimenti ne generiamo una nuova provvisoria.
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    final payload = {
      'allenamento_id': allenamentoId,
      'atleta_id': atletaId,
      'stato': stato,
    };
    try {
      final row = await _client
          .from('presenze')
          .upsert(payload, onConflict: 'allenamento_id,atleta_id')
          .select()
          .single();
      await _db
          .into(_db.presenzeTable)
          .insertOnConflictUpdate(_companionFromMap(row));
      return _fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final allenamento = await (_db.select(
        _db.allenamentiTable,
      )..where((t) => t.id.equals(allenamentoId))).getSingle();
      final esistente = await (_db.select(_db.presenzeTable)..where(
            (t) =>
                t.allenamentoId.equals(allenamentoId) &
                t.atletaId.equals(atletaId),
          ))
          .getSingleOrNull();
      final id = esistente?.id ?? _uuid.v4();
      final payloadCompleto = {...payload, 'id': id, 'club_id': allenamento.clubId};
      await _db
          .into(_db.presenzeTable)
          .insertOnConflictUpdate(_companionFromMap(payloadCompleto));
      await enqueueOperation(
        _db,
        tabella: 'presenze',
        operazione: 'upsert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
      return _fromMap(payloadCompleto);
    }
  }
}

final presenzeRepositoryProvider = Provider<PresenzeRepository>((ref) {
  return PresenzeRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
