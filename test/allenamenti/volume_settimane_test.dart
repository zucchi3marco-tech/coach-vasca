import 'package:coach_vasca/core/supabase/leggi_a_pagine.dart';
import 'package:coach_vasca/core/utils/giorni.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/allenamenti_list_screen.dart';
import 'package:coach_vasca/features/allenamenti/presentation/riepilogo_volumi.dart';
import 'package:coach_vasca/features/allenamenti/presentation/volume_settimane.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Serie _serie(
  String allenamentoId,
  int ripetute, {
  int? distanzaM,
  int? durataS,
  String? esito,
}) => Serie(
  id: '$allenamentoId-$ripetute-$distanzaM-$durataS',
  allenamentoId: allenamentoId,
  clubId: 'c1',
  ordine: 1,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: durataS == null ? 'nuoto' : 'palleggio',
  esito: esito,
);

Allenamento _allenamento(String id, DateTime data, {String? titolo}) =>
    Allenamento(id: id, clubId: 'c1', data: data, titolo: titolo);

Widget _app(Widget figlio) => MaterialApp(
  theme: AppTheme.chiaro,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: figlio,
);

void main() {
  group('volume degli allenamenti e delle settimane', () {
    test('metri e lavoro a tempo per allenamento, anche le saltate', () {
      final volumi = volumiPerAllenamento([
        _serie('a1', 8, distanzaM: 100),
        _serie('a1', 3, durataS: 300),
        _serie('a1', 4, distanzaM: 50, esito: 'saltata'),
        _serie('a2', 2, durataS: 600),
      ]);
      expect(volumi['a1']!.metri, 1000);
      expect(volumi['a1']!.secondi, 900);
      expect(volumi['a2']!.metri, 0);
      expect(volumi['a2']!.secondi, 1200);
      expect(volumi.containsKey('a3'), isFalse);
    });

    test('il lunedì della settimana, anche col cambio dell\'ora', () {
      // Domenica 25 ottobre 2026 dura 25 ore.
      expect(lunediDi(DateTime(2026, 10, 25, 18)), DateTime(2026, 10, 19));
      expect(lunediDi(DateTime(2026, 10, 26)), DateTime(2026, 10, 26));
      expect(lunediDi(DateTime(2026, 10, 8)), DateTime(2026, 10, 5));
    });

    test('la somma di ogni settimana, con quanti allenamenti', () {
      final settimane = volumiPerSettimana(
        [
          _allenamento('a1', DateTime(2026, 10, 5)),
          _allenamento('a2', DateTime(2026, 10, 11)),
          _allenamento('a3', DateTime(2026, 10, 12)),
          // Senza serie: conta come allenamento, a zero metri.
          _allenamento('a4', DateTime(2026, 10, 13)),
        ],
        {
          'a1': const VolumeAllenamento(metri: 4000),
          'a2': const VolumeAllenamento(metri: 3000, secondi: 1200),
          'a3': const VolumeAllenamento(metri: 5000),
        },
      );
      expect(settimane[DateTime(2026, 10, 5)]!.volume.metri, 7000);
      expect(settimane[DateTime(2026, 10, 5)]!.volume.secondi, 1200);
      expect(settimane[DateTime(2026, 10, 5)]!.allenamenti, 2);
      expect(settimane[DateTime(2026, 10, 12)]!.volume.metri, 5000);
      expect(settimane[DateTime(2026, 10, 12)]!.allenamenti, 2);
    });

    test('come si scrive il volume', () {
      expect(etichettaVolume(VolumeAllenamento.zero), isNull);
      expect(etichettaVolume(const VolumeAllenamento(metri: 4200)), '4.200 m');
      expect(
        etichettaVolume(const VolumeAllenamento(metri: 4200, secondi: 1200)),
        "4.200 m + 20'",
      );
      expect(etichettaVolume(const VolumeAllenamento(secondi: 3600)), '1h');
    });
  });

  test('oltre le 1000 righe si legge a pagine fino all\'ultima', () async {
    final richieste = <(int, int)>[];
    final righe = await leggiAPagine((da, a) async {
      richieste.add((da, a));
      final fine = a < 2499 ? a : 2499;
      return [
        for (var i = da; i <= fine; i++) {'i': i},
      ];
    });
    expect(righe, hasLength(2500));
    expect(richieste, [(0, 999), (1000, 1999), (2000, 2999)]);
  });

  group('grafico del volume per settimana', () {
    // Giovedì 8 ottobre 2026: questa settimana parte lunedì 5.
    final oggi = DateTime(2026, 10, 8);
    final allenamenti = [
      _allenamento('scorsa', DateTime(2026, 9, 29)),
      _allenamento('lun', DateTime(2026, 10, 5)),
      _allenamento('gio', DateTime(2026, 10, 8)),
      _allenamento('prossima', DateTime(2026, 10, 13)),
    ];
    const volumi = {
      'scorsa': VolumeAllenamento(metri: 4000),
      'lun': VolumeAllenamento(metri: 2400),
      'gio': VolumeAllenamento(metri: 2600, secondi: 1200),
      'prossima': VolumeAllenamento(metri: 6000),
    };

    testWidgets('questa settimana scelta, i km sopra le colonne', (
      tester,
    ) async {
      DateTime? aperta;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: VolumeSettimane(
              allenamenti: allenamenti,
              volumi: volumi,
              oggi: oggi,
              onApriSettimana: (lunedi) => aperta = lunedi,
            ),
          ),
        ),
      );

      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('6.0'), findsOneWidget);
      expect(find.text('5 ott'), findsWidgets);
      expect(find.text('Questa settimana · 5–11 ott'), findsOneWidget);
      expect(find.text("5.000 m + 20'"), findsOneWidget);
      expect(
        find.text('2 allenamenti · +25% di metri sulla settimana prima'),
        findsOneWidget,
      );

      await tester.tap(find.text('Apri la settimana'));
      expect(aperta, DateTime(2026, 10, 5));

      // La settimana prossima: in programma, un allenamento.
      await tester.tap(find.text('6.0'));
      await tester.pump();
      expect(find.text('Settimana prossima · 12–18 ott'), findsOneWidget);
      expect(find.text('6.000 m'), findsOneWidget);
      expect(
        find.text('1 allenamento · +20% di metri sulla settimana prima'),
        findsOneWidget,
      );

      // A cavallo di due mesi; senza la settimana prima, nessun confronto.
      await tester.tap(find.text('4.0'));
      await tester.pump();
      expect(find.text('Settimana scorsa · 28 set – 4 ott'), findsOneWidget);
      expect(find.text('1 allenamento'), findsOneWidget);
    });

    testWidgets('le frecce spostano le settimane', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: VolumeSettimane(
              allenamenti: allenamenti,
              volumi: volumi,
              oggi: oggi,
              onApriSettimana: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('km dal 31 ago al 25 ott'), findsOneWidget);
      await tester.tap(find.byTooltip('Settimane dopo'));
      await tester.pump();
      expect(find.text('km dal 28 set al 22 nov'), findsOneWidget);
      // La scelta si sposta con la finestra.
      expect(find.text('Settimana dal 2 nov · 2–8 nov'), findsOneWidget);
      expect(find.text('Nessun allenamento'), findsOneWidget);
      expect(find.text('Apri la settimana'), findsNothing);
    });
  });

  testWidgets('nell\'elenco il volume sta accanto al titolo', (tester) async {
    final oggi = soloData(DateTime.now());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value([
              _allenamento('a1', oggi, titolo: 'Aerobico'),
              _allenamento('a2', aggiungiGiorni(oggi, 2), titolo: 'Palleggio'),
            ]),
          ),
          volumiAllenamentiProvider.overrideWith(
            (ref, clubId) => Stream.value(const {
              'a1': VolumeAllenamento(metri: 4200, secondi: 1200),
              'a2': VolumeAllenamento(secondi: 2700),
            }),
          ),
          gruppiListProvider.overrideWith(
            (ref, clubId) => Stream.value(const <Gruppo>[]),
          ),
        ],
        child: _app(const AllenamentiListScreen(clubId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aerobico'), findsOneWidget);
    expect(find.text('4.200 m'), findsOneWidget);
    expect(find.text("+ 20'"), findsOneWidget);
    expect(find.text('Volume per settimana'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Palleggio'), 300);
    expect(find.text("45'"), findsOneWidget);
  });
}
