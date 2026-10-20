import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/com_e_andata.dart';
import 'package:coach_vasca/features/allenamenti/presentation/scheda_bordo_vasca_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// «Com'è andata» a bordo vasca: «Fatta», «In parte» e «Saltata» in tutte le
// misure di schermo (telefono 360 e tablet 1024), con il testo al 130% e nei
// due temi.

Serie _serie(
  int ordine, {
  int ripetute = 10,
  int? distanzaM = 100,
  int? durataS,
  String? esito,
  int? metriFatti,
  int? secondiFatti,
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: durataS == null ? 'nuoto' : 'partita',
  zona: 'B1',
  esito: esito,
  metriFatti: metriFatti,
  secondiFatti: secondiFatti,
);

/// Tiene le serie come le terrebbe il database locale e ricorda cosa si
/// segna: segnare un esito le aggiorna e lo schermo le rilegge dal flusso.
class _SerieFinta implements SerieRepository {
  _SerieFinta(this.serie);

  List<Serie> serie;
  final esiti = <(String, String?)>[];
  final fatti = <(String, String?, int?, int?)>[];

  /// Se non è null, segnare fallisce con questo errore.
  Object? errore;
  final _flusso = StreamController<List<Serie>>.broadcast();

  Stream<List<Serie>> get flusso async* {
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
            esito: esito,
            // Come il repository vero: i numeri valgono solo con 'fatta'.
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
    if (errore case final e?) throw e;
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
    if (errore case final e?) throw e;
    fatti.add((id, esito, metriFatti, secondiFatti));
    _aggiorna(id, esito, metriFatti, secondiFatti);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 10, 8),
);

Widget _app(ThemeData tema, _SerieFinta repository, Widget figlio) =>
    ProviderScope(
      overrides: [
        serieRepositoryProvider.overrideWithValue(repository),
        serieListProvider.overrideWith((ref, id) => repository.flusso),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: tema,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: figlio,
      ),
    );

Future<void> _apri(
  WidgetTester tester,
  ThemeData tema,
  _SerieFinta repository,
  Size misura,
) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = misura;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(tema, repository, SchedaBordoVascaScreen(allenamento: _allenamento)),
  );
  await tester.pumpAndSettle();
}

/// Chiude la schermata dentro lo stesso ProviderScope: la barra del club
/// si rimette a posto prima che i provider spariscano.
Future<void> _chiudi(
  WidgetTester tester,
  ThemeData tema,
  _SerieFinta repository,
) => tester.pumpWidget(_app(tema, repository, const SizedBox()));

/// Il bottone con questa parola (nella scheda, non nel foglio).
Finder _bottone(String parola) =>
    find.ancestor(of: find.text(parola), matching: find.byType(OutlinedButton));

/// È evidenziato come l'esito segnato?
bool _scelto(WidgetTester tester, String parola) =>
    tester.widget<OutlinedButton>(_bottone(parola)).style?.backgroundColor !=
    null;

Finder _nelFoglio(Finder cosa) =>
    find.descendant(of: find.byType(SceltaInParteFoglio), matching: cosa);

