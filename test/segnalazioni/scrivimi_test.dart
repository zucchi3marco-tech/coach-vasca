import 'package:coach_vasca/features/segnalazioni/data/segnalazioni_repository.dart';
import 'package:coach_vasca/features/segnalazioni/domain/segnalazione.dart';
import 'package:coach_vasca/features/segnalazioni/presentation/scrivimi_screen.dart';
import 'package:coach_vasca/features/segnalazioni/presentation/segnalazioni_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/tonal_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'finto_repository.dart';

ContestoSegnalazione _contesto({bool conSchermata = true}) =>
    ContestoSegnalazione(
      versione: '2026-10-19 a6ab096',
      pagina: 'Bordo vasca',
      dispositivo: 'Chrome su Android',
      schermo: '412×915',
      schermata: conSchermata ? pngMinimo : null,
    );

/// Una pagina vuota con «Apri», che spinge [pagina]: così si vede anche la
/// chiusura dopo l'invio.
Future<void> _apri(
  WidgetTester tester,
  FintoSegnalazioniRepository repo,
  Widget pagina, {
  Size misura = const Size(800, 2400),
  ThemeData? tema,
  double scalaTesto = 1,
}) async {
  tester.view.physicalSize = misura;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [segnalazioniRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: tema ?? AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          // Senza movimento: l'acqua della testata non si ferma mai.
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scalaTesto),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => pagina)),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

