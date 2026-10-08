import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/scheda_bordo_vasca_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Serie _serie(
  int ordine, {
  int ripetute = 4,
  int distanzaM = 100,
  double? ripartenza,
  String? esito,
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: 'nuoto',
  ripartenzaS: ripartenza,
  esito: esito,
);

/// Tiene le serie come le terrebbe il database locale: segnare un esito
/// le aggiorna e lo schermo le rilegge dal flusso.
class _SerieFinta implements SerieRepository {
  _SerieFinta(this.serie);

  List<Serie> serie;
  final segnati = <(String, String?)>[];
  final _flusso = StreamController<List<Serie>>.broadcast();

  Stream<List<Serie>> get flusso async* {
    yield serie;
    yield* _flusso.stream;
  }

  @override
  Future<void> segnaEsito(String id, String? esito) async {
    segnati.add((id, esito));
    serie = [
      for (final s in serie)
        if (s.id == id)
          Serie(
            id: s.id,
            allenamentoId: s.allenamentoId,
            clubId: s.clubId,
            ordine: s.ordine,
            blocco: s.blocco,
            ripetute: s.ripetute,
            distanzaM: s.distanzaM,
            stile: s.stile,
            esecuzione: s.esecuzione,
            ripartenzaS: s.ripartenzaS,
            esito: esito,
          )
        else
          s,
    ];
    _flusso.add(serie);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 10, 8),
);

Widget _app(_SerieFinta repository, Widget figlio) => ProviderScope(
  overrides: [
    serieRepositoryProvider.overrideWithValue(repository),
    serieListProvider.overrideWith((ref, id) => repository.flusso),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
  ],
  child: MaterialApp(theme: AppTheme.scuro, home: figlio),
);

Future<void> _apri(WidgetTester tester, _SerieFinta repository) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(repository, SchedaBordoVascaScreen(allenamento: _allenamento)),
  );
  await tester.pumpAndSettle();
}

/// Chiude la schermata dentro lo stesso ProviderScope: la barra del club
/// si rimette a posto prima che i provider spariscano.
Future<void> _chiudi(WidgetTester tester, _SerieFinta repository) async {
  await tester.pumpWidget(_app(repository, const SizedBox()));
}

void main() {
  testWidgets('"Fatta" e "Saltata" segnano la serie e passano alla dopo', (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1), _serie(2), _serie(3)]);
    await _apri(tester, repository);
    expect(find.text('1 di 3'), findsOneWidget);

    await tester.tap(find.text('Fatta'));
    await tester.pumpAndSettle();
    expect(repository.segnati, [('s1', 'fatta')]);
    expect(find.text('2 di 3'), findsOneWidget);

    await tester.tap(find.text('Saltata'));
    await tester.pumpAndSettle();
    expect(repository.segnati.last, ('s2', 'saltata'));
    expect(find.text('3 di 3'), findsOneWidget);
    expect(find.text('1 serie saltata'), findsOneWidget);
    // La 1 è fatta, la 2 saltata: 400 m su 1.200.
    expect(find.text('400 di 1.200 m'), findsOneWidget);

    // Ritoccando l'esito già segnato lo si toglie, e si resta lì.
    await tester.tap(find.text('Indietro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saltata'));
    await tester.pumpAndSettle();
    expect(repository.segnati.last, ('s2', null));
    expect(find.text('2 di 3'), findsOneWidget);

    await _chiudi(tester, repository);
  });

  testWidgets('l\'orologio conta le ripetute e a fine serie la segna fatta', (
    tester,
  ) async {
    final repository = _SerieFinta([
      _serie(1, ripetute: 2, ripartenza: 60),
      _serie(2),
    ]);
    await _apri(tester, repository);
    expect(find.text("1'00''"), findsOneWidget);

    await tester.tap(find.text('Via'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ripetuta 1 di 2'), findsOneWidget);
    // Appena partiti l'orologio dice "Via".
    expect(find.text('Via'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text("30''"), findsOneWidget);

    await tester.pump(const Duration(seconds: 40));
    expect(find.text('Ripetuta 2 di 2'), findsOneWidget);
    // Alla seconda e ultima si conta alla fine della serie (a 120'').
    expect(find.text('Fine serie tra'), findsOneWidget);
    expect(find.text("50''"), findsOneWidget);

    // Pausa: il tempo si ferma.
    await tester.tap(find.byTooltip('Pausa'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 100));
    expect(find.text('0:10'), findsOneWidget);
    await tester.tap(find.byTooltip('Riprendi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();

    expect(repository.segnati, [('s1', 'fatta')]);
    expect(find.text('2 di 2'), findsOneWidget);
    // Sulla serie nuova l'orologio aspetta il "Via".
    expect(find.text('Via'), findsOneWidget);

    await _chiudi(tester, repository);
  });

  testWidgets('girando lo schermo l\'orologio non riparte da zero', (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1, ripartenza: 90)]);
    await _apri(tester, repository);
    await tester.tap(find.text('Via'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('0:20'), findsOneWidget);

    // Da tre bande a una colonna, come un telefono girato.
    tester.view.physicalSize = const Size(600, 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('0:25'), findsOneWidget);

    await _chiudi(tester, repository);
  });

  testWidgets("sul telefono la serie resta in vista sopra l'orologio", (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1, ripartenza: 90), _serie(2)]);
    await _apri(tester, repository);
    tester.view.physicalSize = const Size(390, 740);
    await tester.pumpAndSettle();

    final serie = find.text('4×100m Libero Nuoto');
    expect(serie, findsOneWidget);
    final via = find.text('Via');
    final schermo = tester.getRect(find.byType(Scaffold).first);
    // La serie si vede tutta, sopra il "Via", dentro lo schermo.
    final rettangolo = tester.getRect(serie);
    expect(rettangolo.height, greaterThan(20));
    expect(rettangolo.bottom, lessThan(tester.getRect(via).top));
    expect(schermo.contains(tester.getRect(via).center), isTrue);
    expect(find.text('1 di 2'), findsOneWidget);
    expect(find.byTooltip('Presenze'), findsOneWidget);

    // Gruppi e suono in un foglio a parte.
    await tester.tap(find.byTooltip('Gruppi e suono'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text("Uno dopo l'altro a"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();

    // Anche con l'orologio che corre la serie si vede.
    await tester.tap(find.text('Via'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(tester.getRect(serie).height, greaterThan(20));
    expect(tester.getRect(serie).bottom, lessThan(schermo.bottom));
    expect(tester.takeException(), isNull);

    await _chiudi(tester, repository);
  });

  testWidgets('partenze sfalsate: si vede quando parte ogni gruppo', (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1, ripartenza: 90)]);
    await _apri(tester, repository);

    await tester.tap(find.text('2'));
    await tester.pump();
    // Il tocco arriva al chip, non al suo testo: niente avviso.
    await tester.tap(find.text("15''"), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('Via'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text("Gruppo 2 tra 12''"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _chiudi(tester, repository);
  });
}
