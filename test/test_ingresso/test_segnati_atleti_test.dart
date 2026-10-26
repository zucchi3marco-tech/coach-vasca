import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/test/data/test_club_repository.dart';
import 'package:coach_vasca/features/test/domain/massimale.dart';
import 'package:coach_vasca/features/test/domain/tastierino_test.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/presentation/segna_risultato_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
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

/// Registra i salvataggi; con [errore] li rifiuta.
class _RepositoryFinto implements TestClubRepository {
  final salvati = <String>[];
  Object? errore;

  @override
  Future<void> salvaRisultato({
    required String testId,
    required String atletaId,
    required String clubId,
    required DateTime data,
    required List<double> valori,
    String? note,
    double? caricoKg,
    int? ripetizioni,
    bool comeAtleta = false,
  }) async {
    if (errore case final e?) throw e;
    salvati.add(
      '$testId $atletaId $valori kg:$caricoKg rip:$ripetizioni '
      'atleta:$comeAtleta',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

const _sprint = TestClub(
  id: 't1',
  clubId: 'c1',
  nome: 'Sprint 15 m',
  unita: UnitaTest.secondi,
  piuBassoMeglio: true,
  prove: 2,
  apertoAtleti: true,
);

const _squat = TestClub.massimale(
  id: 't2',
  clubId: 'c1',
  nome: 'Massimale squat',
  esercizioId: 'squat',
  apertoAtleti: true,
);

Future<void> _apri(
  WidgetTester tester,
  _RepositoryFinto repository,
  TestClub test,
) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [testClubRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: SegnaRisultatoScreen(test: test, atleta: _atleta),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('i valori scritti a mano: tempi con la virgola o i minuti', () {
    expect(valoreScritto(UnitaTest.secondi, '8,62'), 8.62);
    expect(valoreScritto(UnitaTest.secondi, '8.62'), 8.62);
    expect(valoreScritto(UnitaTest.secondi, '45'), 45);
    expect(valoreScritto(UnitaTest.secondi, '1:05,20'), closeTo(65.2, 1e-9));
    expect(valoreScritto(UnitaTest.secondi, '1:65'), isNull);
    expect(valoreScritto(UnitaTest.secondi, '0'), isNull);
    expect(valoreScritto(UnitaTest.centimetri, '52'), 52);
    expect(valoreScritto(UnitaTest.kmh, '58,4'), 58.4);
    expect(valoreScritto(UnitaTest.punti, '7'), 7);
    expect(valoreScritto(UnitaTest.punti, '7,5'), isNull);
    expect(valoreScritto(UnitaTest.metri, ''), isNull);
    // Massimale: ripetizioni da 1 a 10, chili fino a 500.
    expect(valoreDelCampoScritto(_squat, 1, '12'), isNull);
    expect(valoreDelCampoScritto(_squat, 0, '52,5'), 52.5);
  });

  testWidgets('l\'atleta scrive le sue prove: si salva come atleta', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, _sprint);

    await tester.enterText(find.byType(TextFormField).at(1), '8,62');
    await tester.enterText(find.byType(TextFormField).at(2), '8,9');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(repository.salvati, [
      't1 a1 [8.62, 8.9] kg:null rip:null atleta:true',
    ]);
  });

  testWidgets('un massimale: chili e ripetizioni, l\'app stima il resto', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository, _squat);

    await tester.enterText(find.byType(TextFormField).at(1), '50');
    await tester.enterText(find.byType(TextFormField).at(2), '12');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    // Oltre 10 ripetizioni non si salva.
    expect(find.text('Non va bene'), findsOneWidget);
    expect(repository.salvati, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(2), '5');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(repository.salvati, [
      't2 a1 [${stimaMassimale(50, 5)}] kg:50.0 rip:5 atleta:true',
    ]);
  });

  testWidgets('se l\'allenatore l\'ha già scritto, l\'atleta lo legge', (
    tester,
  ) async {
    final repository = _RepositoryFinto()
      ..errore = const RisultatoDellAllenatore();
    await _apri(tester, repository, _sprint);
    await tester.enterText(find.byType(TextFormField).at(1), '8,62');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('già il risultato scritto dall\'allenatore'),
      findsOneWidget,
    );
  });

  group('il repository', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.perTest(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('l\'atleta non sovrascrive il risultato dell\'allenatore dello '
        'stesso giorno, il suo sì (anche senza rete)', () async {
      final client = _senzaRete();
      final repository = TestClubRepository(client, db, SyncEngine(db, client));
      final giorno = DateTime(2026, 10, 26);
      await db
          .into(db.testRisultatiTable)
          .insert(
            TestRisultatiTableCompanion.insert(
              id: 'r1',
              testId: 't1',
              atletaId: 'a1',
              clubId: 'c1',
              data: giorno,
              valoriJson: '[8.5]',
            ),
          );

      await expectLater(
        repository.salvaRisultato(
          testId: 't1',
          atletaId: 'a1',
          clubId: 'c1',
          data: giorno,
          valori: const [8.2],
          comeAtleta: true,
        ),
        throwsA(isA<RisultatoDellAllenatore>()),
      );

      // Un altro giorno: si salva sul telefono, segnato dall'atleta.
      await repository.salvaRisultato(
        testId: 't1',
        atletaId: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 27),
        valori: const [8.2],
        comeAtleta: true,
      );
      final suo = await (db.select(
        db.testRisultatiTable,
      )..where((t) => t.id.isNotValue('r1'))).getSingle();
      expect(suo.dallAtleta, isTrue);

      // E lo può correggere.
      await (db.update(db.testRisultatiTable)
            ..where((t) => t.id.equals(suo.id)))
          .write(const TestRisultatiTableCompanion(dallAtleta: Value(true)));
      await repository.salvaRisultato(
        testId: 't1',
        atletaId: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 27),
        valori: const [8.1],
        comeAtleta: true,
      );
      final corretto = await (db.select(
        db.testRisultatiTable,
      )..where((t) => t.id.equals(suo.id))).getSingle();
      expect(corretto.valoriJson, '[8.1]');
    });
  });
}