Future<void> _scorriFinoAllaFine(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Scrivimi', () {
    testWidgets('senza testo non parte', (tester) async {
      final repo = FintoSegnalazioniRepository();
      await _apri(
        tester,
        repo,
        ScrivimiScreen(clubId: 'c1', contesto: _contesto()),
      );

      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();

      expect(find.text('Scrivi cosa è successo'), findsOneWidget);
      expect(repo.inviate, isEmpty);
    });

    testWidgets('parte con il testo, la schermata e gli allegati, poi si '
        'chiude con il grazie', (tester) async {
      final repo = FintoSegnalazioniRepository();
      await _apri(
        tester,
        repo,
        ScrivimiScreen(clubId: 'c1', contesto: _contesto()),
      );
      expect(find.text('La schermata'), findsOneWidget);
      expect(find.text('Pagina: Bordo vasca'), findsOneWidget);
      expect(find.text('2026-10-19 a6ab096'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        '  Il cronometro si ferma  ',
      );
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();

      expect(repo.inviate, hasLength(1));
      final inviata = repo.inviate.single;
      expect(inviata.clubId, 'c1');
      expect(inviata.testo, '  Il cronometro si ferma  ');
      expect(inviata.c.schermata, pngMinimo);
      expect(inviata.c.pagina, 'Bordo vasca');
      expect(inviata.c.versione, '2026-10-19 a6ab096');
      expect(find.text('Apri'), findsOneWidget);
      expect(find.text('Segnalazione inviata. Grazie!'), findsOneWidget);
    });

    testWidgets('la schermata si può togliere', (tester) async {
      final repo = FintoSegnalazioniRepository();
      await _apri(
        tester,
        repo,
        ScrivimiScreen(clubId: 'c1', contesto: _contesto()),
      );

      await tester.tap(find.text('Allega la schermata'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Prova');
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();

      expect(repo.inviate.single.c.schermata, isNull);
      expect(repo.inviate.single.c.pagina, 'Bordo vasca');
    });

    testWidgets('senza schermata non c\'è la sezione', (tester) async {
      await _apri(
        tester,
        FintoSegnalazioniRepository(),
        ScrivimiScreen(clubId: 'c1', contesto: _contesto(conSchermata: false)),
      );
      expect(find.text('La schermata'), findsNothing);
      expect(find.text('Allega la schermata'), findsNothing);
    });

    testWidgets('se non parte lo dice e il testo resta', (tester) async {
      final repo = FintoSegnalazioniRepository()
        ..erroreInvio = Exception('rete assente');
      await _apri(
        tester,
        repo,
        ScrivimiScreen(clubId: 'c1', contesto: _contesto()),
      );

      await tester.enterText(find.byType(TextFormField), 'Non salva');
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();

      expect(find.text('La segnalazione non è partita.'), findsOneWidget);
      expect(find.text('Non salva'), findsOneWidget);
      expect(find.text('Apri'), findsNothing);
    });

    testWidgets('le proprie segnalazioni con lo stato e la risposta', (
      tester,
    ) async {
      final repo = FintoSegnalazioniRepository()
        ..mieSegnalazioni = [
          segnalazioneDiProva(
            id: 's2',
            testo: 'Il PDF esce storto',
            risolta: true,
            risposta: 'Sistemato nella versione di oggi',
          ),
          segnalazioneDiProva(),
        ];
      await _apri(
        tester,
        repo,
        ScrivimiScreen(clubId: 'c1', contesto: _contesto()),
      );

      expect(find.text('Le tue segnalazioni'), findsOneWidget);
      expect(find.text('Il PDF esce storto'), findsOneWidget);
      expect(find.text('Sistemato nella versione di oggi'), findsOneWidget);
      expect(find.text('Risolta'), findsOneWidget);
      expect(find.text('Aperta'), findsOneWidget);
    });
  });

  group('Segnalazioni (chi le legge)', () {
    final elenco = [
      segnalazioneDiProva(schermata: 'u1/s1.png'),
      segnalazioneDiProva(
        id: 's2',
        testo: 'Il PDF esce storto',
        risolta: true,
        risposta: 'Fatto',
      ),
    ];

    testWidgets('prima le aperte; «Risolte» e «Tutte» filtrano', (
      tester,
    ) async {
      final repo = FintoSegnalazioniRepository()..tutteLeSegnalazioni = elenco;
      await _apri(tester, repo, const SegnalazioniScreen());

      expect(find.text('Il cronometro si ferma da solo'), findsOneWidget);
      expect(find.text('Il PDF esce storto'), findsNothing);
      expect(find.textContaining('Marco Rossi, Vasca Club'), findsOneWidget);

      await tester.tap(find.widgetWithText(TonalChip, 'Risolte'));
      await tester.pumpAndSettle();
      expect(find.text('Il cronometro si ferma da solo'), findsNothing);
      expect(find.text('Il PDF esce storto'), findsOneWidget);

      await tester.tap(find.widgetWithText(TonalChip, 'Tutte'));
      await tester.pumpAndSettle();
      expect(find.text('Il cronometro si ferma da solo'), findsOneWidget);
      expect(find.text('Il PDF esce storto'), findsOneWidget);
    });

    testWidgets('nessuna aperta: lo dice', (tester) async {
      final repo = FintoSegnalazioniRepository()
        ..tutteLeSegnalazioni = [elenco.last];
      await _apri(tester, repo, const SegnalazioniScreen());
      expect(find.text('Nessuna segnalazione aperta.'), findsOneWidget);
    });

    testWidgets('una segnalazione: dettagli, schermata, risposta e risolta', (
      tester,
    ) async {
      final repo = FintoSegnalazioniRepository()..tutteLeSegnalazioni = elenco;
      await _apri(tester, repo, const SegnalazioniScreen());

      await tester.tap(find.text('Il cronometro si ferma da solo'));
      await tester.pumpAndSettle();

      expect(find.text('Marco Rossi'), findsOneWidget);
      expect(find.text('Bordo vasca'), findsOneWidget);
      expect(find.text('2026-10-19 a6ab096'), findsOneWidget);
      expect(find.text('Allenatore'), findsOneWidget);
      // La schermata, letta dallo spazio delle segnalazioni.
      expect(find.byType(Image), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Corretto, grazie');
      await tester.tap(find.widgetWithText(SwitchListTile, 'Risolta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      expect(repo.aggiornate.single, (
        id: 's1',
        risolta: true,
        risposta: 'Corretto, grazie',
      ));
      expect(find.text('Salvato.'), findsOneWidget);
    });
  });

  group('Su un telefono stretto con il testo grande', () {
    for (final (nome, tema) in [
      ('chiaro', AppTheme.chiaro),
      ('scuro', AppTheme.scuro),
    ]) {
      testWidgets('Scrivimi, tema $nome', (tester) async {
        final repo = FintoSegnalazioniRepository()
          ..mieSegnalazioni = [
            segnalazioneDiProva(
              risolta: true,
              risposta: 'Sistemato nella versione di oggi, grazie mille',
            ),
          ];
        await _apri(
          tester,
          repo,
          ScrivimiScreen(
            clubId: 'c1',
            contesto: ContestoSegnalazione(
              versione: '2026-10-19 a6ab096',
              pagina: 'Distinta e dal vivo · Under 14 contro Rari Nantes',
              dispositivo:
                  'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36',
              schermo: '360×780, testo 1.3x',
              schermata: pngMinimo,
            ),
          ),
          misura: const Size(360, 780),
          tema: tema,
          scalaTesto: 1.3,
        );
        expect(tester.takeException(), isNull);
        await _scorriFinoAllaFine(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Segnalazioni e dettaglio, tema $nome', (tester) async {
        final repo = FintoSegnalazioniRepository()
          ..tutteLeSegnalazioni = [segnalazioneDiProva(schermata: 'u1/s1.png')];
        await _apri(
          tester,
          repo,
          const SegnalazioniScreen(),
          misura: const Size(360, 780),
          tema: tema,
          scalaTesto: 1.3,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Il cronometro si ferma da solo'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _scorriFinoAllaFine(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
