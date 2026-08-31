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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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
    },
  );

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
