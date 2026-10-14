import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/data/serie_fatte_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';
import 'package:coach_vasca/features/secco/presentation/chili_di_ognuno.dart';
import 'package:coach_vasca/features/secco/presentation/registra_secco_screen.dart';
import 'package:coach_vasca/features/secco/presentation/seduta_secco_atleta_screen.dart';
import 'package:coach_vasca/features/test/application/test_club_providers.dart';
import 'package:coach_vasca/features/test/data/test_club_repository.dart';
import 'package:coach_vasca/features/test/domain/massimale.dart';
import 'package:coach_vasca/features/test/domain/tastierino_test.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/presentation/test_club_form_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

const _squat = EsercizioSeduta(
  id: 'r1',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'squat',
  ordine: 1,
  serie: 4,
  ripetizioni: 6,
  carico: '70%',
  recuperoS: 120,
);

const _test = TestClub.massimale(
  id: 'm1',
  clubId: 'c1',
  nome: 'Massimale squat',
  esercizioId: 'squat',
);

RisultatoTest _risultato(
  String atleta,
  DateTime data,
  double kg,
  int rip, {
  String test = 'm1',
}) => RisultatoTest(
  id: '$atleta-$data',
  testId: test,
  atletaId: atleta,
  clubId: 'c1',
  data: data,
  valori: [stimaMassimale(kg, rip)],
  caricoKg: kg,
  ripetizioni: rip,
);

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Luca',
  cognome: cognome,
  dataNascita: DateTime(2009, 5, 1),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'g1',
);

final _seduta = Allenamento(
  id: 's1',
  clubId: 'c1',
  data: DateTime(2026, 10, 14),
  titolo: 'Forza',
  tipo: 'secco',
  durataMin: 45,
  gruppoId: 'g1',
);

const _esercizioSquat = EsercizioSecco(
  id: 'squat',
  clubId: 'c1',
  nome: 'Squat con bilanciere',
  categoria: CategoriaEsercizio.forza,
);

/// Le serie salvate dalla schermata, senza rete né database.
class _SerieFinte implements SerieFatteRepository {
  final salvate = <SerieFatta>[];

