import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/pallanuoto/application/schemi_tattici_providers.dart';
import 'package:coach_vasca/features/pallanuoto/domain/schema_tattico.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/schema_tattico_form_screen.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/water_polo_tactics_board.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget figlio) => ProviderScope(
  overrides: [
    schemiTatticiListProvider.overrideWith(
      (ref, clubId) => Stream.value(<SchemaTattico>[]),
    ),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value(<Gruppo>[])),
  ],
  child: figlio,
);

Future<void> _apriEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      MaterialApp(
        theme: AppTheme.chiaro,
        home: const SchemaTatticoFormScreen(clubId: 'c1'),
      ),
    ),
  );
  await tester.pump();
}

/// Smonta l'editor prima del ProviderScope: chi nasconde la barra del
/// club la rimette a posto nel dispose, e a scope già chiuso fallirebbe.
Future<void> _chiudi(WidgetTester tester) async {
  await tester.pumpWidget(_app(const SizedBox()));
}

Offset _punto(WidgetTester tester, double x, double y) {
  final r = tester.getRect(find.byKey(const Key('vasca-lavagna')));
  return Offset(r.left + r.width * x, r.top + r.height * y);
}

Finder _semantica(String etichetta) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == etichetta,
);

void main() {
  testWidgets('play nell\'editor: anima i passi e torna a modificare', (
    tester,
  ) async {
    await _apriEditor(tester);
    expect(find.text('Passo 1 di 1'), findsOneWidget);

    await tester.tapAt(_punto(tester, 0.3, 0.6));
    await tester.pump();
    await tester.tap(find.byTooltip('Aggiungi un passo'));
    await tester.pump();
    expect(find.text('Passo 2 di 2'), findsOneWidget);

    // Dall'ultimo passo il play riparte dal primo.
    await tester.tap(find.byTooltip('Guarda lo schema in movimento'));
    await tester.pump();
    expect(find.byTooltip('Ferma'), findsOneWidget);
    expect(find.text('Passo 1 di 2'), findsOneWidget);
    // Gli strumenti restano al loro posto, spenti.
    expect(find.text('Giocatori'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ferma'), findsNothing);
    expect(find.text('Passo 2 di 2'), findsOneWidget);
    // Di nuovo la vasca modificabile, con la calottina copiata dal passo 1.
    expect(find.byKey(const Key('vasca-lavagna')), findsOneWidget);
    expect(_semantica('Calottina bianca 1'), findsWidgets);
    await _chiudi(tester);
  });

  testWidgets('la miniatura segue le modifiche del passo', (tester) async {
    await _apriEditor(tester);
    MiniaturaPassoPainter miniatura() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<MiniaturaPassoPainter>()
        .single;
    expect(miniatura().passo.giocatori, isEmpty);

    await tester.tapAt(_punto(tester, 0.3, 0.6));
    await tester.pump();

    expect(miniatura().passo.giocatori, hasLength(1));
    await _chiudi(tester);
  });

  testWidgets('duplica ed elimina dal menu della miniatura', (tester) async {
    await _apriEditor(tester);
    await tester.tapAt(_punto(tester, 0.3, 0.6));
    await tester.pump();

    await tester.tap(find.byTooltip('Azioni sul passo 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplica'));
    await tester.pumpAndSettle();
    expect(find.text('Passo 2 di 2'), findsOneWidget);
    expect(_semantica('Calottina bianca 1'), findsWidgets);

    // Sul passo 2 se ne aggiunge una seconda, poi lo si elimina: la
    // lavagna deve tornare a mostrare il passo 1, con una sola calottina.
    await tester.tapAt(_punto(tester, 0.6, 0.4));
    await tester.pump();
    expect(_semantica('Calottina bianca 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Azioni sul passo 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina').last);
    await tester.pumpAndSettle();

    expect(find.text('Passo 1 di 1'), findsOneWidget);
    expect(_semantica('Calottina bianca 2'), findsNothing);
    expect(_semantica('Calottina bianca 1'), findsWidgets);
    await _chiudi(tester);
  });
}
