import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ClubTable,
    AtletiTable,
    TestIngressoTable,
    TabellePassiTable,
    StagioniTable,
    MacrocicliTable,
    MesocicliTable,
    MicrocicliTable,
    AllenamentiTable,
    SerieTable,
    PresenzeTable,
    PendingOperationsTable,
    PartiteTable,
    DistintaGiocatoriTable,
    EventiPartitaTable,
    RefertiPartitaTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: aggiunta la coda di sincronizzazione.
      if (from < 2) {
        await m.createTable(pendingOperationsTable);
      }
      // v2 -> v3: aggiunta la gerarchia di stagione (Fase 4).
      if (from < 3) {
        await m.createTable(stagioniTable);
        await m.createTable(macrocicliTable);
        await m.createTable(mesocicliTable);
        await m.createTable(microcicliTable);
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
          await m.addColumn(eventiPartitaTable, eventiPartitaTable.contestoTiro);
        }
      }
    },
  );

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
