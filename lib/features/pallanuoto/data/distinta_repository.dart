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
import '../domain/distinta_giocatore.dart';

const _uuid = Uuid();

class DistintaRepository {
  DistintaRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  DistintaGiocatore _fromRow(DistintaGiocatoriTableData row) {
    return DistintaGiocatore(
      id: row.id,
      partitaId: row.partitaId,
      atletaId: row.atletaId,
      clubId: row.clubId,
      numeroCalottina: row.numeroCalottina,
      capitano: row.capitano,
      viceCapitano: row.viceCapitano,
      portiere: row.portiere,
      fuoriquota: row.fuoriquota,
    );
  }

  DistintaGiocatoriTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return DistintaGiocatoriTableCompanion.insert(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      numeroCalottina: map['numero_calottina'] as int,
      capitano: Value(map['capitano'] as bool? ?? false),
      viceCapitano: Value(map['vice_capitano'] as bool? ?? false),
      portiere: Value(map['portiere'] as bool? ?? false),
      fuoriquota: Value(map['fuoriquota'] as bool? ?? false),
    );
  }

  Stream<List<DistintaGiocatore>> watchPerPartita(String partitaId) {
    final query = _db.select(_db.distintaGiocatoriTable)
      ..where((t) => t.partitaId.equals(partitaId))
      ..orderBy([(t) => OrderingTerm.asc(t.numeroCalottina)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questa partita (non insertOrReplace): un
  /// convocato rimosso fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String partitaId) async {
    final rows = await _client
        .from('distinta_giocatori')
        .select()
        .eq('partita_id', partitaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.distintaGiocatoriTable,
      )..where((t) => t.partitaId.equals(partitaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.distintaGiocatoriTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<DistintaGiocatore> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.distintaGiocatoriTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<DistintaGiocatore> aggiungiConvocato({
    required String partitaId,
    required String atletaId,
    required int numeroCalottina,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'partita_id': partitaId,
      'atleta_id': atletaId,
      'numero_calottina': numeroCalottina,
    };
    try {
      final row = await _client
          .from('distinta_giocatori')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.distintaGiocatoriTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id e' normalmente ricalcolato dal trigger a partire dalla
      // partita: offline usiamo quello gia' in cache locale.
      final partita = await (_db.select(
        _db.partiteTable,
      )..where((t) => t.id.equals(partitaId))).getSingle();
      final payloadConClub = {...payload, 'club_id': partita.clubId};
      await _db
          .into(_db.distintaGiocatoriTable)
          .insertOnConflictUpdate(_companionFromMap(payloadConClub));
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<DistintaGiocatore> aggiornaConvocato({
    required String id,
    required int numeroCalottina,
    required bool capitano,
    required bool viceCapitano,
    required bool portiere,
    required bool fuoriquota,
  }) async {
    final payload = {
      'numero_calottina': numeroCalottina,
      'capitano': capitano,
      'vice_capitano': viceCapitano,
      'portiere': portiere,
      'fuoriquota': fuoriquota,
    };
    try {
      final row = await _client
          .from('distinta_giocatori')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.distintaGiocatoriTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.distintaGiocatoriTable,
      )..where((t) => t.id.equals(id))).write(
        DistintaGiocatoriTableCompanion(
          numeroCalottina: Value(numeroCalottina),
          capitano: Value(capitano),
          viceCapitano: Value(viceCapitano),
          portiere: Value(portiere),
          fuoriquota: Value(fuoriquota),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> rimuoviConvocato(String id) async {
    try {
      await _client.from('distinta_giocatori').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.distintaGiocatoriTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final distintaRepositoryProvider = Provider<DistintaRepository>((ref) {
  return DistintaRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
