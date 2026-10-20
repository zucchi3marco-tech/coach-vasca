import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/application/passo_riferimento_provider.dart';
import 'package:coach_vasca/features/allenamenti/data/modifiche_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/allenamento_detail_screen.dart';
import 'package:coach_vasca/features/allenamenti/presentation/card_com_e_andata.dart';
import 'package:coach_vasca/features/allenamenti/presentation/com_e_andata.dart';
import 'package:coach_vasca/features/allenamenti/presentation/com_e_andata_screen.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// «Com'è andata» nel dettaglio dell'allenamento: la scheda con quanto è
// stato fatto, e la schermata per segnarlo serie per serie.

Serie _s(
  String id,
  int ordine, {
  int ripetute = 1,
  int? distanzaM,
  int? durataS,
  String? zona,
  String? esito,
  int? metriFatti,
  int? secondiFatti,
  Destinatari destinatari = Destinatari.tutti,
  String? momentoId,
}) => Serie(
  id: id,
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: durataS == null ? 'nuoto' : 'partita',
  zona: zona,
  esito: esito,
  metriFatti: metriFatti,
  secondiFatti: secondiFatti,
  destinatari: destinatari,
  momentoId: momentoId,
);

/// Le serie come le terrebbe il database locale, e cosa si segna.
class _SerieFinte implements SerieRepository {
  _SerieFinte(this.serie);

  List<Serie> serie;
  final esiti = <(String, String?)>[];
  final fatti = <(String, String?, int?, int?)>[];
  final _flusso = StreamController<List<Serie>>.broadcast();

  Stream<List<Serie>> osserva() async* {
    yield serie;
    yield* _flusso.stream;
  }

