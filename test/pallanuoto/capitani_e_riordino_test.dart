import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/capitani_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/riordina_numeri_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/cap_badge.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 17),
  squadraCasa: 'Pallanuoto Riviera',
  squadraTrasferta: 'Rari Nantes Bologna',
  numeroMaxConvocati: 15,
);

Atleta _atleta(String id, String cognome, String nome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

/// La riga della distinta: l'id è "d" più il numero di partenza.
DistintaGiocatore _g(
  int numero, {
  bool portiere = false,
  bool capitano = false,
  bool vice = false,
}) => DistintaGiocatore(
  id: 'd$numero',
  partitaId: 'p1',
  atletaId: 'a$numero',
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: capitano,
  viceCapitano: vice,
  portiere: portiere,
  fuoriquota: false,
);

/// Un atleta per ogni riga (a2 → "Cognome2 Nome2"), con nomi che si
/// leggono: i primi hanno quelli veri.
Map<String, Atleta> _atleti(
  List<DistintaGiocatore> convocati, [
  Map<int, (String, String)> nomi = const {},
]) => {
  for (final g in convocati)
    g.atletaId: _atleta(
      g.atletaId,
      nomi[g.numeroCalottina]?.$1 ?? 'Cognome${g.numeroCalottina}',
      nomi[g.numeroCalottina]?.$2 ?? 'Nome${g.numeroCalottina}',
    ),
};

const _nomi = {
  1: ('Rossi', 'Marco'),
  2: ('Bianchi', 'Luca'),
  3: ('Verdi', 'Paolo'),
  4: ('Neri', 'Anna'),
  5: ('Gialli', 'Sara'),
  13: ('Blu', 'Elia'),
};

/// Il database finto: annota le chiamate e, se serve, fallisce.
class _DistintaFinta implements DistintaRepository {
  final capitani = <({String? capitanoId, String? viceId})>[];
  final numeri = <Map<String, int>>[];
  Object? errore;

  @override
  Future<void> scegliCapitani(
    String partitaId, {
    String? capitanoId,
    String? viceId,
  }) async {
    expect(partitaId, 'p1');
    if (errore != null) throw errore!;
    capitani.add((capitanoId: capitanoId, viceId: viceId));
  }

  @override
  Future<void> rinumera(String partitaId, Map<String, int> numeri) async {
    expect(partitaId, 'p1');
    if (errore != null) throw errore!;
    this.numeri.add(numeri);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(
  _DistintaFinta finta, {
  required Widget Function(BuildContext) schermata,
  double scalaTesto = 1,
}) => ProviderScope(
  overrides: [distintaRepositoryProvider.overrideWithValue(finta)],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scalaTesto)),
      child: child!,
    ),
    home: Builder(builder: schermata),
  ),
);

/// Capitano e vice dentro una pagina qualsiasi (come nella distinta).
Widget _appCapitani(
  _DistintaFinta finta,
  List<DistintaGiocatore> convocati, {
  Map<String, Atleta>? atleti,
  double scalaTesto = 1,
}) => _app(
  finta,
  scalaTesto: scalaTesto,
  schermata: (_) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CapitaniDistinta(
        partita: _partita,
        convocati: convocati,
        atletiPerId: atleti ?? _atleti(convocati, _nomi),
      ),
    ),
  ),
);

/// Una pagina con "Apri" che mette in pila il riordino e ricorda cosa
/// restituisce.
Widget _appRiordina(
  _DistintaFinta finta,
  List<DistintaGiocatore> convocati, {
  required List<bool?> risultati,
  Map<String, Atleta>? atleti,
  double scalaTesto = 1,
}) => _app(
  finta,
  scalaTesto: scalaTesto,
  schermata: (context) => Scaffold(
    body: TextButton(
      onPressed: () async {
        risultati.add(
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RiordinaNumeriScreen(
                partita: _partita,
                convocati: convocati,
                atletiPerId: atleti ?? _atleti(convocati, _nomi),
              ),
            ),
          ),
        );
      },
      child: const Text('Apri'),
    ),
  ),
);

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Nel foglio che si apre dal basso (il nome si legge anche nella riga).
Finder _nelFoglio(String testo) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(testo));

