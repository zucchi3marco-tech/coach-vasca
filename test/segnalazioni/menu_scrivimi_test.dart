import 'package:coach_vasca/core/navigation/navigator_key.dart';
import 'package:coach_vasca/core/segnalazioni/schermata_app.dart';
import 'package:coach_vasca/core/supabase/supabase_providers.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/novita/domain/novita.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/home/barra_club.dart';
import 'package:coach_vasca/features/notifiche/data/notifiche_repository.dart';
import 'package:coach_vasca/features/segnalazioni/data/segnalazioni_repository.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, User;

import 'finto_repository.dart';

const _club = Club(id: 'c1', nome: 'Vasca Club', sport: 'pallanuoto');

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Bianchi',
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

Future<void> _monta(
  WidgetTester tester, {
  bool amministratore = false,
  bool atleta = false,
}) async {
  // Alta abbastanza da avere tutta la pagina di «Scrivimi» costruita.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(AuthState(AuthChangeEvent.signedIn, sessione)),
        ),
        currentAtletaProvider.overrideWith(
          (ref) async => atleta ? _atleta : null,
        ),
        currentClubProvider.overrideWith((ref) async => atleta ? null : _club),
        clubAtletaProvider.overrideWith((ref, _) async => _club),
        notificheNonLetteProvider.overrideWith((ref, clubId) async => []),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        pendingOperationsCountProvider.overrideWith((ref) => Stream.value(0)),
        sonoAmministratoreAppProvider.overrideWith(
          (ref) async => amministratore,
        ),
        segnalazioniRepositoryProvider.overrideWithValue(
          FintoSegnalazioniRepository(),
        ),
        catturaSchermataProvider.overrideWithValue(() async => pngMinimo),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKeyApp,
        navigatorObservers: [osservatorePagine],
        theme: AppTheme.chiaro,
        // Senza movimento: l'acqua delle testate non si ferma mai.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: BarraClubHost(child: child),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Distinta e dal vivo')),
          body: const Text('Contenuto'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _apriMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('l\'allenatore ha Novità e Scrivimi, non Segnalazioni', (
    tester,
  ) async {
    await _monta(tester);
    await _apriMenu(tester);

    expect(find.text('Novità'), findsOneWidget);
    expect(find.text('Scrivimi'), findsOneWidget);
    expect(find.text('Segnalazioni'), findsNothing);
  });

  testWidgets('chi legge le segnalazioni ha anche «Segnalazioni»', (
    tester,
  ) async {
    await _monta(tester, amministratore: true);
    await _apriMenu(tester);

    expect(find.text('Segnalazioni'), findsOneWidget);
  });

  testWidgets('l\'atleta ha Novità ma non Scrivimi', (tester) async {
    await _monta(tester, atleta: true);
    await _apriMenu(tester);

    expect(find.text('Novità'), findsOneWidget);
    expect(find.text('Scrivimi'), findsNothing);
    expect(find.text('Segnalazioni'), findsNothing);
  });

  testWidgets('Scrivimi allega la schermata, la pagina e la versione', (
    tester,
  ) async {
    await _monta(tester);
    await _apriMenu(tester);

    await tester.tap(find.text('Scrivimi'));
    // Il menu sparisce, poi si prepara cosa allegare.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Cosa è successo?'), findsOneWidget);
    expect(find.text('La schermata'), findsOneWidget);
    expect(find.text('Pagina: Distinta e dal vivo'), findsOneWidget);
    expect(find.text('Allega la schermata'), findsOneWidget);
  });

  testWidgets('Novità apre il registro', (tester) async {
    await _monta(tester);
    await _apriMenu(tester);

    await tester.tap(find.text('Novità'));
    await tester.pumpAndSettle();

    // La più recente è in cima (le vecchie scendono a ogni pubblicazione).
    expect(find.text(registroNovita.first.titolo), findsOneWidget);
  });
}
