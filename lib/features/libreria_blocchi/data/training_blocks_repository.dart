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

  Future<List<TrainingBlockParte>> fetchParti(String bloccoId) async {
    final rows = await _client
        .from('training_block_parti')
        .select()
        .eq('blocco_id', bloccoId)
        .order('ordine');
    return rows.map(TrainingBlockParte.fromMap).toList();
  }

  /// Le parti di più blocchi in un colpo solo (es. per l'esportazione
  /// Excel di tutta la libreria): una richiesta sola, non una per
  /// blocco in sequenza — lo stesso errore corretto in
  /// `selezione_blocchi_service.dart` dopo il blocco trovato dal coach.
  Future<Map<String, List<TrainingBlockParte>>> fetchPartiPerBlocchi(
    List<String> bloccoIds,
  ) async {
    if (bloccoIds.isEmpty) return {};
    final rows = await _client
        .from('training_block_parti')
        .select()
        .inFilter('blocco_id', bloccoIds)
        .order('ordine');
    final risultato = <String, List<TrainingBlockParte>>{};
    for (final r in rows) {
      final parte = TrainingBlockParte.fromMap(r);
      (risultato[parte.bloccoId] ??= []).add(parte);
    }
    return risultato;
  }

  /// Sostituzione totale per questo club (non insertOrReplace): un
  /// blocco eliminato fuori dall'app resterebbe altrimenti in cache.
  Future<void> refreshFromRemote(String clubId) async {
    final blocchi = await _client
        .from('training_blocks')
        .select()
        .eq('club_id', clubId);
    final idBlocchi = [for (final b in blocchi) b['id'] as String];
    final parti = idBlocchi.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('training_block_parti')
              .select()
              .inFilter('blocco_id', idBlocchi);
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
    final esistenti = await _client
        .from('training_blocks')
        .select('codice')
        .eq('club_id', originale.clubId);
    final codiciEsistenti = {for (final r in esistenti) r['codice'] as String};
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
    final payload = [
      for (final p in parti)
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
    final righe = await _client
        .from('training_block_parti')
        .insert(payload)
        .select();
    await _db.batch((batch) {
      for (final r in righe) {
        batch.insert(
          _db.trainingBlockPartiTable,
          _parteCompanionFromMap({...r, 'club_id': clubId}),
        );
      }
    });
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
    final esistenti = await _client
        .from('training_blocks')
        .select('id, codice, modificato_in_app')
        .eq('club_id', clubId);
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
