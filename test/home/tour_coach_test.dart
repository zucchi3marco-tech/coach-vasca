import 'package:coach_vasca/core/onboarding/onboarding_coach.dart';
import 'package:coach_vasca/features/home/tour_coach.dart';
import 'package:coach_vasca/features/home/voci_home.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Il tour di benvenuto: pagine, scheda vera che cambia dietro, chiusura,
/// segno di "già visto" e resa a 360 px con il testo ingrandito.

/// Cosa è successo alla home finta dietro il tour.
class _Dietro {
  final schede = <int>[];
  int tocchi = 0;
}

Future<_Dietro> _apri(
  WidgetTester tester, {
  ThemeData? tema,
  Size dimensione = const Size(360, 780),
  double testo = 1.0,
}) async {
  final dietro = _Dietro();
  tester.view.physicalSize = dimensione;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: tema ?? AppTheme.chiaro,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(testo)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => dietro.tocchi++,
                child: const Text('Scheda vera dietro'),
              ),
              TextButton(
                onPressed: () =>
                    mostraTourCoach(context, vaiAllaScheda: dietro.schede.add),
                child: const Text('Apri la guida'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Apri la guida'));
  await _assesta(tester);
  return dietro;
}

Future<void> _assesta(WidgetTester tester) async {
  // L'acqua della testata si anima senza fine: niente pumpAndSettle.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _avanti(WidgetTester tester) async {
  await tester.tap(find.text('Avanti'));
  await _assesta(tester);
}

Future<void> _indietro(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Indietro'));
  await _assesta(tester);
}

/// Conta le pagine scorrendole con "Avanti" fino all'ultima.
Future<int> _contaPagine(WidgetTester tester) async {
  var pagine = 1;
  while (find.text('Avanti').evaluate().isNotEmpty) {
    await _avanti(tester);
    pagine++;
  }
  return pagine;
}

/// Il riquadro del tour: il primo Material sopra le pagine.
final _card = find
    .ancestor(of: find.byType(PageView), matching: find.byType(Material))
    .first;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pagine', () {
    testWidgets('benvenuto, 6 schede e il menu', (tester) async {
      await _apri(tester);
      expect(vociHome(), hasLength(6));
      expect(await _contaPagine(tester), 1 + 6 + 1);
      expect(find.text('Dal menu ☰'), findsOneWidget);
    });

    testWidgets('le etichette delle pagine', (tester) async {
      await _apri(tester);
      expect(find.text('Iniziamo'), findsOneWidget); // etichetta benvenuto
      expect(find.text('Benvenuto, coach'), findsOneWidget);
      await _avanti(tester);
      expect(find.text('Scheda 1 di 6'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await _avanti(tester);
      }
      expect(find.text('Scheda 6 di 6'), findsOneWidget);
      await _avanti(tester);
      expect(find.text('Il menu'), findsOneWidget);
    });
  });

  group('scheda vera dietro', () {
    testWidgets('all\'apertura va su Oggi', (tester) async {
      final dietro = await _apri(tester);
      expect(dietro.schede, [0]);
    });

    testWidgets('Avanti e Indietro seguono le voci', (tester) async {
      final dietro = await _apri(tester);
      dietro.schede.clear();
      // Benvenuto -> Oggi (0) -> Atleti (1) -> Allenamenti (2) -> Schemi (3).
      for (var i = 0; i < 4; i++) {
        await _avanti(tester);
      }
      expect(dietro.schede, [0, 1, 2, 3]);
      dietro.schede.clear();
      await _indietro(tester);
      await _indietro(tester);
      expect(dietro.schede, [2, 1]);
      // Fino in fondo: Stagioni (4), Partite (5), poi il menu (Oggi, 0).
      dietro.schede.clear();
      for (var i = 0; i < 5; i++) {
        await _avanti(tester);
      }
      expect(dietro.schede, [2, 3, 4, 5, 0]);
    });

    testWidgets('lo scorrimento con il dito cambia scheda', (tester) async {
      final dietro = await _apri(tester);
      dietro.schede.clear();
      await tester.drag(find.text('Benvenuto, coach'), const Offset(-300, 0));
      await _assesta(tester);
      expect(find.text('Scheda 1 di 6'), findsOneWidget);
      await tester.drag(find.text('Oggi'), const Offset(-300, 0));
      await _assesta(tester);
      expect(dietro.schede, [0, 1]);
    });

    testWidgets('un pallino lontano salta in un colpo solo', (tester) async {
      final dietro = await _apri(tester);
      dietro.schede.clear();
      final pallini = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(GestureDetector),
      );
      // Il pallino della pagina 5 (Stagioni, scheda 4 = indice 4).
      final tocco = tester.getCenter(pallini.at(5));
      await tester.tapAt(tocco);
      await _assesta(tester);
      expect(dietro.schede, [4]);
    });
  });

  group('chiusura', () {
    testWidgets('Salta chiude e riporta su Oggi', (tester) async {
      final dietro = await _apri(tester);
      await _avanti(tester);
      await _avanti(tester);
      dietro.schede.clear();
      await tester.tap(find.text('Salta'));
      await _assesta(tester);
      expect(find.text('Benvenuto, coach'), findsNothing);
      expect(find.text('Scheda 2 di 6'), findsNothing);
      expect(dietro.schede, [0]);
    });

    testWidgets('l\'ultima pagina: menu, Scrivimi e Iniziamo che chiude', (
      tester,
    ) async {
      final dietro = await _apri(tester);
      await _contaPagine(tester);
      expect(find.text('Dal menu ☰'), findsOneWidget);
      expect(find.textContaining('Scrivimi'), findsOneWidget);
      expect(find.textContaining('Il mio club'), findsOneWidget);
      expect(find.textContaining('Rivedi la guida'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Iniziamo'), findsOneWidget);
      dietro.schede.clear();
      await tester.tap(find.widgetWithText(FilledButton, 'Iniziamo'));
      await _assesta(tester);
      expect(find.text('Dal menu ☰'), findsNothing);
      expect(dietro.schede, [0]);
    });

    testWidgets('è segnato come visto anche chiudendo con Salta', (
      tester,
    ) async {
      expect(await onboardingCoachGiaVisto(), isFalse);
      await _apri(tester);
      await tester.tap(find.text('Salta'));
      await _assesta(tester);
      expect(await onboardingCoachGiaVisto(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_coach_tab_visto_v3'), isTrue);
    });
  });

  testWidgets('la home resta visibile dietro e non si tocca', (tester) async {
    final dietro = await _apri(tester);
    // Il velo non è opaco: la scheda vera si vede ancora...
    expect(find.text('Scheda vera dietro'), findsOneWidget);
    // ...ma il tocco non la raggiunge.
    await tester.tap(find.text('Scheda vera dietro'), warnIfMissed: false);
    await _assesta(tester);
    expect(dietro.tocchi, 0);
    expect(find.text('Benvenuto, coach'), findsOneWidget);
  });

  for (final (nomeTema, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    testWidgets('telefono 360x780, testo 1.3, tema $nomeTema: ogni pagina '
        'entra', (tester) async {
      await _apri(tester, tema: tema, testo: 1.3);
      expect(tester.takeException(), isNull);
      while (find.text('Avanti').evaluate().isNotEmpty) {
        await _avanti(tester);
        expect(tester.takeException(), isNull);
      }
      // La card non invade la barra delle schede (68 px + 8 di margine).
      final card = tester.getRect(_card);
      expect(card.bottom, lessThanOrEqualTo(780 - 68 - 8));
      expect(card.left, greaterThanOrEqualTo(16));
      expect(card.right, lessThanOrEqualTo(360 - 16));
    });
  }

  testWidgets('schermo largo 1280x800: riquadro in basso, largo al massimo '
      '520', (tester) async {
    await _apri(tester, dimensione: const Size(1280, 800));
    expect(await _contaPagine(tester), 8);
    expect(tester.takeException(), isNull);
    final card = tester.getRect(_card);
    expect(card.width, lessThanOrEqualTo(520));
    expect(card.bottom, 800 - 16);
  });
}
