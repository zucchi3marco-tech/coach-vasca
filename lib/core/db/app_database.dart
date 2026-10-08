import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ClubTable,
    AtletiTable,
    PersonalBestTable,
    TempiGaraTable,
    SchemiTatticiTable,
    TestIngressoTable,
    TabellePassiTable,
    StagioniTable,
    AllenamentiTable,
    SerieTable,
    PresenzeTable,
    PendingOperationsTable,
    PartiteTable,
    DistintaGiocatoriTable,
    EventiPartitaTable,
    RefertiPartitaTable,
    GruppiTable,
    GareTable,
    GaraIscrittiTable,
    TrainingBlocksTable,
    TrainingBlockPartiTable,
    SchedeBenessereTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 31;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: aggiunta la coda di sincronizzazione.
      if (from < 2) {
        await m.createTable(pendingOperationsTable);
      }
      // v2 -> v3: aggiunta la gerarchia di stagione (Fase 4). La
      // gerarchia macrociclo/mesociclo/microciclo creata qui e' stata poi
      // rimossa in FASE 11 (v14 -> v15): non piu' nello schema, quindi
      // non piu' creata qui (verrebbe comunque droppata subito dopo).
      if (from < 3) {
        await m.createTable(stagioniTable);
      }
      // v3 -> v4: pallanuoto V2, partite e distinta (Fase 7).
      if (from < 4) {
        await m.addColumn(atletiTable, atletiTable.numeroTesseraFin);
        await m.createTable(partiteTable);
        await m.createTable(distintaGiocatoriTable);
      }
      // v4 -> v5: eventi partita base (Fase 7, punto 2).
      // Controlli difensivi (colonna/tabella gia' presente): la cache
      // locale web (IndexedDB/OPFS) puo' restare a meta' tra due versioni
      // dello schema se il dev server viene ricaricato a meta' di una
      // migrazione precedente, senza che la versione salvata avanzi.
      if (from < 5) {
        if (!await _hasColumn(m, 'partite_table', 'dettaglio_tiro')) {
          await m.addColumn(partiteTable, partiteTable.dettaglioTiro);
        }
        if (!await _hasColumn(m, 'partite_table', 'traccia_tempo')) {
          await m.addColumn(partiteTable, partiteTable.tracciaTempo);
        }
        if (!await _hasColumn(m, 'partite_table', 'modalita_superiorita')) {
          await m.addColumn(partiteTable, partiteTable.modalitaSuperiorita);
        }
        if (!await _hasTable(m, 'eventi_partita_table')) {
          await m.createTable(eventiPartitaTable);
        }
      }
      // v5 -> v6: salvataggio referti analizzati (Fase 8).
      if (from < 6) {
        if (!await _hasTable(m, 'referti_partita_table')) {
          await m.createTable(refertiPartitaTable);
        }
      }
      // v6 -> v7: nostra squadra su partita, per le statistiche
      // stagionali (Fase 8).
      if (from < 7) {
        if (!await _hasColumn(m, 'partite_table', 'nostra_squadra')) {
          await m.addColumn(partiteTable, partiteTable.nostraSquadra);
        }
      }
      // v7 -> v8: contesto del tiro (azione/superiorita/rigore), per le
      // statistiche stagionali "da eventi live" (Fase 8).
      if (from < 8) {
        if (!await _hasColumn(m, 'eventi_partita_table', 'contesto_tiro')) {
          await m.addColumn(
            eventiPartitaTable,
            eventiPartitaTable.contestoTiro,
          );
        }
      }
      // v8 -> v9: account atleta (user_id su atleti) e personal best
      // (Fase 9).
      if (from < 9) {
        if (!await _hasColumn(m, 'atleti_table', 'user_id')) {
          await m.addColumn(atletiTable, atletiTable.userId);
        }
        if (!await _hasTable(m, 'personal_best_table')) {
          await m.createTable(personalBestTable);
        }
      }
      // v9 -> v10: scadenza visita medica (Fase 9).
      if (from < 10) {
        if (!await _hasColumn(m, 'atleti_table', 'visita_medica_scadenza')) {
          await m.addColumn(atletiTable, atletiTable.visitaMedicaScadenza);
        }
      }
      // v10 -> v11: posizione del tiro ed espulsioni avversarie (Fase 9).
      if (from < 11) {
        if (!await _hasColumn(m, 'eventi_partita_table', 'pos_x')) {
          await m.addColumn(eventiPartitaTable, eventiPartitaTable.posX);
        }
        if (!await _hasColumn(m, 'eventi_partita_table', 'pos_y')) {
          await m.addColumn(eventiPartitaTable, eventiPartitaTable.posY);
        }
        if (!await _hasColumn(
          m,
          'eventi_partita_table',
          'numero_calottina_avversario',
        )) {
          await m.addColumn(
            eventiPartitaTable,
            eventiPartitaTable.numeroCalottinaAvversario,
          );
        }
        if (!await _hasColumn(
          m,
          'eventi_partita_table',
          'espulsione_da_rigore',
        )) {
          await m.addColumn(
            eventiPartitaTable,
            eventiPartitaTable.espulsioneDaRigore,
          );
        }
      }
      // v11 -> v12: campionato sulla stagione, non piu' sulla singola
      // partita (FASE 10, punto 1) — ereditato automaticamente in base
      // alla data della partita.
      if (from < 12) {
        if (!await _hasColumn(m, 'stagioni_table', 'campionato')) {
          await m.addColumn(stagioniTable, stagioniTable.campionato);
        }
      }
      // v12 -> v13: gruppi di allenamento formali (FASE 10, ultimo punto)
      // al posto del campo "gruppo" testo libero su atleti/allenamenti/
      // stagioni.
      if (from < 13) {
        if (!await _hasTable(m, 'gruppi_table')) {
          await m.createTable(gruppiTable);
        }
        if (!await _hasColumn(m, 'atleti_table', 'gruppo_id')) {
          await m.addColumn(atletiTable, atletiTable.gruppoId);
        }
        if (await _hasColumn(m, 'atleti_table', 'gruppo')) {
          await m.database.customStatement(
            'ALTER TABLE atleti_table DROP COLUMN gruppo',
          );
        }
        if (!await _hasColumn(m, 'allenamenti_table', 'gruppo_id')) {
          await m.addColumn(allenamentiTable, allenamentiTable.gruppoId);
        }
        if (await _hasColumn(m, 'allenamenti_table', 'gruppo')) {
          await m.database.customStatement(
            'ALTER TABLE allenamenti_table DROP COLUMN gruppo',
          );
        }
        if (!await _hasColumn(m, 'stagioni_table', 'gruppo_id')) {
          await m.addColumn(stagioniTable, stagioniTable.gruppoId);
        }
        if (await _hasColumn(m, 'stagioni_table', 'gruppo')) {
          await m.database.customStatement(
            'ALTER TABLE stagioni_table DROP COLUMN gruppo',
          );
        }
      }
      // v13 -> v14: sport e categorie allenate sul club (FASE 11), chiesti
      // alla prima registrazione insieme a nome e citta'.
      if (from < 14) {
        if (!await _hasColumn(m, 'club_table', 'sport')) {
          await m.addColumn(clubTable, clubTable.sport);
        }
        if (!await _hasColumn(m, 'club_table', 'categorie_json')) {
          await m.addColumn(clubTable, clubTable.categorieJson);
        }
      }
      // v14 -> v15: eliminata la gerarchia macrociclo/mesociclo/microciclo
      // (FASE 11, punto 6) — la stagione resta solo nome + periodo, gli
      // allenamenti non si collegano piu' a un microciclo.
      if (from < 15) {
        if (await _hasColumn(m, 'allenamenti_table', 'microciclo_id')) {
          await m.database.customStatement(
            'ALTER TABLE allenamenti_table DROP COLUMN microciclo_id',
          );
        }
        for (final tabella in [
          'microcicli_table',
          'mesocicli_table',
          'macrocicli_table',
        ]) {
          if (await _hasTable(m, tabella)) {
            await m.database.customStatement('DROP TABLE $tabella');
          }
        }
      }
      // v15 -> v16: sport per gruppo (FASE 13, punto 2) — la
      // registrazione via codice di gruppo deduce lo sport dal gruppo
      // invece di chiederlo sempre.
      if (from < 16) {
        if (!await _hasColumn(m, 'gruppi_table', 'sport')) {
          await m.addColumn(gruppiTable, gruppiTable.sport);
        }
      }
      // v16 -> v17: storico tempi gara nuoto — a differenza di
      // PersonalBestTable (un solo tempo, il migliore, per stile+
      // distanza), qui ogni tempo inserito resta una voce separata,
      // per la curva delle prestazioni nel tempo.
      if (from < 17) {
        if (!await _hasTable(m, 'tempi_gara_table')) {
          await m.createTable(tempiGaraTable);
        }
      }
      // v17 -> v18: schemi tattici salvati (lavagnetta pallanuoto): prima
      // era solo locale, ora l'allenatore li disegna e li salva, gli
      // atleti li sfogliano.
      if (from < 18) {
        if (!await _hasTable(m, 'schemi_tattici_table')) {
          await m.createTable(schemiTatticiTable);
        }
      }
      // v18 -> v19: categoria (gruppo libero) e campo (intero/meta) per
      // gli schemi tattici, dopo il primo giro d'uso della lavagna.
      if (from < 19) {
        if (!await _hasColumn(m, 'schemi_tattici_table', 'categoria')) {
          await m.addColumn(schemiTatticiTable, schemiTatticiTable.categoria);
        }
        if (!await _hasColumn(m, 'schemi_tattici_table', 'campo')) {
          await m.addColumn(schemiTatticiTable, schemiTatticiTable.campo);
        }
      }
      // v19 -> v20: isolamento per gruppo estesa a partite e schemi
      // tattici (prima condivisi con tutto il club senza eccezioni).
      if (from < 20) {
        if (!await _hasColumn(m, 'partite_table', 'gruppo_id')) {
          await m.addColumn(partiteTable, partiteTable.gruppoId);
        }
        if (!await _hasColumn(m, 'schemi_tattici_table', 'gruppo_id')) {
          // Colonna rimossa in v23 -> v24 (sostituita da
          // gruppo_ids_json): SQL diretto invece di
          // schemiTatticiTable.gruppoId, che non esiste piu' nel
          // modello Drift attuale.
          await m.database.customStatement(
            'ALTER TABLE schemi_tattici_table ADD COLUMN gruppo_id TEXT',
          );
        }
      }
      // v20 -> v21: gare del nuoto (evento di calendario, come la partita
      // per la pallanuoto).
      if (from < 21) {
        if (!await _hasTable(m, 'gare_table')) {
          await m.createTable(gareTable);
        }
      }
      // v21 -> v22: atleti iscritti alle gare.
      if (from < 22) {
        if (!await _hasTable(m, 'gara_iscritti_table')) {
          await m.createTable(garaIscrittiTable);
        }
      }
      // v22 -> v23: risultati di gara (un tempo puo' essere collegato
      // alla gara in cui e' stato nuotato).
      if (from < 23) {
        if (!await _hasColumn(m, 'tempi_gara_table', 'gara_id')) {
          await m.addColumn(tempiGaraTable, tempiGaraTable.garaId);
        }
      }
      // v23 -> v24: uno schema tattico puo' appartenere a piu' gruppi
      // (prima un solo `gruppo_id` nullable) — sostituito da un elenco
      // JSON di id, stesso schema di [ClubTable.categorieJson]. La
      // cache si ripopola al prossimo refresh, nessun backfill locale
      // necessario.
      if (from < 24) {
        if (!await _hasColumn(m, 'schemi_tattici_table', 'gruppo_ids_json')) {
          await m.addColumn(
            schemiTatticiTable,
            schemiTatticiTable.gruppoIdsJson,
          );
        }
        if (await _hasColumn(m, 'schemi_tattici_table', 'gruppo_id')) {
          await m.database.customStatement(
            'ALTER TABLE schemi_tattici_table DROP COLUMN gruppo_id',
          );
        }
      }
      // v24 -> v25: le righe di una serie piramidale (es. 50-100-200-
      // 100-50, dalla barra rapida) condividono un piramide_id, per
      // raggrupparle in un'unica riga visiva.
      if (from < 25) {
        if (!await _hasColumn(m, 'serie_table', 'piramide_id')) {
          await m.addColumn(serieTable, serieTable.piramideId);
        }
      }
      // v25 -> v26: campo "durata in secondi" sulla serie (RIPROGETTAZIONE
      // AI, FASE 1), alternativa alla distanza. SQLite non supporta
      // rilassare un NOT NULL con ALTER COLUMN: si ricrea la tabella
      // (sempre e solo una cache, non la fonte di verita') copiando i
      // dati esistenti, tutti ancora a distanza.
      if (from < 26) {
        if (!await _hasColumn(m, 'serie_table', 'durata_s')) {
          await m.database.customStatement(
            'ALTER TABLE serie_table RENAME TO serie_table_old_v25',
          );
          await m.createTable(serieTable);
          await m.database.customStatement('''
            INSERT INTO serie_table (
              id, allenamento_id, club_id, ordine, blocco, ripetute,
              distanza_m, durata_s, stile, esecuzione, zona,
              passo_obiettivo_s, recupero_s, ripartenza_s, attrezzatura,
              note, piramide_id
            )
            SELECT
              id, allenamento_id, club_id, ordine, blocco, ripetute,
              distanza_m, NULL, stile, esecuzione, zona,
              passo_obiettivo_s, recupero_s, ripartenza_s, attrezzatura,
              note, piramide_id
            FROM serie_table_old_v25
          ''');
          await m.database.customStatement('DROP TABLE serie_table_old_v25');
        }
      }
      // v26 -> v27: libreria di blocchi di allenamento approvati
      // (RIPROGETTAZIONE AI, FASE 1).
      if (from < 27) {
        if (!await _hasTable(m, 'training_blocks_table')) {
          await m.createTable(trainingBlocksTable);
        }
        if (!await _hasTable(m, 'training_block_parti_table')) {
          await m.createTable(trainingBlockPartiTable);
        }
      }
      // v27 -> v28: "importanza" su gare e partite (RIPROGETTAZIONE AI,
      // FASE 3) — lo scarico pre-gara del generatore settimanale scatta
      // solo per le "alta".
      if (from < 28) {
        if (!await _hasColumn(m, 'gare_table', 'importanza')) {
          await m.addColumn(gareTable, gareTable.importanza);
        }
        if (!await _hasColumn(m, 'partite_table', 'importanza')) {
          await m.addColumn(partiteTable, partiteTable.importanza);
        }
      }
      // v28 -> v29: scheda benessere dell'atleta (dolori, ore di sonno).
      if (from < 29) {
        if (!await _hasTable(m, 'schede_benessere_table')) {
          await m.createTable(schedeBenessereTable);
        }
      }
      // v29 -> v30: scheda benessere con le voci del questionario McLean.
      if (from < 30 && from >= 29) {
        final t = schedeBenessereTable;
        for (final (nome, colonna) in [
          ('qualita_sonno', t.qualitaSonno),
          ('energia', t.energia),
          ('muscoli', t.muscoli),
          ('stress', t.stress),
          ('umore', t.umore),
          ('sintomi_json', t.sintomiJson),
        ]) {
          if (!await _hasColumn(m, 'schede_benessere_table', nome)) {
            await m.addColumn(t, colonna);
          }
        }
      }
      // v30 -> v31: esito della serie (fatta/saltata) segnato a bordo
      // vasca.
      if (from < 31) {
        if (!await _hasColumn(m, 'serie_table', 'esito')) {
          await m.addColumn(serieTable, serieTable.esito);
        }
      }
    },
  );

  /// Svuota ogni tabella locale (chiamato quando cambia l'utente
  /// autenticato su questo device — vedi `cache_utente_guard.dart`):
  /// senza, i dati dell'utente precedente resterebbero in cache e
  /// verrebbero mostrati al nuovo finche' un refresh online non
  /// sovrascrive per caso ogni singola tabella.
  Future<void> clearAll() async {
    await transaction(() async {
      for (final tabella in allTables) {
        await customStatement('DELETE FROM ${tabella.actualTableName}');
      }
    });
  }

  static Future<bool> _hasColumn(
    Migrator m,
    String table,
    String column,
  ) async {
    final righe = await m.database
        .customSelect('PRAGMA table_info($table)')
        .get();
    return righe.any((riga) => riga.data['name'] == column);
  }

  static Future<bool> _hasTable(Migrator m, String table) async {
    final righe = await m.database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable.withString(table)],
        )
        .get();
    return righe.isNotEmpty;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'coach_vasca',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
