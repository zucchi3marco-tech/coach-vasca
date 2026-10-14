import 'dart:convert';

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
import '../domain/test_club.dart';

const _uuid = Uuid();

/// I test del club e i loro risultati. Ogni scrittura prova prima il
/// server; senza rete va nella copia locale e in coda, e parte appena
/// torna la rete (a bordo vasca succede): vedi `SyncEngine`.
class TestClubRepository {
  TestClubRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  TestClub _testDaRiga(TestClubTableData r) => TestClub(
    id: r.id,
    clubId: r.clubId,
    nome: r.nome,
    descrizione: r.descrizione,
    unita: UnitaTest.daNome(r.unita),
    piuBassoMeglio: r.migliore == 'minore',
    prove: r.prove,
    punteggio: PunteggioTest.daNome(r.punteggio),
    modello: r.modello,
    archiviato: r.archiviato,
    esercizioId: r.esercizioId,
  );

  TestClubTableCompanion _testDaMap(Map<String, dynamic> m) =>
      TestClubTableCompanion.insert(
        id: m['id'] as String,
        clubId: m['club_id'] as String,
        nome: m['nome'] as String,
        descrizione: Value(m['descrizione'] as String?),
        unita: m['unita'] as String,
        migliore: m['migliore'] as String,
        prove: Value((m['prove'] as num?)?.toInt() ?? 1),
        punteggio: Value(m['punteggio'] as String? ?? 'migliore'),
        modello: Value(m['modello'] as String?),
        archiviato: Value(m['archiviato'] as bool? ?? false),
        esercizioId: Value(m['esercizio_id'] as String?),
      );

  RisultatoTest _risultatoDaRiga(TestRisultatiTableData r) => RisultatoTest(
    id: r.id,
    testId: r.testId,
    atletaId: r.atletaId,
    clubId: r.clubId,
    data: r.data,
    valori: valoriDa(r.valoriJson),
    note: r.note,
    caricoKg: r.caricoKg,
    ripetizioni: r.ripetizioni,
  );

  TestRisultatiTableCompanion _risultatoDaMap(Map<String, dynamic> m) =>
      TestRisultatiTableCompanion.insert(
        id: m['id'] as String,
        testId: m['test_id'] as String,
        atletaId: m['atleta_id'] as String,
        clubId: m['club_id'] as String,
        data: DateTime.parse(m['data'] as String),
        valoriJson: jsonEncode(valoriDa(m['valori'])),
        note: Value(m['note'] as String?),
        caricoKg: Value((m['carico_kg'] as num?)?.toDouble()),
        ripetizioni: Value((m['ripetizioni'] as num?)?.toInt()),
      );

  // -------------------------------------------------------------------------
  // Test

  Stream<List<TestClub>> watchTest(String clubId) {
    final q = _db.select(_db.testClubTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.nome)]);
    return q.watch().map((righe) => righe.map(_testDaRiga).toList());
  }

  /// Sostituzione totale per il club: un test eliminato altrove non resta.
  Future<void> refreshTest(String clubId) async {
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('test_club')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    await _db.transaction(() async {
      await (_db.delete(
        _db.testClubTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.testClubTable, _testDaMap(r));
        }
      });
    });
  }

  /// Crea un test nuovo (o uno pronto, con il suo `modello`).
  Future<TestClub> creaTest(TestClub test) async {
    final payload = {
      'id': _uuid.v4(),
      'club_id': test.clubId,
      ...test.toPayload(),
    };
    return _scrivi(payload, operazione: 'insert');
  }

  Future<TestClub> aggiornaTest(TestClub test) =>
      _scrivi({'id': test.id, ...test.toPayload()}, operazione: 'update');

  Future<TestClub> _scrivi(
    Map<String, dynamic> payload, {
    required String operazione,
  }) async {
    final id = payload['id'] as String;
    try {
      final riga = operazione == 'insert'
          ? await _client.from('test_club').insert(payload).select().single()
          : await _client
                .from('test_club')
                .update(payload)
                .eq('id', id)
                .select()
                .single();
      await _db
          .into(_db.testClubTable)
          .insertOnConflictUpdate(_testDaMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      if (operazione == 'insert') {
        await _db
            .into(_db.testClubTable)
            .insertOnConflictUpdate(_testDaMap(payload));
      } else {
        final attuale = await (_db.select(
          _db.testClubTable,
        )..where((t) => t.id.equals(id))).getSingle();
        await _db
            .into(_db.testClubTable)
            .insertOnConflictUpdate(
              _testDaMap({
                'club_id': attuale.clubId,
                'unita': attuale.unita,
                'migliore': attuale.migliore,
                ...payload,
              }),
            );
      }
      await enqueueOperation(
        _db,
        tabella: 'test_club',
        operazione: operazione,
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _testDaRiga(
      await (_db.select(
        _db.testClubTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  /// Elimina il test e, sul server a cascata, i suoi risultati.
  Future<void> eliminaTest(String id) async {
    try {
      await _client.from('test_club').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'test_club',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.testRisultatiTable,
      )..where((t) => t.testId.equals(id))).go();
      await (_db.delete(_db.testClubTable)..where((t) => t.id.equals(id))).go();
    });
  }

  // -------------------------------------------------------------------------
  // Risultati

  Stream<List<RisultatoTest>> watchRisultati(String clubId) {
    final q = _db.select(_db.testRisultatiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return q.watch().map((righe) => righe.map(_risultatoDaRiga).toList());
  }

  /// Tutti i risultati del club, a pagine (vedi [leggiAPagine]).
  Future<void> refreshRisultati(String clubId) async {
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('test_risultati')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    await _db.transaction(() async {
      await (_db.delete(
        _db.testRisultatiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.testRisultatiTable, _risultatoDaMap(r));
        }
      });
    });
  }

  /// Salva il risultato di un atleta in un giorno: rifarlo lo stesso
  /// giorno lo sostituisce (chiave test, atleta, giorno). Per un
  /// massimale [valori] è il massimale stimato, con i chili sollevati
  /// ([caricoKg]) e le [ripetizioni].
  Future<void> salvaRisultato({
    required String testId,
    required String atletaId,
    required String clubId,
    required DateTime data,
    required List<double> valori,
    String? note,
    double? caricoKg,
    int? ripetizioni,
  }) async {
    final giorno = DateTime(data.year, data.month, data.day);
    final esistente =
        await (_db.select(_db.testRisultatiTable)..where(
              (t) =>
                  t.testId.equals(testId) &
                  t.atletaId.equals(atletaId) &
                  t.data.equals(giorno),
            ))
            .getSingleOrNull();
    final payload = {
      'id': esistente?.id ?? _uuid.v4(),
      'test_id': testId,
      'atleta_id': atletaId,
      'club_id': clubId,
      'data': formatDateOnly(giorno),
      'valori': valori,
      'note': note,
      'carico_kg': caricoKg,
      'ripetizioni': ripetizioni,
    };
    try {
      final riga = await _client
          .from('test_risultati')
          .upsert(payload, onConflict: 'test_id,atleta_id,data')
          .select()
          .single();
      await _db
          .into(_db.testRisultatiTable)
          .insertOnConflictUpdate(_risultatoDaMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.testRisultatiTable)
          .insertOnConflictUpdate(_risultatoDaMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'test_risultati',
        operazione: 'upsert',
        rigaId: payload['id']! as String,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> eliminaRisultato(String id) async {
    try {
      await _client.from('test_risultati').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'test_risultati',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.testRisultatiTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final testClubRepositoryProvider = Provider<TestClubRepository>(
  (ref) => TestClubRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  ),
);
