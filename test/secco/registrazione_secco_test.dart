import 'dart:async';
import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/application/carico_providers.dart';
import 'package:coach_vasca/features/carico/data/rpe_repository.dart';
import 'package:coach_vasca/features/carico/domain/rpe_seduta.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/data/serie_fatte_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';
import 'package:coach_vasca/features/secco/presentation/card_secco_da_fare.dart';
import 'package:coach_vasca/features/secco/presentation/registra_secco_screen.dart';
import 'package:coach_vasca/features/secco/presentation/registrazioni_seduta.dart';
import 'package:coach_vasca/features/secco/presentation/seduta_secco_atleta_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'serie_finte.dart';

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

const _riga = EsercizioSeduta(
  id: 'r1',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'face',
  ordine: 1,
  serie: 2,
  ripetizioni: 12,
  carico: 'elastico rosso',
  recuperoS: 30,
);

const _plank = EsercizioSeduta(
  id: 'r2',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'plank',
  ordine: 2,
  serie: 1,
  durataS: 20,
);

SerieFatta _fatta({
  String riga = 'r1',
  String seduta = 's1',
  String esercizio = 'face',
  String atleta = 'a1',
  int serie = 1,
  int? ripetizioni = 12,
  int? durataS,
  String? carico,
  String? previsto,
  DateTime? il,
  VotoSerie? voto,
}) => SerieFatta(
  id: '$atleta-$riga-$serie',
  atletaId: atleta,
  clubId: 'c1',
  allenamentoId: seduta,
  rigaId: riga,
  esercizioId: esercizio,
  serie: serie,
  ripetizioni: ripetizioni,
  durataS: durataS,
  carico: carico,
  caricoPrevisto: previsto,
  fattaIl: il ?? DateTime(2026, 10, 14, 18),
  voto: voto,
);

final _seduta = Allenamento(
  id: 's1',
  clubId: 'c1',
  data: DateTime(2026, 10, 14),
  titolo: 'Spalla del tiratore · settimana 2, seduta A',
  tipo: 'secco',
  durataMin: 15,
);

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Marco',
  cognome: 'Rossi',
  dataNascita: DateTime(2010, 3, 1),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

