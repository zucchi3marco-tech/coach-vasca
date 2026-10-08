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
import '../../allenamenti/domain/serie.dart';
import '../application/excel_import.dart';
import '../domain/training_block.dart';

const _uuid = Uuid();

/// Esito di un'importazione Excel, per il riepilogo mostrato al coach.
class RiepilogoImportazione {
  const RiepilogoImportazione({
    required this.importati,
    required this.aggiornati,
    required this.saltati,
    required this.errori,
  });

  final int importati;
  final int aggiornati;
  final int saltati;
  final List<RigaErrore> errori;
}

class TrainingBlocksRepository {
  TrainingBlocksRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  TrainingBlock _bloccoFromRow(TrainingBlocksTableData row) => TrainingBlock(
    id: row.id,
    clubId: row.clubId,
    codice: row.codice,
    sport: row.sport,
    fase: row.fase,
    obiettivo: row.obiettivo,
    zoneCoinvolte: row.zoneCoinvolte,
    titolo: row.titolo,
    descrizione: row.descrizione,
    stilePrincipale: row.stilePrincipale,
    livelli: row.livelli,
    attrezzi: row.attrezzi,
    metriTotali: row.metriTotali,
    durataStimataMin: row.durataStimataMin,
    note: row.note,
    stato: row.stato,
    fonte: row.fonte,
    importatoIl: row.importatoIl,
    modificatoInApp: row.modificatoInApp,
  );

  TrainingBlockParte _parteFromRow(TrainingBlockPartiTableData row) =>
      TrainingBlockParte(
        id: row.id,
        bloccoId: row.bloccoId,
        clubId: row.clubId,
        ordine: row.ordine,
        giri: row.giri,
        ripetizioni: row.ripetizioni,
        distanzaM: row.distanzaM,
        durataS: row.durataS,
        stile: row.stile,
        esercizio: row.esercizio,
        zona: row.zona,
        esecuzione: row.esecuzione,
        recuperoS: row.recuperoS,
        attrezzi: row.attrezzi,
        note: row.note,
      );