  @override
  Future<SerieFatta> salva(SerieFatta f) async {
    salvate.add(f);
    return f;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// I test creati dal modulo.
class _TestFinti implements TestClubRepository {
  final creati = <TestClub>[];

  @override
  Future<TestClub> creaTest(TestClub test) async {
    creati.add(test);
    return test;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('i conti dei massimali', () {
    test('la stima da chili × ripetizioni, mai sotto i chili sollevati', () {
      expect(stimaMassimale(40, 5), 45);
      // Con una ripetizione è quello provato.
      expect(stimaMassimale(62.5, 1), 62.5);
      expect(stimaMassimale(100, 10), 133.5);
      // Oltre le 10 ripetizioni si conta come 10.
      expect(stimaMassimale(100, 12), 133.5);
      // Al mezzo chilo, ma mai meno di quanto sollevato.
      expect(stimaMassimale(5.1, 2), 5.1);
    });

    test('la percentuale scritta come carico', () {
      expect(percentualeDelCarico('70%'), 70);
      expect(percentualeDelCarico(' 70 % '), 70);
      expect(percentualeDelCarico('72,5%'), 72.5);
      expect(percentualeDelCarico('70% del massimale'), 70);
      expect(percentualeDelCarico('80% 1RM'), 80);
      expect(percentualeDelCarico('8 kg'), isNull);
      expect(percentualeDelCarico('elastico rosso'), isNull);
      expect(percentualeDelCarico('0%'), isNull);
      expect(percentualeDelCarico('150%'), isNull);
      expect(percentualeDelCarico(null), isNull);
    });

    test('i chili di ognuno, al chilo, e la prescrizione dell\'atleta', () {
      expect(chiliDaPercentuale(70, 45), 32);
      expect(chiliDaPercentuale(70, 80), 56);
      expect(caricoPerAtleta('70%', 80), '56 kg (70%)');
      expect(caricoPerAtleta('70%', null), '70%');
      expect(caricoPerAtleta('8 kg', 80), '8 kg');
      expect(
        prescrizioneEsercizio(_squat, massimale: 80),
        "4 × 6, 56 kg (70%) · recupero 2'",
      );
      expect(prescrizioneEsercizio(_squat), "4 × 6, 70% · recupero 2'");
    });

    test('il massimale di ognuno è l\'ultimo, solo dei test di massimale', () {
      const sprint = TestClub(
        id: 't1',
        clubId: 'c1',
        nome: 'Sprint',
        unita: UnitaTest.secondi,
        piuBassoMeglio: true,
      );
      final massimali = massimaliPerEsercizio(
        [_test, sprint],
        [
          _risultato('a1', DateTime(2026, 9, 1), 60, 5),
          _risultato('a1', DateTime(2026, 10, 1), 64, 5),
          _risultato('a2', DateTime(2026, 9, 15), 50, 1),
          RisultatoTest(
            id: 'x',
            testId: 't1',
            atletaId: 'a1',
            clubId: 'c1',
            data: DateTime(2026, 10, 2),
            valori: const [8.6],
          ),
        ],
      );
      expect(massimali.keys, ['squat']);
      expect(massimali['squat']!['a1']!.kg, 72);
      expect(massimali['squat']!['a1']!.ripetizioni, 5);
      expect(massimali['squat']!['a2']!.kg, 50);
    });

    test('il carico proposto: dal massimale di adesso, poi la serie prima', () {
      final ultimaVolta = SerieFatta(
        id: 'p',
        atletaId: 'a1',
        clubId: 'c1',
        allenamentoId: 's0',
        rigaId: 'r0',
        esercizioId: 'squat',
        serie: 4,
        ripetizioni: 6,
        carico: '50 kg',
        caricoPrevisto: '70%',
        fattaIl: DateTime(2026, 10, 7),
      );
      // Con il massimale: i suoi chili, non quelli dell'ultima volta.
      expect(
        caricoProposto(
          riga: _squat,
          fatteRiga: const [],
          precedenti: [ultimaVolta],
          massimale: 80,
        ),
        '56 kg',
      );
      // Senza: come prima, l'ultima volta con la stessa prescrizione.
      expect(
        caricoProposto(
          riga: _squat,
          fatteRiga: const [],
          precedenti: [ultimaVolta],
        ),
        '50 kg',
      );
      // Dopo la prima serie, quella.
      expect(
        caricoProposto(
          riga: _squat,
          fatteRiga: [
            SerieFatta(
              id: 'q',
              atletaId: 'a1',
              clubId: 'c1',
              allenamentoId: 's1',
              rigaId: 'r1',
              esercizioId: 'squat',
              serie: 1,
              ripetizioni: 6,
              carico: '55 kg',
              caricoPrevisto: '70%',
              fattaIl: DateTime(2026, 10, 14),
            ),
          ],
          precedenti: const [],
          massimale: 80,
        ),
        '55 kg',
      );
    });

    test('i campi a raffica di un massimale e la classifica in CSV', () {
      expect(campiPerAtleta(_test), 2);
      expect(unitaDelCampo(_test, 0), UnitaTest.chili);
      expect(unitaDelCampo(_test, 1), UnitaTest.ripetizioni);
      expect(valoreDelCampo(_test, 0, '42,5'), 42.5);
      expect(valoreDelCampo(_test, 1, '5'), 5);
      expect(valoreDelCampo(_test, 1, '11'), isNull);
      expect(_test.comeSiLegge, 'Chili × ripetizioni');

      final posti = classifica(
        _test,
        [_risultato('a1', DateTime(2026, 10, 1), 40, 5)],
        [_atleta('a1', 'Rossi')],
      );
      final righe = csvClassifica(_test, posti).split('\r\n');
      expect(
        righe.first,
        'Posizione;Atleta;Anno di nascita;Data;Massimale squat (kg);'
        'Chili sollevati;Ripetizioni',
      );
      expect(righe.last, '1;Rossi Luca;2009;01/10/2026;45;40;5');
    });
  });

  test('senza rete: il massimale pronto con il suo esercizio, il risultato '
      'con chili e ripetizioni, e l\'esercizio non si elimina più', () async {
    final client = _senzaRete();
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await client.dispose();
    });
    final sync = SyncEngine(db, client);
    final secco = SeccoRepository(client, db, sync);
    final test = TestClubRepository(client, db, sync);

    final modello = modelliMassimali.first;
    final esercizio = await secco.esercizioPronto(
      'c1',
      modelliEsercizi.firstWhere((m) => m.chiave == modello.esercizio),
    );
    expect(esercizio.nome, 'Squat con bilanciere');
    // Chiesto di nuovo, è lo stesso.
    expect(
      (await secco.esercizioPronto(
        'c1',
        modelliEsercizi.firstWhere((m) => m.chiave == modello.esercizio),
      )).id,
      esercizio.id,
    );
    expect(await secco.inUso(esercizio.id), isFalse);

    final massimale = await test.creaTest(
      TestClub.massimale(
        id: '',
        clubId: 'c1',
        nome: modello.nome,
        esercizioId: esercizio.id,
        modello: modello.chiave,
      ),
    );
    expect(massimale.massimale, isTrue);
    expect(massimale.unita, UnitaTest.chili);
    expect(massimale.piuBassoMeglio, isFalse);
    expect(await secco.inUso(esercizio.id), isTrue);

    await test.salvaRisultato(
      testId: massimale.id,
      atletaId: 'a1',
      clubId: 'c1',
      data: DateTime(2026, 10, 14),
      valori: [stimaMassimale(40, 5)],
      caricoKg: 40,
      ripetizioni: 5,
    );
    final risultato = (await test.watchRisultati('c1').first).single;
    expect(risultato.valori, [45]);
    expect((risultato.caricoKg, risultato.ripetizioni), (40.0, 5));
    final coda = await db.select(db.pendingOperationsTable).get();
    final upsert = coda.where((o) => o.tabella == 'test_risultati').single;
    expect(upsert.payloadJson, contains('"carico_kg":40'));
    expect(upsert.payloadJson, contains('"ripetizioni":5'));
    expect(
      coda.where((o) => o.tabella == 'test_club').single.payloadJson,
      contains('"esercizio_id":"${esercizio.id}"'),
    );
  });

  testWidgets('l\'atleta vede i suoi chili al posto del 70% e li registra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final serie = _SerieFinte();
    const esercizi = [
      EsercizioSedutaAtleta(esercizio: _esercizioSquat, riga: _squat),
    ];
    final atleta = _atleta('a1', 'Rossi');
    final scope = ProviderScope(
      overrides: [
        eserciziSedutaAtletaProvider.overrideWith((ref, id) async => esercizi),
        serieFatteAtletaProvider.overrideWith(
          (ref, id) => Stream.value(const []),
        ),
        serieFatteRepositoryProvider.overrideWithValue(serie),
        massimaliProvider.overrideWith(
          (ref, clubId) => {
            'squat': {
              'a1': Massimale(
                kg: 80,
                data: DateTime(2026, 10, 1),
                caricoKg: 70,
                ripetizioni: 5,
              ),
            },
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SedutaSeccoAtletaScreen(allenamento: _seduta, atleta: atleta),
      ),
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();
    expect(find.text("4 × 6, 56 kg (70%) · recupero 2'"), findsOneWidget);

    await tester.tap(find.text('Comincia la seduta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegistraSeccoScreen), findsOneWidget);
    expect(find.text('Carico: 56 kg'), findsOneWidget);

    // Nel foglio del carico: cosa ha scritto l'allenatore e la proposta.
    await tester.tap(find.text('Carico: 56 kg'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "L'allenatore ha scritto: 70%, con il tuo massimale di 80 kg sono "
        '56 kg',
      ),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fatta'));
    await tester.pump();
    final salvata = serie.salvate.single;
    expect((salvata.carico, salvata.caricoPrevisto), ('56 kg', '70%'));

    // Si torna indietro dentro lo stesso ProviderScope.
    await tester.tap(find.text('Salta il recupero'));
    await tester.pump();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('l\'allenatore vede i chili di ognuno', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([
              _atleta('a1', 'Rossi'),
              _atleta('a2', 'Bianchi'),
            ]),
          ),
          massimaliProvider.overrideWith(
            (ref, clubId) => {
              'squat': {'a1': Massimale(kg: 80, data: DateTime(2026, 10, 1))},
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: Scaffold(
            body: ListView(
              children: [
                ChiliDiOgnuno(
                  allenamento: _seduta,
                  righe: const [_squat],
                  esercizi: const {'squat': _esercizioSquat},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chili di ognuno'), findsOneWidget);
    expect(find.text('4 × 6 al 70% · 1 di 2 con il massimale'), findsOneWidget);
    await tester.tap(find.text('Squat con bilanciere'));
    await tester.pumpAndSettle();
    expect(find.text('4 × 6 al 70% del massimale'), findsOneWidget);
    expect(find.text('56 kg'), findsOneWidget);
    expect(find.text('Nessun massimale'), findsOneWidget);
  });

  testWidgets('nuovo test: un massimale con il suo esercizio e il nome '
      'proposto', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _TestFinti();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          testClubRepositoryProvider.overrideWithValue(repository),
          eserciziSeccoProvider.overrideWith(
            (ref, clubId) => Stream.value(const [
              _esercizioSquat,
              // Già con il suo massimale: non si sceglie.
              EsercizioSecco(
                id: 'panca',
                clubId: 'c1',
                nome: 'Panca piana',
                categoria: CategoriaEsercizio.forza,
              ),
              // A tempo: non ha un massimale.
              EsercizioSecco(
                id: 'plank',
                clubId: 'c1',
                nome: 'Plank',
                categoria: CategoriaEsercizio.core,
                misura: MisuraEsercizio.tempo,
              ),
            ]),
          ),
          testClubProvider.overrideWith(
            (ref, clubId) => Stream.value(const [
              TestClub.massimale(
                id: 'm2',
                clubId: 'c1',
                nome: 'Massimale panca',
                esercizioId: 'panca',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: const TestClubFormScreen(clubId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Un massimale'));
    await tester.pumpAndSettle();

    // Senza esercizio non si salva.
    await tester.tap(find.text('Salva test'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli l\'esercizio'), findsWidgets);
    expect(repository.creati, isEmpty);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Panca piana'), findsNothing);
    expect(find.text('Plank'), findsNothing);
    await tester.tap(find.text('Squat con bilanciere').last);
    await tester.pumpAndSettle();
    expect(find.text('Massimale squat con bilanciere'), findsOneWidget);

    await tester.tap(find.text('Salva test'));
    await tester.pumpAndSettle();
    final creato = repository.creati.single;
    expect(creato.massimale, isTrue);
    expect(creato.esercizioId, 'squat');
    expect(creato.nome, 'Massimale squat con bilanciere');
    expect(creato.unita, UnitaTest.chili);
    expect(creato.descrizione, comeSiFaMassimale);
  });

  testWidgets('senza carichi in percentuale non c\'è niente', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChiliDiOgnuno(
              allenamento: _seduta,
              righe: const [
                EsercizioSeduta(
                  id: 'r2',
                  allenamentoId: 's1',
                  clubId: 'c1',
                  esercizioId: 'face',
                  ordine: 1,
                  carico: 'elastico rosso',
                ),
              ],
              esercizi: const {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Chili di ognuno'), findsNothing);
  });
}
