import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/theme/colori_app.dart';
import 'package:coach_vasca/theme/tokens_dominio.dart';

void main() {
  group('AppTheme — estensioni sempre presenti', () {
    testWidgets(
      'ColoriApp e TokenDominio non sono mai null con AppTheme.chiaro',
      (tester) async {
        ColoriApp? colori;
        TokenDominio? dominio;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.chiaro,
            home: Builder(
              builder: (context) {
                colori = Theme.of(context).extension<ColoriApp>();
                dominio = Theme.of(context).extension<TokenDominio>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(colori, isNotNull);
        expect(dominio, isNotNull);
      },
    );

    testWidgets(
      'ColoriApp e TokenDominio non sono mai null con AppTheme.scuro',
      (tester) async {
        ColoriApp? colori;
        TokenDominio? dominio;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.scuro,
            home: Builder(
              builder: (context) {
                colori = Theme.of(context).extension<ColoriApp>();
                dominio = Theme.of(context).extension<TokenDominio>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(colori, isNotNull);
        expect(dominio, isNotNull);
      },
    );
  });

  group('DESIGN.md sezione 5 — ogni token semantico differisce fra i temi', () {
    test('nessun valore di ColoriApp è identico fra chiaro e scuro', () {
      const chiaro = ColoriApp.chiaro;
      const scuro = ColoriApp.scuro;

      final coppie = <String, (Color, Color)>{
        'sfondo': (chiaro.sfondo, scuro.sfondo),
        'superficie': (chiaro.superficie, scuro.superficie),
        'superficieAlt': (chiaro.superficieAlt, scuro.superficieAlt),
        'superficieAlta': (chiaro.superficieAlta, scuro.superficieAlta),
        'superficieMassima': (
          chiaro.superficieMassima,
          scuro.superficieMassima,
        ),
        'scrim': (chiaro.scrim, scuro.scrim),
        'linea': (chiaro.linea, scuro.linea),
        'lineaForte': (chiaro.lineaForte, scuro.lineaForte),
        'testo': (chiaro.testo, scuro.testo),
        'testoSecondario': (chiaro.testoSecondario, scuro.testoSecondario),
        'testoTenue': (chiaro.testoTenue, scuro.testoTenue),
        'azione': (chiaro.azione, scuro.azione),
        'azionePremuta': (chiaro.azionePremuta, scuro.azionePremuta),
        'azioneInk': (chiaro.azioneInk, scuro.azioneInk),
        'azioneTenue': (chiaro.azioneTenue, scuro.azioneTenue),
        'azioneFuoco': (chiaro.azioneFuoco, scuro.azioneFuoco),
        'rosso': (chiaro.rosso, scuro.rosso),
        'rossoTenue': (chiaro.rossoTenue, scuro.rossoTenue),
        'ok': (chiaro.ok, scuro.ok),
        'okTenue': (chiaro.okTenue, scuro.okTenue),
        'attenzione': (chiaro.attenzione, scuro.attenzione),
        'attenzioneTenue': (chiaro.attenzioneTenue, scuro.attenzioneTenue),
      };

      for (final entry in coppie.entries) {
        expect(
          entry.value.$1,
          isNot(equals(entry.value.$2)),
          reason:
              'Il token "${entry.key}" ha lo stesso valore in chiaro e '
              'scuro: ${entry.value.$1} — errore di trascrizione da '
              'DESIGN.md sezione 5.',
        );
      }
    });
  });
}