  TrainingBlocksTableCompanion _bloccoCompanionFromMap(
    Map<String, dynamic> map,
  ) {
    return TrainingBlocksTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      codice: map['codice'] as String,
      sport: map['sport'] as String,
      fase: map['fase'] as String,
      obiettivo: map['obiettivo'] as String,
      zoneCoinvolte: map['zone_coinvolte'] as String,
      titolo: map['titolo'] as String,
      descrizione: map['descrizione'] as String,
      stilePrincipale: Value(map['stile_principale'] as String?),
      livelli: Value(map['livelli'] as String? ?? ''),
      attrezzi: Value(map['attrezzi'] as String?),
      metriTotali: Value(map['metri_totali'] as int? ?? 0),
      durataStimataMin: Value(map['durata_stimata_min'] as int? ?? 0),
      note: Value(map['note'] as String?),
      stato: Value(map['stato'] as String? ?? 'bozza'),
      fonte: Value(map['fonte'] as String? ?? 'Allenatore'),
      importatoIl: Value(
        map['importato_il'] == null
            ? null
            : DateTime.parse(map['importato_il'] as String),
      ),
      modificatoInApp: Value(map['modificato_in_app'] as bool? ?? false),
    );
  }

  TrainingBlockPartiTableCompanion _parteCompanionFromMap(
    Map<String, dynamic> map,
  ) {
    return TrainingBlockPartiTableCompanion.insert(
      id: map['id'] as String,
      bloccoId: map['blocco_id'] as String,
      clubId: map['club_id'] as String,
      ordine: Value(map['ordine'] as int? ?? 1),
      giri: Value(map['giri'] as int? ?? 1),
      ripetizioni: Value(map['ripetizioni'] as int? ?? 1),
      distanzaM: Value(map['distanza_m'] as int?),
      durataS: Value(map['durata_s'] as int?),
      stile: Value(map['stile'] as String?),
      esercizio: Value(map['esercizio'] as String?),
      zona: map['zona'] as String,
      esecuzione: map['esecuzione'] as String,
      recuperoS: Value(map['recupero_s'] as int?),
      attrezzi: Value(map['attrezzi'] as String?),
      note: Value(map['note'] as String?),
    );
  }

  /// Companion con solo i campi presenti in [campi] (chiavi snake_case,
  /// stesso formato della riga Supabase): per l'aggiornamento parziale
  /// in locale quando offline, senza toccare i campi non modificati.
  TrainingBlocksTableCompanion _companionParziale(Map<String, dynamic> campi) {
    return TrainingBlocksTableCompanion(
      sport: campi.containsKey('sport')
          ? Value(campi['sport'] as String)
          : const Value.absent(),
      fase: campi.containsKey('fase')
          ? Value(campi['fase'] as String)
          : const Value.absent(),
      obiettivo: campi.containsKey('obiettivo')
          ? Value(campi['obiettivo'] as String)
          : const Value.absent(),
      zoneCoinvolte: campi.containsKey('zone_coinvolte')
          ? Value(campi['zone_coinvolte'] as String)
          : const Value.absent(),
      titolo: campi.containsKey('titolo')
          ? Value(campi['titolo'] as String)
          : const Value.absent(),
      descrizione: campi.containsKey('descrizione')
          ? Value(campi['descrizione'] as String)
          : const Value.absent(),
      stilePrincipale: campi.containsKey('stile_principale')
          ? Value(campi['stile_principale'] as String?)
          : const Value.absent(),
      livelli: campi.containsKey('livelli')
          ? Value(campi['livelli'] as String)
          : const Value.absent(),
      attrezzi: campi.containsKey('attrezzi')
          ? Value(campi['attrezzi'] as String?)
          : const Value.absent(),
      metriTotali: campi.containsKey('metri_totali')
          ? Value(campi['metri_totali'] as int)
          : const Value.absent(),
      durataStimataMin: campi.containsKey('durata_stimata_min')
          ? Value(campi['durata_stimata_min'] as int)
          : const Value.absent(),
      note: campi.containsKey('note')
          ? Value(campi['note'] as String?)
          : const Value.absent(),
      stato: campi.containsKey('stato')
          ? Value(campi['stato'] as String)
          : const Value.absent(),
      modificatoInApp: const Value(true),
    );
  }

  Stream<List<TrainingBlock>> watchPerClub(String clubId) {
    final query = _db.select(_db.trainingBlocksTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.asc(t.titolo)]);
    return query.watch().map((rows) => rows.map(_bloccoFromRow).toList());
  }

  Stream<List<TrainingBlockParte>> watchParti(String bloccoId) {
    final query = _db.select(_db.trainingBlockPartiTable)
      ..where((t) => t.bloccoId.equals(bloccoId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_parteFromRow).toList());
  }

  /// Senza rete legge le parti dalla copia locale: prima, senza
  /// connessione, aggiungere o modificare una parte falliva sempre.
  Future<List<TrainingBlockParte>> fetchParti(String bloccoId) async {
    try {
      final rows = await _client
          .from('training_block_parti')
          .select()
          .eq('blocco_id', bloccoId)
          .order('ordine');
      return rows.map(TrainingBlockParte.fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      return _partiLocali([bloccoId]);
    }
  }

  Future<List<TrainingBlockParte>> _partiLocali(List<String> bloccoIds) async {
    final query = _db.select(_db.trainingBlockPartiTable)
      ..where((t) => t.bloccoId.isIn(bloccoIds))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return (await query.get()).map(_parteFromRow).toList();
  }

  /// Le parti di più blocchi in un colpo solo (es. per l'esportazione
  /// Excel di tutta la libreria): una richiesta sola, non una per
  /// blocco in sequenza — lo stesso errore corretto in
  /// `selezione_blocchi_service.dart` dopo il blocco trovato dal coach.
  Future<Map<String, List<TrainingBlockParte>>> fetchPartiPerBlocchi(
    List<String> bloccoIds,
  ) async {
    if (bloccoIds.isEmpty) return {};
    List<TrainingBlockParte> parti;
    try {
      final rows = await _client
          .from('training_block_parti')
          .select()
          .inFilter('blocco_id', bloccoIds)
          .order('ordine');
      parti = rows.map(TrainingBlockParte.fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      parti = await _partiLocali(bloccoIds);
    }
    final risultato = <String, List<TrainingBlockParte>>{};
    for (final parte in parti) {
      (risultato[parte.bloccoId] ??= []).add(parte);
    }
    return risultato;
  }

  /// Sostituzione totale per questo club (non insertOrReplace): un
  /// blocco eliminato fuori dall'app resterebbe altrimenti in cache.
  Future<void> refreshFromRemote(String clubId) async {
    // A pagine (vedi [leggiAPagine]). Le parti per club e non per elenco
    // di blocchi: con centinaia di id in una richiesta l'indirizzo
    // diventava troppo lungo.
    final blocchi = await leggiAPagine(
      (da, a) => _client
          .from('training_blocks')
          .select()
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    final parti = blocchi.isEmpty
        ? <Map<String, dynamic>>[]
        : await leggiAPagine(
            (da, a) => _client
                .from('training_block_parti')
                .select()
                .eq('club_id', clubId)
                .order('id')
                .range(da, a),
          );
    await _db.transaction(() async {
      await (_db.delete(
        _db.trainingBlocksTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await (_db.delete(
        _db.trainingBlockPartiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in blocchi) {
          batch.insert(_db.trainingBlocksTable, _bloccoCompanionFromMap(row));
        }
        for (final row in parti) {
          batch.insert(
            _db.trainingBlockPartiTable,
            _parteCompanionFromMap(row),
          );
        }
      });
    });
  }

  Future<TrainingBlock> createBlocco({
    required String clubId,
    required String codice,
    required String sport,
    required String fase,
    required String obiettivo,
    String zoneCoinvolte = '',
    required String titolo,
    String descrizione = '',
    String? stilePrincipale,
    String livelli = '',
    String? attrezzi,
    int metriTotali = 0,
    int durataStimataMin = 0,
    String? note,
    String stato = 'bozza',
    String fonte = 'Allenatore',
  }) async {
    final payload = {
      'id': _uuid.v4(),
      'club_id': clubId,
      'codice': codice,
      'sport': sport,
      'fase': fase,
      'obiettivo': obiettivo,
      'zone_coinvolte': zoneCoinvolte,
      'titolo': titolo,
      'descrizione': descrizione,
      'stile_principale': stilePrincipale,
      'livelli': livelli,
      'attrezzi': attrezzi,
      'metri_totali': metriTotali,
      'durata_stimata_min': durataStimataMin,
      'note': note,
      'stato': stato,
      'fonte': fonte,
      'modificato_in_app': true,
    };
    try {
      final row = await _client
          .from('training_blocks')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.trainingBlocksTable)
          .insertOnConflictUpdate(_bloccoCompanionFromMap(row));
      return _bloccoFromRow(
        await (_db.select(
          _db.trainingBlocksTable,
        )..where((t) => t.id.equals(row['id'] as String))).getSingle(),
      );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.trainingBlocksTable)
          .insertOnConflictUpdate(_bloccoCompanionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'training_blocks',
        operazione: 'insert',
        rigaId: payload['id'] as String,
        payload: payload,
      );
      _syncEngine.processQueue();
      return _bloccoFromRow(
        await (_db.select(
          _db.trainingBlocksTable,
        )..where((t) => t.id.equals(payload['id'] as String))).getSingle(),
      );
    }
  }

  /// Aggiorna un blocco esistente — marca sempre `modificato_in_app`:
  /// un'importazione successiva non lo sovrascriverà più.
  Future<void> updateBlocco(String id, Map<String, dynamic> campi) async {
    final payload = {...campi, 'modificato_in_app': true};
    try {
      final row = await _client
          .from('training_blocks')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.trainingBlocksTable)
          .insertOnConflictUpdate(_bloccoCompanionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.trainingBlocksTable,
      )..where((t) => t.id.equals(id))).write(_companionParziale(payload));
      await enqueueOperation(
        _db,
        tabella: 'training_blocks',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> deleteBlocco(String id) async {
    try {
      await _client.from('training_blocks').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'training_blocks',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.trainingBlocksTable,
    )..where((t) => t.id.equals(id))).go();
    await (_db.delete(
      _db.trainingBlockPartiTable,
    )..where((t) => t.bloccoId.equals(id))).go();
  }

  Future<TrainingBlock> duplicaBlocco(TrainingBlock originale) async {
    final parti = await fetchParti(originale.id);
    var codiceCopia = '${originale.codice}-copia';
    Set<String> codiciEsistenti;
    try {
      final esistenti = await leggiAPagine(
        (da, a) => _client
            .from('training_blocks')
            .select('id, codice')
            .eq('club_id', originale.clubId)
            .order('id')
            .range(da, a),
      );
      codiciEsistenti = {for (final r in esistenti) r['codice'] as String};
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.trainingBlocksTable,
      )..where((t) => t.clubId.equals(originale.clubId))).get();
      codiciEsistenti = {for (final b in locali) b.codice};
    }
    var n = 2;
    while (codiciEsistenti.contains(codiceCopia)) {
      codiceCopia = '${originale.codice}-copia$n';
      n++;
    }
    final nuovo = await createBlocco(
      clubId: originale.clubId,
      codice: codiceCopia,
      sport: originale.sport,
      fase: originale.fase,
      obiettivo: originale.obiettivo,
      zoneCoinvolte: originale.zoneCoinvolte,
      titolo: '${originale.titolo} (copia)',
      descrizione: originale.descrizione,
      stilePrincipale: originale.stilePrincipale,
      livelli: originale.livelli,
      attrezzi: originale.attrezzi,
      metriTotali: originale.metriTotali,
      durataStimataMin: originale.durataStimataMin,
      note: originale.note,
      stato: 'bozza',
      fonte: originale.fonte,
    );
    await _inserisciParti(nuovo.id, originale.clubId, parti);
    return nuovo;
  }

  Future<void> _inserisciParti(
    String bloccoId,
    String clubId,
    List<TrainingBlockParte> parti,
  ) async {
    if (parti.isEmpty) return;
    // Id scelto qui (non dal server): serve per salvare in locale e
    // mettere in coda la stessa riga quando manca la rete.
    final payload = [
      for (final p in parti)
        {
          'id': _uuid.v4(),
          'blocco_id': bloccoId,
          'ordine': p.ordine,
          'giri': p.giri,
          'ripetizioni': p.ripetizioni,
          'distanza_m': p.distanzaM,
          'durata_s': p.durataS,
          'stile': p.stile,
          'esercizio': p.esercizio,
          'zona': p.zona,
          'esecuzione': p.esecuzione,
          'recupero_s': p.recuperoS,
          'attrezzi': p.attrezzi,
          'note': p.note,
        },
    ];
    List<Map<String, dynamic>> righe;
    try {
      righe = await _client
          .from('training_block_parti')
          .insert(payload)
          .select();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id lo mette il trigger sul server: in coda va la riga
      // cosi' come la si sarebbe inviata adesso.
      for (final riga in payload) {
        await enqueueOperation(
          _db,
          tabella: 'training_block_parti',
          operazione: 'insert',
          rigaId: riga['id'] as String,
          payload: riga,
        );
      }
      _syncEngine.processQueue();
      righe = payload;
    }
    await _db.batch((batch) {
      for (final r in righe) {
        batch.insert(
          _db.trainingBlockPartiTable,
          _parteCompanionFromMap({...r, 'club_id': clubId}),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Passo medio di fabbrica (s/100m) per stimare la durata di un
  /// blocco dai suoi metri — stesso valore di default usato
  /// dall'importatore Excel quando il foglio Legenda non lo specifica
  /// (vedi `excel_import.dart`): qui non c'è un file da cui leggerlo,
  /// quindi si usa sempre questo.
  static const _passoMedioS100 = 110;

  /// Ricalcola "metri totali" e "durata stimata" di un blocco dalle sue
  /// parti attuali — stessa formula dell'importatore Excel (FASE 1):
  /// va richiamato dopo ogni aggiunta/modifica/eliminazione di una
  /// parte, mai lasciato "sporco" rispetto al contenuto vero.
  Future<void> _ricalcolaAggregatiBlocco(String bloccoId) async {
    final parti = await fetchParti(bloccoId);
    final metriTotali = parti.fold<int>(
      0,
      (t, p) => t + p.giri * p.ripetizioni * (p.distanzaM ?? 0),
    );
    final secondiRecuperoETempo = parti.fold<int>(
      0,
      (t, p) =>
          t + p.giri * p.ripetizioni * ((p.durataS ?? 0) + (p.recuperoS ?? 0)),
    );
    final durataStimataMin =
        ((metriTotali * _passoMedioS100 / 100 + secondiRecuperoETempo) / 60)
            .round();
    await updateBlocco(bloccoId, {
      'metri_totali': metriTotali,
      'durata_stimata_min': durataStimataMin,
    });
  }

  /// Aggiunge una parte a un blocco esistente, in fondo (o alla
  /// posizione [ordine] se indicata) — dalla schermata del blocco, non
  /// solo da import Excel o "Salva come blocco" (FASE 1, rifinitura).
  Future<void> createParte({
    required String bloccoId,
    required String clubId,
    int? ordine,
    int giri = 1,
    required int ripetizioni,
    int? distanzaM,
    int? durataS,
    String? stile,
    String? esercizio,
    required String zona,
    required String esecuzione,
    int? recuperoS,
    String? attrezzi,
    String? note,
  }) async {
    final attuali = await fetchParti(bloccoId);
    await _inserisciParti(bloccoId, clubId, [
      TrainingBlockParte(
        id: '',
        bloccoId: bloccoId,
        clubId: clubId,
        ordine: ordine ?? attuali.length + 1,
        giri: giri,
        ripetizioni: ripetizioni,
        distanzaM: distanzaM,
        durataS: durataS,
        stile: stile,
        esercizio: esercizio,
        zona: zona,
        esecuzione: esecuzione,
        recuperoS: recuperoS,
        attrezzi: attrezzi,
        note: note,
      ),
    ]);
    await _ricalcolaAggregatiBlocco(bloccoId);
  }

  Future<void> updateParte(
    String id, {
    required String bloccoId,
    required int ordine,
    required int giri,
    required int ripetizioni,
    int? distanzaM,
    int? durataS,
    String? stile,
    String? esercizio,
    required String zona,
    required String esecuzione,
    int? recuperoS,
    String? attrezzi,
    String? note,
  }) async {
    final payload = {
      'ordine': ordine,
      'giri': giri,
      'ripetizioni': ripetizioni,
      'distanza_m': distanzaM,
      'durata_s': durataS,
      'stile': stile,
      'esercizio': esercizio,
      'zona': zona,
      'esecuzione': esecuzione,
      'recupero_s': recuperoS,
      'attrezzi': attrezzi,
      'note': note,
    };
    try {
      final row = await _client
          .from('training_block_parti')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.trainingBlockPartiTable)
          .insertOnConflictUpdate(_parteCompanionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.trainingBlockPartiTable,
      )..where((t) => t.id.equals(id))).write(
        TrainingBlockPartiTableCompanion(
          ordine: Value(ordine),
          giri: Value(giri),
          ripetizioni: Value(ripetizioni),
          distanzaM: Value(distanzaM),
          durataS: Value(durataS),
          stile: Value(stile),
          esercizio: Value(esercizio),
          zona: Value(zona),
          esecuzione: Value(esecuzione),
          recuperoS: Value(recuperoS),
          attrezzi: Value(attrezzi),
          note: Value(note),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'training_block_parti',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    // _ricalcolaAggregatiBlocco chiama updateBlocco, che marca sempre
    // modificato_in_app=true: non serve un'altra chiamata solo per quello.
    await _ricalcolaAggregatiBlocco(bloccoId);
  }

  Future<void> deleteParte(String id, {required String bloccoId}) async {
    try {
      await _client.from('training_block_parti').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'training_block_parti',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.trainingBlockPartiTable,
    )..where((t) => t.id.equals(id))).go();
    await _ricalcolaAggregatiBlocco(bloccoId);
  }

  /// Crea un blocco in libreria (stato "bozza") a partire da una o più
  /// serie vere già salvate — "Salva come blocco" sulla scheda
  /// allenamento. Un gruppo di più righe (es. una piramide) diventa un
  /// blocco con più parti, nello stesso ordine.
  Future<TrainingBlock> salvaSerieComeBlocco({
    required String clubId,
    required String codice,
    required String sport,
    required String titolo,
    required List<Serie> serieGruppo,
  }) async {
    final metriTotali = serieGruppo.fold<int>(
      0,
      (t, s) => t + s.distanzaTotaleM,
    );
    final secondiATempo = serieGruppo
        .where((s) => s.aTempo)
        .fold<int>(0, (t, s) => t + s.ripetute * s.durataS!);
    final nuovo = await createBlocco(
      clubId: clubId,
      codice: codice,
      sport: sport,
      fase: 'Serie principale',
      obiettivo: 'Da allenamento',
      titolo: titolo,
      descrizione: titolo,
      stilePrincipale: serieGruppo.first.stile,
      metriTotali: metriTotali,
      durataStimataMin: secondiATempo == 0 ? 0 : (secondiATempo / 60).ceil(),
      stato: 'bozza',
      fonte: 'Allenatore',
    );
    await _inserisciParti(nuovo.id, clubId, [
      for (var i = 0; i < serieGruppo.length; i++)
        TrainingBlockParte(
          id: '',
          bloccoId: nuovo.id,
          clubId: clubId,
          ordine: i + 1,
          giri: 1,
          ripetizioni: serieGruppo[i].ripetute,
          distanzaM: serieGruppo[i].distanzaM,
          durataS: serieGruppo[i].durataS,
          stile: serieGruppo[i].stile,
          zona: serieGruppo[i].zona ?? '',
          esecuzione: serieGruppo[i].esecuzione,
          recuperoS: serieGruppo[i].recuperoS,
          attrezzi: serieGruppo[i].attrezzatura,
          note: serieGruppo[i].note,
        ),
    ]);
    return nuovo;
  }

  /// Importa il risultato di [parseLibreriaExcel]: un blocco nuovo
  /// (codice non ancora in libreria) viene creato, uno esistente non
  /// toccato dal coach viene aggiornato, uno modificato in app viene
  /// saltato — mai sovrascritto per sbaglio (vedi piano FASE 1).
  Future<RiepilogoImportazione> importa(
    String clubId,
    RisultatoParsingLibreria parsed,
  ) async {
    // Tutti, a pagine: oltre i primi 1000 un blocco già importato
    // sembrerebbe nuovo e verrebbe duplicato.
    final esistenti = await leggiAPagine(
      (da, a) => _client
          .from('training_blocks')
          .select('id, codice, modificato_in_app')
          .eq('club_id', clubId)
          .order('id')
          .range(da, a),
    );
    final perCodice = {for (final r in esistenti) r['codice'] as String: r};

    var importati = 0;
    var aggiornati = 0;
    var saltati = 0;
    final errori = [...parsed.errori];

    for (final b in parsed.blocchi) {
      final esistente = perCodice[b.codice];
      if (esistente != null && esistente['modificato_in_app'] == true) {
        saltati++;
        continue;
      }

      final payloadBlocco = {
        'club_id': clubId,
        'codice': b.codice,
        'sport': b.sport,
        'fase': b.fase,
        'obiettivo': b.obiettivo,
        'zone_coinvolte': b.zoneCoinvolte,
        'titolo': b.titolo,
        'descrizione': b.descrizione,
        'stile_principale': b.stilePrincipale,
        'livelli': b.livelli,
        'attrezzi': b.attrezzi,
        'metri_totali': b.metriTotali,
        'durata_stimata_min': b.durataStimataMin,
        'note': b.note,
        'stato': b.stato,
        'fonte': b.fonte,
        'importato_il': DateTime.now().toIso8601String(),
        'modificato_in_app': false,
      };

      String bloccoId;
      if (esistente == null) {
        final row = await _client
            .from('training_blocks')
            .insert(payloadBlocco)
            .select()
            .single();
        bloccoId = row['id'] as String;
        importati++;
      } else {
        bloccoId = esistente['id'] as String;
        await _client
            .from('training_blocks')
            .update(payloadBlocco)
            .eq('id', bloccoId);
        await _client
            .from('training_block_parti')
            .delete()
            .eq('blocco_id', bloccoId);
        aggiornati++;
      }

      final payloadParti = [
        for (final p in b.parti)
          {
            'blocco_id': bloccoId,
            'ordine': p.ordine,
            'giri': p.giri,
            'ripetizioni': p.ripetizioni,
            'distanza_m': p.distanzaM,
            'durata_s': p.durataS,
            'stile': p.stile,
            'esercizio': p.esercizio,
            'zona': p.zona,
            'esecuzione': p.esecuzione,
            'recupero_s': p.recuperoS,
            'attrezzi': p.attrezzi,
            'note': p.note,
          },
      ];
      if (payloadParti.isNotEmpty) {
        await _client.from('training_block_parti').insert(payloadParti);
      }
    }

    await refreshFromRemote(clubId);
    return RiepilogoImportazione(
      importati: importati,
      aggiornati: aggiornati,
      saltati: saltati,
      errori: errori,
    );
  }
}

final trainingBlocksRepositoryProvider = Provider<TrainingBlocksRepository>((
  ref,
) {
  return TrainingBlocksRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
