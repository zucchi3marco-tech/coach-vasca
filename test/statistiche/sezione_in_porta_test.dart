import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/domain/numeri_portiere.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/statistiche/application/statistiche_providers.dart';
import 'package:coach_vasca/features/statistiche/domain/statistiche_stagionali.dart';
import 'package:coach_vasca/features/statistiche/presentation/statistiche_atleta_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime.now();

final _stagione = Stagione(
  id: 's1',
  clubId: 'c1',
  nome: 'Stagione U16',
  dataInizio: _oggi.subtract(const Duration(days: 30)),
  dataFine: _oggi.add(const Duration(days: 200)),
);

Atleta _atleta(String? ruolo) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  ruolo: ruolo,
  consensoPrivacyFirmato: true,
  attivo: true,
);

void main() {
  Future<List<ChiaveNumeriPortiere>> apri(
    WidgetTester tester,
    Atleta atleta,
    NumeriPortiere numeri,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final richieste = <ChiaveNumeriPortiere>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stagioniListProvider.overrideWith(
            (ref, clubId) => Stream.value([_stagione]),
          ),
          riepilogoRefertiProvider.overrideWith(
            (ref, chiave) async => RiepilogoSquadraReferti.vuoto,
          ),
          riepilogoEventiProvider.overrideWith(
            (ref, chiave) async => RiepilogoSquadraEventi.vuoto,
          ),
          tiriAtletaProvider.overrideWith((ref, id) async => []),
          numeriPortiereProvider.overrideWith((ref, chiave) async {
            richieste.add(chiave);
            return numeri;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: StatisticheAtletaScreen(atleta: atleta),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return richieste;
  }

  testWidgets('il portiere ha in cima la sezione «In porta» della stagione', (
    tester,
  ) async {
    final richieste = await apri(
      tester,
      _atleta('portiere'),
      const NumeriPortiere(
        partite: 4,
        parate: 20,
        golSubiti: 30,
        golSubitiDalVivo: 10,
      ),
    );

    expect(find.text('In porta'), findsOneWidget);
    for (final etichetta in [
      'Partite',
      'Parate',
      'Gol subiti',
      '% parate',
      'Gol subiti/partita',
    ]) {
      expect(find.text(etichetta), findsOneWidget, reason: etichetta);
    }
    expect(find.text('20'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    // 20 parate su 30 tiri in porta dal vivo.
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('7.50'), findsOneWidget);

    // Le sezioni di sempre restano sotto: i gol che segna si vedono lì.
    expect(find.text('Da referti'), findsOneWidget);
    expect(find.text('Da eventi live'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('In porta')).dy,
      lessThan(tester.getTopLeft(find.text('Da referti')).dy),
    );

    // Filtrata sulla stagione scelta.
    expect(richieste, isNotEmpty);
    expect(richieste.last.atletaId, 'a1');
    expect(richieste.last.dataInizio, _stagione.dataInizio);
    expect(richieste.last.dataFine, _stagione.dataFine);
  });

  testWidgets('senza partite in porta nella stagione lo dice', (tester) async {
    await apri(tester, _atleta('portiere'), NumeriPortiere.vuoto);

    expect(find.text('In porta'), findsOneWidget);
    expect(
      find.text('Nessuna partita in porta in questa stagione.'),
      findsOneWidget,
    );
    expect(find.text('Da referti'), findsOneWidget);
  });

  testWidgets('chi gioca in campo non ha la sezione «In porta»', (
    tester,
  ) async {
    final richieste = await apri(
      tester,
      _atleta('centroboa'),
      NumeriPortiere.vuoto,
    );

    expect(find.text('In porta'), findsNothing);
    expect(find.text('Da referti'), findsOneWidget);
    expect(richieste, isEmpty);
  });
}