  void _aggiorna(String id, String? esito, int? metri, int? secondi) {
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
            durataS: s.durataS,
            stile: s.stile,
            esecuzione: s.esecuzione,
            zona: s.zona,
            destinatari: s.destinatari,
            momentoId: s.momentoId,
            esito: esito,
            metriFatti: esito == 'fatta' ? metri : null,
            secondiFatti: esito == 'fatta' ? secondi : null,
          )
        else
          s,
    ];
    _flusso.add(serie);
  }

  @override
  Future<void> segnaEsito(String id, String? esito) async {
    esiti.add((id, esito));
    _aggiorna(id, esito, null, null);
  }

  @override
  Future<void> segnaFatto(
    String id, {
    required String? esito,
    int? metriFatti,
    int? secondiFatti,
  }) async {
    fatti.add((id, esito, metriFatti, secondiFatti));
    _aggiorna(id, esito, metriFatti, secondiFatti);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Nessuna modifica da controllare: la fascia sotto la testata resta vuota.
class _ModificheVuote implements ModificheRepository {
  @override
  Future<List<ModificaAllenamento>> daControllare(String clubId) async => [];

  @override
  Future<ModificaAllenamento?> aperta(String allenamentoId) async => null;

  @override
  Future<void> segnaVista(String id) async {}
}

Allenamento _allenamento(DateTime data) =>
    Allenamento(id: 'a1', clubId: 'c1', data: data, titolo: 'Misto');

final _passato = _allenamento(DateTime(2020, 1, 15));

Widget _intorno(ThemeData tema, Widget figlio, {_SerieFinte? registro}) =>
    ProviderScope(
      overrides: [
        if (registro != null) ...[
          serieRepositoryProvider.overrideWithValue(registro),
          modificheRepositoryProvider.overrideWithValue(_ModificheVuote()),
          serieListProvider.overrideWith((ref, id) => registro.osserva()),
        ],
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        atletiListProvider.overrideWith((ref, chiave) => Stream.value([])),
        passoRiferimentoProvider.overrideWith((ref, chiave) => null),
      ],
      child: MaterialApp(
        theme: tema,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
            // L'acqua animata della testata non si ferma mai.
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: figlio,
      ),
    );

/// Il bottone con questa parola (e non la riga che dice com'è andata).
Finder _bottone(String parola) => find.widgetWithText(OutlinedButton, parola);

void _schermo(WidgetTester tester, Size misura) {
  tester.view.physicalSize = misura;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _card(
  List<Serie> serie, {
  Allenamento? allenamento,
  VoidCallback? onSegna,
}) => Scaffold(
  body: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: CardComEAndata(
      allenamento: allenamento ?? _passato,
      serie: serie,
      onSegna: onSegna ?? () {},
    ),
  ),
);

/// 10x100 con 6 fatte (zona A), una da 400 saltata (zona B), una da 200
/// che non si è segnata (senza zona).
List<Serie> _esempio() => [
  _s(
    'a',
    1,
    ripetute: 10,
    distanzaM: 100,
    zona: 'A2',
    esito: 'fatta',
    metriFatti: 600,
  ),
  _s('b', 2, distanzaM: 400, zona: 'B1', esito: 'saltata'),
  _s('c', 3, distanzaM: 200),
];

void main() {
  for (final (nome, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('la scheda «Com\'è andata» a 360 px, testo al 130%, tema $nome', () {
      testWidgets('quanto fatto, quante in parte e saltate, e le zone', (
        tester,
      ) async {
        _schermo(tester, const Size(360, 900));
        await tester.pumpWidget(_intorno(tema, _card(_esempio())));
        expect(tester.takeException(), isNull);

        expect(find.text("Com'è andata"), findsOneWidget);
        // 600 + 0 + 200 su 1000 + 400 + 200.
        expect(find.text('Fatti 800 di 1.600 m'), findsOneWidget);
        expect(find.text('1 in parte · 1 saltata'), findsOneWidget);
        expect(
          find.text('Nessuna serie segnata: contano come scritte.'),
          findsNothing,
        );

        // Una riga per famiglia di zona: lo scritto, il fatto e lo scarto.
        expect(find.text('Zona A'), findsOneWidget);
        expect(find.text('600 di 1.000 m'), findsOneWidget);
        expect(find.text('Zona B'), findsOneWidget);
        expect(find.text('0 di 400 m'), findsOneWidget);
        expect(find.text('−400'), findsNWidgets(2));
        expect(find.text('Senza zona'), findsOneWidget);
        expect(find.text('200 di 200 m'), findsOneWidget);
        expect(find.text('Zona C'), findsNothing);
        expect(find.text('Zona D'), findsNothing);
        // Le zone nell'ordine A, B, senza zona.
        final y = [
          for (final t in ['Zona A', 'Zona B', 'Senza zona'])
            tester.getTopLeft(find.text(t)).dy,
        ];
        expect(y, orderedEquals([...y]..sort()));

        expect(find.text("Segna com'è andata"), findsOneWidget);
        final bottone = find.ancestor(
          of: find.text("Segna com'è andata"),
          matching: find.byType(OutlinedButton),
        );
        expect(tester.getSize(bottone).height, greaterThanOrEqualTo(48));
      });

      testWidgets('il lavoro a tempo accanto ai metri', (tester) async {
        _schermo(tester, const Size(360, 900));
        await tester.pumpWidget(
          _intorno(
            tema,
            _card([
              _s(
                'a',
                1,
                ripetute: 6,
                durataS: 300,
                zona: 'C1',
                esito: 'fatta',
                secondiFatti: 1500,
              ),
              _s('b', 2, distanzaM: 400, zona: 'C2', esito: 'fatta'),
            ]),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text("Fatti 400 di 400 m · 25' di 30' a tempo"),
          findsOneWidget,
        );
        expect(find.text('1 in parte'), findsOneWidget);
        // C1 e C2 sono una famiglia sola, con lo scarto in minuti.
        expect(find.text('Zona C'), findsOneWidget);
        expect(find.text("400 di 400 m · 25' di 30'"), findsOneWidget);
        expect(find.text("−5'"), findsOneWidget);
      });

      testWidgets('niente segnato: contano come scritte', (tester) async {
        _schermo(tester, const Size(360, 900));
        await tester.pumpWidget(
          _intorno(
            tema,
            _card([
              _s('a', 1, ripetute: 4, distanzaM: 100, zona: 'A1'),
              _s('b', 2, distanzaM: 400, zona: 'B1'),
            ]),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Fatti 800 di 800 m'), findsOneWidget);
        expect(
          find.text('Nessuna serie segnata: contano come scritte.'),
          findsOneWidget,
        );
        expect(find.textContaining('in parte'), findsNothing);
        expect(find.textContaining('saltat'), findsNothing);
      });

      testWidgets('il lavoro dei soli portieri non conta per il gruppo', (
        tester,
      ) async {
        _schermo(tester, const Size(360, 900));
        await tester.pumpWidget(
          _intorno(
            tema,
            _card([
              _s('a', 1, distanzaM: 400, zona: 'A1', esito: 'fatta'),
              _s(
                'p',
                2,
                distanzaM: 800,
                zona: 'A1',
                esito: 'saltata',
                destinatari: Destinatari.portieri,
              ),
            ]),
          ),
        );
        expect(find.text('Fatti 400 di 400 m'), findsOneWidget);
        expect(find.textContaining('saltat'), findsNothing);
      });

      testWidgets('il pulsante apre la schermata per segnare', (tester) async {
        _schermo(tester, const Size(360, 900));
        var aperta = 0;
        await tester.pumpWidget(
          _intorno(tema, _card(_esempio(), onSegna: () => aperta++)),
        );
        await tester.tap(find.text("Segna com'è andata"));
        expect(aperta, 1);
      });
    });
  }

  group('quando c\'è la scheda', () {
    final oggi = DateTime.now();

    testWidgets('per un allenamento passato e per quello di oggi', (
      tester,
    ) async {
      _schermo(tester, const Size(360, 900));
      for (final data in [
        DateTime(2020, 1, 15),
        oggi.subtract(const Duration(days: 1)),
        DateTime(oggi.year, oggi.month, oggi.day), // mezzanotte di oggi
        DateTime(oggi.year, oggi.month, oggi.day, 23, 59), // stasera
      ]) {
        await tester.pumpWidget(
          _intorno(
            AppTheme.chiaro,
            _card(_esempio(), allenamento: _allenamento(data)),
          ),
        );
        expect(find.text("Com'è andata"), findsOneWidget, reason: '$data');
      }
    });

    testWidgets('non per domani né senza serie', (tester) async {
      _schermo(tester, const Size(360, 900));
      await tester.pumpWidget(
        _intorno(
          AppTheme.chiaro,
          _card(
            _esempio(),
            allenamento: _allenamento(oggi.add(const Duration(days: 1))),
          ),
        ),
      );
      expect(find.text("Com'è andata"), findsNothing);
      expect(find.text("Segna com'è andata"), findsNothing);

      await tester.pumpWidget(_intorno(AppTheme.chiaro, _card(const [])));
      expect(find.text("Com'è andata"), findsNothing);
    });
  });

  group('nel dettaglio dell\'allenamento', () {
    Future<_SerieFinte> apri(
      WidgetTester tester,
      ThemeData tema,
      List<Serie> serie, {
      Size misura = const Size(1000, 3000),
    }) async {
      _schermo(tester, misura);
      final registro = _SerieFinte(serie);
      await tester.pumpWidget(
        _intorno(
          tema,
          AllenamentoDetailScreen(allenamento: _passato),
          registro: registro,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return registro;
    }

    testWidgets('la scheda sta fra il riepilogo e l\'elenco delle serie', (
      tester,
    ) async {
      await apri(tester, AppTheme.chiaro, _esempio());
      expect(tester.takeException(), isNull);
      expect(find.text('Fatti 800 di 1.600 m'), findsOneWidget);
      // Sopra la prima serie dell'elenco, sotto il titolo «Serie».
      final scheda = tester.getTopLeft(find.text("Com'è andata")).dy;
      final titoloSerie = tester.getTopLeft(find.byType(TitoloSezione)).dy;
      final primaRiga = tester.getTopLeft(find.textContaining('10×100m')).dy;
      expect(titoloSerie, lessThan(scheda));
      expect(scheda, lessThan(primaRiga));
      // La riga di prima non c'è più nel riepilogo dei blocchi.
      expect(find.textContaining('svolti'), findsNothing);
    });

    testWidgets('«Segna com\'è andata» apre la schermata, e segnare aggiorna '
        'anche la scheda', (tester) async {
      final registro = await apri(tester, AppTheme.scuro, [
        _s('a', 1, ripetute: 10, distanzaM: 100, zona: 'A2'),
        _s('b', 2, distanzaM: 400, zona: 'B1'),
      ]);
      expect(find.text('Fatti 1.400 di 1.400 m'), findsOneWidget);
      await tester.tap(find.text("Segna com'è andata"));
      await tester.pumpAndSettle();
      expect(find.byType(ComEAndataScreen), findsOneWidget);

      // Le 10x100 fatte in parte: 6 ripetute.
      await tester.tap(_bottone('In parte').first);
      await tester.pumpAndSettle();
      expect(find.text('Quante ripetute di 10?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(SceltaInParteFoglio),
          matching: find.text('6'),
        ),
      );
      await tester.pumpAndSettle();
      expect(registro.fatti, [('a', 'fatta', 600, null)]);
      // La 400 saltata.
      await tester.tap(_bottone('Saltata').last);
      await tester.pumpAndSettle();
      expect(registro.esiti, [('b', 'saltata')]);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ComEAndataScreen), findsNothing);
      expect(find.text('Fatti 600 di 1.400 m'), findsOneWidget);
      expect(find.text('1 in parte · 1 saltata'), findsOneWidget);
      // E nell'elenco, la riga dice che è in parte.
      expect(find.textContaining('in parte · 6 di 10'), findsOneWidget);
    });

    testWidgets('ogni riga dell\'elenco dice com\'è andata', (tester) async {
      await apri(tester, AppTheme.chiaro, [
        _s('p1', 1, ripetute: 4, distanzaM: 50, esito: 'fatta'),
        _s(
          'p2',
          2,
          ripetute: 4,
          distanzaM: 100,
          esito: 'fatta',
          metriFatti: 200,
        ),
        _s(
          'p3',
          3,
          ripetute: 6,
          durataS: 300,
          secondiFatti: 720,
          esito: 'fatta',
        ),
        _s('p4', 4, ripetute: 4, distanzaM: 50, esito: 'saltata'),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('fatta ·'), findsOneWidget);
      expect(find.textContaining('in parte · 2 di 4'), findsOneWidget);
      expect(find.textContaining("in parte · 12' di 30'"), findsOneWidget);
      expect(find.textContaining('saltata ·'), findsOneWidget);
    });

    testWidgets('anche dentro un lavoro in parallelo, a 360 px', (
      tester,
    ) async {
      await apri(tester, AppTheme.chiaro, [
        _s(
          'm1',
          1,
          ripetute: 10,
          distanzaM: 25,
          esito: 'fatta',
          metriFatti: 150,
          momentoId: 'm',
        ),
        _s(
          'm2',
          2,
          ripetute: 3,
          durataS: 360,
          esito: 'saltata',
          destinatari: Destinatari.portieri,
          momentoId: 'm',
        ),
      ], misura: const Size(360, 3000));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('In parallelo'), findsOneWidget);
      expect(find.text('in parte · 6 di 10'), findsOneWidget);
    });

    testWidgets('una piramide dice quante sono fatte, in parte e saltate', (
      tester,
    ) async {
      Serie riga(String id, int ordine, String? esito, {int? metriFatti}) =>
          Serie(
            id: id,
            allenamentoId: 'a1',
            clubId: 'c1',
            ordine: ordine,
            blocco: 'principale',
            ripetute: 2,
            distanzaM: 100,
            stile: 'libero',
            esecuzione: 'nuoto',
            piramideId: 'g1',
            esito: esito,
            metriFatti: metriFatti,
          );
      await apri(tester, AppTheme.chiaro, [
        riga('g1a', 1, 'fatta'),
        riga('g1b', 2, 'fatta', metriFatti: 100),
        riga('g1c', 3, 'saltata'),
        riga('g1d', 4, null),
      ]);
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('1 fatta, 1 in parte, 1 saltata'),
        findsOneWidget,
      );
    });
  });

  for (final (nome, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('la schermata per segnare a 360 px, testo al 130%, tema $nome', () {
      Future<_SerieFinte> apri(WidgetTester tester, List<Serie> serie) async {
        _schermo(tester, const Size(360, 3000));
        final registro = _SerieFinte(serie);
        await tester.pumpWidget(
          _intorno(
            tema,
            ComEAndataScreen(allenamento: _passato),
            registro: registro,
          ),
        );
        await tester.pumpAndSettle();
        return registro;
      }

      testWidgets('tutte le serie in ordine, ognuna con tre bottoni da 48', (
        tester,
      ) async {
        await apri(tester, [
          _s('a', 1, ripetute: 10, distanzaM: 100, zona: 'A2'),
          _s(
            'p',
            2,
            ripetute: 4,
            distanzaM: 50,
            zona: 'A1',
            destinatari: Destinatari.portieri,
          ),
          _s('t', 3, ripetute: 6, durataS: 300, zona: 'C1'),
          _s('c', 4, distanzaM: 25),
        ]);
        expect(tester.takeException(), isNull);
        expect(find.text("Com'è andata"), findsOneWidget);
        expect(find.textContaining('10×100m'), findsOneWidget);
        expect(find.textContaining('4×50m'), findsOneWidget);
        expect(find.textContaining('6×5'), findsOneWidget);
        // Per chi è la serie dei portieri.
        expect(find.text('Portieri'), findsOneWidget);
        // Tre bottoni per le prime tre; la 1x25 non ha «In parte».
        expect(find.text('Fatta'), findsNWidgets(4));
        expect(find.text('Saltata'), findsNWidgets(4));
        expect(find.text('In parte'), findsNWidgets(3));
        for (final parola in ['Fatta', 'In parte', 'Saltata']) {
          final bottoni = find.ancestor(
            of: find.text(parola),
            matching: find.byType(OutlinedButton),
          );
          for (final b in bottoni.evaluate()) {
            expect(
              tester.getSize(find.byWidget(b.widget)).height,
              greaterThanOrEqualTo(48),
              reason: parola,
            );
          }
        }
        // L'ordine è quello della seduta.
        final y = [
          for (final t in ['10×100m', '4×50m', '6×5', '1×25m'])
            tester.getTopLeft(find.textContaining(t)).dy,
        ];
        expect(y, orderedEquals([...y]..sort()));
      });

      testWidgets('si segna fatta, in parte e saltata, e la riga lo dice', (
        tester,
      ) async {
        final registro = await apri(tester, [
          _s('a', 1, ripetute: 10, distanzaM: 100, zona: 'A2'),
          _s('b', 2, ripetute: 6, durataS: 300, zona: 'C1'),
          _s('c', 3, distanzaM: 800, zona: 'B1'),
        ]);
        expect(
          find.text("Fatti 1.800 di 1.800 m · 30' di 30' a tempo"),
          findsOneWidget,
        );
        expect(
          find.text('Nessuna serie segnata: contano come scritte.'),
          findsOneWidget,
        );

        // La prima: fatta tutta.
        await tester.tap(_bottone('Fatta').at(0));
        await tester.pumpAndSettle();
        expect(registro.esiti, [('a', 'fatta')]);
        // Tre bottoni, e ora la riga della prima dice «Fatta».
        expect(find.text('Fatta'), findsNWidgets(4));
        // La seconda (a tempo): 12 minuti su 30.
        await tester.tap(_bottone('In parte').at(1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Quanti minuti di 30?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(SceltaInParteFoglio),
            matching: find.text('12'),
          ),
        );
        await tester.pumpAndSettle();
        expect(registro.fatti, [('b', 'fatta', null, 720)]);
        expect(find.text("In parte · 12' di 30'"), findsOneWidget);
        // La terza (800 m): saltata.
        await tester.tap(_bottone('Saltata').at(2));
        await tester.pumpAndSettle();
        expect(registro.esiti.last, ('c', 'saltata'));
        // In cima: 1000 m + 12' fatti su 1800 m + 30'.
        expect(
          find.text("Fatti 1.000 di 1.800 m · 12' di 30' a tempo"),
          findsOneWidget,
        );
        expect(find.text('1 in parte · 1 saltata'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('le regole del tocco: Fatta su una in parte la fa tutta, un '
          'secondo tocco toglie', (tester) async {
        final registro = await apri(tester, [
          _s(
            'a',
            1,
            ripetute: 10,
            distanzaM: 100,
            esito: 'fatta',
            metriFatti: 600,
          ),
        ]);
        expect(find.text('In parte · 6 di 10'), findsOneWidget);

        await tester.tap(_bottone('Fatta'));
        await tester.pumpAndSettle();
        expect(registro.esiti, [('a', 'fatta')]);
        expect(registro.serie.single.fattaTutta, isTrue);
        expect(find.textContaining('In parte ·'), findsNothing);

        await tester.tap(_bottone('Fatta'));
        await tester.pumpAndSettle();
        expect(registro.esiti.last, ('a', null));
        expect(registro.serie.single.esito, isNull);

        // «In parte» e poi «Togli».
        await tester.tap(_bottone('In parte'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(SceltaInParteFoglio),
            matching: find.text('3'),
          ),
        );
        await tester.pumpAndSettle();
        expect(registro.fatti.last, ('a', 'fatta', 300, null));
        await tester.tap(_bottone('In parte'));
        await tester.pumpAndSettle();
        expect(find.text('Togli "In parte"'), findsOneWidget);
        await tester.tap(find.text('Togli "In parte"'));
        await tester.pumpAndSettle();
        expect(registro.esiti.last, ('a', null));
        expect(registro.serie.single.inParte, isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('nel foglio i bottoni sono alti almeno 48', (tester) async {
        await apri(tester, [_s('a', 1, ripetute: 10, distanzaM: 100)]);
        await tester.tap(_bottone('In parte'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var k = 1; k <= 9; k++) {
          final b = find.ancestor(
            of: find.descendant(
              of: find.byType(SceltaInParteFoglio),
              matching: find.text('$k'),
            ),
            matching: find.byType(OutlinedButton),
          );
          expect(tester.getSize(b).height, greaterThanOrEqualTo(48));
        }
      });
    });
  }
}
