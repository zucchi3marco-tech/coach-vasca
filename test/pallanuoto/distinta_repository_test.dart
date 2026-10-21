import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/gruppi/data/gruppi_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/numeri_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/domain/staff_distinta.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

SupabaseClient _client(MockClient http) =>
    SupabaseClient('http://supabase.finto', 'chiave-finta', httpClient: http);

SupabaseClient _senzaRete() => _client(
  MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.perTest(NativeDatabase.memory());
    Future<void> partita(String id, DateTime data, {String? gruppo}) => db
        .into(db.partiteTable)
        .insert(
          PartiteTableCompanion.insert(
            id: id,
            clubId: 'c1',
            gruppoId: Value(gruppo),
            data: data,
            squadraCasa: 'Canottieri',
            squadraTrasferta: 'Avversari $id',
          ),
        );
    await partita('oggi', DateTime(2026, 10, 25), gruppo: 'u16');
    await partita('prima', DateTime(2026, 10, 18), gruppo: 'u16');
    await partita('senza-convocati', DateTime(2026, 10, 21), gruppo: 'u16');
    await partita('altra-squadra', DateTime(2026, 10, 22), gruppo: 'u14');
    await partita('dopo', DateTime(2026, 11, 1), gruppo: 'u16');
  });

  tearDown(() => db.close());

  Future<void> convocato(
    String id,
    String partita,
    String atleta,
    int numero, {
    bool capitano = false,
    bool vice = false,
  }) => db
      .into(db.distintaGiocatoriTable)
      .insert(
        DistintaGiocatoriTableCompanion.insert(
          id: id,
          partitaId: partita,
          atletaId: atleta,
          clubId: 'c1',
          numeroCalottina: numero,
          capitano: Value(capitano),
          viceCapitano: Value(vice),
        ),
      );

  Future<List<(String, String, String, Object?)>> coda() async => [
    for (final o in await (db.select(
      db.pendingOperationsTable,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
      (
        o.tabella,
        o.operazione,
        o.rigaId,
        o.payloadJson == null ? null : jsonDecode(o.payloadJson!),
      ),
  ];

  Future<Map<String, int>> numeri(String partita) async => {
    for (final r in await (db.select(
      db.distintaGiocatoriTable,
    )..where((t) => t.partitaId.equals(partita))).get())
      r.atletaId: r.numeroCalottina,
  };

  group('senza rete', () {
    late SupabaseClient client;
    late DistintaRepository repository;

    setUp(() {
      client = _senzaRete();
      repository = DistintaRepository(client, db, SyncEngine(db, client));
    });

    tearDown(() => client.dispose());

    test('tutti i convocati insieme: prima esce chi si toglie, poi entrano '
        'i nuovi, e la coda li manda nello stesso ordine', () async {
      await convocato('r1', 'oggi', 'vecchio', 5);
      await repository.salvaConvocati(
        partitaId: 'oggi',
        togli: ['r1'],
        aggiungi: [
          (
            atletaId: 'a',
            numero: 5,
            portiere: false,
            capitano: true,
            viceCapitano: false,
          ),
          (
            atletaId: 'b',
            numero: 1,
            portiere: true,
            capitano: false,
            viceCapitano: false,
          ),
        ],
      );

      expect(await numeri('oggi'), {'a': 5, 'b': 1});
      final ops = await coda();
      expect([for (final o in ops) (o.$1, o.$2)], [
        ('distinta_giocatori', 'delete'),
        ('distinta_giocatori', 'insert'),
        ('distinta_giocatori', 'insert'),
      ]);
      expect(ops[0].$3, 'r1');
      final primo = ops[1].$4! as Map<String, dynamic>;
      expect(primo['atleta_id'], 'a');
      expect(primo['capitano'], isTrue);
      expect(primo.containsKey('club_id'), isFalse);
      final secondo = ops[2].$4! as Map<String, dynamic>;
      expect(secondo['portiere'], isTrue);
    });

    test('Riordina cambia i numeri sul telefono e mette in coda una sola '
        'funzione del database', () async {
      await convocato('r1', 'oggi', 'a', 2);
      await convocato('r2', 'oggi', 'b', 3);
      await repository.rinumera('oggi', {'r1': 3, 'r2': 2});

      expect(await numeri('oggi'), {'a': 3, 'b': 2});
      final ops = await coda();
      expect(ops.single.$1, 'rinumera_distinta');
      expect(ops.single.$2, 'rpc');
      expect(ops.single.$4, {
        'p_partita_id': 'oggi',
        'p_numeri': [
          {'id': 'r1', 'numero': 3},
          {'id': 'r2', 'numero': 2},
        ],
      });
    });

    test('un capitano nuovo toglie la fascia al vecchio', () async {
      await convocato('r1', 'oggi', 'a', 2, capitano: true);
      await convocato('r2', 'oggi', 'b', 3);
      await convocato('r3', 'oggi', 'c', 4, vice: true);
      await repository.scegliCapitani('oggi', capitanoId: 'r2', viceId: 'r1');

      final righe = {
        for (final r in await db.select(db.distintaGiocatoriTable).get())
          r.id: (r.capitano, r.viceCapitano),
      };
      expect(righe, {
        'r1': (false, true),
        'r2': (true, false),
        'r3': (false, false),
      });
      final op = (await coda()).single;
      expect(op.$1, 'scegli_capitani');
      expect(op.$4, {
        'p_partita_id': 'oggi',
        'p_capitano_id': 'r2',
        'p_vice_id': 'r1',
      });
    });

    test('capitano e vice non possono essere lo stesso', () {
      expect(
        () => repository.scegliCapitani('oggi', capitanoId: 'r1', viceId: 'r1'),
        throwsStateError,
      );
    });

    test('l\'ultima partita è la più recente della stessa squadra, fino al '
        'giorno di questa, con dei convocati', () async {
      await convocato('x1', 'prima', 'a', 4, capitano: true);
      await convocato('x2', 'prima', 'b', 9, vice: true);
      await convocato('y1', 'altra-squadra', 'a', 7);
      await convocato('z1', 'dopo', 'a', 11);

      final ultima = await repository.ultimaDellaSquadra((
        partitaId: 'oggi',
        clubId: 'c1',
        gruppoId: 'u16',
        data: DateTime(2026, 10, 25),
      ));
      expect(ultima?.partitaId, 'prima');
      expect(ultima?.avversario, 'Avversari prima');
      expect(ultima?.perAtleta, {
        'a': (numero: 4, capitano: true, viceCapitano: false),
        'b': (numero: 9, capitano: false, viceCapitano: true),
      });
    });

    test('nessuna partita prima con dei convocati: null', () async {
      final ultima = await repository.ultimaDellaSquadra((
        partitaId: 'oggi',
        clubId: 'c1',
        gruppoId: 'u16',
        data: DateTime(2026, 10, 25),
      ));
      expect(ultima, isNull);
    });

    test('lo staff della squadra e quello cambiato per una partita', () async {
      await db
          .into(db.gruppiTable)
          .insert(
            GruppiTableCompanion.insert(id: 'u16', clubId: 'c1', nome: 'U16'),
          );
      final gruppi = GruppiRepository(client, db, SyncEngine(db, client));
      final partite = PartiteRepository(client, db, SyncEngine(db, client));
      const staff = StaffDistinta({
        RuoloStaff.tecnico: PersonaStaff(nome: 'Rossi', tessera: '167499'),
      });

      expect(await gruppi.staffDellaSquadra('u16'), StaffDistinta.vuoto);
      await gruppi.aggiornaStaffDellaSquadra('u16', staff);
      expect(await gruppi.staffDellaSquadra('u16'), staff);
      expect(await partite.staffDellaPartita('oggi'), isNull);

      final soloOggi = staff.con(
        RuoloStaff.medico,
        const PersonaStaff(nome: 'Bianchi'),
      );
      await partite.aggiornaStaffDellaPartita('oggi', soloOggi);
      expect(await partite.staffDellaPartita('oggi'), soloOggi);
      await partite.aggiornaStaffDellaPartita('oggi', null);
      expect(await partite.staffDellaPartita('oggi'), isNull);

      final ops = await coda();
      expect([for (final o in ops) o.$1], ['gruppi', 'partite', 'partite']);
      expect([for (final o in ops) o.$4], [
        {
          'staff_distinta': {
            'tecnico': {'nome': 'Rossi', 'tessera': '167499'},
          },
        },
        {'staff_distinta': soloOggi.toJson()},
        {'staff_distinta': null},
      ]);
    });
  });

  test('con la rete Riordina chiama la funzione del database e la coda '
      'resta vuota', () async {
    final chiamate = <http.Request>[];
    final client = _client(
      MockClient((r) async {
        chiamate.add(r);
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = DistintaRepository(client, db, SyncEngine(db, client));
    await convocato('r1', 'oggi', 'a', 2);

    await repository.rinumera('oggi', {'r1': 8});

    expect(chiamate.single.url.path, '/rest/v1/rpc/rinumera_distinta');
    expect(jsonDecode(chiamate.single.body), {
      'p_partita_id': 'oggi',
      'p_numeri': [
        {'id': 'r1', 'numero': 8},
      ],
    });
    expect(await numeri('oggi'), {'a': 8});
    expect(await coda(), isEmpty);
  });

  test('la coda rimanda una funzione del database quando torna la rete', () async {
    final offline = _senzaRete();
    addTearDown(offline.dispose);
    await DistintaRepository(
      offline,
      db,
      SyncEngine(db, offline),
    ).scegliCapitani('oggi', capitanoId: 'r1');
    expect(await coda(), hasLength(1));

    final chiamate = <http.Request>[];
    final online = _client(
      MockClient((r) async {
        chiamate.add(r);
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      }),
    );
    addTearDown(online.dispose);
    final rifiutate = [];
    await SyncEngine(db, online, suRifiuto: rifiutate.add).processQueue();
    expect(rifiutate, isEmpty);

    expect(chiamate.single.url.path, '/rest/v1/rpc/scegli_capitani');
    expect(jsonDecode(chiamate.single.body), {
      'p_partita_id': 'oggi',
      'p_capitano_id': 'r1',
      'p_vice_id': null,
    });
    expect(await coda(), isEmpty);
  });
}
