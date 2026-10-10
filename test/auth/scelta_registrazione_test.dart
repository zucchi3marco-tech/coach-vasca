import 'package:coach_vasca/features/auth/presentation/login_screen.dart';
import 'package:coach_vasca/features/auth/presentation/riscatta_invito_screen.dart';
import 'package:coach_vasca/features/auth/presentation/signup_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _apriScelta(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.chiaro, home: const LoginScreen()),
    ),
  );
  await tester.tap(find.text('Registrati'));
  await tester.pumpAndSettle();
  expect(find.text('Chi sei?'), findsOneWidget);
}

void main() {
  testWidgets('"Registrati" chiede prima se sei atleta o allenatore', (
    tester,
  ) async {
    await _apriScelta(tester);

    await tester.tap(find.text('Sono un atleta'));
    await tester.pumpAndSettle();
    expect(find.byType(RiscattaInvitoScreen), findsOneWidget);

    // La scelta è stata sostituita: indietro si torna al login.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Chi sei?'), findsNothing);
  });

  testWidgets('l\'allenatore arriva alla sua registrazione, con l\'uscita '
      'per l\'atleta finito lì per sbaglio', (tester) async {
    await _apriScelta(tester);

    await tester.tap(find.text('Sono un allenatore'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Registrazione allenatore'), findsOneWidget);

    await tester.tap(find.text('Sono un atleta, ho un codice'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(RiscattaInvitoScreen), findsOneWidget);
  });
}
