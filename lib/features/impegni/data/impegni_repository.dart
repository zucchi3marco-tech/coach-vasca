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
import '../../../core/utils/giorni.dart';
import '../domain/impegno.dart';

const _uuid = Uuid();

/// Gli impegni fuori calendario: scrive prima su Supabase e solo se manca
/// la rete accoda l'operazione (come gare e partite).
class ImpegniRepository {
  ImpegniRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Impegno _fromRow(ImpegniTableData row) => Impegno(
    id: row.id,
    clubId: row.clubId,
    gruppoId: row.gruppoId,
    tipo: TipoImpegno.daValore(row.tipo),
    dal: row.dal,
    al: row.al,
    nome: row.nome,
    luogo: row.luogo,
    note: row.note,
  );

  ImpegniTableCompanion _companionFromMap(Map<String, dynamic> map) =>
      ImpegniTableCompanion.insert(
        id: map['id'] as String,
        clubId: map['club_id'] as String,
        gruppoId: Value(map['gruppo_id'] as String?),
        tipo: map['tipo'] as String,
        dal: DateTime.parse(map['dal'] as String),
        al: DateTime.parse(map['al'] as String),
        nome: Value(map['nome'] as String?),
        luogo: Value(map['luogo'] as String?),
        note: Value(map['note'] as String?),
      );

  Stream<List<Impegno>> watchPerClub(String clubId) {
    final query = _db.select(_db.impegniTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.dal)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per il club: un impegno tolto fuori dall'app
  /// resterebbe altrimenti nella copia del telefono.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client.from('impegni').select().eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.impegniTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.impegniTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<Impegno> _rileggiLocale(String id) async => _fromRow(
    await (_db.select(
      _db.impegniTable,
    )..where((t) => t.id.equals(id))).getSingle(),
  );

  static String? _pulito(String? testo) {
    final t = testo?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  Map<String, dynamic> _campi({
    required String? gruppoId,
    required TipoImpegno tipo,
    required DateTime dal,
    required DateTime al,
    String? nome,
    String? luogo,
    String? note,
  }) => {
    'gruppo_id': gruppoId,
    'tipo': tipo.name,
    'dal': formatDateOnly(dal),
    'al': formatDateOnly(al),
    'nome': _pulito(nome),
    'luogo': _pulito(luogo),
    'note': _pulito(note),
  };

  Future<Impegno> crea({
    required String clubId,
    String? gruppoId,
    required TipoImpegno tipo,
    required DateTime dal,
    required DateTime al,
    String? nome,
    String? luogo,
    String? note,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      ..._campi(
        gruppoId: gruppoId,
        tipo: tipo,
        dal: dal,
        al: al,
        nome: nome,
        luogo: luogo,
        note: note,
      ),
    };
    try {
      final row = await _client
          .from('impegni')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.impegniTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.impegniTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'impegni',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Impegno> aggiorna({
    required String id,
    String? gruppoId,
    required TipoImpegno tipo,
    required DateTime dal,
    required DateTime al,
    String? nome,
    String? luogo,
    String? note,
  }) async {
    final payload = _campi(
      gruppoId: gruppoId,
      tipo: tipo,
      dal: dal,
      al: al,
      nome: nome,
      luogo: luogo,
      note: note,
    );
    try {
      final row = await _client
          .from('impegni')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.impegniTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.impegniTable)..where((t) => t.id.equals(id))).write(
        ImpegniTableCompanion(
          gruppoId: Value(gruppoId),
          tipo: Value(tipo.name),
          dal: Value(soloData(dal)),
          al: Value(soloData(al)),
          nome: Value(payload['nome'] as String?),
          luogo: Value(payload['luogo'] as String?),
          note: Value(payload['note'] as String?),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'impegni',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> elimina(String id) async {
    try {
      await _client.from('impegni').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'impegni',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.impegniTable)..where((t) => t.id.equals(id))).go();
  }
}

final impegniRepositoryProvider = Provider<ImpegniRepository>((ref) {
  return ImpegniRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
