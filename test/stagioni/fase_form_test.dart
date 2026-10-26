import 'package:coach_vasca/features/stagioni/data/stagioni_repository.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/stagioni/presentation/fase_form_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StagioniFinte implements StagioniRepository {
  List<FaseStagione>? salvate;

  @override
  Future<Stagione> salvaFasi(String id, List<FaseStagione> fasi) async {
    salvate = fasi;
    return _stagione(fasi);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Stagione _stagione(List<FaseStagione> fasi) => Stagione(
  id: 's1',
  clubId: 'c1',
  nome: 'Stagione',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  fasi: fasi,
);

Finder _campo(String etichetta) => find.descendant(
  of: find.widgetWithText(AppTextField, etichetta),
  matching: find.byType(TextFormField),
);

Future<_StagioniFinte> _apri(
  WidgetTester tester,
  Stagione stagione, {
  int? indice,
}) async {
  final repository = _StagioniFinte();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [stagioniRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => FaseFormScreen(stagione: stagione, indice: indice),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  test('i km si leggono con la virgola', () {
    expect(metriDaKm('18'), 18000);
    expect(metriDaKm('18,5'), 18500);
    expect(metriDaKm(''), isNull);
    expect(metriDaKm('tanti'), -1);
    expect(kmDaMetri(18500), '18,5');
    expect(kmDaMetri(18000), '18');
  });

  testWidgets('una fase nuova si salva con i suoi obiettivi', (tester) async {
    final andata = FaseStagione(
      nome: 'Andata',
      dataInizio: DateTime(2026, 9, 1),
      dataFine: DateTime(2026, 12, 31),
    );
    final repository = await _apri(tester, _stagione([andata]));

    // Il nome proposto è il primo non ancora usato, e la fase parte il
    // giorno dopo l'ultima.
    expect(find.text('Preparazione'), findsWidgets);
    expect(find.text('01/01/2027'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Ritorno'));
    await tester.enterText(
      _campo('Volume della squadra, km (facoltativo)'),
      '18,5',
    );
    await tester.enterText(_campo('Carico di un atleta (facoltativo)'), '2400');
    await tester.ensureVisible(find.text('Salva fase'));
    await tester.tap(find.text('Salva fase'));
    await tester.pumpAndSettle();

    final salvate = repository.salvate!;
    expect(salvate, hasLength(2));
    final ritorno = salvate.last;
    expect(ritorno.nome, 'Ritorno');
    expect(ritorno.dataInizio, DateTime(2027, 1, 1));
    expect(ritorno.dataFine, DateTime(2027, 6, 30));
    expect(ritorno.obiettivoMetri, 18500);
    expect(ritorno.obiettivoCarico, 2400);
  });

  testWidgets('due fasi non si sovrappongono', (tester) async {
    final andata = FaseStagione(
      nome: 'Andata',
      dataInizio: DateTime(2026, 9, 1),
      dataFine: DateTime(2027, 6, 30),
    );
    final repository = await _apri(tester, _stagione([andata]));
    await tester.ensureVisible(find.text('Salva fase'));
    await tester.tap(find.text('Salva fase'));
    await tester.pumpAndSettle();

    expect(repository.salvate, isNull);
    expect(
      find.textContaining('Si sovrappone alla fase «Andata»'),
      findsOneWidget,
    );
  });

  testWidgets('«A cosa serve» e la riga di una settimana per gli atleti', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Quattro settimane, dal lunedì 5 ottobre alla domenica 1 novembre;
    // una riga vecchia cade fuori dalla fase e al salvataggio sparisce.
    final preparazione = FaseStagione(
      nome: 'Preparazione',
      dataInizio: DateTime(2026, 10, 5),
      dataFine: DateTime(2026, 11, 1),
      righeSettimane: {DateTime(2026, 12, 7): 'Vecchia'},
    );
    final repository = await _apri(
      tester,
      _stagione([preparazione]),
      indice: 0,
    );

    await tester.enterText(
      _campo('A cosa serve (facoltativo)'),
      '  Costruiamo il fondo: tanti metri, poca velocità ',
    );
    await tester.tap(find.text('Una riga diversa per una settimana'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Settimana 4 ·'), findsOneWidget);
    expect(find.textContaining('Settimana 5 ·'), findsNothing);

    await tester.tap(find.textContaining('Settimana 2 ·'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Settimana del derby: si scarica',
    );
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.text('Settimana del derby: si scarica'), findsOneWidget);

    await tester.ensureVisible(find.text('Salva fase'));
    await tester.tap(find.text('Salva fase'));
    await tester.pumpAndSettle();

    final salvata = repository.salvate!.single;
    expect(salvata.scopo, 'Costruiamo il fondo: tanti metri, poca velocità');
    expect(salvata.righeSettimane, {
      DateTime(2026, 10, 12): 'Settimana del derby: si scarica',
    });
  });
}
