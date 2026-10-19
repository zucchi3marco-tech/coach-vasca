import 'package:coach_vasca/features/novita/domain/novita.dart';
import 'package:coach_vasca/features/novita/presentation/finestra_novita.dart';
import 'package:coach_vasca/features/novita/presentation/novita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le novità su un telefono stretto (360 px) con il testo di sistema
/// ingrandito, nei due temi: niente deve uscire dallo schermo (un overflow
/// fa fallire il test).

const _testoLungo =
    'Nel menu ☰ «Scrivimi» manda a chi sviluppa WaterTactics cosa non va, '
    'con la schermata dove eri. Qui in «Novità» trovi cosa è cambiato a '
    'ogni aggiornamento, con parole abbastanza lunghe da andare a capo più '
    'di una volta anche su uno schermo stretto.';

final _registro = [
  for (var i = 0; i < 8; i++)
    Novita(
      id: 'n$i',
      data: DateTime(2026, 10, 19 - i ~/ 2),
      titolo: 'Una novità con un titolo piuttosto lungo numero $i',
      testo: _testoLungo,
      importante: i.isEven,
      perChi: PerChi.tutti,
    ),
];

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(ThemeData tema, Widget home) => MaterialApp(
  theme: tema,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.3)),
    child: child!,
  ),
  home: home,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (nomeTema, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('tema $nomeTema', () {
      testWidgets('la pagina, allenatore', (tester) async {
        _telefono(tester);
        await tester.pumpWidget(
          _app(tema, NovitaScreen(atleta: false, registro: _registro)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Importante'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('la pagina con il registro vero', (tester) async {
        _telefono(tester);
        await tester.pumpWidget(_app(tema, const NovitaScreen(atleta: false)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('la pagina vuota', (tester) async {
        _telefono(tester);
        await tester.pumpWidget(
          _app(tema, const NovitaScreen(atleta: true, registro: [])),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ancora nessuna novità'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('la finestra dopo un aggiornamento', (tester) async {
        _telefono(tester);
        SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'n7'});
        await tester.pumpWidget(
          _app(
            tema,
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => mostraNovitaSeServe(
                    context,
                    atleta: false,
                    registro: _registro,
                  ),
                  child: const Text('Vai'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Vai'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Novità'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
