import 'package:coach_vasca/features/test/application/test_club_providers.dart';
import 'package:coach_vasca/features/test/data/test_club_repository.dart';
import 'package:coach_vasca/features/test/domain/massimale.dart';
import 'package:coach_vasca/features/test/domain/spiegazioni_test.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/presentation/spiegazione_test.dart';
import 'package:coach_vasca/features/test/presentation/test_club_form_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

TestClub _test({String? modello, String? descrizione, String? esercizio}) =>
    esercizio == null
    ? TestClub(
        id: 't1',
        clubId: 'c1',
        nome: 'Sprint',
        unita: UnitaTest.secondi,
        piuBassoMeglio: true,
        modello: modello,
        descrizione: descrizione,
      )
    : TestClub.massimale(
        id: 't1',
        clubId: 'c1',
        nome: 'Massimale',
        esercizioId: esercizio,
        modello: modello,
        descrizione: descrizione,
      );

void main() {
  group('le spiegazioni', () {
    test('ogni test pronto ha una scheda completa e non troppo lunga', () {
      final schede = [
        for (final m in modelliTest) m.descrizione,
        for (final m in modelliMassimali) spiegazioneOriginale(m.chiave)!,
        spiegazioneBvs,
        spiegazioneT30,
      ];
      for (final s in schede) {
        expect(s.length, lessThanOrEqualTo(lunghezzaMassimaSpiegazione));
        final titoli = [for (final b in blocchiSpiegazione(s)) b.titolo];
        expect(
          titoli,
          containsAll(['A cosa serve', 'Come si fa', 'Come si misura']),
          reason: s,
        );
      }
      // Ogni massimale ha la sua tecnica.
      expect(spiegazioneOriginale('massimale_panca'), contains('Panca:'));
    });

    test('chi non ha cambiato la riga di prima legge la scheda nuova', () {
      expect(
        spiegazioneDi(
          _test(
            modello: 'sprint_15',
            descrizione: 'Partenza da fermi in acqua, al fischio. Due prove.',
          ),
        ),
        spiegazioneSprint15,
      );
      expect(spiegazioneDi(_test(modello: 'wist')), spiegazioneWist);
      // Il massimale pronto con la riga uguale per tutti di prima.
      expect(
        spiegazioneDi(
          _test(
            modello: 'massimale_squat',
            esercizio: 'squat',
            descrizione:
                'Dopo il riscaldamento, il carico più pesante con cui '
                'l\'atleta fa da 3 a 6 ripetizioni pulite: si scrivono chili '
                'e ripetizioni e l\'app stima il massimale. Sempre con '
                'qualcuno che assiste.',
          ),
        ),
        contains('Squat:'),
      );
    });

    test('quella scritta dall\'allenatore resta sua', () {
      expect(
        spiegazioneDi(
          _test(modello: 'sprint_15', descrizione: 'Dal blocco, 2 prove'),
        ),
        'Dal blocco, 2 prove',
      );
      expect(spiegazioneDi(_test()), isNull);
      expect(spiegazioneDi(_test(descrizione: '  ')), isNull);
      // Un massimale inventato ha quella generica.
      expect(spiegazioneDi(_test(esercizio: 'e1')), comeSiFaMassimale);
    });

    test('BVS e T30: quella del club, se no l\'originale', () {
      expect(spiegazioneTestNuoto('BVS', null), spiegazioneBvs);
      expect(spiegazioneTestNuoto('T30', ' '), spiegazioneT30);
      expect(spiegazioneTestNuoto('T30', 'Il nostro T30'), 'Il nostro T30');
    });

    test('i blocchi: titolo, righe e punti', () {
      final b = blocchiSpiegazione(
        'Una riga sola.\n\nCome si fa\n• Primo\n• Secondo\n\n\n• Da solo',
      );
      expect(b, hasLength(3));
      expect(b[0].titolo, isNull);
      expect(b[0].righe, ['Una riga sola.']);
      expect(b[1].titolo, 'Come si fa');
      expect(b[1].righe, ['• Primo', '• Secondo']);
      expect(b[2].titolo, isNull);
    });
  });

  testWidgets('il foglio «Come si fa» di un test pronto: aggiungi o cambia', (
    tester,
  ) async {
    var aggiunto = false;
    var cambiato = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.chiaro,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => mostraComeSiFaTest(
              context,
              titolo: 'Sprint 15 m senza palla',
              testo: spiegazioneSprint15,
              onAggiungi: () => aggiunto = true,
              etichettaModifica: 'Cambialo prima di aggiungerlo',
              onModifica: () => cambiato = true,
            ),
            child: const Text('apri'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.text('A cosa serve'), findsOneWidget);
    expect(find.text('Errori da evitare'), findsOneWidget);
    await tester.ensureVisible(find.text('Aggiungi al club'));
    await tester.tap(find.text('Aggiungi al club'));
    await tester.pumpAndSettle();
    expect(aggiunto, isTrue);

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cambialo prima di aggiungerlo'));
    await tester.tap(find.text('Cambialo prima di aggiungerlo'));
    await tester.pumpAndSettle();
    expect(cambiato, isTrue);
  });

  testWidgets('un test pronto si cambia nel modulo e si aggiunge, con la '
      'sua spiegazione e il pulsante per tornare all\'originale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _TestFinti();
    final modello = modelliTest.firstWhere((m) => m.chiave == 'salto');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          testClubRepositoryProvider.overrideWithValue(repository),
          risultatiTestClubProvider.overrideWith(
            (ref, clubId) => Stream.value(const []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: TestClubFormScreen(clubId: 'c1', modello: modello),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aggiungi test'), findsOneWidget);
    // Niente scelta fra misura e massimale: è già un test pronto.
    expect(find.text('Un massimale'), findsNothing);
    expect(find.text('Ripristina la spiegazione originale'), findsNothing);

    final campo = find.widgetWithText(TextFormField, spiegazioneSalto);
    await tester.enterText(campo, 'Dal bordo, tre prove.');
    await tester.pump();
    expect(find.text('Ripristina la spiegazione originale'), findsOneWidget);
    await tester.tap(find.text('Ripristina la spiegazione originale'));
    await tester.pump();
    expect(find.text('Ripristina la spiegazione originale'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, spiegazioneSalto),
      'Dal bordo, tre prove.',
    );

    await tester.ensureVisible(find.text('Aggiungi al club'));
    await tester.tap(find.text('Aggiungi al club'));
    await tester.pumpAndSettle();
    final creato = repository.creati.single;
    expect(creato.modello, 'salto');
    expect(creato.nome, "Salto fuori dall'acqua");
    expect(creato.prove, 3);
    expect(creato.unita, UnitaTest.centimetri);
    expect(creato.descrizione, 'Dal bordo, tre prove.');
  });
}
