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
      data: row.data,
      titolo: row.titolo,
      gruppoId: row.gruppoId,
      note: row.note,
    );
  }

  AllenamentiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return AllenamentiTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      data: DateTime.parse(map['data'] as String),
      titolo: Value(map['titolo'] as String?),
      gruppoId: Value(map['gruppo_id'] as String?),
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<Allenamento>> watchPerClub(String clubId) {
    final query = _db.select(_db.allenamentiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Letto da remoto quando possibile (dati sempre freschi per "Duplica
  /// settimana"), con fallback sulla cache locale se offline — stesso
  /// schema di `PartiteRepository.perClubEPeriodo`.
  Future<List<Allenamento>> fetchPerClubEPeriodo({
    required String clubId,
    required DateTime dataInizio,
    required DateTime dataFine,
  }) async {
    try {
      final rows = await leggiAPagine(
        (da, a) => _client
            .from('allenamenti')
            .select()
            .eq('club_id', clubId)
            .gte('data', formatDateOnly(dataInizio))
            .lte('data', formatDateOnly(dataFine))
            .order('id')
            .range(da, a),
      );
      return [for (final r in rows) Allenamento.fromMap(r)];
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe =
          await (_db.select(_db.allenamentiTable)
                ..where((t) => t.clubId.equals(clubId))
                ..where((t) => t.data.isBiggerOrEqualValue(dataInizio))
                ..where((t) => t.data.isSmallerOrEqualValue(dataFine)))
              .get();
      return righe.map(_fromRow).toList();
    }
  }

  /// Per l'atleta collegato (FASE 13, punto 3): l'accesso diretto alla
  /// tabella e' riservato al coach (l'atleta non ha una policy select
  /// club-wide, per non esporre le note di sedute di altri gruppi — vedi
  /// audit del 12/09), quindi si passa dalla funzione `allenamenti_atleta`
  /// che espone solo id/data/titolo/gruppo, mai `note`.
  Future<List<Allenamento>> fetchPerAtleta(String clubId) async {
    try {
      final righe = await leggiAPagine(
        (da, a) => _client.rpc('allenamenti_atleta').order('id').range(da, a),
      );
      return righe.map(Allenamento.fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe = await (_db.select(
        _db.allenamentiTable,
      )..where((t) => t.clubId.equals(clubId))).get();
      return righe.map(_fromRow).toList();
    }
  }

  /// Sostituzione totale per questo club (non insertOrReplace): un
  /// allenamento eliminato fuori dall'app resterebbe altrimenti in cache
  /// a tempo indeterminato.
  Future<void> refreshFromRemote(String clubId) async {
    // A pagine, come tutte le letture dell'intero club (vedi
    // [leggiAPagine]).
    final rows = await leggiAPagine(
      (da, a) => _client
          .from('allenamenti')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    await _db.transaction(() async {
      await (_db.delete(
        _db.allenamentiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.allenamentiTable, _companionFromMap(row));
        }
      });
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
    String? gruppoId,
    String? note,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'data': formatDateOnly(data),
      if (titolo != null && titolo.isNotEmpty) 'titolo': titolo,
      'gruppo_id': ?gruppoId,
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

  /// Manda solo i campi davvero cambiati rispetto a [originale] (sia
  /// online sia nella coda offline): un aggiornamento "a tutto il modulo"
  /// rischierebbe di riportare indietro un campo che un altro dispositivo
  /// ha modificato nel frattempo, anche se qui non è mai stato toccato.
  Future<Allenamento> updateAllenamento({
    required Allenamento originale,
    required DateTime data,
    String? titolo,
    String? gruppoId,
    String? note,
  }) async {
    final id = originale.id;
    final payload = <String, dynamic>{
      if (data != originale.data) 'data': formatDateOnly(data),
      if (titolo != originale.titolo) 'titolo': titolo,
      if (gruppoId != originale.gruppoId) 'gruppo_id': gruppoId,
      if (note != originale.note) 'note': note,
    };
    if (payload.isEmpty) return originale;

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
          data: payload.containsKey('data')
              ? Value(data)
              : const Value.absent(),
          titolo: payload.containsKey('titolo')
              ? Value(titolo)
              : const Value.absent(),
          gruppoId: payload.containsKey('gruppo_id')
              ? Value(gruppoId)
              : const Value.absent(),
          note: payload.containsKey('note')
              ? Value(note)
              : const Value.absent(),
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
    await _db.transaction(() async {
      await (_db.delete(
        _db.serieTable,
      )..where((t) => t.allenamentoId.equals(id))).go();
      await (_db.delete(
        _db.presenzeTable,
      )..where((t) => t.allenamentoId.equals(id))).go();
      await (_db.delete(
        _db.allenamentiTable,
      )..where((t) => t.id.equals(id))).go();
    });
  }
}

final allenamentiRepositoryProvider = Provider<AllenamentiRepository>((ref) {
  return AllenamentiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
