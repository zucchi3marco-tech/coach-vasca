import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/gare/application/gare_providers.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/stagioni/data/stagioni_repository.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/stagioni/presentation/proponi_fasi_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
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
  gruppoId: 'u16',
  nome: 'Campionato U16',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  fasi: fasi,
);

Partita _partita(
  String id,
  DateTime data,
  String trasferta, {
  String? gruppo,
}) => Partita(
  id: id,
  clubId: 'c1',
  gruppoId: gruppo ?? 'u16',
  data: data,
  squadraCasa: 'Canottieri Milano',
  squadraTrasferta: trasferta,
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: 'casa',
);

final _partite = [
  _partita('p1', DateTime(2026, 10, 24), 'NC Monza'),
  _partita('p2', DateTime(2026, 10, 31), 'AN Brescia'),
  _partita('p3', DateTime(2026, 11, 7), 'SG Arese'),
  _partita('p4', DateTime(2026, 11, 14), 'NC Monza 2'),
  // Un'altra squadra: non conta.
  _partita('u14', DateTime(2026, 10, 25), 'PN Monza', gruppo: 'u14'),
  _partita('finale', DateTime(2027, 6, 19), 'Finale scudetto'),
];

Future<_StagioniFinte> _apri(WidgetTester tester, Stagione stagione) async {
  tester.view.physicalSize = const Size(420, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _StagioniFinte();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stagioniRepositoryProvider.overrideWithValue(repository),
        currentClubProvider.overrideWith((ref) async => null),
        partiteListProvider.overrideWith((ref, _) => Stream.value(_partite)),
        gareListProvider.overrideWith((ref, _) => Stream.value(const [])),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => ProponiFasiScreen(stagione: stagione),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'una partita come obiettivo: fasi a ritroso, poi si sostituiscono',
    (tester) async {
      final vecchia = FaseStagione(
        nome: 'Andata',
        dataInizio: DateTime(2026, 11, 30),
        dataFine: DateTime(2027, 2, 7),
        scopo: 'Vincere in casa',
      );
      final repository = await _apri(tester, _stagione([vecchia]));

      // Senza obiettivi: le cinque partite U16 (la U14 no), divise a metà.
      expect(find.textContaining('dalle 5 partite'), findsOneWidget);
      expect(find.text('Fine stagione'), findsOneWidget);

      await tester.tap(find.text('Aggiungi un obiettivo'));
      await tester.pumpAndSettle();
      // La partita U14 non è fra quelle della stagione U16.
      expect(find.text('Canottieri Milano - PN Monza'), findsNothing);
      await tester.tap(find.text('Canottieri Milano - Finale scudetto'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Finali nazionali');
      await tester.tap(find.text('Fatto'));
      await tester.pumpAndSettle();

      expect(find.text('Finali nazionali'), findsNWidgets(2));
      expect(find.text('Scarico'), findsOneWidget);
      // La finale scelta come obiettivo non conta più fra le partite.
      expect(find.textContaining('dalle 4 partite'), findsOneWidget);

      // Una settimana in più di preparazione.
      await tester.tap(find.byTooltip('Preparazione: una settimana in più'));
      await tester.pumpAndSettle();
      expect(find.textContaining('– dom 25 ott'), findsOneWidget);

      await tester.tap(find.text('Usa queste fasi'));
      await tester.pumpAndSettle();
      expect(find.text('Sostituire le fasi?'), findsOneWidget);
      await tester.tap(find.text('Sostituisci'));
      await tester.pumpAndSettle();

      final salvate = repository.salvate!;
      expect(
        [for (final f in salvate) f.nome],
        [
          'Preparazione',
          'Andata',
          'Ritorno',
          'Scarico',
          'Finali nazionali',
          'Fine stagione',
        ],
      );
      expect(salvate.first.dataFine, DateTime(2026, 10, 25));
      expect(salvate[1].dataInizio, DateTime(2026, 10, 26));
      // L'andata di prima passa «A cosa serve» a quella nuova.
      expect(salvate[1].scopo, 'Vincere in casa');
      expect(salvate[4].dataInizio, DateTime(2027, 6, 19));
      expect(salvate[4].dataFine, DateTime(2027, 6, 19));
    },
  );

  testWidgets('senza fasi di prima si salva senza chiedere', (tester) async {
    final repository = await _apri(tester, _stagione(const []));
    await tester.tap(find.text('Usa queste fasi'));
    await tester.pumpAndSettle();
    expect(find.text('Sostituire le fasi?'), findsNothing);
    expect(repository.salvate, isNotNull);
    expect(repository.salvate!.first.nome, 'Preparazione');
  });
}