void main() {
  final misure = {
    'telefono 360': const Size(360, 800),
    'tablet 1024': const Size(1024, 700),
  };

  for (final (nomeTema, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    for (final MapEntry(key: nomeMisura, value: misura) in misure.entries) {
      group('$nomeMisura, testo al 130%, tema $nomeTema', () {
        testWidgets('«Fatta», «In parte» e «Saltata» ci sono, alti 64', (
          tester,
        ) async {
          final repository = _SerieFinta([_serie(1), _serie(2), _serie(3)]);
          await _apri(tester, tema, repository, misura);
          expect(tester.takeException(), isNull);

          for (final parola in ['Fatta', 'In parte', 'Saltata']) {
            expect(_bottone(parola), findsOneWidget, reason: parola);
            expect(
              tester.getSize(_bottone(parola)).height,
              greaterThanOrEqualTo(64),
              reason: parola,
            );
          }
          // Sul telefono sono in una riga; sul tablet uno sotto l'altro.
          final fatta = tester.getRect(_bottone('Fatta'));
          final inParte = tester.getRect(_bottone('In parte'));
          final saltata = tester.getRect(_bottone('Saltata'));
          if (misura.width < 700) {
            expect(inParte.top, fatta.top);
            expect(saltata.top, fatta.top);
            expect(fatta.right, lessThan(inParte.left));
            expect(inParte.right, lessThan(saltata.left));
            expect(saltata.right, lessThanOrEqualTo(misura.width));
          } else {
            expect(inParte.left, fatta.left);
            expect(fatta.bottom, lessThan(inParte.top));
            expect(inParte.bottom, lessThan(saltata.top));
          }
          expect(_scelto(tester, 'In parte'), isFalse);
          await _chiudi(tester, tema, repository);
        });

        testWidgets('«In parte»: si sceglie quante ripetute e si passa alla '
            'serie dopo', (tester) async {
          final repository = _SerieFinta([
            _serie(1),
            _serie(2, ripetute: 4),
            _serie(3, ripetute: 4),
          ]);
          await _apri(tester, tema, repository, misura);

          await tester.tap(find.text('In parte'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Quante ripetute di 10?'), findsOneWidget);
          // Nove scelte, da 1 a 9, ognuna alta almeno 64.
          for (var k = 1; k <= 9; k++) {
            final scelta = _nelFoglio(find.text('$k'));
            expect(scelta, findsOneWidget, reason: '$k');
            final bottone = find.ancestor(
              of: scelta,
              matching: find.byType(OutlinedButton),
            );
            expect(
              tester.getSize(bottone).height,
              greaterThanOrEqualTo(64),
              reason: '$k',
            );
          }
          expect(_nelFoglio(find.text('600 m')), findsOneWidget);
          expect(_nelFoglio(find.text('Togli "In parte"')), findsNothing);

          await tester.tap(_nelFoglio(find.text('6')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(repository.fatti, [('s1', 'fatta', 600, null)]);
          expect(repository.esiti, isEmpty);
          // Passata alla serie dopo, e il contatore conta i soli 600 m.
          expect(find.text('2 di 3'), findsOneWidget);
          expect(find.text('600 di 1.800 m'), findsOneWidget);
          await _chiudi(tester, tema, repository);
        });

        testWidgets('una serie a tempo si fa in parte a minuti', (
          tester,
        ) async {
          final repository = _SerieFinta([
            _serie(1, ripetute: 6, distanzaM: null, durataS: 300),
            _serie(2),
          ]);
          await _apri(tester, tema, repository, misura);

          await tester.tap(find.text('In parte'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Quanti minuti di 30?'), findsOneWidget);
          await tester.tap(_nelFoglio(find.text('12')));
          await tester.pumpAndSettle();
          expect(repository.fatti, [('s1', 'fatta', null, 720)]);
          expect(find.text('2 di 2'), findsOneWidget);
          await _chiudi(tester, tema, repository);
        });

        testWidgets('una distanza sola si fa in parte a metri', (tester) async {
          final repository = _SerieFinta([
            _serie(1, ripetute: 1, distanzaM: 800),
            _serie(2),
          ]);
          await _apri(tester, tema, repository, misura);

          await tester.tap(find.text('In parte'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Quanti metri di 800?'), findsOneWidget);
          await tester.tap(_nelFoglio(find.text('600')));
          await tester.pumpAndSettle();
          expect(repository.fatti, [('s1', 'fatta', 600, null)]);
          await _chiudi(tester, tema, repository);
        });
      });
    }
  }

  testWidgets('senza scelte «In parte» non c\'è', (tester) async {
    final repository = _SerieFinta([
      _serie(1, ripetute: 1, distanzaM: 25),
      _serie(2),
    ]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(360, 800));
    expect(find.text('Fatta'), findsOneWidget);
    expect(find.text('Saltata'), findsOneWidget);
    expect(find.text('In parte'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Fatta'));
    await tester.pumpAndSettle();
    expect(repository.esiti, [('s1', 'fatta')]);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('«Fatta» su una fatta in parte la fa diventare fatta tutta', (
    tester,
  ) async {
    final repository = _SerieFinta([
      _serie(1, esito: 'fatta', metriFatti: 600),
      _serie(2),
    ]);
    await _apri(tester, AppTheme.scuro, repository, const Size(1024, 700));
    // In parte è evidenziata, Fatta no.
    expect(_scelto(tester, 'In parte'), isTrue);
    expect(_scelto(tester, 'Fatta'), isFalse);
    expect(_scelto(tester, 'Saltata'), isFalse);

    await tester.tap(find.text('Fatta'));
    await tester.pumpAndSettle();
    expect(repository.esiti, [('s1', 'fatta')]);
    expect(repository.fatti, isEmpty);
    // Non l'ha tolta: la serie è fatta tutta e si passa alla successiva.
    expect(repository.serie.first.fattaTutta, isTrue);
    expect(repository.serie.first.inParte, isFalse);
    expect(find.text('2 di 2'), findsOneWidget);

    // Tornando indietro «Fatta» è evidenziata e un secondo tocco la toglie.
    await tester.tap(find.text('Indietro'));
    await tester.pumpAndSettle();
    expect(_scelto(tester, 'Fatta'), isTrue);
    expect(_scelto(tester, 'In parte'), isFalse);
    await tester.tap(find.text('Fatta'));
    await tester.pumpAndSettle();
    expect(repository.esiti.last, ('s1', null));
    expect(find.text('1 di 2'), findsOneWidget);
    await _chiudi(tester, AppTheme.scuro, repository);
  });

  testWidgets('«Saltata» su una fatta in parte la segna saltata, e al secondo '
      'tocco la toglie', (tester) async {
    final repository = _SerieFinta([
      _serie(1, esito: 'fatta', metriFatti: 600),
      _serie(2),
    ]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(1024, 700));
    await tester.tap(find.text('Saltata'));
    await tester.pumpAndSettle();
    expect(repository.esiti, [('s1', 'saltata')]);
    expect(repository.serie.first.inParte, isFalse);
    await tester.tap(find.text('Indietro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saltata'));
    await tester.pumpAndSettle();
    expect(repository.esiti.last, ('s1', null));
    expect(find.text('1 di 2'), findsOneWidget);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('una serie già in parte: la scelta è evidenziata e «Togli» la '
      'toglie, restando lì', (tester) async {
    final repository = _SerieFinta([
      _serie(1, esito: 'fatta', metriFatti: 600),
      _serie(2),
    ]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(360, 800));
    await tester.tap(find.text('In parte'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // La scelta fatta (6) è evidenziata, le altre no.
    bool evidenziata(String numero) =>
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: _nelFoglio(find.text(numero)),
                matching: find.byType(OutlinedButton),
              ),
            )
            .style
            ?.backgroundColor !=
        null;
    expect(evidenziata('6'), isTrue);
    expect(evidenziata('5'), isFalse);

    final togli = _nelFoglio(find.text('Togli "In parte"'));
    expect(togli, findsOneWidget);
    expect(
      tester
          .getSize(
            find.ancestor(of: togli, matching: find.byType(OutlinedButton)),
          )
          .height,
      greaterThanOrEqualTo(64),
    );
    await tester.tap(togli);
    await tester.pumpAndSettle();
    expect(repository.esiti, [('s1', null)]);
    expect(repository.serie.first.esito, isNull);
    expect(repository.serie.first.inParte, isFalse);
    expect(find.text('1 di 2'), findsOneWidget);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('cambiare la scelta di una serie in parte', (tester) async {
    final repository = _SerieFinta([
      _serie(1, esito: 'fatta', metriFatti: 600),
      _serie(2),
    ]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(1024, 700));
    await tester.tap(find.text('In parte'));
    await tester.pumpAndSettle();
    await tester.tap(_nelFoglio(find.text('3')));
    await tester.pumpAndSettle();
    expect(repository.fatti, [('s1', 'fatta', 300, null)]);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('chiudere il foglio senza scegliere non segna niente', (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1), _serie(2)]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(360, 800));
    await tester.tap(find.text('In parte'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(find.byType(SceltaInParteFoglio), findsNothing);
    expect(repository.fatti, isEmpty);
    expect(repository.esiti, isEmpty);
    expect(find.text('1 di 2'), findsOneWidget);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('se segnare fallisce si dice, e si resta sulla serie', (
    tester,
  ) async {
    final repository = _SerieFinta([_serie(1), _serie(2)])
      ..errore = const PostgrestException(message: 'no', code: '42501');
    await _apri(tester, AppTheme.chiaro, repository, const Size(360, 800));
    await tester.tap(find.text('In parte'));
    await tester.pumpAndSettle();
    await tester.tap(_nelFoglio(find.text('6')));
    await tester.pumpAndSettle();
    expect(
      find.text('Non hai i permessi per completare questa operazione.'),
      findsOneWidget,
    );
    expect(find.text('1 di 2'), findsOneWidget);
    expect(repository.serie.first.inParte, isFalse);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });

  testWidgets('tutte le serie: fatta, saltata e in parte quanto', (
    tester,
  ) async {
    final repository = _SerieFinta([
      _serie(1, esito: 'fatta', metriFatti: 600),
      _serie(2, ripetute: 4, esito: 'fatta'),
      _serie(3, ripetute: 4, esito: 'saltata'),
      _serie(
        4,
        ripetute: 6,
        distanzaM: null,
        durataS: 300,
        esito: 'fatta',
        secondiFatti: 720,
      ),
    ]);
    await _apri(tester, AppTheme.scuro, repository, const Size(360, 2400));
    await tester.tap(find.byTooltip('Mostra tutte le serie'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('In parte · 6 di 10'), findsOneWidget);
    expect(find.text("In parte · 12' di 30'"), findsOneWidget);
    expect(find.text('Fatta'), findsOneWidget);
    expect(find.text('Saltata'), findsOneWidget);
    await _chiudi(tester, AppTheme.scuro, repository);
  });

  testWidgets('il contatore: di una serie in parte contano i metri fatti', (
    tester,
  ) async {
    final repository = _SerieFinta([
      _serie(1, ripetute: 10, esito: 'fatta', metriFatti: 600),
      _serie(2, ripetute: 4, esito: 'saltata'),
      _serie(3, ripetute: 4),
      _serie(4, ripetute: 4),
    ]);
    await _apri(tester, AppTheme.chiaro, repository, const Size(1024, 700));
    // Serie 1 in corso: 600 m fatti su 2.400.
    expect(find.text('600 di 2.200 m'), findsOneWidget);
    expect(find.text('1 serie saltata'), findsOneWidget);
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    // Alla terza: la prima in parte (600), la seconda saltata (0).
    expect(find.text('3 di 4'), findsOneWidget);
    expect(find.text('600 di 2.200 m'), findsOneWidget);
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    // Alla quarta si aggiunge la terza, passata senza segno: tutta.
    expect(find.text('1.000 di 2.200 m'), findsOneWidget);
    await _chiudi(tester, AppTheme.chiaro, repository);
  });
}
