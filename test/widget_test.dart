import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_vasca/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets(
    'LoginScreen mostra i campi email, password e il bottone Accedi',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('WaterTactics'), findsOneWidget);
      // AppTextField mostra l'etichetta come Text separato sopra il campo,
      // mai come InputDecoration.labelText flottante (DESIGN.md sezione 8):
      // "Email"/"Password" sono quindi fratelli del TextFormField, non suoi
      // discendenti — vedi lib/widgets/app_text_field.dart.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, 'Accedi'), findsOneWidget);
    },
  );

  testWidgets('mostra un errore se si tenta il login senza compilare i campi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pump();

    expect(find.text('Inserisci la tua email'), findsOneWidget);
    expect(find.text('Inserisci la tua password'), findsOneWidget);
  });
}
