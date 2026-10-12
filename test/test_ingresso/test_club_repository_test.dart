import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/test/data/test_club_repository.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// A bordo vasca la rete può mancare: ogni richiesta fallisce come un
/// errore di rete.
SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  test('senza rete il risultato resta sul telefono e parte dopo', () async {
    final client = _senzaRete();
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await client.dispose();
    });
    final repository = TestClubRepository(client, db, SyncEngine(db, client));

    final test = await repository.creaTest(
      const TestClub(
        id: '',
        clubId: 'c1',
        nome: 'Sprint 15 m',
        unita: UnitaTest.secondi,
        piuBassoMeglio: true,
        prove: 2,
      ),
    );
    expect(test.id, isNotEmpty);
    expect(test.prove, 2);

    final giorno = DateTime(2026, 10, 12, 18, 30);
    await repository.salvaRisultato(
      testId: test.id,
      atletaId: 'a1',
      clubId: 'c1',
      data: giorno,
      valori: const [8.7, 8.9],
    );
    // Rifatto lo stesso giorno: sostituisce, non aggiunge.
    await repository.salvaRisultato(
      testId: test.id,
      atletaId: 'a1',
      clubId: 'c1',
      data: giorno,
      valori: const [8.6, 8.8],
    );

    final risultati = await repository.watchRisultati('c1').first;
    expect(risultati.single.valori, [8.6, 8.8]);
    expect(risultati.single.data, DateTime(2026, 10, 12));

    final coda = await db.select(db.pendingOperationsTable).get();
    final dei = [
      for (final o in coda)
        if (o.tabella == 'test_risultati') o,
    ];
    expect(dei.map((o) => o.operazione).toSet(), {'upsert'});
    expect(dei.map((o) => o.rigaId).toSet(), {risultati.single.id});
    expect(
      coda.where((o) => o.tabella == 'test_club').single.operazione,
      'insert',
    );

    // Eliminando il test se ne vanno anche i risultati in locale.
    await repository.eliminaTest(test.id);
    expect(await repository.watchRisultati('c1').first, isEmpty);
    expect(await repository.watchTest('c1').first, isEmpty);
  });
}