/// Le calottine nell'ordine in cui si vedono, dall'alto.
List<int> _numeriVisti(WidgetTester tester) {
  final badge = tester.widgetList<CapBadge>(find.byType(CapBadge)).toList();
  final posti = {
    for (final b in badge) b: tester.getTopLeft(find.byWidget(b)).dy,
  };
  return (badge..sort((a, b) => posti[a]!.compareTo(posti[b]!)))
      .map((b) => b.numero)
      .toList();
}

Future<void> _apriRiordino(WidgetTester tester) async {
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

FilledButton _salva(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Salva i numeri'),
);

void main() {
  final convocati = [
    _g(1, portiere: true),
    _g(2, capitano: true),
    _g(3, vice: true),
    _g(4),
    _g(5),
  ];

  group('Capitano e vice', () {
    testWidgets('si vedono i due ruoli, con "Scegli" per chi manca', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      expect(find.text('Capitano'), findsOneWidget);
      expect(find.text('Bianchi Luca'), findsOneWidget);
      expect(find.text('Vice capitano'), findsOneWidget);
      expect(find.text('Verdi Paolo'), findsOneWidget);
      expect(find.text('Scegli'), findsNothing);

      await tester.pumpWidget(
        _appCapitani(finta, [_g(1, portiere: true), _g(2)]),
      );
      expect(find.text('Scegli'), findsNWidgets(2));
    });

    testWidgets('senza convocati non si vede niente', (tester) async {
      await tester.pumpWidget(_appCapitani(_DistintaFinta(), const []));
      expect(find.text('Capitano'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('un capitano nuovo: il vice resta com\'è', (tester) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Capitano'));
      await tester.pumpAndSettle();
      expect(find.text('Chi è il capitano?'), findsOneWidget);
      // Nessuno in cima, poi per numero; il capitano di oggi è spuntato.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(_nelFoglio('Nessuno'), findsOneWidget);
      final altezze = [
        for (final nome in [
          'Nessuno',
          'Rossi Marco',
          'Bianchi Luca',
          'Verdi Paolo',
          'Neri Anna',
          'Gialli Sara',
        ])
          tester.getTopLeft(_nelFoglio(nome)).dy,
      ];
      expect(altezze, [...altezze]..sort());

      await tester.tap(_nelFoglio('Neri Anna'));
      await tester.pumpAndSettle();

      expect(finta.capitani, [(capitanoId: 'd4', viceId: 'd3')]);
      expect(find.text('Chi è il capitano?'), findsNothing);
    });

    testWidgets('il vice scelto come capitano resta senza vice', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Capitano'));
      await tester.pumpAndSettle();
      // Il foglio dice chi perde il ruolo.
      expect(find.text('Ora è il vice'), findsOneWidget);
      await tester.tap(_nelFoglio('Verdi Paolo'));
      await tester.pumpAndSettle();

      expect(finta.capitani, [(capitanoId: 'd3', viceId: null)]);
    });

    testWidgets('e il capitano scelto come vice lascia il posto', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Vice capitano'));
      await tester.pumpAndSettle();
      expect(find.text('Chi è il vice?'), findsOneWidget);
      expect(find.text('Ora è il capitano'), findsOneWidget);
      await tester.tap(_nelFoglio('Bianchi Luca'));
      await tester.pumpAndSettle();

      expect(finta.capitani, [(capitanoId: null, viceId: 'd2')]);
    });

    testWidgets('"Nessuno" toglie il capitano e lascia il vice', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Capitano'));
      await tester.pumpAndSettle();
      await tester.tap(_nelFoglio('Nessuno'));
      await tester.pumpAndSettle();

      expect(finta.capitani, [(capitanoId: null, viceId: 'd3')]);
    });

    testWidgets('scegliere chi lo è già, o chiudere il foglio, non cambia '
        'niente', (tester) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Capitano'));
      await tester.pumpAndSettle();
      await tester.tap(_nelFoglio('Bianchi Luca'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vice capitano'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // sul velo: chiude
      await tester.pumpAndSettle();

      expect(finta.capitani, isEmpty);
    });

    testWidgets('se il salvataggio fallisce lo dice in un messaggio', (
      tester,
    ) async {
      final finta = _DistintaFinta()..errore = Exception('Rete assente');
      await tester.pumpWidget(_appCapitani(finta, convocati));

      await tester.tap(find.text('Capitano'));
      await tester.pumpAndSettle();
      await tester.tap(_nelFoglio('Neri Anna'));
      await tester.pumpAndSettle();

      expect(find.text('Rete assente'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Riordina i numeri', () {
    // Due portieri e quattro di movimento; 2 capitano, 3 vice.
    final due = [
      _g(1, portiere: true),
      _g(13, portiere: true),
      _g(2, capitano: true),
      _g(3, vice: true),
      _g(4),
      _g(5),
    ];

    testWidgets('i portieri stanno fermi in cima, il resto segue l\'ordine; '
        'senza cambi il pulsante è spento', (tester) async {
      final finta = _DistintaFinta();
      final risultati = <bool?>[];
      await tester.pumpWidget(_appRiordina(finta, due, risultati: risultati));
      await _apriRiordino(tester);

      expect(find.text('Riordina i numeri'), findsOneWidget);
      expect(
        find.text(
          'Trascina le righe: il numero segue la posizione. '
          'I portieri restano all\'1 e al 13.',
        ),
        findsOneWidget,
      );
      expect(_numeriVisti(tester), [1, 13, 2, 3, 4, 5]);
      // Due lucchetti, e una maniglia per ognuno degli altri.
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(4));
      // I segni di capitano e vice stanno sulle loro righe.
      expect(find.byType(SegnoFascia), findsNWidgets(2));
      expect(
        find.descendant(of: find.byType(SegnoFascia), matching: find.text('C')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(SegnoFascia), matching: find.text('V')),
        findsOneWidget,
      );
      expect(_salva(tester).onPressed, isNull);
    });

    testWidgets('chi non vede legge "Capitano" e "Vice capitano" sui segni', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _appRiordina(_DistintaFinta(), due, risultati: <bool?>[]),
      );
      await _apriRiordino(tester);

      // Il segno si legge insieme al nome della riga.
      expect(find.bySemanticsLabel(RegExp('Capitano')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Vice capitano')), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('con i pulsanti una riga sale sopra l\'altra e si salvano '
        'solo i numeri che cambiano', (tester) async {
      final finta = _DistintaFinta();
      final risultati = <bool?>[];
      await tester.pumpWidget(_appRiordina(finta, due, risultati: risultati));
      await _apriRiordino(tester);

      // Neri (4) è la terza fra gli altri: due volte "Sposta su".
      await tester.tap(find.byTooltip('Sposta su').at(2));
      await tester.pump();
      await tester.tap(find.byTooltip('Sposta su').at(1));
      await tester.pumpAndSettle();

      // Neri ha il 2, Bianchi il 3, Verdi il 4, Gialli resta al 5.
      expect(_numeriVisti(tester), [1, 13, 2, 3, 4, 5]);
      expect(find.text('Neri Anna'), findsOneWidget);
      expect(find.text('Era il 4'), findsOneWidget);
      expect(find.text('Era il 2'), findsOneWidget);
      expect(find.text('Era il 3'), findsOneWidget);
      expect(find.text('Era il 5'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Neri Anna')).dy,
        lessThan(tester.getTopLeft(find.text('Bianchi Luca')).dy),
      );
      expect(_salva(tester).onPressed, isNotNull);

      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();

      // I portieri non si toccano, Gialli neppure.
      expect(finta.numeri, [
        {'d4': 2, 'd2': 3, 'd3': 4},
      ]);
      expect(risultati, [true]);
      expect(find.text('Riordina i numeri'), findsNothing);
    });

    testWidgets('trascinando la maniglia si ottiene lo stesso', (tester) async {
      // Uno schermo alto: tutte le righe sopra la barra di «Salva».
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final finta = _DistintaFinta();
      final risultati = <bool?>[];
      await tester.pumpWidget(_appRiordina(finta, due, risultati: risultati));
      await _apriRiordino(tester);

      // Dall'ultima (Gialli, 5) sopra la prima (Bianchi, 2).
      final maniglia = find.byIcon(Icons.drag_indicator).at(3);
      final inizio = tester.getCenter(maniglia);
      final arrivo = tester.getCenter(find.byIcon(Icons.drag_indicator).at(0));
      final gesto = await tester.startGesture(inizio);
      await tester.pump(kLongPressTimeout);
      // A piccoli passi, come un dito vero.
      const passi = 12;
      final dy = (arrivo.dy - inizio.dy - 20) / passi;
      for (var i = 0; i < passi; i++) {
        await gesto.moveBy(Offset(0, dy));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesto.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();

      // Gialli 2, Bianchi 3, Verdi 4, Neri 5.
      expect(finta.numeri, [
        {'d5': 2, 'd2': 3, 'd3': 4, 'd4': 5},
      ]);
      expect(risultati, [true]);
    });

    testWidgets('rimettere le righe com\'erano spegne di nuovo il pulsante', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      await tester.pumpWidget(_appRiordina(finta, due, risultati: <bool?>[]));
      await _apriRiordino(tester);

      await tester.tap(find.byTooltip('Sposta giù').at(0));
      await tester.pump();
      expect(_salva(tester).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Sposta su').at(1));
      await tester.pump();
      expect(_salva(tester).onPressed, isNull);
      expect(find.textContaining('Era il'), findsNothing);
    });

    testWidgets('con un portiere solo gli altri vanno da 2 senza buchi, '
        'anche sul 13', (tester) async {
      final finta = _DistintaFinta();
      final risultati = <bool?>[];
      // Lo schermo è alto: le quindici righe stanno tutte in vista.
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Il portiere e 13 di movimento col 13 saltato: 2…12, 14, 15.
      final uno = [
        _g(1, portiere: true),
        for (var n = 2; n <= 12; n++) _g(n),
        _g(14),
        _g(15),
      ];
      await tester.pumpWidget(_appRiordina(finta, uno, risultati: risultati));
      await _apriRiordino(tester);

      // Il buco si chiude da solo: il pulsante è già acceso.
      expect(_salva(tester).onPressed, isNotNull);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Era il 14'), findsOneWidget);
      expect(find.text('Era il 15'), findsOneWidget);

      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();

      expect(finta.numeri, [
        {'d14': 13, 'd15': 14},
      ]);
      expect(risultati, [true]);
    });

    testWidgets('un terzo portiere si trascina come gli altri', (tester) async {
      final finta = _DistintaFinta();
      final tre = [
        _g(1, portiere: true),
        _g(13, portiere: true),
        _g(14, portiere: true),
        _g(2),
        _g(3),
      ];
      await tester.pumpWidget(_appRiordina(finta, tre, risultati: <bool?>[]));
      await _apriRiordino(tester);

      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));
      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();

      // Il terzo portiere (14) è l'ultimo della lista: diventa il 4.
      expect(finta.numeri, [
        {'d14': 4},
      ]);
    });

    testWidgets('se salvare non riesce l\'errore resta nella pagina', (
      tester,
    ) async {
      final finta = _DistintaFinta()..errore = Exception('Rete assente');
      final risultati = <bool?>[];
      await tester.pumpWidget(_appRiordina(finta, due, risultati: risultati));
      await _apriRiordino(tester);

      await tester.tap(find.byTooltip('Sposta giù').at(0));
      await tester.pump();
      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();

      expect(
        find.text('Non è stato possibile salvare i numeri.'),
        findsOneWidget,
      );
      expect(find.text('Riordina i numeri'), findsOneWidget);
      expect(risultati, isEmpty);
      // Si può riprovare.
      expect(_salva(tester).onPressed, isNotNull);

      finta.errore = null;
      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();
      expect(risultati, [true]);
      expect(finta.numeri, hasLength(1));
    });

    testWidgets('uscendo con delle modifiche chiede, e senza no', (
      tester,
    ) async {
      final finta = _DistintaFinta();
      final risultati = <bool?>[];
      await tester.pumpWidget(_appRiordina(finta, due, risultati: risultati));

      // Niente di spostato: si esce subito.
      await _apriRiordino(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Riordina i numeri'), findsNothing);
      expect(find.text('Uscire senza salvare?'), findsNothing);

      // Spostato: prima chiede, "Resta" lascia tutto com'è.
      await _apriRiordino(tester);
      await tester.tap(find.byTooltip('Sposta giù').at(0));
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Uscire senza salvare?'), findsOneWidget);
      await tester.tap(find.text('Resta'));
      await tester.pumpAndSettle();
      expect(find.text('Riordina i numeri'), findsOneWidget);
      expect(find.text('Uscire senza salvare?'), findsNothing);

      // "Esci senza salvare" chiude, senza salvare niente.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esci senza salvare'));
      await tester.pumpAndSettle();
      expect(find.text('Riordina i numeri'), findsNothing);
      expect(finta.numeri, isEmpty);
      expect(risultati, [null, null]);
    });
  });

  group('Su un telefono stretto', () {
    // Nomi lunghi, ruoli e testo ingrandito: niente deve uscire dalle righe.
    final lunghi = [
      _g(1, portiere: true),
      _g(13, portiere: true),
      for (var n = 2; n <= 12; n++) _g(n, capitano: n == 2, vice: n == 3),
    ];
    final nomiLunghi = {
      for (final g in lunghi)
        g.atletaId: _atleta(
          g.atletaId,
          'Di Bartolomeo Castelnuovo${g.numeroCalottina}',
          'Gianalessandro Maria',
        ),
    };

    testWidgets('capitano e vice, con il foglio aperto', (tester) async {
      _telefono(tester);
      final finta = _DistintaFinta();
      await tester.pumpWidget(
        _appCapitani(finta, lunghi, atleti: nomiLunghi, scalaTesto: 1.3),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Vice capitano'));
      await tester.pumpAndSettle();
      expect(find.text('Chi è il vice?'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // L'elenco è lungo: scorre dentro il foglio e si arriva all'ultimo.
      await tester.scrollUntilVisible(
        find.textContaining('Castelnuovo12'),
        200,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('riordino', (tester) async {
      _telefono(tester);
      final finta = _DistintaFinta();
      await tester.pumpWidget(
        _appRiordina(
          finta,
          lunghi,
          risultati: <bool?>[],
          atleti: nomiLunghi,
          scalaTesto: 1.3,
        ),
      );
      await _apriRiordino(tester);
      expect(tester.takeException(), isNull);

      // Il carattere dei test è largo il doppio del vero: i nomi vanno a
      // capo molte volte e le righe da spostare stanno più in basso.
      await tester.scrollUntilVisible(
        find.byTooltip('Sposta giù'),
        200,
        scrollable: find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);

      // Con qualcosa di spostato compaiono "Era il…" e l'errore: stanno
      // dentro lo schermo anche loro.
      finta.errore = Exception('Rete assente');
      // Ancora un po' in su: la riga trovata può stare sotto la barra.
      await tester.drag(
        find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Scrollable),
        ),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sposta giù').hitTestable().first);
      await tester.pump();
      await tester.tap(find.text('Salva i numeri'));
      await tester.pumpAndSettle();
      expect(
        find.text('Non è stato possibile salvare i numeri.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Ogni riga è alta almeno quanto un bersaglio da toccare.
      final riga = find
          .ancestor(
            of: find.byType(CapBadge).first,
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(riga).height, greaterThanOrEqualTo(48));
    });
  });
}
