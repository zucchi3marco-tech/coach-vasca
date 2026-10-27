import 'package:coach_vasca/features/campionati/application/sito_fin_cambiato.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import 'pagine_fin_vere.dart';

final _oggi = DateTime(2026, 10, 20, 18);

/// Il sito FIN finto: le pagine della demo, e i collegamenti in memoria.
class _CampionatiFinti implements CampionatiRepository {
  _CampionatiFinti([List<GironeCollegato>? collegati, this.paginaGirone])
    : _collegati = [...?collegati];

  final List<GironeCollegato> _collegati;
  final richiesteGirone = <int>[];

  /// Una pagina del girone al posto di quella della demo.
  final String? paginaGirone;

  @override
  Future<ElencoFin> elenco({String? stagione}) async =>
      leggiElencoFin(paginaElencoDemoFin());

  @override
  Future<LetturaGirone> girone(int cmpId) async {
    richiesteGirone.add(cmpId);
    return LetturaGirone(
      girone: leggiGironeFin(
        paginaGirone ?? paginaGironeDemoFin(cmpId, oggi: _oggi),
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
  List<String>? segnalazioni,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        campionatiRepositoryProvider.overrideWithValue(campionati),
        if (segnalazioni != null)
          segnalatoreSitoFinProvider.overrideWithValue(
            SegnalatoreSitoFin(({
              required clubId,
              required testo,
              required contesto,
            }) async {
              segnalazioni.add('$clubId · ${contesto.pagina}');
            }),
          ),
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
    expect(find.text('Prossima · 3ª Giornata (Andata)'), findsOneWidget);
    expect(find.textContaining('vs '), findsNWidgets(5));
    // Solo l'allenatore collega e toglie.
    expect(find.text('Collega un girone'), findsNothing);
    expect(find.text('Togli questo girone'), findsNothing);

    await tester.tap(find.text('Tutto il calendario'));
    await tester.pumpAndSettle();
    expect(find.text('1ª Giornata (Andata)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5ª Giornata (Andata)'), 300);
    expect(find.text('5ª Giornata (Andata)'), findsOneWidget);
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

  testWidgets('il sito FIN cambiato: lo dice e parte una segnalazione', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // La classifica perde la colonna della differenza reti.
    final cambiata = paginaGironeVera.replaceAll(
      RegExp(
        r'<td class="text-center font-monospace fw-bold text-(success|danger)">'
        r'\s*[+-]?\d+\s*</td>',
      ),
      '',
    );
    final campionati = _CampionatiFinti([
      const GironeCollegato(
        id: 'g1',
        clubId: 'c1',
        gruppoId: 'u14',
        cmpId: 259,
        stagione: '2026-2027',
        campionato: 'Ragazzi (M/F)',
        fase: 'Qualificazioni',
        girone: 'Girone 6',
        squadra: 'CANOTTIERI MILANO',
      ),
    ], cambiata);
    final segnalazioni = <String>[];
    await _apri(
      tester,
      campionati,
      allenatore: true,
      segnalazioni: segnalazioni,
    );

    expect(find.text(testoSitoFinCambiato), findsOneWidget);
    expect(
      find.text('La classifica non si riesce a leggere dal sito della FIN.'),
      findsOneWidget,
    );
    // Le partite si leggono ancora.
    expect(find.textContaining('vs '), findsNWidgets(2));
    expect(segnalazioni, [
      'c1 · Campionati FIN, girone Ragazzi (M/F) · Qualificazioni · '
          'Girone 6, CMPid 259',
    ]);
  });

  testWidgets('il sito FIN com\'è oggi: nessun avviso, nessuna segnalazione', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final campionati = _CampionatiFinti([
      const GironeCollegato(
        id: 'g1',
        clubId: 'c1',
        gruppoId: 'u14',
        cmpId: 259,
        stagione: '2026-2027',
        campionato: 'Ragazzi (M/F)',
        fase: 'Qualificazioni',
        girone: 'Girone 6',
        squadra: 'CANOTTIERI MILANO',
      ),
    ], paginaGironeVera);
    final segnalazioni = <String>[];
    await _apri(
      tester,
      campionati,
      allenatore: true,
      segnalazioni: segnalazioni,
    );

    expect(find.text(testoSitoFinCambiato), findsNothing);
    expect(find.text('AN BRESCIA TEAM 2'), findsWidgets);
    expect(segnalazioni, isEmpty);
  });
}
