import 'package:coach_vasca/features/ai_genera/presentation/campi_generatore.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ThemeData tema, Widget figlio) => MaterialApp(
  theme: tema,
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: figlio,
    ),
  ),
);

void main() {
  for (final (nome, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    testWidgets('griglia tipi di lavoro su telefono stretto, tema $nome', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final selezionati = <String>{'A1'};
      for (final mostraCodici in [true, false]) {
        await tester.pumpWidget(
          _app(
            tema,
            StatefulBuilder(
              builder: (context, setState) => GrigliaTipiLavoro(
                selezionati: selezionati,
                mostraCodici: mostraCodici,
                onCambia: (z, s) => setState(
                  () => s ? selezionati.add(z) : selezionati.remove(z),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(TileTipoLavoro), findsNWidgets(8));
      }

      await tester.tap(find.byType(TileTipoLavoro).at(2));
      await tester.pump();
      expect(selezionati, containsAll(['A1', 'B1']));
    });

    testWidgets('slider con valore e pannello senza overflow, tema $nome', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          tema,
          PannelloCampi(
            titolo: 'Dettaglio gambe',
            figli: [
              SliderConValore(
                etichetta: 'Metri di gambe',
                valore: 700,
                min: 0,
                max: 3000,
                divisioni: 30,
                onChanged: (_) {},
              ),
              SliderConValore(
                etichetta:
                    "Volume lavoro centrale (m) — se non lo muovi decide l'AI",
                valore: 0,
                min: 0,
                max: 3000,
                divisioni: 30,
                testoValore: 'Auto',
                onChanged: (_) {},
              ),
              GruppoChip(
                etichetta: 'Stile gambe (facoltativo)',
                chip: [
                  for (final s in ['SL', 'DO', 'RA', 'FA', 'MX'])
                    Chip(label: Text(s)),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('700'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });
  }
}
