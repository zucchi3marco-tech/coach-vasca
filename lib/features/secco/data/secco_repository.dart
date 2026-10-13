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
import '../domain/esercizio_secco.dart';

const _uuid = Uuid();

/// L'elenco degli esercizi a secco del club e gli esercizi di ogni seduta
/// a secco. Ogni scrittura prova prima il server; senza rete va nella
/// copia locale e in coda (vedi `SyncEngine`), come gli allenamenti.
class SeccoRepository {
  SeccoRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  EsercizioSecco _esercizioDaRiga(EserciziSeccoTableData r) => EsercizioSecco(
    id: r.id,
    clubId: r.clubId,
    nome: r.nome,
    categoria: CategoriaEsercizio.daNome(r.categoria),
    misura: MisuraEsercizio.daNome(r.misura),
    attrezzo: r.attrezzo,
    descrizione: r.descrizione,
    modello: r.modello,
    archiviato: r.archiviato,
  );

  EserciziSeccoTableCompanion _esercizioDaMap(Map<String, dynamic> m) =>
      EserciziSeccoTableCompanion.insert(
        id: m['id'] as String,
        clubId: m['club_id'] as String,
        nome: m['nome'] as String,
        categoria: m['categoria'] as String,
        misura: Value(m['misura'] as String? ?? 'ripetizioni'),
        attrezzo: Value(m['attrezzo'] as String?),
        descrizione: Value(m['descrizione'] as String?),
        modello: Value(m['modello'] as String?),
        archiviato: Value(m['archiviato'] as bool? ?? false),
      );

  EsercizioSeduta _rigaDaRiga(EserciziSedutaTableData r) => EsercizioSeduta(
    id: r.id,
    allenamentoId: r.allenamentoId,
    clubId: r.clubId,
    esercizioId: r.esercizioId,
    ordine: r.ordine,
    serie: r.serie,
    ripetizioni: r.ripetizioni,
    durataS: r.durataS,
    carico: r.carico,
    recuperoS: r.recuperoS,
    note: r.note,
  );

  EserciziSedutaTableCompanion _rigaDaMap(Map<String, dynamic> m) =>
      EserciziSedutaTableCompanion.insert(
        id: m['id'] as String,
        allenamentoId: m['allenamento_id'] as String,
        clubId: m['club_id'] as String,
        esercizioId: m['esercizio_id'] as String,
        ordine: (m['ordine'] as num).toInt(),
        serie: Value((m['serie'] as num?)?.toInt() ?? 3),
        ripetizioni: Value((m['ripetizioni'] as num?)?.toInt()),
        durataS: Value((m['durata_s'] as num?)?.toInt()),
        carico: Value(m['carico'] as String?),
        recuperoS: Value((m['recupero_s'] as num?)?.toInt()),
        note: Value(m['note'] as String?),
      );

