import 'package:coach_vasca/core/versione/versione_app.dart';
import 'package:coach_vasca/features/novita/data/novita_viste.dart';
import 'package:coach_vasca/features/novita/domain/novita.dart';
import 'package:coach_vasca/features/novita/presentation/finestra_novita.dart';
import 'package:coach_vasca/features/novita/presentation/novita_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _registro = [
  Novita(
    id: 'terza',
    data: DateTime(2026, 10, 19),
    titolo: 'Titolo terza',
    testo: 'Testo terza',
    importante: true,
  ),
  Novita(
    id: 'seconda',
    data: DateTime(2026, 10, 19),
    titolo: 'Titolo seconda',
    testo: 'Testo seconda',
  ),
  Novita(
    id: 'prima',
    data: DateTime(2026, 10, 18),
    titolo: 'Titolo prima',
    testo: 'Testo prima',
    perChi: PerChi.tutti,
    importante: true,
  ),
  Novita(
    id: 'zero',
    data: DateTime(2026, 10, 15),
    titolo: 'Titolo zero',
    testo: 'Testo zero',
  ),
];

/// Una pagina con un pulsante che chiama [mostraNovitaSeServe].
Widget _app({required bool atleta, List<Novita>? registro}) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => mostraNovitaSeServe(
            context,
            atleta: atleta,
            registro: registro ?? _registro,
          ),
          child: const Text('Vai'),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('NovitaScreen', () {
    testWidgets('versione, giorni, Importante e riga Scrivimi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: NovitaScreen(atleta: false, registro: _registro)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novità'), findsOneWidget);
      expect(find.text(VersioneApp.corrente.etichetta), findsOneWidget);
      expect(find.text('19 ottobre 2026'), findsOneWidget);
      expect(find.text('15 ottobre 2026'), findsOneWidget);
      // Le voci per tutti si vedono anche all'allenatore.
      expect(find.text('18 ottobre 2026'), findsOneWidget);
      expect(find.text('Titolo prima'), findsOneWidget);
      expect(find.text('Testo terza'), findsOneWidget);
      // Due voci importanti, due pastiglie.
      expect(find.text('Importante'), findsNWidgets(2));
      expect(
        find.text('Qualcosa non va? Dal menu ☰ tocca «Scrivimi».'),
        findsOneWidget,
      );
    });

    testWidgets('per l\'atleta: solo le sue, senza riga Scrivimi', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: NovitaScreen(atleta: true, registro: _registro)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Titolo prima'), findsOneWidget);
      expect(find.text('Titolo terza'), findsNothing);
      expect(find.text('19 ottobre 2026'), findsNothing);
      expect(find.text('Importante'), findsOneWidget);
      expect(find.textContaining('Scrivimi'), findsNothing);
    });

    testWidgets('senza novità: schermata vuota', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NovitaScreen(atleta: true, registro: [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ancora nessuna novità'), findsOneWidget);
    });

    testWidgets('aprirla segna le novità come viste', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: NovitaScreen(atleta: false, registro: _registro)),
      );
      await tester.pumpAndSettle();

      expect(await leggiUltimaNovitaVista(), 'terza');
    });

    testWidgets('il registro vero si apre senza errori', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NovitaScreen(atleta: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text(registroNovita.first.titolo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('mostraNovitaSeServe', () {
    testWidgets('la prima volta non mostra niente e segna il punto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await leggiUltimaNovitaVista(), 'terza');
    });

    testWidgets('mostra solo le importanti nuove', (tester) async {
      SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'zero'});
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Novità'), findsOneWidget);
      expect(find.text('Titolo terza'), findsOneWidget);
      expect(find.text('Titolo prima'), findsOneWidget);
      // Non importante: solo nella pagina.
      expect(find.text('Titolo seconda'), findsNothing);
      expect(find.text('Tutte le novità'), findsOneWidget);
      expect(find.text('Ho capito'), findsOneWidget);
      // Segnate subito, prima ancora di chiudere.
      expect(await leggiUltimaNovitaVista(), 'terza');
    });

    testWidgets('con una sola voce il titolo è «Una novità»', (tester) async {
      SharedPreferences.setMockInitialValues({
        'novita_ultima_vista': 'seconda',
      });
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();

      expect(find.text('Una novità'), findsOneWidget);
      expect(find.text('Titolo terza'), findsOneWidget);
    });

    testWidgets('l\'atleta vede solo le sue', (tester) async {
      SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'zero'});
      await tester.pumpWidget(_app(atleta: true));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();

      expect(find.text('Titolo prima'), findsOneWidget);
      expect(find.text('Titolo terza'), findsNothing);
    });

    testWidgets('«Ho capito» chiude e non ricompare', (tester) async {
      SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'zero'});
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NovitaScreen), findsNothing);

      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('toccando fuori chiude e non ricompare', (tester) async {
      SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'zero'});
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('«Tutte le novità» apre la pagina', (tester) async {
      SharedPreferences.setMockInitialValues({'novita_ultima_vista': 'zero'});
      await tester.pumpWidget(_app(atleta: false));
      await tester.tap(find.text('Vai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tutte le novità'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NovitaScreen), findsOneWidget);
      // Nella pagina c'è anche la voce non importante.
      expect(find.text('Titolo seconda'), findsOneWidget);
    });
  });
}
