import 'package:coach_vasca/core/navigation/navigator_key.dart';
import 'package:coach_vasca/core/supabase/supabase_providers.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/home/barra_club.dart';
import 'package:coach_vasca/features/notifiche/data/notifiche_repository.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/nascondi_barra_club.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, User;

Widget _app({required bool autenticato}) {
  final sessione = Session(
    accessToken: 't',
    tokenType: 'bearer',
    user: const User(
      id: 'u',
      appMetadata: {},
      userMetadata: {},
      aud: 'a',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(
          AuthState(
            autenticato ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
            autenticato ? sessione : null,
          ),
        ),
      ),
      currentAtletaProvider.overrideWith((ref) async => null),
      currentClubProvider.overrideWith(
        (ref) async =>
            const Club(id: 'c1', nome: 'Vasca Club', sport: 'pallanuoto'),
      ),
      notificheNonLetteProvider.overrideWith((ref, clubId) async => []),
      gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
      pendingOperationsCountProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKeyApp,
      theme: AppTheme.chiaro,
      builder: (context, child) => BarraClubHost(child: child),
      home: const Scaffold(body: Text('Contenuto')),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('con l\'utente autenticato mostra il nome del club sopra il '
      'contenuto', (tester) async {
    await tester.pumpWidget(_app(autenticato: true));
    await tester.pumpAndSettle();

    expect(find.text('Vasca Club'), findsOneWidget);
    expect(find.text('Contenuto'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Vasca Club')).dy,
      lessThan(tester.getTopLeft(find.text('Contenuto')).dy),
    );
  });

  testWidgets('senza sessione la barra non compare', (tester) async {
    await tester.pumpWidget(_app(autenticato: false));
    await tester.pumpAndSettle();

    expect(find.text('Vasca Club'), findsNothing);
    expect(find.text('Contenuto'), findsOneWidget);
  });

  testWidgets('il menu ☰ si apre pur stando sopra il Navigator', (
    tester,
  ) async {
    await tester.pumpWidget(_app(autenticato: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Esci'), findsOneWidget);
  });

  testWidgets('il selettore del tema si apre dalla barra', (tester) async {
    await tester.pumpWidget(_app(autenticato: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Chiaro'), findsOneWidget);
    expect(find.text('Scuro'), findsOneWidget);
  });

  testWidgets('una schermata con NascondiBarraClub toglie la barra e la '
      'restituisce alla chiusura', (tester) async {
    await tester.pumpWidget(_app(autenticato: true));
    await tester.pumpAndSettle();
    expect(find.text('Vasca Club'), findsOneWidget);

    navigatorKeyApp.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const NascondiBarraClub(child: Scaffold(body: Text('Bordo vasca'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bordo vasca'), findsOneWidget);
    expect(find.text('Vasca Club'), findsNothing);

    navigatorKeyApp.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Vasca Club'), findsOneWidget);
  });
}