  /// Scrive una riga (insert o update) sul server o, senza rete, sul
  /// telefono e in coda. [locale] la rimette nella copia locale da una
  /// mappa completa.
  Future<void> _scrivi({
    required String tabella,
    required String operazione,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> Function(Map<String, dynamic> payload)
    completa,
    required Future<void> Function(Map<String, dynamic> riga) locale,
  }) async {
    final id = payload['id'] as String;
    try {
      final riga = operazione == 'insert'
          ? await _client.from(tabella).insert(payload).select().single()
          : await _client
                .from(tabella)
                .update(payload)
                .eq('id', id)
                .select()
                .single();
      await locale(riga);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await locale(completa(payload));
      await enqueueOperation(
        _db,
        tabella: tabella,
        operazione: operazione,
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> _elimina(String tabella, String id) async {
    try {
      await _client.from(tabella).delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: tabella,
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
  }

  // -------------------------------------------------------------------------
  // L'elenco degli esercizi del club

  Stream<List<EsercizioSecco>> watchEsercizi(String clubId) {
    final q = _db.select(_db.eserciziSeccoTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.nome)]);
    return q.watch().map((righe) => righe.map(_esercizioDaRiga).toList());
  }

  /// Sostituzione totale per il club: un esercizio eliminato altrove non
  /// resta.
  Future<void> refreshEsercizi(String clubId) async {
    final righe = await leggiAPagine(
      (da, a) => _client
          .from('esercizi_secco')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    await _db.transaction(() async {
      await (_db.delete(
        _db.eserciziSeccoTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.eserciziSeccoTable, _esercizioDaMap(r));
        }
      });
    });
  }

  Future<EsercizioSecco> _leggiEsercizio(String id) async => _esercizioDaRiga(
    await (_db.select(
      _db.eserciziSeccoTable,
    )..where((t) => t.id.equals(id))).getSingle(),
  );

  Future<void> _salvaEsercizioLocale(Map<String, dynamic> riga) => _db
      .into(_db.eserciziSeccoTable)
      .insertOnConflictUpdate(_esercizioDaMap(riga));

  /// Crea un esercizio (uno dell'allenatore, o uno pronto con il suo
  /// `modello`).
  Future<EsercizioSecco> creaEsercizio(EsercizioSecco esercizio) async {
    final payload = {
      'id': _uuid.v4(),
      'club_id': esercizio.clubId,
      ...esercizio.toPayload(),
    };
    await _scrivi(
      tabella: 'esercizi_secco',
      operazione: 'insert',
      payload: payload,
      completa: (p) => p,
      locale: _salvaEsercizioLocale,
    );
    return _leggiEsercizio(payload['id'] as String);
  }

  Future<EsercizioSecco> aggiornaEsercizio(EsercizioSecco esercizio) async {
    final payload = {'id': esercizio.id, ...esercizio.toPayload()};
    await _scrivi(
      tabella: 'esercizi_secco',
      operazione: 'update',
      payload: payload,
      completa: (p) => {'club_id': esercizio.clubId, ...p},
      locale: _salvaEsercizioLocale,
    );
    return _leggiEsercizio(esercizio.id);
  }

  /// Gli esercizi pronti scelti, aggiunti all'elenco del club. Quelli già
  /// aggiunti (stesso `modello`) si saltano.
  Future<void> aggiungiModelli(
    String clubId,
    Iterable<ModelloEsercizio> modelli,
  ) async {
    final presenti = {
      for (final r in await (_db.select(
        _db.eserciziSeccoTable,
      )..where((t) => t.clubId.equals(clubId))).get())
        ?r.modello,
    };
    for (final m in modelli) {
      if (presenti.contains(m.chiave)) continue;
      await creaEsercizio(
        EsercizioSecco(
          id: '',
          clubId: clubId,
          nome: m.nome,
          categoria: m.categoria,
          misura: m.misura,
          attrezzo: m.attrezzo,
          descrizione: m.descrizione,
          modello: m.chiave,
        ),
      );
    }
  }

  /// Se l'esercizio è in qualche seduta (sul telefono): allora non si
  /// elimina, si archivia.
  Future<bool> inUso(String esercizioId) async {
    final righe =
        await (_db.select(_db.eserciziSedutaTable)
              ..where((t) => t.esercizioId.equals(esercizioId))
              ..limit(1))
            .get();
    return righe.isNotEmpty;
  }

  Future<void> eliminaEsercizio(String id) async {
    await _elimina('esercizi_secco', id);
    await (_db.delete(
      _db.eserciziSeccoTable,
    )..where((t) => t.id.equals(id))).go();
  }

  // -------------------------------------------------------------------------
  // Gli esercizi di una seduta

  Stream<List<EsercizioSeduta>> watchSeduta(String allenamentoId) {
    final q = _db.select(_db.eserciziSedutaTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return q.watch().map((righe) => righe.map(_rigaDaRiga).toList());
  }

  Future<void> refreshSeduta(String allenamentoId) async {
    final righe = await _client
        .from('esercizi_seduta')
        .select()
        .eq('allenamento_id', allenamentoId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.eserciziSedutaTable,
      )..where((t) => t.allenamentoId.equals(allenamentoId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.eserciziSedutaTable, _rigaDaMap(r));
        }
      });
    });
  }

  /// Gli esercizi di una seduta, dal server se c'è rete (per copiarla),
  /// se no dal telefono.
  Future<List<EsercizioSeduta>> fetchSeduta(String allenamentoId) async {
    try {
      final righe = await _client
          .from('esercizi_seduta')
          .select()
          .eq('allenamento_id', allenamentoId)
          .order('ordine');
      return [
        for (final r in righe)
          _rigaDaRiga(
            EserciziSedutaTableData(
              id: r['id'] as String,
              allenamentoId: r['allenamento_id'] as String,
              clubId: r['club_id'] as String,
              esercizioId: r['esercizio_id'] as String,
              ordine: (r['ordine'] as num).toInt(),
              serie: (r['serie'] as num?)?.toInt() ?? 3,
              ripetizioni: (r['ripetizioni'] as num?)?.toInt(),
              durataS: (r['durata_s'] as num?)?.toInt(),
              carico: r['carico'] as String?,
              recuperoS: (r['recupero_s'] as num?)?.toInt(),
              note: r['note'] as String?,
            ),
          ),
      ];
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return watchSeduta(allenamentoId).first;
    }
  }

  /// L'ultima volta che il club ha messo questo esercizio in una seduta
  /// (sul telefono): la prescrizione da riproporre.
  Future<EsercizioSeduta?> ultimaVolta(String esercizioId) async {
    final righe =
        await (_db.select(_db.eserciziSedutaTable)
              ..where((t) => t.esercizioId.equals(esercizioId))
              ..orderBy([(t) => OrderingTerm.desc(t.rowId)])
              ..limit(1))
            .get();
    return righe.isEmpty ? null : _rigaDaRiga(righe.first);
  }

  Future<void> _salvaRigaLocale(Map<String, dynamic> riga) => _db
      .into(_db.eserciziSedutaTable)
      .insertOnConflictUpdate(_rigaDaMap(riga));

  /// Aggiunge un esercizio in fondo alla seduta.
  Future<void> aggiungiAllaSeduta(EsercizioSeduta riga) async {
    final payload = {
      'id': _uuid.v4(),
      'allenamento_id': riga.allenamentoId,
      'club_id': riga.clubId,
      'esercizio_id': riga.esercizioId,
      ...riga.toPayload(),
    };
    await _scrivi(
      tabella: 'esercizi_seduta',
      operazione: 'insert',
      payload: payload,
      completa: (p) => p,
      locale: _salvaRigaLocale,
    );
  }

  Future<void> aggiornaRiga(EsercizioSeduta riga) async {
    final payload = {'id': riga.id, ...riga.toPayload()};
    await _scrivi(
      tabella: 'esercizi_seduta',
      operazione: 'update',
      payload: payload,
      completa: (p) => {
        'allenamento_id': riga.allenamentoId,
        'club_id': riga.clubId,
        'esercizio_id': riga.esercizioId,
        ...p,
      },
      locale: _salvaRigaLocale,
    );
  }

  Future<void> eliminaRiga(String id) async {
    await _elimina('esercizi_seduta', id);
    await (_db.delete(
      _db.eserciziSedutaTable,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Rinumera da 1 nell'ordine dato, scrivendo solo le righe che cambiano.
  Future<void> riordina(List<EsercizioSeduta> ordinate) async {
    for (final (i, r) in ordinate.indexed) {
      if (r.ordine != i + 1) await aggiornaRiga(r.copyWith(ordine: i + 1));
    }
  }

  /// Copia gli esercizi di una seduta in un'altra (per "Duplica").
  Future<void> copiaSeduta({
    required String daAllenamentoId,
    required String aAllenamentoId,
    required String clubId,
  }) async {
    for (final (i, r) in (await fetchSeduta(daAllenamentoId)).indexed) {
      await aggiungiAllaSeduta(
        EsercizioSeduta(
          id: '',
          allenamentoId: aAllenamentoId,
          clubId: clubId,
          esercizioId: r.esercizioId,
          ordine: i + 1,
          serie: r.serie,
          ripetizioni: r.ripetizioni,
          durataS: r.durataS,
          carico: r.carico,
          recuperoS: r.recuperoS,
          note: r.note,
        ),
      );
    }
  }

  /// Gli esercizi di una seduta come li vede l'atleta collegato: con come
  /// si fa, senza le note (funzione `esercizi_seduta_atleta`). Solo da
  /// rete, come le serie dell'atleta.
  Future<List<EsercizioSedutaAtleta>> perAtleta(String allenamentoId) async {
    final righe = await _client.rpc(
      'esercizi_seduta_atleta',
      params: {'p_allenamento_id': allenamentoId},
    );
    return [
      for (final r in righe as List)
        EsercizioSedutaAtleta.fromMap(r as Map<String, dynamic>),
    ];
  }
}

final seccoRepositoryProvider = Provider<SeccoRepository>((ref) {
  return SeccoRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
