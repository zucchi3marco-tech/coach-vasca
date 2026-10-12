import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
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
  test('senza rete gli eventi completi restano sul telefono e partono '
      'dopo', () async {
    final client = _senzaRete();
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await client.dispose();
    });
    await db
        .into(db.partiteTable)
        .insert(
          PartiteTableCompanion.insert(
            id: 'p1',
            clubId: 'c1',
            data: DateTime(2026, 10, 12),
            squadraCasa: 'Noi',
            squadraTrasferta: 'Loro',
          ),
        );
    final repository = EventiPartitaRepository(
      client,
      db,
      SyncEngine(db, client),
    );

    // Il gol si salva subito, l'assist arriva dopo.
    final gol = await repository.registraTiro(
      partitaId: 'p1',
      atletaId: 'rossi',
      esito: 'gol',
      contestoTiro: 'controfuga',
    );
    final conAssist = await repository.impostaAssist(
      id: gol.id,
      atletaId: 'bianchi',
    );
    expect(conAssist.assistDi, 'bianchi');
    expect(conAssist.contestoTiro, 'controfuga');
    expect(conAssist.clubId, 'c1');

    // Se non era gol, l'assist se ne va.
    final corretto = await repository.modificaEsito(
      id: gol.id,
      esito: 'parato',
    );
    expect(corretto.assistDi, isNull);

    final palla = await repository.registraPalla(
      partitaId: 'p1',
      recuperata: false,
    );
    expect(palla.tipo, 'palla_persa');
    expect(palla.atletaId, isNull);

    final espulsione = await repository.registraEspulsione(
      partitaId: 'p1',
      numeroCalottinaAvversario: 7,
    );
    final guadagnata = await repository.impostaGuadagnataDa(
      id: espulsione.id,
      atletaId: 'rossi',
    );
    expect(guadagnata.guadagnataDa, 'rossi');
    expect(guadagnata.squadra, 'avversaria');

    expect(await repository.watchPerPartita('p1').first, hasLength(3));

    final coda = [
      for (final o in await db.select(db.pendingOperationsTable).get())
        (
          o.operazione,
          jsonDecode(o.payloadJson ?? '{}') as Map<String, dynamic>,
        ),
    ];
    expect(coda.map((o) => o.$1), [
      'insert',
      'update',
      'update',
      'insert',
      'insert',
      'update',
    ]);
    expect(coda[1].$2, {'assist_di': 'bianchi'});
    expect(coda[2].$2, {'esito': 'parato', 'assist_di': null});
    expect(coda[3].$2['tipo'], 'palla_persa');
    expect(coda[5].$2, {'guadagnata_da': 'rossi'});
  });
}