void main() {
  // Creato fuori dal tempo finto dei test dei widget: il suo timer di
  // rinnovo della sessione non resta in sospeso alla fine.
  late SupabaseClient clientFuoriDalTempoFinto;
  setUpAll(() => clientFuoriDalTempoFinto = _senzaRete());
  tearDownAll(() => clientFuoriDalTempoFinto.dispose());

  group('i conti della registrazione', () {
    test('la prossima serie, le serie contate e da dove ripartire', () {
      expect(prossimaSerie(_riga, const []), 1);
      expect(prossimaSerie(_riga, [_fatta()]), 2);
      expect(prossimaSerie(_riga, [_fatta(), _fatta(serie: 2)]), isNull);
      // La serie 2 senza la 1 (una tolta): si rifà la 1.
      expect(prossimaSerie(_riga, [_fatta(serie: 2)]), 1);

      final righe = [_riga, _plank];
      // Una serie in più (l'allenatore ne ha tolta una dopo) non conta.
      final conto = contaSerie(righe, [
        _fatta(),
        _fatta(serie: 2),
        _fatta(serie: 3),
      ]);
      expect((conto.fatte, conto.totali), (2, 3));
      expect(esercizioDaCuiPartire(righe, const []), 0);
      expect(esercizioDaCuiPartire(righe, [_fatta(), _fatta(serie: 2)]), 1);
      expect(
        esercizioDaCuiPartire(righe, [
          _fatta(),
          _fatta(serie: 2),
          _fatta(
            riga: 'r2',
            esercizio: 'plank',
            ripetizioni: null,
            durataS: 20,
          ),
        ]),
        0,
      );
    });

    test('il carico: la serie prima, se no l\'ultima volta se la prescrizione '
        'è la stessa, se no quella dell\'allenatore', () {
      // Prima volta: quello scritto.
      expect(
        caricoProposto(riga: _riga, fatteRiga: const [], precedenti: const []),
        'elastico rosso',
      );
      // La serie prima in questa seduta vince.
      expect(
        caricoProposto(
          riga: _riga,
          fatteRiga: [_fatta(carico: 'elastico verde')],
          precedenti: const [],
        ),
        'elastico verde',
      );
      // L'ultima volta, con la stessa prescrizione: il suo carico.
      final ultimaVolta = [
        _fatta(
          seduta: 's0',
          riga: 'r0',
          carico: 'elastico giallo',
          previsto: 'elastico rosso',
          il: DateTime(2026, 10, 1),
        ),
        _fatta(
          seduta: 's0',
          riga: 'r0',
          serie: 2,
          carico: 'elastico verde',
          previsto: 'Elastico rosso',
          il: DateTime(2026, 10, 1),
        ),
        // Un altro esercizio non conta.
        _fatta(
          seduta: 's0',
          riga: 'rx',
          esercizio: 'altro',
          carico: '10 kg',
          il: DateTime(2026, 10, 2),
        ),
      ];
      expect(
        caricoProposto(
          riga: _riga,
          fatteRiga: const [],
          precedenti: ultimaVolta,
        ),
        'elastico verde',
      );
      // L'allenatore l'ha cambiato da allora: il suo.
      expect(
        caricoProposto(
          riga: const EsercizioSeduta(
            id: 'r1',
            allenamentoId: 's1',
            clubId: 'c1',
            esercizioId: 'face',
            ordine: 1,
            carico: 'elastico più duro',
          ),
          fatteRiga: const [],
          precedenti: ultimaVolta,
        ),
        'elastico più duro',
      );
    });

    test('cosa ha fatto: uguali, diverse, con il carico che cambia', () {
      expect(descriviFatte(const [], aTempo: false), isNull);
      expect(
        descriviFatte([
          _fatta(serie: 2, carico: 'elastico rosso'),
          _fatta(carico: 'elastico rosso'),
        ], aTempo: false),
        '2 × 12, elastico rosso',
      );
      expect(
        descriviFatte([
          _fatta(ripetizioni: 13, carico: 'elastico rosso'),
          _fatta(serie: 2, ripetizioni: 10, carico: 'elastico verde'),
        ], aTempo: false),
        '13 + 10, elastico rosso → elastico verde',
      );
      expect(
        descriviFatte([
          _fatta(ripetizioni: null, durataS: 40),
          _fatta(serie: 2, ripetizioni: null, durataS: 40),
        ], aTempo: true),
        "2 × 40''",
      );
    });

    test('le sedute a secco da registrare nella home', () {
      final oggi = DateTime(2026, 10, 14, 9);
      Allenamento seduta(String id, int giorno, {String tipo = 'secco'}) =>
          Allenamento(
            id: id,
            clubId: 'c1',
            data: DateTime(2026, 10, giorno),
            tipo: tipo,
          );
      final sedute = seduteSeccoDaFare(
        allenamenti: [
          seduta('oggi', 14),
          seduta('acqua', 14, tipo: 'acqua'),
          seduta('domani', 15),
          seduta('ieri-cominciata', 13),
          seduta('ieri-mai', 13),
          seduta('vecchia', 10),
          seduta('finita', 14),
          seduta('assente', 14),
          seduta('prossima', 14),
        ],
        gruppoAtleta: null,
        assenti: {'assente'},
        finite: {'finita'},
        fatte: [
          _fatta(seduta: 'ieri-cominciata'),
          _fatta(seduta: 'vecchia'),
        ],
        prossimoId: 'prossima',
        oggi: oggi,
      );
      expect(
        [for (final s in sedute) (s.seduta.id, s.serieFatte)],
        [('oggi', 0), ('ieri-cominciata', 1)],
      );
    });
  });

  group('senza rete', () {
    late SupabaseClient client;
    late AppDatabase db;
    late SerieFatteRepository repository;

    setUp(() {
      client = _senzaRete();
      db = AppDatabase.perTest(NativeDatabase.memory());
      repository = SerieFatteRepository(client, db, SyncEngine(db, client));
    });
    tearDown(() async {
      await db.close();
      await client.dispose();
    });

    test('la serie resta sul telefono e parte dopo; rifatta tiene l\'id, '
        'tolta parte la cancellazione', () async {
      final prima = await repository.salva(
        _fatta(
          carico: 'elastico rosso',
          previsto: 'elastico rosso',
        ).copiaSenzaId(),
      );
      final rifatta = await repository.salva(
        _fatta(ripetizioni: 10, carico: 'elastico verde').copiaSenzaId(),
      );
      expect(rifatta.id, prima.id);
      final locali = await repository.watchPerAtleta('a1').first;
      expect(locali.single.ripetizioni, 10);
      expect(locali.single.carico, 'elastico verde');

      await repository.togli(rifatta);
      expect(await repository.watchPerSeduta('s1').first, isEmpty);

      final coda = await (db.select(
        db.pendingOperationsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(
        [for (final o in coda) o.operazione],
        ['upsert', 'upsert', 'delete'],
      );
      final payload =
          jsonDecode(coda.first.payloadJson!) as Map<String, dynamic>;
      expect(payload['riga_id'], 'r1');
      expect(payload['serie'], 1);
      expect(payload['carico_previsto'], 'elastico rosso');
      expect(coda.last.rigaId, prima.id);
    });

    test('la seduta dell\'atleta si apre dalla copia, e nella demo dalla '
        'cache dell\'allenatore senza le note', () async {
      final secco = SeccoRepository(client, db, SyncEngine(db, client));
      await db
          .into(db.seduteSeccoAtletaTable)
          .insert(
            SeduteSeccoAtletaTableCompanion.insert(
              allenamentoId: 's1',
              eserciziJson: jsonEncode([
                {
                  'id': 'r1',
                  'allenamento_id': 's1',
                  'esercizio_id': 'face',
                  'ordine': 1,
                  'nome': 'Face pull',
                  'categoria': 'scapole',
                  'misura': 'ripetizioni',
                  'serie': 3,
                  'ripetizioni': 12,
                },
              ]),
              lettaIl: DateTime(2026, 10, 13),
            ),
          );
      final dallaCopia = await secco.perAtleta('s1');
      expect(dallaCopia.single.esercizio.nome, 'Face pull');

      await db
          .into(db.eserciziSeccoTable)
          .insert(
            EserciziSeccoTableCompanion.insert(
              id: 'plank',
              clubId: 'c1',
              nome: 'Plank frontale',
              categoria: 'core',
              misura: const Value('tempo'),
            ),
          );
      await db
          .into(db.eserciziSedutaTable)
          .insert(
            EserciziSedutaTableCompanion.insert(
              id: 'r9',
              allenamentoId: 's2',
              clubId: 'c1',
              esercizioId: 'plank',
              ordine: 1,
              durataS: const Value(40),
              note: const Value('Rossi solo 20 secondi'),
            ),
          );
      final dallaCache = await secco.perAtleta('s2');
      expect(dallaCache.single.esercizio.nome, 'Plank frontale');
      expect(dallaCache.single.riga.durataS, 40);
      expect(dallaCache.single.riga.note, isNull);

      // Né copia né cache: l'errore di rete.
      await expectLater(secco.perAtleta('s3'), throwsA(isA<Exception>()));
    });
  });

  testWidgets('l\'atleta registra la seduta: serie, carico, recupero con il '
      'bip, l\'esercizio a tempo e quanto è stata dura', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = clientFuoriDalTempoFinto;
    final db = AppDatabase.perTest(NativeDatabase.memory());
    final sync = SyncEngine(db, client);
    final serie = SerieFatteRepository(client, db, sync);
    final rpe = RpeRepository(client, db, sync);
    var ora = DateTime(2026, 10, 14, 18);
    final bip = <bool>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serieFatteRepositoryProvider.overrideWithValue(serie),
          rpeRepositoryProvider.overrideWithValue(rpe),
          // Dal telefono, senza la lettura dal server (che senza rete
          // ritenta dopo qualche secondo).
          serieFatteAtletaProvider.overrideWith(
            (ref, id) => serie.watchPerAtleta(id),
          ),
          rpeAtletaProvider.overrideWith((ref, id) => rpe.watchPerAtleta(id)),
          seduteCaricoProvider.overrideWith((ref, chiave) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: _Apri(
            schermata: RegistraSeccoScreen(
              allenamento: _seduta,
              atleta: _atleta,
              esercizi: const [
                EsercizioSedutaAtleta(
                  esercizio: EsercizioSecco(
                    id: 'face',
                    clubId: '',
                    nome: 'Face pull',
                    categoria: CategoriaEsercizio.scapole,
                  ),
                  riga: _riga,
                ),
                EsercizioSedutaAtleta(
                  esercizio: EsercizioSecco(
                    id: 'plank',
                    clubId: '',
                    nome: 'Plank frontale',
                    categoria: CategoriaEsercizio.core,
                    misura: MisuraEsercizio.tempo,
                  ),
                  riga: _plank,
                ),
              ],
              adesso: () => ora,
              suona: ({bool lungo = false}) => bip.add(lungo),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    Future<void> avanti(int secondi) async {
      ora = ora.add(Duration(seconds: secondi));
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('Esercizio 1 di 2'), findsOneWidget);
    expect(find.text('0 serie su 3'), findsOneWidget);
    expect(find.text('Serie 1 di 2'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Carico: elastico rosso'), findsOneWidget);

    // Una in più, poi "Fatta": parte il recupero.
    await tester.tap(find.byTooltip('Una in più'));
    await tester.pump();
    expect(find.text('13'), findsOneWidget);
    await tester.tap(find.text('Fatta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Recupero'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('Poi: serie 2'), findsOneWidget);
    expect(find.text('Serie 1 di Face pull segnata'), findsOneWidget);

    // Gli ultimi tre secondi tre bip, alla fine uno lungo.
    await avanti(27);
    await avanti(1);
    await avanti(1);
    expect(bip, [false, false, false]);
    await avanti(1);
    expect(bip.last, isTrue);
    expect(find.text('Serie 2 di 2'), findsOneWidget);
    expect(find.text('1 serie su 3'), findsOneWidget);

    // Il carico della seconda serie: un altro elastico.
    await tester.tap(find.text('Carico: elastico rosso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'elastico verde');
    await tester.tap(find.text('Usa'));
    await tester.pumpAndSettle();
    expect(find.text('Carico: elastico verde'), findsOneWidget);
    await tester.tap(find.text('Fatta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Finito il face pull si passa al plank, con il recupero in corso.
    expect(find.text('Esercizio 2 di 2'), findsOneWidget);
    expect(find.text('Recupero'), findsOneWidget);
    await tester.tap(find.text('Salta il recupero'));
    await tester.pump();
    expect(find.text("20''"), findsOneWidget);

    // A tempo: "Via", tre secondi per mettersi in posizione, poi il
    // telefono conta e la segna da solo.
    bip.clear();
    await tester.tap(find.text('Via'));
    await tester.pump();
    expect(find.text('Pronti'), findsOneWidget);
    await avanti(3);
    expect(find.text('Tieni'), findsOneWidget);
    expect(find.text('0:20'), findsOneWidget);
    await avanti(20);
    await tester.pumpAndSettle();

    expect(find.text('Seduta finita'), findsOneWidget);
    expect(find.text('3 serie su 3'), findsOneWidget);
    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();

    final salvate = await (db.select(
      db.serieSeccoFatteTable,
    )..orderBy([(t) => OrderingTerm.asc(t.fattaIl)])).get();
    expect(
      [
        for (final s in salvate)
          (s.rigaId, s.serie, s.ripetizioni, s.durataS, s.carico),
      ],
      [
        ('r1', 1, 13, null, 'elastico rosso'),
        ('r1', 2, 12, null, 'elastico verde'),
        ('r2', 1, null, 20, null),
      ],
    );
    expect(salvate.first.caricoPrevisto, 'elastico rosso');
    final risposta = await db.select(db.rpeSeduteTable).getSingle();
    expect((risposta.eventoId, risposta.rpe), ('s1', 6));

    // "Fatto" chiude la schermata.
    await tester.tap(find.text('Fatto'));
    await tester.pumpAndSettle();
    expect(find.text('Apri'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    // Drift chiude con i timer del tempo finto: si fa scorrere.
    var chiuso = false;
    unawaited(db.close().then((_) => chiuso = true));
    for (var i = 0; i < 50 && !chiuso; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(chiuso, isTrue);
  });

  testWidgets('nella seduta dell\'atleta "Continua la seduta" e le serie '
      'fatte di ogni esercizio', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eserciziSedutaAtletaProvider.overrideWith(
            (ref, id) async => const [
              EsercizioSedutaAtleta(
                esercizio: EsercizioSecco(
                  id: 'face',
                  clubId: '',
                  nome: 'Face pull',
                  categoria: CategoriaEsercizio.scapole,
                ),
                riga: _riga,
              ),
              EsercizioSedutaAtleta(
                esercizio: EsercizioSecco(
                  id: 'plank',
                  clubId: '',
                  nome: 'Plank frontale',
                  categoria: CategoriaEsercizio.core,
                  misura: MisuraEsercizio.tempo,
                ),
                riga: _plank,
              ),
            ],
          ),
          serieFatteAtletaProvider.overrideWith(
            (ref, id) => Stream.value([
              _fatta(),
              // Di un'altra seduta: qui non conta.
              _fatta(seduta: 's0', riga: 'r0'),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          // L'acqua animata della testata, ferma.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SedutaSeccoAtletaScreen(allenamento: _seduta, atleta: _atleta),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continua la seduta'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('l\'allenatore vede chi l\'ha registrata e cosa ha fatto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serieFatteSedutaProvider.overrideWith(
            (ref, id) => Stream.value([
              _fatta(ripetizioni: 13, carico: 'elastico rosso'),
              _fatta(serie: 2, carico: 'elastico verde'),
            ]),
          ),
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([_atleta]),
          ),
          rpeClubProvider.overrideWith(
            (ref, clubId) => Stream.value([
              RpeSeduta(
                id: 'x',
                atletaId: 'a1',
                clubId: 'c1',
                eventoTipo: 'allenamento',
                eventoId: 's1',
                data: DateTime(2026, 10, 14),
                rpe: 6,
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: Scaffold(
            body: ListView(
              children: [
                RegistrazioniSeduta(
                  allenamento: _seduta,
                  righe: const [_riga, _plank],
                  esercizi: const {
                    'face': EsercizioSecco(
                      id: 'face',
                      clubId: 'c1',
                      nome: 'Face pull',
                      categoria: CategoriaEsercizio.scapole,
                    ),
                    'plank': EsercizioSecco(
                      id: 'plank',
                      clubId: 'c1',
                      nome: 'Plank frontale',
                      categoria: CategoriaEsercizio.core,
                      misura: MisuraEsercizio.tempo,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registrata dagli atleti'), findsOneWidget);
    expect(find.text('Rossi Marco'), findsOneWidget);
    expect(find.text('2 serie su 3 · RPE 6'), findsOneWidget);
    await tester.tap(find.text('Rossi Marco'));
    await tester.pumpAndSettle();
    expect(
      find.text('13 + 12, elastico rosso → elastico verde'),
      findsOneWidget,
    );
    expect(find.text('Non fatto'), findsOneWidget);
    expect(
      find.text("Previsto: 2 × 12, elastico rosso · recupero 30''"),
      findsOneWidget,
    );
  });

  group('il voto della serie', () {
    const face = EsercizioSedutaAtleta(
      esercizio: EsercizioSecco(
        id: 'face',
        clubId: '',
        nome: 'Face pull',
        categoria: CategoriaEsercizio.scapole,
      ),
      riga: _riga,
    );
    const plank = EsercizioSedutaAtleta(
      esercizio: EsercizioSecco(
        id: 'plank',
        clubId: '',
        nome: 'Plank frontale',
        categoria: CategoriaEsercizio.core,
        misura: MisuraEsercizio.tempo,
      ),
      riga: _plank,
    );
    // Tre serie da 10, senza recupero.
    const senzaRecupero = EsercizioSedutaAtleta(
      esercizio: EsercizioSecco(
        id: 'squat',
        clubId: '',
        nome: 'Squat a corpo libero',
        categoria: CategoriaEsercizio.gambe,
      ),
      riga: EsercizioSeduta(
        id: 'r3',
        allenamentoId: 's1',
        clubId: 'c1',
        esercizioId: 'squat',
        ordine: 1,
        ripetizioni: 10,
      ),
    );
    // Una sola serie, senza recupero: finita lei, finisce la seduta.
    const unaSola = EsercizioSedutaAtleta(
      esercizio: EsercizioSecco(
        id: 'squat',
        clubId: '',
        nome: 'Squat a corpo libero',
        categoria: CategoriaEsercizio.gambe,
      ),
      riga: EsercizioSeduta(
        id: 'r4',
        allenamentoId: 's1',
        clubId: 'c1',
        esercizioId: 'squat',
        ordine: 1,
        serie: 1,
        ripetizioni: 10,
      ),
    );

    Widget app(
      SerieFinte serie,
      List<EsercizioSedutaAtleta> esercizi, {
      bool daTablet = false,
      ThemeData? tema,
      double testo = 1,
    }) => ProviderScope(
      overrides: [
        serieFatteRepositoryProvider.overrideWithValue(serie),
        serieFatteAtletaProvider.overrideWith(
          (ref, id) => serie.watchPerAtleta(id),
        ),
        rpeAtletaProvider.overrideWith((ref, id) => Stream.value(const [])),
        seduteCaricoProvider.overrideWith((ref, chiave) async => const []),
      ],
      child: MaterialApp(
        theme: tema ?? AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(testo)),
          child: child!,
        ),
        home: _Apri(
          schermata: RegistraSeccoScreen(
            allenamento: _seduta,
            atleta: _atleta,
            esercizi: esercizi,
            adesso: () => DateTime(2026, 10, 14, 18),
            suona: ({bool lungo = false}) {},
            daTablet: daTablet,
          ),
        ),
      ),
    );

    Future<void> apri(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
    }

    /// Chiude la schermata prima che i provider spariscano (la barra del
    /// club si rimette a posto alla chiusura).
    Future<void> chiudi(WidgetTester tester) async {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .popUntil((r) => r.isFirst);
      await tester.pumpAndSettle();
    }

    Color? colore(WidgetTester tester, VotoSerie v) => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byKey(ValueKey('voto-${v.name}')),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    testWidgets('«Dura» durante il recupero salva il voto; ancora «Dura» lo '
        'toglie; «Facile» lo cambia', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final serie = SerieFinte();
      await tester.pumpWidget(app(serie, [face]));
      await apri(tester);

      // Prima di segnare una serie non c'è niente da votare.
      expect(find.text('Dura'), findsNothing);
      await tester.tap(find.text('Fatta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Recupero'), findsOneWidget);
      expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('Giusta'), findsOneWidget);
      expect(find.text('Dura'), findsOneWidget);
      expect(serie.salvate, hasLength(1));
      expect(serie.salvate.single.voto, isNull);
      final neutro = colore(tester, VotoSerie.facile);
      expect(colore(tester, VotoSerie.dura), neutro);

      await tester.tap(find.text('Dura'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(serie.salvate, hasLength(2));
      expect(serie.salvate.last.voto, VotoSerie.dura);
      expect(serie.salvate.last.serie, 1);
      // Si vede subito: «Dura» evidenziato, gli altri no.
      expect(colore(tester, VotoSerie.dura), isNot(neutro));
      expect(colore(tester, VotoSerie.facile), neutro);

      await tester.tap(find.text('Dura'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(serie.salvate, hasLength(3));
      expect(serie.salvate.last.voto, isNull);
      expect(colore(tester, VotoSerie.dura), neutro);

      await tester.tap(find.text('Facile'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(serie.salvate.last.voto, VotoSerie.facile);
      // Il voto è nella serie che vede anche l'allenatore.
      expect(serie.serie.single.voto, VotoSerie.facile);
      // E non ha bloccato niente: si salta il recupero e si va avanti.
      await tester.tap(find.text('Salta il recupero'));
      await tester.pump();
      expect(find.text('Serie 2 di 2'), findsOneWidget);
      expect(find.text('Dura'), findsNothing);
      await chiudi(tester);
    });

    testWidgets('senza recupero il voto resta finché non segni la serie '
        'dopo, che ha il suo', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final serie = SerieFinte();
      await tester.pumpWidget(app(serie, [senzaRecupero]));
      await apri(tester);

      await tester.tap(find.text('Fatta'));
      await tester.pump();
      expect(find.text('Serie 2 di 3'), findsOneWidget);
      expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
      await tester.tap(find.text('Giusta'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(serie.salvate.last.voto, VotoSerie.giusta);

      await tester.tap(find.text('Fatta'));
      await tester.pump();
      expect(find.text('Com\'è andata la serie 2?'), findsOneWidget);
      // La seconda serie non ha ancora il voto.
      expect(
        colore(tester, VotoSerie.giusta),
        colore(tester, VotoSerie.facile),
      );
      expect(
        [for (final s in serie.serie) (s.serie, s.voto)],
        [(1, VotoSerie.giusta), (2, null)],
      );
      await chiudi(tester);
    });

    testWidgets('alla fine, sopra «Quanto è stata dura?», e resta dopo '
        'averlo dato', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final serie = SerieFinte();
      await tester.pumpWidget(app(serie, [unaSola]));
      await apri(tester);

      await tester.tap(find.text('Fatta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Seduta finita'), findsOneWidget);
      expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Com\'è andata la serie 1?')).dy,
        lessThan(tester.getTopLeft(find.text('Quanto è stata dura?')).dy),
      );

      await tester.tap(find.text('Dura'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(serie.salvate.last.voto, VotoSerie.dura);
      // Resta, con la scelta in vista: si può cambiare.
      expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
      expect(
        colore(tester, VotoSerie.dura),
        isNot(colore(tester, VotoSerie.facile)),
      );
      await chiudi(tester);
    });

    testWidgets('«L\'ultima volta» dice com\'è andata, se ci sono voti', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ieri = DateTime(2026, 10, 7, 18);
      final serie = SerieFinte([
        // L'altra volta il face pull: due serie facili.
        _fatta(seduta: 's0', riga: 'r0', il: ieri, voto: VotoSerie.facile),
        _fatta(
          seduta: 's0',
          riga: 'r0',
          serie: 2,
          il: ieri,
          voto: VotoSerie.facile,
        ),
        // Il plank senza voti: niente da dire.
        _fatta(
          seduta: 's0',
          riga: 'r9',
          esercizio: 'plank',
          ripetizioni: null,
          durataS: 20,
          il: ieri,
        ),
      ]);
      await tester.pumpWidget(app(serie, [face, plank]));
      await apri(tester);

      expect(find.text('L\'ultima volta: tutte facili'), findsOneWidget);
      // Il carico proposto non cambia da solo.
      expect(find.text('Carico: elastico rosso'), findsOneWidget);

      // Il plank: nessun voto l'altra volta, nessuna riga.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esercizio successivo'));
      await tester.pumpAndSettle();
      expect(find.text('Plank frontale'), findsOneWidget);
      expect(find.textContaining('L\'ultima volta'), findsNothing);
      await chiudi(tester);
    });

    for (final (nome, tema) in [
      ('chiaro', AppTheme.chiaro),
      ('scuro', AppTheme.scuro),
    ]) {
      testWidgets('dal tablet: il nome in alto e il voto stanno a 360 con il '
          'testo grande, tema $nome', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final serie = SerieFinte();
        await tester.pumpWidget(
          app(serie, [face, plank], daTablet: true, tema: tema, testo: 1.3),
        );
        await apri(tester);
        expect(find.text('Rossi Marco'), findsOneWidget);
        expect(find.text('Esercizio 1 di 2'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Fatta'));
        await tester.pump();
        // L'avviso «Serie segnata» sparisce da solo dopo 4 secondi.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
        await tester.tap(find.text('Facile'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(serie.salvate.last.voto, VotoSerie.facile);
        expect(tester.takeException(), isNull);
        // Tolto: la serie resta senza voto, e alla fine si chiede.
        await tester.tap(find.text('Facile'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(serie.salvate.last.voto, isNull);

        // La fine: il nome torna «Seduta a secco», il voto è sopra l'RPE.
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Finisci la seduta'));
        await tester.pumpAndSettle();
        expect(find.text('Seduta finita'), findsOneWidget);
        expect(find.text('Rossi Marco'), findsOneWidget);
        expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await chiudi(tester);
      });
    }
  });
}

extension on SerieFatta {
  /// Come la crea la schermata: senza id, lo sceglie il repository.
  SerieFatta copiaSenzaId() => SerieFatta(
    id: '',
    atletaId: atletaId,
    clubId: clubId,
    allenamentoId: allenamentoId,
    rigaId: rigaId,
    esercizioId: esercizioId,
    serie: serie,
    ripetizioni: ripetizioni,
    durataS: durataS,
    carico: carico,
    caricoPrevisto: caricoPrevisto,
    fattaIl: fattaIl,
  );
}

/// Un pulsante che apre la schermata, come la seduta dell'atleta.
class _Apri extends StatelessWidget {
  const _Apri({required this.schermata});

  final Widget schermata;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => schermata)),
      child: const Text('Apri'),
    ),
  );
}
