import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/modifiche_rifiutate.dart';
import 'package:coach_vasca/core/sync/pending_operations.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Il server finto: dice l'ora, risponde con l'updated_at delle righe
/// ([righe], chiave «tabella|valori dei filtri»; assente = la riga non
/// c'è) e annota le scritture.
class _Server {
  _Server({this.conOra = true});

  final bool conOra;
  final adesso = DateTime.now().toUtc();
  final righe = <String, DateTime>{};
  final scritture = <String>[];

  http.Response _json(Object? corpo, http.Request r, [int stato = 200]) =>
      http.Response(
        jsonEncode(corpo),
        stato,
        headers: {'content-type': 'application/json'},
        request: r,
      );

  Future<http.Response> rispondi(http.Request r) async {
    final percorso = r.url.path;
    if (percorso.endsWith('/rpc/ora_del_server')) {
      return conOra
          ? _json(adesso.toIso8601String(), r)
          : _json(
              {'code': 'PGRST202', 'message': 'Could not find the function'},
              r,
              404,
            );
    }
    final tabella = percorso.split('/').last;
    if (r.method == 'GET') {
      final valori = [
        for (final MapEntry(:key, :value) in r.url.queryParameters.entries)
          if (key != 'select' && key != 'limit') value.replaceFirst('eq.', ''),
      ];
      final ora = righe['$tabella|${valori.join('|')}'];
      return _json([
        if (ora != null) {'updated_at': ora.toIso8601String()},
      ], r);
    }
    scritture.add('${r.method} $tabella');
    // La scrittura arriva ora: la riga è aggiornata adesso.
    final id = r.url.queryParameters['id']?.replaceFirst('eq.', '');
    if (id != null) righe['$tabella|$id'] = DateTime.now().toUtc();
    return _json(null, r, 204);
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.perTest(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<({List<ModificaRifiutata> rifiutate, List<String> conflitti})>
  sincronizza(_Server server) async {
    final client = SupabaseClient(
      'http://supabase.finto',
      'chiave-finta',
      httpClient: MockClient(server.rispondi),
    );
    addTearDown(client.dispose);
    final rifiutate = <ModificaRifiutata>[];
    final conflitti = <String>[];
    await SyncEngine(
      db,
      client,
      suRifiuto: rifiutate.add,
      suConflitto: conflitti.add,
    ).processQueue();
    return (rifiutate: rifiutate, conflitti: conflitti);
  }

  Future<int> coda() async =>
      (await db.select(db.pendingOperationsTable).get()).length;

  test('l\'ora conta da quanto tempo fa è stata fatta la modifica', () {
    final server = DateTime.utc(2026, 10, 27, 10);
    // Il telefono è 7 minuti avanti: non importa.
    final fatta = fattaInOraServer(
      creataIl: DateTime(2026, 10, 27, 11, 2),
      adesso: DateTime(2026, 10, 27, 11, 7),
      oraServer: server,
    );
    expect(fatta, DateTime.utc(2026, 10, 27, 9, 55));
    expect(cambiataDaAltri(aggiornata: server, fatta: fatta), isTrue);
    expect(
      cambiataDaAltri(
        aggiornata: DateTime.utc(2026, 10, 27, 9, 50),
        fatta: fatta,
      ),
      isFalse,
    );
    // L'ultima scrittura era mia: non è un conflitto.
    expect(
      cambiataDaAltri(
        aggiornata: server,
        fatta: fatta,
        scrittaDaMe: server.add(const Duration(seconds: 5)),
      ),
      isFalse,
    );
  });

  test('un collega ha cambiato la riga: la modifica non parte e la spia '
      'lo dice', () async {
    final server = _Server();
    server.righe['serie|s1'] = server.adesso.add(const Duration(minutes: 1));
    await enqueueOperation(
      db,
      tabella: 'serie',
      operazione: 'update',
      rigaId: 's1',
      payload: {'note': 'la mia'},
    );
    final esito = await sincronizza(server);
    expect(server.scritture, isEmpty);
    expect(await coda(), 0);
    expect(esito.rifiutate.single.codice, ModificaRifiutata.codiceConflitto);
    expect(esito.rifiutate.single.perche, contains('è rimasta la sua'));
    expect(esito.conflitti, ['serie']);
  });

  test('nessuno l\'ha toccata dopo: la modifica parte', () async {
    final server = _Server();
    server.righe['serie|s1'] = server.adesso.subtract(const Duration(hours: 1));
    await enqueueOperation(
      db,
      tabella: 'serie',
      operazione: 'update',
      rigaId: 's1',
      payload: {'note': 'la mia'},
    );
    final esito = await sincronizza(server);
    expect(server.scritture, ['PATCH serie']);
    expect(esito.rifiutate, isEmpty);
    expect(await coda(), 0);
  });

  test('un collega l\'ha tolta: cambiarla non la fa tornare', () async {
    final server = _Server();
    await enqueueOperation(
      db,
      tabella: 'partite',
      operazione: 'update',
      rigaId: 'p1',
      payload: {'note': 'x'},
    );
    final esito = await sincronizza(server);
    expect(server.scritture, isEmpty);
    expect(esito.rifiutate.single.codice, ModificaRifiutata.codiceTolta);
  });

  test('togliere una riga che un collega ha cambiato: resta la sua', () async {
    final server = _Server();
    server.righe['atleti|a1'] = server.adesso.add(const Duration(minutes: 2));
    await enqueueOperation(
      db,
      tabella: 'atleti',
      operazione: 'delete',
      rigaId: 'a1',
    );
    final esito = await sincronizza(server);
    expect(server.scritture, isEmpty);
    expect(esito.rifiutate.single.tipo, 'eliminazione');
  });

  test('l\'appello: si guarda la presenza per seduta e atleta', () async {
    final server = _Server();
    server.righe['presenze|al1|a1'] = server.adesso.add(
      const Duration(minutes: 1),
    );
    await enqueueOperation(
      db,
      tabella: 'presenze',
      operazione: 'upsert',
      rigaId: 'x',
      payload: {'allenamento_id': 'al1', 'atleta_id': 'a1', 'stato': 'assente'},
    );
    await enqueueOperation(
      db,
      tabella: 'presenze',
      operazione: 'upsert',
      rigaId: 'y',
      payload: {
        'allenamento_id': 'al1',
        'atleta_id': 'a2',
        'stato': 'presente',
      },
    );
    final esito = await sincronizza(server);
    // La prima l'ha cambiata un collega, la seconda no.
    expect(server.scritture, ['POST presenze']);
    expect(esito.rifiutate, hasLength(1));
    expect(esito.conflitti, ['presenze']);
  });

  test(
    'due modifiche mie di fila sulla stessa riga non si scontrano',
    () async {
      final server = _Server();
      server.righe['serie|s1'] = server.adesso.subtract(
        const Duration(hours: 1),
      );
      for (final nota in ['prima', 'seconda']) {
        await enqueueOperation(
          db,
          tabella: 'serie',
          operazione: 'update',
          rigaId: 's1',
          payload: {'note': nota},
        );
      }
      final esito = await sincronizza(server);
      expect(server.scritture, ['PATCH serie', 'PATCH serie']);
      expect(esito.rifiutate, isEmpty);
    },
  );

  test('se il server non sa dire l\'ora si manda come prima', () async {
    final server = _Server(conOra: false);
    server.righe['serie|s1'] = server.adesso.add(const Duration(minutes: 1));
    await enqueueOperation(
      db,
      tabella: 'serie',
      operazione: 'update',
      rigaId: 's1',
      payload: {'note': 'la mia'},
    );
    final esito = await sincronizza(server);
    expect(server.scritture, ['PATCH serie']);
    expect(esito.rifiutate, isEmpty);
  });
}
