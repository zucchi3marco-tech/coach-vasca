import 'package:coach_vasca/features/allenamenti/domain/riordino_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie_rapida.dart';
import 'package:coach_vasca/features/allenamenti/presentation/pannello_aggiungi_serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/riepilogo_volumi.dart';
import 'package:coach_vasca/features/allenamenti/presentation/riga_serie.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Serie _serie(
  String id,
  int ordine, {
  String blocco = 'principale',
  int ripetute = 8,
  int distanzaM = 100,
  String? zona = 'A2',
  String esecuzione = 'nuoto',
  String? attrezzatura,
}) => Serie(
  id: id,
  allenamentoId: 'a',
  clubId: 'c',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: zona,
  recuperoS: 20,
  attrezzatura: attrezzatura,
);

Widget _app(ThemeData tema, Widget figlio) => MaterialApp(
  theme: tema,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: figlio),
  ),
);

void main() {
  group('spostaSerie', () {
    final tre = [_serie('a', 1), _serie('b', 2), _serie('c', 3)];

    test('porta una serie in una nuova posizione', () {
      expect(spostaSerie(tre, 0, 2).map((s) => s.id), ['b', 'c', 'a']);
      expect(spostaSerie(tre, 2, 0).map((s) => s.id), ['c', 'a', 'b']);
    });

    test('la destinazione fuori dai limiti si ferma al bordo', () {
      expect(spostaSerie(tre, 1, -1).map((s) => s.id), ['b', 'a', 'c']);
      expect(spostaSerie(tre, 1, 9).map((s) => s.id), ['a', 'c', 'b']);
    });

    test('un indice di partenza non valido non cambia nulla', () {
      expect(spostaSerie(tre, 7, 0).map((s) => s.id), ['a', 'b', 'c']);
    });
  });

  group('cambiDiOrdine', () {
    test('riscrive solo le serie che cambiano numero', () {
      final ordinate = spostaSerie(
        [_serie('a', 1), _serie('b', 2), _serie('c', 3), _serie('d', 4)],
        2,
        1,
      );
      final cambi = cambiDiOrdine(ordinate);
      expect(cambi.map((c) => (c.serie.id, c.ordine)), [('c', 2), ('b', 3)]);
    });

    test('con i buchi dopo una cancellazione rinumera da 1', () {
      final cambi = cambiDiOrdine([_serie('a', 1), _serie('c', 3)]);
      expect(cambi.map((c) => (c.serie.id, c.ordine)), [('c', 2)]);
    });
  });

  group('formattaMetri', () {
    test('punto come separatore delle migliaia', () {
      expect(formattaMetri(0), '0');
      expect(formattaMetri(400), '400');
      expect(formattaMetri(3200), '3.200');
      expect(formattaMetri(12000), '12.000');
      expect(formattaMetri(1234567), '1.234.567');
    });
  });

  for (final (nome, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('tema $nome, telefono stretto', () {
      setUp(() {});

      testWidgets('RiepilogoVolumi mostra solo i blocchi con serie', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(
            tema,
            RiepilogoVolumi(
              serie: [
                _serie(
                  'a',
                  1,
                  blocco: 'riscaldamento',
                  ripetute: 1,
                  distanzaM: 400,
                ),
                _serie(
                  'b',
                  2,
                  ripetute: 8,
                  distanzaM: 300,
                  attrezzatura: 'pull',
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('2.800 m'), findsOneWidget);
        expect(find.textContaining('Risc. 400'), findsOneWidget);
        expect(find.textContaining('Princ. 2.400'), findsOneWidget);
        expect(find.textContaining('Defat.'), findsNothing);
        expect(find.textContaining('Materiale: pull'), findsOneWidget);
      });

      testWidgets('RigaSerie sta in una riga bassa e il menu ha le azioni', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final azioni = <AzioneSerie>[];
        var aperta = 0;
        await tester.pumpWidget(
          _app(
            tema,
            RigaSerie(
              serie: _serie('a', 3, attrezzatura: 'palette, pull'),
              maniglia: const Icon(Icons.drag_indicator),
              primo: false,
              ultimo: false,
              onApri: () => aperta++,
              onAzione: azioni.add,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('8×100m Libero'), findsOneWidget);
        expect(tester.getSize(find.byType(RigaSerie)).height, lessThan(90));

        await tester.tap(find.textContaining('8×100m Libero'));
        expect(aperta, 1);

        await tester.tap(find.byType(PopupMenuButton<AzioneSerie>));
        await tester.pumpAndSettle();
        for (final voce in [
          'Sposta su',
          'Sposta giù',
          'Cambia blocco',
          'Duplica',
          'Elimina',
        ]) {
          expect(find.text(voce), findsOneWidget);
        }
        await tester.tap(find.text('Duplica'));
        await tester.pumpAndSettle();
        expect(azioni, [AzioneSerie.duplica]);
      });

      testWidgets('la prima serie non si può spostare su, l\'ultima giù', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            tema,
            RigaSerie(
              serie: _serie('a', 1),
              maniglia: const Icon(Icons.drag_indicator),
              primo: true,
              ultimo: true,
              onApri: () {},
              onAzione: (_) {},
            ),
          ),
        );
        await tester.tap(find.byType(PopupMenuButton<AzioneSerie>));
        await tester.pumpAndSettle();
        final su = tester.widget<PopupMenuItem<AzioneSerie>>(
          find.ancestor(
            of: find.text('Sposta su'),
            matching: find.byType(PopupMenuItem<AzioneSerie>),
          ),
        );
        final giu = tester.widget<PopupMenuItem<AzioneSerie>>(
          find.ancestor(
            of: find.text('Sposta giù'),
            matching: find.byType(PopupMenuItem<AzioneSerie>),
          ),
        );
        expect(su.enabled, isFalse);
        expect(giu.enabled, isFalse);
      });
    });
  }

  group('PannelloAggiungiSerie', () {
    testWidgets('aggiunge nel blocco scelto e resta aperto per la prossima', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final aggiunte = <(List<SerieRapida>, String)>[];
      final blocchi = <String>[];
      await tester.pumpWidget(
        _app(
          AppTheme.scuro,
          SingleChildScrollView(
            child: PannelloAggiungiSerie(
              bloccoIniziale: 'principale',
              onBloccoCambiato: blocchi.add,
              aggiungiRapida: (serie, blocco) async =>
                  aggiunte.add((serie, blocco)),
              onScrivi: () {},
              onSerieCompleta: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Risc.'));
      await tester.pump();
      expect(blocchi, ['riscaldamento']);

      await tester.enterText(find.byType(TextField), '10x100 A2 r15');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pumpAndSettle();

      expect(aggiunte, hasLength(1));
      expect(aggiunte.single.$2, 'riscaldamento');
      expect(aggiunte.single.$1.single.ripetute, 10);
      expect(aggiunte.single.$1.single.distanzaM, 100);
      expect(find.textContaining('Aggiunta:'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });
  });
}
