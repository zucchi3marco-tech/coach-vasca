import 'package:coach_vasca/core/segnalazioni/schermata_app.dart';
import 'package:coach_vasca/widgets/testata_pagina.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('titoloDellaPagina', () {
    Future<String?> titolo(WidgetTester tester, Widget pagina) async {
      final chiave = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: KeyedSubtree(key: chiave, child: pagina),
        ),
      );
      return titoloDellaPagina(chiave.currentContext!);
    }

    testWidgets('il testo della barra della pagina', (tester) async {
      expect(
        await titolo(
          tester,
          Scaffold(
            appBar: AppBar(title: const Text('Dettaglio allenamento')),
            body: const Text('Serie'),
          ),
        ),
        'Dettaglio allenamento',
      );
    });

    testWidgets('un titolo che non è un Text: il primo testo dentro', (
      tester,
    ) async {
      expect(
        await titolo(
          tester,
          Scaffold(
            appBar: AppBar(
              title: const Column(children: [Text('Partita'), Text('U14')]),
            ),
          ),
        ),
        'Partita',
      );
    });

    testWidgets('la testata della pagina, senza il trattino invisibile', (
      tester,
    ) async {
      expect(
        await titolo(
          tester,
          Scaffold(
            appBar: AppBar(),
            body: ListView(
              children: const [TestataPagina(titolo: 'Allena­menti')],
            ),
          ),
        ),
        'Allenamenti',
      );
    });

    testWidgets('di uno IndexedStack solo la scheda in vista', (tester) async {
      expect(
        await titolo(
          tester,
          Scaffold(
            body: IndexedStack(
              index: 1,
              children: [
                ListView(children: const [TestataPagina(titolo: 'Oggi')]),
                ListView(children: const [TestataPagina(titolo: 'Atleti')]),
              ],
            ),
          ),
        ),
        'Atleti',
      );
    });

    testWidgets('senza barra né testata: nessun titolo', (tester) async {
      expect(
        await titolo(tester, const Scaffold(body: Text('Solo testo'))),
        isNull,
      );
    });
  });

  testWidgets('OsservatorePagine: la pagina in cima, non i dialoghi', (
    tester,
  ) async {
    final osservatore = OsservatorePagine();
    final navigatore = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatore,
        navigatorObservers: [osservatore],
        home: Scaffold(appBar: AppBar(title: const Text('Home'))),
      ),
    );
    expect(osservatore.soloLaPrima, isTrue);
    expect(osservatore.titoloPaginaInCima(), 'Home');

    navigatore.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(appBar: AppBar(title: const Text('Partita'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(osservatore.soloLaPrima, isFalse);
    expect(osservatore.titoloPaginaInCima(), 'Partita');

    showDialog<void>(
      context: navigatore.currentContext!,
      builder: (_) => const AlertDialog(title: Text('Conferma')),
    );
    await tester.pumpAndSettle();
    expect(osservatore.titoloPaginaInCima(), 'Partita');

    navigatore.currentState!.pop();
    await tester.pumpAndSettle();
    navigatore.currentState!.pop();
    await tester.pumpAndSettle();
    expect(osservatore.soloLaPrima, isTrue);
    expect(osservatore.titoloPaginaInCima(), 'Home');
  });

  testWidgets('catturaSchermata: un PNG largo al massimo quanto chiesto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: chiaveSchermataApp,
          child: const Scaffold(body: Center(child: Text('Da fotografare'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final png = await tester.runAsync(
      () => catturaSchermata(larghezzaMassima: 200),
    );
    expect(png, isNotNull);
    // La firma dei PNG, poi la larghezza nell'intestazione (byte 16-19).
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    final larghezza =
        (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19];
    expect(larghezza, 200);
  });

  testWidgets('catturaSchermata senza il riquadro: null', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Niente')));
    expect(await tester.runAsync(catturaSchermata), isNull);
  });
}
