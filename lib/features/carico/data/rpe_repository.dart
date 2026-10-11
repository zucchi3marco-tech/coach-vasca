import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/leggi_a_pagine.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/utils/date_format.dart';
import '../domain/rpe_seduta.dart';

const _uuid = Uuid();

/// RPE di fine seduta: scritto dall'atleta (o dall'allenatore per lui),
/// letto anche dall'allenatore del club. Uno per atleta e per seduta,
/// salvato con upsert sulla chiave naturale, come le schede benessere.
class RpeRepository {
  RpeRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  RpeSeduta _fromRow(RpeSeduteTableData r) => RpeSeduta(
    id: r.id,
    atletaId: r.atletaId,
    clubId: r.clubId,
    eventoTipo: r.eventoTipo,
    eventoId: r.eventoId,
    data: r.data,
    rpe: r.rpe,
  );

  RpeSeduteTableCompanion _companionFromMap(Map<String, dynamic> m) =>
      RpeSeduteTableCompanion.insert(
        id: m['id'] as String,
        atletaId: m['atleta_id'] as String,
        clubId: m['club_id'] as String,
        eventoTipo: m['evento_tipo'] as String,
        eventoId: m['evento_id'] as String,
        data: DateTime.parse(m['data'] as String),
        rpe: m['rpe'] as int,
      );

  Stream<List<RpeSeduta>> watchPerAtleta(String atletaId) {
    final q = _db.select(_db.rpeSeduteTable)
      ..where((t) => t.atletaId.equals(atletaId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return q.watch().map((righe) => righe.map(_fromRow).toList());
  }

  Stream<List<RpeSeduta>> watchPerClub(String clubId) {
    final q = _db.select(_db.rpeSeduteTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return q.watch().map((righe) => righe.map(_fromRow).toList());
  }

  /// Le risposte di un atleta: dal server, o dalla cache senza rete.
  Future<List<RpeSeduta>> perAtleta(String atletaId) async {
    try {
      await refreshFromRemote(atletaId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
    }
    return watchPerAtleta(atletaId).first;
  }

  /// Le risposte di tutto il club (solo l'allenatore le vede tutte).
  Future<List<RpeSeduta>> perClub(String clubId) async {
    try {
      await refreshFromRemoteClub(clubId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
    }
    return watchPerClub(clubId).first;
  }

  /// Sostituzione totale per il club, a pagine (vedi [leggiAPagine]).
  Future<void> refreshFromRemoteClub(String clubId) async {
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('rpe_sedute')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    await _db.transaction(() async {
      await (_db.delete(
        _db.rpeSeduteTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.rpeSeduteTable, _companionFromMap(r));
        }
      });
    });
  }

  /// Sostituzione totale per l'atleta: una risposta cancellata fuori
  /// dall'app non resta in cache.
  Future<void> refreshFromRemote(String atletaId) async {
    final righe = await _client
        .from('rpe_sedute')
        .select()
        .eq('atleta_id', atletaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.rpeSeduteTable,
      )..where((t) => t.atletaId.equals(atletaId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.rpeSeduteTable, _companionFromMap(r));
        }
      });
    });
  }

  /// Salva (o aggiorna) l'RPE di una seduta. Senza rete va in locale e in
  /// coda, e parte appena torna la rete.
  Future<void> salva({
    required String atletaId,
    required String clubId,
    required String eventoTipo,
    required String eventoId,
    required DateTime data,
    required int rpe,
  }) async {
    final esistente =
        await (_db.select(_db.rpeSeduteTable)..where(
              (t) =>
                  t.atletaId.equals(atletaId) &
                  t.eventoTipo.equals(eventoTipo) &
                  t.eventoId.equals(eventoId),
            ))
            .getSingleOrNull();
    final payload = {
      'id': esistente?.id ?? _uuid.v4(),
      'atleta_id': atletaId,
      'club_id': clubId,
      'evento_tipo': eventoTipo,
      'evento_id': eventoId,
      'data': formatDateOnly(data),
      'rpe': rpe,
    };
    try {
      final riga = await _client
          .from('rpe_sedute')
          .upsert(payload, onConflict: 'atleta_id,evento_tipo,evento_id')
          .select()
          .single();
      await _db
          .into(_db.rpeSeduteTable)
          .insertOnConflictUpdate(_companionFromMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.rpeSeduteTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'rpe_sedute',
        operazione: 'upsert',
        rigaId: payload['id']! as String,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }
}

final rpeRepositoryProvider = Provider<RpeRepository>(
  (ref) => RpeRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  ),
);
