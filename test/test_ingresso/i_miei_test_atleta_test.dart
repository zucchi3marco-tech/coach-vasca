import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/atleti/application/personal_best_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:coach_vasca/features/atleti/presentation/pb_list_screen.dart';
import 'package:coach_vasca/features/test/application/test_club_providers.dart';
import 'package:coach_vasca/features/test/application/test_providers.dart';
import 'package:coach_vasca/features/test/data/spiegazioni_test_repository.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/domain/test_ingresso.dart';
import 'package:coach_vasca/features/test/presentation/segna_risultato_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

TestClub _test(String id, String nome, {bool aperto = false}) => TestClub(
  id: id,
  clubId: 'c1',
  nome: nome,
  unita: UnitaTest.secondi,
  piuBassoMeglio: true,
  apertoAtleti: aperto,
);

RisultatoTest _risultato(
  String id,
  String test,
  double v, {
  bool suo = false,
}) => RisultatoTest(
  id: id,
  testId: test,
  atletaId: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 10, 20),
  valori: [v],
  dallAtleta: suo,
);

Future<void> _apri(WidgetTester tester, {required bool eLui}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        personalBestListProvider.overrideWith(
          (ref, id) => Stream.value(<PersonalBest>[]),
        ),
        testListProvider.overrideWith(
          (ref, id) => Stream.value(<TestIngresso>[]),
        ),
        spiegazioniTestNuotoProvider.overrideWith((ref, clubId) async => {}),
        currentAtletaProvider.overrideWith(
          (ref) async => eLui ? _atleta : null,
        ),
        testClubProvider.overrideWith(
          (ref, clubId) => Stream.value([
            _test('aperto', 'Sprint 15 m', aperto: true),
            _test('chiuso', 'Sprint 10 m'),
            _test('fatto', 'Salto', aperto: true),
          ]),
        ),
        risultatiTestClubProvider.overrideWith(
          (ref, clubId) =>
              Stream.value([_risultato('r1', 'fatto', 52, suo: true)]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: PbListScreen(atleta: _atleta),
      ),
    ),
  );
  await _attendi(tester);
}

/// La pagina ha animazioni che non si fermano: attese fisse.
Future<void> _attendi(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('l\'atleta vede i test aperti da segnare e li segna', (
    tester,
  ) async {
    await _apri(tester, eLui: true);

    // Il test aperto senza risultati; quello chiuso senza risultati no.
    expect(find.text('Sprint 15 m'), findsOneWidget);
    expect(find.text('Da segnare: scrivi il tuo risultato'), findsOneWidget);
    expect(find.text('Sprint 10 m'), findsNothing);

    await tester.tap(find.text('Sprint 15 m'));
    await _attendi(tester);
    await tester.tap(find.text('Segna un risultato'));
    await _attendi(tester);
    expect(find.byType(SegnaRisultatoScreen), findsOneWidget);
    expect(find.text('Il tuo risultato'), findsOneWidget);
  });

  testWidgets('il suo risultato si tocca per correggerlo', (tester) async {
    await _apri(tester, eLui: true);
    await tester.tap(find.text('Salto'));
    await _attendi(tester);
    expect(find.textContaining('segnato da te'), findsOneWidget);
    await tester.tap(find.textContaining('segnato da te'));
    await _attendi(tester);
    expect(find.text('Correggi'), findsOneWidget);
  });

  testWidgets('l\'allenatore che guarda la pagina non segna niente', (
    tester,
  ) async {
    await _apri(tester, eLui: false);
    expect(find.text('Sprint 15 m'), findsNothing);
    await tester.tap(find.text('Salto'));
    await _attendi(tester);
    expect(find.text('Segna un risultato'), findsNothing);
  });
}
