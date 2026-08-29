import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_vasca/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen mostra i campi email, password e il bottone Accedi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('SwimCoach FIN'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accedi'), findsOneWidget);
  });

  testWidgets('mostra un errore se si tenta il login senza compilare i campi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Accedi'));
    await tester.pump();

    expect(find.text('Inserisci la tua email'), findsOneWidget);
    expect(find.text('Inserisci la tua password'), findsOneWidget);
  });
}
