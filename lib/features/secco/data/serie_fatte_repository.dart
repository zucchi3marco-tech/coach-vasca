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
import '../domain/serie_fatta.dart';

const _uuid = Uuid();

/// Le serie a secco fatte: le scrive l'atleta dal suo telefono, serie per
/// serie; le legge anche l'allenatore del club. A differenza delle altre
/// scritture, la serie va prima nel telefono (in palestra la rete è
/// spesso lenta e il recupero parte subito), poi al server, una scrittura
/// alla volta nell'ordine in cui sono state fatte; senza rete resta in
/// coda (upsert sulla chiave atleta, esercizio della seduta, serie), come
/// l'RPE. Se il server la rifiuta, sul telefono torna com'era.
class SerieFatteRepository {
  SerieFatteRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  /// Le scritture al server, una dopo l'altra: togliere una serie appena
  /// segnata non deve arrivare prima di averla segnata.
  Future<void> _coda = Future.value();

  Future<T> _inOrdine<T>(Future<T> Function() lavoro) {
    final risultato = _coda.then((_) => lavoro());
    _coda = risultato.then((_) {}, onError: (_) {});
    return risultato;
  }

  SerieFatta _daRiga(SerieSeccoFatteTableData r) => SerieFatta(
    id: r.id,
    atletaId: r.atletaId,
    clubId: r.clubId,
    allenamentoId: r.allenamentoId,
    rigaId: r.rigaId,
    esercizioId: r.esercizioId,
    serie: r.serie,
    ripetizioni: r.ripetizioni,
    durataS: r.durataS,
    carico: r.carico,
    caricoPrevisto: r.caricoPrevisto,
    fattaIl: r.fattaIl,
    voto: VotoSerie.daNome(r.voto),
  );

  SerieSeccoFatteTableCompanion _companion(SerieFatta f) =>
      SerieSeccoFatteTableCompanion.insert(
        id: f.id,
        atletaId: f.atletaId,
        clubId: f.clubId,
        allenamentoId: f.allenamentoId,
        rigaId: f.rigaId,
        esercizioId: f.esercizioId,
        serie: f.serie,
        ripetizioni: Value(f.ripetizioni),
        durataS: Value(f.durataS),
        carico: Value(f.carico),
        caricoPrevisto: Value(f.caricoPrevisto),
        fattaIl: f.fattaIl,
        voto: Value(f.voto?.name),
      );

  /// Le serie fatte da un atleta, in tutte le sedute.
  Stream<List<SerieFatta>> watchPerAtleta(String atletaId) {
    final q = _db.select(_db.serieSeccoFatteTable)
      ..where((t) => t.atletaId.equals(atletaId));
    return q.watch().map((righe) => righe.map(_daRiga).toList());
  }

  /// Le serie fatte in una seduta, da tutti gli atleti (per l'allenatore).
  Stream<List<SerieFatta>> watchPerSeduta(String allenamentoId) {
    final q = _db.select(_db.serieSeccoFatteTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId));
    return q.watch().map((righe) => righe.map(_daRiga).toList());
  }

  /// Sostituzione totale per l'atleta, a pagine. Prima parte la coda:
  /// una serie segnata senza rete (o ancora in viaggio) non sparisce dal
  /// telefono perché il server non l'ha ancora.
  Future<void> refreshPerAtleta(String atletaId) async {
    await _coda;
    await _syncEngine.processQueue();
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('serie_secco_fatte')
          .select()
          .eq('atleta_id', atletaId)
          .order('id')
          .range(da, a),
    );
    await _sostituisci((t) => t.atletaId.equals(atletaId), [
      for (final r in righe) SerieFatta.fromMap(r),
    ]);
  }

  /// Sostituzione totale per la seduta (l'allenatore le legge tutte).
  Future<void> refreshPerSeduta(String allenamentoId) async {
    await _coda;
    await _syncEngine.processQueue();
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('serie_secco_fatte')
          .select()
          .eq('allenamento_id', allenamentoId)
          .order('id')
          .range(da, a),
    );
    await _sostituisci((t) => t.allenamentoId.equals(allenamentoId), [
      for (final r in righe) SerieFatta.fromMap(r),
    ]);
  }

  Future<void> _sostituisci(
    Expression<bool> Function($SerieSeccoFatteTableTable t) dove,
    List<SerieFatta> serie,
  ) => _db.transaction(() async {
    await (_db.delete(_db.serieSeccoFatteTable)..where(dove)).go();
    await _db.batch((b) {
      for (final f in serie) {
        b.insert(_db.serieSeccoFatteTable, _companion(f));
      }
    });
  });

  /// Segna (o corregge) una serie. L'id resta quello già sul telefono per
  /// la stessa serie, così la coda e il server parlano della stessa riga.
  Future<SerieFatta> salva(SerieFatta f) async {
    final esistente =
        await (_db.select(_db.serieSeccoFatteTable)..where(
              (t) =>
                  t.atletaId.equals(f.atletaId) &
                  t.rigaId.equals(f.rigaId) &
                  t.serie.equals(f.serie),
            ))
            .getSingleOrNull();
    final daSalvare = SerieFatta(
      id: esistente?.id ?? (f.id.isEmpty ? _uuid.v4() : f.id),
      atletaId: f.atletaId,
      clubId: f.clubId,
      allenamentoId: f.allenamentoId,
      rigaId: f.rigaId,
      esercizioId: f.esercizioId,
      serie: f.serie,
      ripetizioni: f.ripetizioni,
      durataS: f.durataS,
      carico: f.carico,
      caricoPrevisto: f.caricoPrevisto,
      fattaIl: f.fattaIl,
      voto: f.voto,
    );
    final payload = daSalvare.toPayload();
    // Prima sul telefono: la schermata va avanti subito.
    await _db
        .into(_db.serieSeccoFatteTable)
        .insertOnConflictUpdate(_companion(daSalvare));
    return _inOrdine(() async {
      try {
        final riga = await _client
            .from('serie_secco_fatte')
            .upsert(payload, onConflict: 'atleta_id,riga_id,serie')
            .select()
            .single();
        return SerieFatta.fromMap(riga);
      } catch (e) {
        if (!isNetworkFailure(e)) {
          // Il server l'ha rifiutata: sul telefono torna com'era.
          if (esistente != null) {
            await _db
                .into(_db.serieSeccoFatteTable)
                .insertOnConflictUpdate(esistente);
          } else {
            await (_db.delete(
              _db.serieSeccoFatteTable,
            )..where((t) => t.id.equals(daSalvare.id))).go();
          }
          rethrow;
        }
        await enqueueOperation(
          _db,
          tabella: 'serie_secco_fatte',
          operazione: 'upsert',
          rigaId: daSalvare.id,
          payload: payload,
        );
        _syncEngine.processQueue();
        return daSalvare;
      }
    });
  }

  /// Toglie una serie segnata per sbaglio.
  Future<void> togli(SerieFatta f) async {
    await (_db.delete(
      _db.serieSeccoFatteTable,
    )..where((t) => t.id.equals(f.id))).go();
    return _inOrdine(() async {
      try {
        await _client.from('serie_secco_fatte').delete().eq('id', f.id);
      } catch (e) {
        if (!isNetworkFailure(e)) rethrow;
        await enqueueOperation(
          _db,
          tabella: 'serie_secco_fatte',
          operazione: 'delete',
          rigaId: f.id,
        );
        _syncEngine.processQueue();
      }
    });
  }
}

final serieFatteRepositoryProvider = Provider<SerieFatteRepository>(
  (ref) => SerieFatteRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  ),
);
