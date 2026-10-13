import 'package:coach_vasca/features/campionati/data/campionati_repository.dart';
import 'package:coach_vasca/features/campionati/data/pagine_fin_demo.dart';
import 'package:coach_vasca/features/campionati/domain/campionato_fin.dart';
import 'package:coach_vasca/features/campionati/domain/lettore_fin.dart';
import 'package:coach_vasca/features/campionati/presentation/classifica_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 20, 18);

/// Il sito FIN finto: le pagine della demo, e i collegamenti in memoria.
class _CampionatiFinti implements CampionatiRepository {
  _CampionatiFinti([List<GironeCollegato>? collegati])
    : _collegati = [...?collegati];

  final List<GironeCollegato> _collegati;
  final richiesteGirone = <int>[];

  @override
  Future<ElencoFin> elenco({String? stagione}) async =>
      leggiElencoFin(paginaElencoDemoFin());

  @override
  Future<LetturaGirone> girone(int cmpId) async {
    richiesteGirone.add(cmpId);
    return LetturaGirone(
      girone: leggiGironeFin(
        paginaGironeDemoFin(cmpId, oggi: _oggi),
        cmpId: cmpId,
      ),
      lettoIl: DateTime(2026, 10, 20, 17, 5),
    );
  }

  @override
  Future<List<GironeCollegato>> collegati(String clubId) async => [
    ..._collegati,
  ];

  @override
  Future<GironeCollegato> collega({
    required String clubId,
    required String? gruppoId,
    required VoceElencoFin voce,
    required String stagione,
    required String squadra,
  }) async {
    final nuovo = GironeCollegato(
      id: 'g${_collegati.length + 1}',
      clubId: clubId,
      gruppoId: gruppoId,
      cmpId: voce.cmpId,
      stagione: stagione,
      campionato: voce.campionato,
      fase: voce.fase,
      girone: voce.girone,
      squadra: squadra,
    );
    _collegati.insert(0, nuovo);
    return nuovo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _apri(
  WidgetTester tester,
  _CampionatiFinti campionati, {
  required bool allenatore,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        campionatiRepositoryProvider.overrideWithValue(campionati),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: ClassificaScreen(
          clubId: 'c1',
          gruppoId: 'u14',
          puoModificare: allenatore,
          oggi: _oggi,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('atleta: classifica, le nostre partite e tutto il calendario', (
    tester,
  ) async {
    final campionati = _CampionatiFinti([
      const GironeCollegato(
        id: 'g1',
        clubId: 'c1',
        gruppoId: 'u14',
        cmpId: 229,
        stagione: stagioneDemoFin,
        campionato: 'Under 14 (M)',
        fase: 'Fase 1',
        girone: 'Girone 1',
        squadra: squadraDemoFin,
      ),
    ]);
    await _apri(tester, campionati, allenatore: false);

    expect(find.text('Classifica'), findsWidgets);
    expect(find.text('Under 14 (M) · Fase 1 · Girone 1'), findsOneWidget);
    expect(find.text('Posizione'), findsOneWidget);
    // Le sei squadre in tabella, la nostra compresa.
    expect(find.text('Delfini Ravenna'), findsOneWidget);
    expect(find.text(squadraDemoFin), findsOneWidget);
    expect(
      find.text('Fonte: FIN Lombardia · aggiornata alle 17:05'),
      findsOneWidget,
    );
    // Le nostre 5 partite: le prime due giocate, la terza è la prossima.
    expect(find.text('Prossima · 3a giornata'), findsOneWidget);
    expect(find.textContaining('vs '), findsNWidgets(5));
    // Solo l'allenatore collega e toglie.
    expect(find.text('Collega un girone'), findsNothing);
    expect(find.text('Togli questo girone'), findsNothing);

    await tester.tap(find.text('Tutto il calendario'));
    await tester.pumpAndSettle();
    expect(find.text('1a giornata'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5a giornata'), 300);
    expect(find.text('5a giornata'), findsOneWidget);
    expect(find.textContaining('vs '), findsNothing);
  });

  testWidgets('atleta senza campionato collegato', (tester) async {
    await _apri(tester, _CampionatiFinti(), allenatore: false);
    expect(find.text('Nessun campionato'), findsOneWidget);
    expect(find.text('Collega un girone'), findsNothing);
  });

  testWidgets("l'allenatore collega un girone e sceglie la sua squadra", (
    tester,
  ) async {
    final campionati = _CampionatiFinti();
    await _apri(tester, campionati, allenatore: true);

    expect(find.text('Nessun campionato collegato'), findsOneWidget);
    await tester.tap(find.text('Collega un girone'));
    await tester.pumpAndSettle();

    // L'elenco della FIN, per campionato.
    expect(find.text('Under 14 (M)'), findsOneWidget);
    expect(find.text('Under 16 (F)'), findsOneWidget);
    await tester.tap(find.text('Fase 1 · Girone 2'));
    await tester.pumpAndSettle();

    expect(find.text('Qual è la tua squadra?'), findsOneWidget);
    await tester.tap(find.text(squadraDemoFin));
    await tester.pumpAndSettle();

    final collegato = (await campionati.collegati('c1')).single;
    expect(collegato.cmpId, 230);
    expect(collegato.gruppoId, 'u14');
    expect(collegato.campionato, 'Under 14 (M)');
    expect(collegato.squadra, squadraDemoFin);
    // Di nuovo nella classifica, con il girone appena collegato.
    expect(find.text('Under 14 (M) · Fase 1 · Girone 2'), findsOneWidget);
    expect(find.text('Togli questo girone'), findsOneWidget);
    expect(campionati.richiesteGirone, contains(230));
  });
}
