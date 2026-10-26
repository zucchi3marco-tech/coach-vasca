import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/test/application/test_club_providers.dart';
import 'package:coach_vasca/features/test/data/test_club_repository.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/features/test/presentation/inserisci_risultati_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepositoryFinto implements TestClubRepository {
  final salvati =
      <({String atletaId, List<double> valori, double? kg, int? rip})>[];

  @override
  Future<void> salvaRisultato({
    required String testId,
    required String atletaId,
    required String clubId,
    required DateTime data,
    required List<double> valori,
    String? note,
    double? caricoKg,
    int? ripetizioni,
    bool comeAtleta = false,
  }) async => salvati.add((
    atletaId: atletaId,
    valori: valori,
    kg: caricoKg,
    rip: ripetizioni,
  ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'X',
  cognome: cognome,
  dataNascita: DateTime(2011),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

const _test = TestClub(
  id: 't1',
  clubId: 'c1',
  nome: 'Sprint 15 m',
  unita: UnitaTest.secondi,
  piuBassoMeglio: true,
  prove: 2,
);

Widget _app(_RepositoryFinto repository, Widget figlio) => ProviderScope(
  overrides: [
    testClubRepositoryProvider.overrideWithValue(repository),
    risultatiTestClubProvider.overrideWith(
      (ref, clubId) => Stream.value(const []),
    ),
    atletiListProvider.overrideWith(
      (ref, filtro) =>
          Stream.value([_atleta('a', 'Bianchi'), _atleta('b', 'Rossi')]),
    ),
  ],
  child: MaterialApp(theme: AppTheme.chiaro, home: figlio),
);

Future<void> _apri(
  WidgetTester tester,
  _RepositoryFinto repository, {
  TestClub test = _test,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(repository, InserisciRisultatiScreen(test: test)),
  );
  await tester.pumpAndSettle();
}

/// Chiude la schermata dentro lo stesso ProviderScope: la barra del club
/// si rimette a posto prima che i provider spariscano.
Future<void> _chiudi(WidgetTester tester, _RepositoryFinto repository) =>
    tester.pumpWidget(_app(repository, const SizedBox()));

Future<void> _digita(WidgetTester tester, String cifre) async {
  for (final c in cifre.split('')) {
    await tester.tap(find.widgetWithText(OutlinedButton, c));
    await tester.pump();
  }
}

void main() {
  testWidgets('un atleta dopo l\'altro: due prove, poi si salva e si passa', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository);

    expect(find.text('Bianchi X'), findsOneWidget);
    await _digita(tester, '862');
    expect(find.text('8,62 s', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Registra'));
    await tester.pump();
    // La prima prova è nella fila; si scrive la seconda.
    expect(find.text('1ª 8,62', findRichText: true), findsOneWidget);

    await _digita(tester, '9');
    // ⌫ cancella l'ultima cifra.
    await tester.tap(find.widgetWithText(OutlinedButton, '⌫'));
    await tester.pump();
    await _digita(tester, '901');
    await tester.tap(find.text('Registra e avanti'));
    await tester.pumpAndSettle();

    expect(repository.salvati.single.atletaId, 'a');
    expect(repository.salvati.single.valori, [8.62, 9.01]);
    expect(find.text('Rossi X'), findsOneWidget);

    // "Salta" senza prove passa oltre senza salvare: la squadra è finita.
    await tester.tap(find.text('Salta'));
    await tester.pumpAndSettle();
    expect(repository.salvati, hasLength(1));
    expect(find.text('Squadra finita'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _chiudi(tester, repository);
  });

  testWidgets('⌫ a campo vuoto riapre l\'ultima prova', (tester) async {
    final repository = _RepositoryFinto();
    await _apri(tester, repository);
    await _digita(tester, '862');
    await tester.tap(find.text('Registra'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, '⌫'));
    await tester.pump();
    expect(find.text('8,62 s', findRichText: true), findsOneWidget);
    expect(find.text('Registra'), findsOneWidget);
    await _chiudi(tester, repository);
  });

  testWidgets('un massimale: chili, poi ripetizioni, e si salva la stima', (
    tester,
  ) async {
    final repository = _RepositoryFinto();
    await _apri(
      tester,
      repository,
      test: const TestClub.massimale(
        id: 'm1',
        clubId: 'c1',
        nome: 'Massimale squat',
        esercizioId: 'e1',
      ),
    );
    expect(find.text('Chili sollevati'), findsOneWidget);
    await _digita(tester, '40');
    expect(find.text('40 kg', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Avanti'));
    await tester.pump();
    expect(find.text('Chili 40', findRichText: true), findsOneWidget);
    expect(find.text('Ripetizioni fatte (fino a 10)'), findsOneWidget);

    // Oltre le 10 ripetizioni la stima non regge: non si registra.
    await _digita(tester, '12');
    expect(find.textContaining('oltre, la stima non regge'), findsOneWidget);
    final registra = find.widgetWithText(FilledButton, 'Registra e avanti');
    expect(tester.widget<FilledButton>(registra).onPressed, isNull);

    await tester.tap(find.widgetWithText(OutlinedButton, '⌫'));
    await tester.tap(find.widgetWithText(OutlinedButton, '⌫'));
    await tester.pump();
    await _digita(tester, '5');
    expect(find.text('Massimale stimato: 45 kg'), findsOneWidget);
    await tester.tap(registra);
    await tester.pumpAndSettle();

    final salvato = repository.salvati.single;
    expect(salvato.atletaId, 'a');
    expect(salvato.valori, [45]);
    expect(salvato.kg, 40);
    expect(salvato.rip, 5);
    expect(find.text('Rossi X'), findsOneWidget);
    await _chiudi(tester, repository);
  });
}
