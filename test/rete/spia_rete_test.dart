import 'dart:async';
import 'dart:convert';

import 'package:coach_vasca/core/navigation/navigator_key.dart';
import 'package:coach_vasca/core/rete/controllo_rete.dart';
import 'package:coach_vasca/core/rete/stato_rete.dart';
import 'package:coach_vasca/core/segnalazioni/schermata_app.dart';
import 'package:coach_vasca/core/supabase/supabase_providers.dart';
import 'package:coach_vasca/core/sync/modifiche_rifiutate.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/home/barra_club.dart';
import 'package:coach_vasca/features/notifiche/data/notifiche_repository.dart';
import 'package:coach_vasca/features/segnalazioni/data/segnalazioni_repository.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/theme/colori_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, User;

import '../segnalazioni/finto_repository.dart';

const _club = Club(id: 'c1', nome: 'Vasca Club', sport: 'pallanuoto');

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Bianchi',
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

/// Un permesso negato sulle presenze, il 19 ottobre alle 18:42.
final _presenze = ModificaRifiutata(
  tabella: 'presenze',
  operazione: 'update',
  quando: DateTime(2026, 10, 19, 18, 42),
  codice: '42501',
  messaggio: 'new row violates row-level security policy',
);

/// Oggi alle 18:42 (qualunque sia oggi): "Senza rete dalle 18:42".
DateTime _oggiAlle1842() {
  final adesso = DateTime.now();
  return DateTime(adesso.year, adesso.month, adesso.day, 18, 42);
}

/// Il sync finto: segna solo che la coda è stata provata.
class _FintoSyncEngine implements SyncEngine {
  _FintoSyncEngine(this._chiamate);

  final List<String> _chiamate;

  @override
  void Function(ModificaRifiutata modifica)? get suRifiuto => null;

  @override
  Future<void> processQueue() async => _chiamate.add('coda');
}

/// Cosa è stato chiamato, nell'ordine: 'controllo', 'coda'.
late List<String> _chiamate;

Future<void> _monta(
  WidgetTester tester, {
  int inCoda = 0,
  Stream<int>? codaDal,
  List<ModificaRifiutata> rifiutate = const [],
  bool atleta = false,
  Size misura = const Size(800, 2400),
  double scalaTesto = 1,
  ThemeData? tema,

  /// Cosa fa il controllo della rete finto (di solito niente).
  void Function()? alControllo,
}) async {
  tester.view.physicalSize = misura;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _chiamate = [];
  SharedPreferences.setMockInitialValues({
    if (rifiutate.isNotEmpty)
      'modifiche_rifiutate': jsonEncode([
        for (final m in rifiutate) m.aMappa(),
      ]),
  });
  final sessione = Session(
    accessToken: 't',
    tokenType: 'bearer',
    user: const User(
      id: 'u',
      appMetadata: {},
      userMetadata: {},
      aud: 'a',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(AuthState(AuthChangeEvent.signedIn, sessione)),
        ),
        currentAtletaProvider.overrideWith(
          (ref) async => atleta ? _atleta : null,
        ),
        currentClubProvider.overrideWith((ref) async => atleta ? null : _club),
        clubAtletaProvider.overrideWith((ref, _) async => _club),
        notificheNonLetteProvider.overrideWith((ref, clubId) async => []),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        pendingOperationsCountProvider.overrideWith(
          (ref) => codaDal ?? Stream.value(inCoda),
        ),
        sonoAmministratoreAppProvider.overrideWith((ref) async => false),
        segnalazioniRepositoryProvider.overrideWithValue(
          FintoSegnalazioniRepository(),
        ),
        catturaSchermataProvider.overrideWithValue(() async => pngMinimo),
        controllaReteProvider.overrideWithValue(() async {
          _chiamate.add('controllo');
          alControllo?.call();
        }),
        syncEngineProvider.overrideWithValue(_FintoSyncEngine(_chiamate)),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKeyApp,
        navigatorObservers: [osservatorePagine],
        theme: tema ?? AppTheme.chiaro,
        // Senza movimento: l'acqua delle testate non si ferma mai.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scalaTesto),
          ),
          child: BarraClubHost(child: child),
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Distinta e dal vivo')),
          body: const Text('Contenuto'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// L'etichetta che la spia dà al lettore di schermo. Si legge dal widget e non
/// dall'albero della semantica: la barra sta prima del Navigator, e il velo
/// delle sue pagine ne toglie i nodi dall'albero (vale per tutta la barra,
/// logo compreso).
String? _etichettaDellaSpia() {
  final trovati = find
      .byWidgetPredicate(
        (w) =>
            w is Semantics && w.excludeSemantics && w.properties.button == true,
      )
      .evaluate();
  expect(trovati, hasLength(1));
  return (trovati.single.widget as Semantics).properties.label;
}

/// Tocca la spia (riconosciuta dalla sua icona) e aspetta il riquadro.
Future<void> _apriRiquadro(WidgetTester tester, IconData icona) async {
  await tester.tap(find.byIcon(icona));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(statoRete.rispostaArrivata);

  group('la spia nella barra', () {
    testWidgets('con tutto a posto non c\'è', (tester) async {
      await _monta(tester);

      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      expect(find.byIcon(Icons.sync_problem_outlined), findsNothing);
    });

    testWidgets('senza rete: la nuvola barrata', (tester) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester);

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      // Senza modifiche in coda, niente numero.
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('senza rete con 3 modifiche in coda: anche il numero', (
      tester,
    ) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, inCoda: 3);

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('in rete ma con modifiche in coda: la nuvola che sale', (
      tester,
    ) async {
      await _monta(tester, inCoda: 2);

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('modifiche rifiutate: la spia è rossa e vince sulle altre', (
      tester,
    ) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, inCoda: 3, rifiutate: [_presenze]);

      final icona = tester.widget<Icon>(
        find.byIcon(Icons.sync_problem_outlined),
      );
      expect(icona.color, AppTheme.chiaro.extension<ColoriApp>()!.rosso);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });

    // Cosa sente chi usa il lettore di schermo: (senza rete, in coda,
    // rifiutate) → etichetta.
    final etichette = [
      (true, 3, 0, 'Senza rete, 3 modifiche in attesa'),
      (true, 0, 0, 'Senza rete'),
      (false, 1, 0, '1 modifica in attesa'),
      (false, 4, 0, '4 modifiche in attesa'),
      (false, 0, 1, '1 modifica non accettata dal server'),
      (
        true,
        3,
        1,
        '1 modifica non accettata dal server. '
            'Senza rete, 3 modifiche in attesa',
      ),
    ];
    for (final (senzaRete, inCoda, rifiutate, etichetta) in etichette) {
      testWidgets('dice a parole "$etichetta"', (tester) async {
        if (senzaRete) statoRete.chiamataFallita(_oggiAlle1842());
        await _monta(
          tester,
          inCoda: inCoda,
          rifiutate: [for (var i = 0; i < rifiutate; i++) _presenze],
        );

        expect(_etichettaDellaSpia(), etichetta);
      });
    }

    testWidgets('si accende e si spegne da sola con la rete', (tester) async {
      await _monta(tester);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);

      statoRete.chiamataFallita(_oggiAlle1842());
      await tester.pump();
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

      statoRete.rispostaArrivata();
      await tester.pump();
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
    });
  });

  group('il riquadro «La rete»', () {
    testWidgets('senza rete da oggi: l\'ora, il perché e la coda', (
      tester,
    ) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, inCoda: 3);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      expect(find.text('La rete'), findsOneWidget);
      expect(find.text('Senza rete dalle 18:42'), findsOneWidget);
      expect(
        find.text(
          'Il server non risponde. Quello che salvi resta sul telefono e '
          'parte da solo quando torna la rete.',
        ),
        findsOneWidget,
      );
      expect(find.text('3 modifiche aspettano di partire'), findsOneWidget);
      expect(find.text('Riprova ora'), findsOneWidget);
    });

    testWidgets('senza rete da un altro giorno: dice anche il giorno', (
      tester,
    ) async {
      statoRete.chiamataFallita(DateTime(2020, 3, 5, 9, 5));
      await _monta(tester, inCoda: 1);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      expect(find.text('Senza rete dal 5 marzo, alle 09:05'), findsOneWidget);
      expect(find.text('1 modifica aspetta di partire'), findsOneWidget);
    });

    testWidgets('in rete con la coda: le modifiche stanno partendo', (
      tester,
    ) async {
      await _monta(tester, inCoda: 3);
      await _apriRiquadro(tester, Icons.cloud_upload_outlined);

      expect(find.text('In rete'), findsOneWidget);
      expect(find.text('Le modifiche stanno partendo.'), findsOneWidget);
      expect(find.text('3 modifiche aspettano di partire'), findsOneWidget);
      expect(find.text('Riprova ora'), findsOneWidget);
      // Niente modifiche rifiutate: niente quella sezione.
      expect(find.text('Non accettate dal server'), findsNothing);
    });

    testWidgets('si aggiorna da solo mentre è aperto', (tester) async {
      final coda = StreamController<int>();
      addTearDown(coda.close);
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, codaDal: coda.stream);
      coda.add(3);
      await tester.pumpAndSettle();
      await _apriRiquadro(tester, Icons.cloud_off_outlined);
      expect(find.text('3 modifiche aspettano di partire'), findsOneWidget);

      coda.add(1);
      await tester.pumpAndSettle();
      expect(find.text('1 modifica aspetta di partire'), findsOneWidget);

      // Torna la rete: il titolo cambia, la coda resta.
      statoRete.rispostaArrivata();
      await tester.pumpAndSettle();
      expect(find.text('In rete'), findsOneWidget);
      expect(find.textContaining('Senza rete'), findsNothing);
    });

    testWidgets('«Riprova ora» controlla la rete, poi prova la coda', (
      tester,
    ) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, inCoda: 2);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      await tester.tap(find.text('Riprova ora'));
      await tester.pump();

      // Mentre lavora: indicatore al posto del testo, pulsante spento.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Riprova ora'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.pumpAndSettle();
      expect(_chiamate, ['controllo', 'coda']);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Riprova ora'), findsOneWidget);
    });

    testWidgets('«Riprova ora» due volte di fila parte una volta sola', (
      tester,
    ) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      await tester.tap(find.text('Riprova ora'));
      await tester.pump();
      // Il pulsante è spento: il secondo tocco non fa niente.
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_chiamate, ['controllo', 'coda']);
    });

    testWidgets('esito: la rete è tornata e la coda è vuota', (tester) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester, alControllo: statoRete.rispostaArrivata);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      await tester.tap(find.text('Riprova ora'));
      await tester.pumpAndSettle();

      expect(find.text('Tutto partito.'), findsOneWidget);
      // Non c'è più niente da riprovare.
      expect(find.text('Riprova ora'), findsNothing);
    });

    testWidgets('esito: il server ancora non risponde', (tester) async {
      statoRete.chiamataFallita(_oggiAlle1842());
      await _monta(tester);
      await _apriRiquadro(tester, Icons.cloud_off_outlined);

      await tester.tap(find.text('Riprova ora'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Il server ancora non risponde: riprovo da solo ogni 20 secondi.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('esito: in rete ma qualcosa aspetta ancora', (tester) async {
      await _monta(tester, inCoda: 2);
      await _apriRiquadro(tester, Icons.cloud_upload_outlined);

      await tester.tap(find.text('Riprova ora'));
      await tester.pumpAndSettle();

      expect(find.text('Ancora 2 in attesa.'), findsOneWidget);
    });
  });

  group('le modifiche non accettate dal server', () {
    final ordini = ModificaRifiutata(
      tabella: 'schede_benessere',
      operazione: 'insert',
      quando: DateTime(2026, 10, 18, 9, 5),
    );

    testWidgets('si elencano con cosa, perché e quando', (tester) async {
      await _monta(tester, rifiutate: [_presenze, ordini]);
      await _apriRiquadro(tester, Icons.sync_problem_outlined);

      expect(find.text('Non accettate dal server'), findsOneWidget);
      expect(
        find.text(
          'Queste modifiche non sono partite e non partiranno: rifalle '
          'dall\'app.',
        ),
        findsOneWidget,
      );
      expect(find.text('Presenze · modifica'), findsOneWidget);
      expect(
        find.text('Permesso negato: questo account non può farlo.'),
        findsOneWidget,
      );
      expect(find.text('19 ottobre alle 18:42'), findsOneWidget);
      expect(find.text('Benessere · nuova'), findsOneWidget);
      expect(find.text('Il server non l\'ha accettata.'), findsOneWidget);
      expect(find.text('18 ottobre alle 09:05'), findsOneWidget);
      // In rete e senza coda: niente «Riprova ora».
      expect(find.text('Riprova ora'), findsNothing);
    });

    testWidgets('«Ho capito» svuota l\'elenco e la spia si spegne', (
      tester,
    ) async {
      await _monta(tester, rifiutate: [_presenze]);
      await _apriRiquadro(tester, Icons.sync_problem_outlined);

      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();

      expect(find.text('Non accettate dal server'), findsNothing);
      expect(find.text('Presenze · modifica'), findsNothing);
      expect(find.byIcon(Icons.sync_problem_outlined), findsNothing);
      final contenitore = ProviderScope.containerOf(
        tester.element(find.byType(BarraClubHost)),
      );
      expect(contenitore.read(modificheRifiutateProvider), isEmpty);
    });

    testWidgets('«Segnala» apre Scrivimi con il testo già scritto', (
      tester,
    ) async {
      await _monta(tester, rifiutate: [_presenze]);
      await _apriRiquadro(tester, Icons.sync_problem_outlined);

      await tester.tap(find.text('Segnala'));
      // Il riquadro sparisce, poi si prepara cosa allegare.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Cosa è successo?'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Il server non ha accettato queste modifiche:\n'
        '• Presenze, modifica, 19 ottobre alle 18:42: Permesso negato: '
        'questo account non può farlo. '
        '(42501: new row violates row-level security policy)',
      );
      // La segnalazione non cancella niente: resta nella spia.
      final contenitore = ProviderScope.containerOf(
        tester.element(find.byType(BarraClubHost)),
      );
      expect(contenitore.read(modificheRifiutateProvider), hasLength(1));
    });

    testWidgets('con tante modifiche il testo resta nei limiti', (
      tester,
    ) async {
      final molte = [
        for (var i = 0; i < 20; i++)
          ModificaRifiutata(
            tabella: 'presenze',
            operazione: 'update',
            quando: DateTime(2026, 10, 19, 18, i),
            codice: '42501',
            messaggio: 'x' * 400,
          ),
      ];
      await _monta(tester, rifiutate: molte);
      await _apriRiquadro(tester, Icons.sync_problem_outlined);

      await tester.scrollUntilVisible(
        find.text('Segnala'),
        200,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Segnala'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final testo = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .text;
      expect(testo.length, lessThanOrEqualTo(4000));
      expect(testo, contains('… e altre'));
    });

    testWidgets('l\'atleta non ha «Segnala»: deve chiedere al suo allenatore', (
      tester,
    ) async {
      await _monta(tester, rifiutate: [_presenze], atleta: true);
      await _apriRiquadro(tester, Icons.sync_problem_outlined);

      expect(find.text('Segnala'), findsNothing);
      expect(
        find.text('Se ti serve aiuto, dillo al tuo allenatore.'),
        findsOneWidget,
      );
      expect(find.text('Ho capito'), findsOneWidget);
    });
  });

  group('il menu ☰', () {
    for (final inCoda in [0, 2]) {
      testWidgets('non ha più «Sincronizza» ($inCoda in coda)', (tester) async {
        await _monta(tester, inCoda: inCoda);

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Il menu è aperto...
        expect(find.text('Notifiche'), findsOneWidget);
        // ...e la sincronizzazione ora è la spia, non una voce.
        expect(find.text('Sincronizza'), findsNothing);
        expect(find.text('Tutto sincronizzato'), findsNothing);
      });
    }
  });

  group('su un telefono stretto, con il testo grande', () {
    final temi = {'chiaro': AppTheme.chiaro, 'scuro': AppTheme.scuro};
    for (final MapEntry(key: nome, value: tema) in temi.entries) {
      testWidgets('tema $nome: barra e riquadro senza eccezioni', (
        tester,
      ) async {
        statoRete.chiamataFallita(DateTime(2020, 3, 5, 9, 5));
        await _monta(
          tester,
          inCoda: 12,
          rifiutate: [
            _presenze,
            ModificaRifiutata(
              tabella: 'distinta_giocatori',
              operazione: 'insert',
              quando: DateTime(2026, 10, 18, 21, 30),
              codice: '23505',
              messaggio: 'duplicate key value violates unique constraint',
            ),
            ModificaRifiutata(
              tabella: 'training_block_parti',
              operazione: 'delete',
              quando: DateTime(2026, 10, 17, 7, 0),
              codice: 'PGRST204',
            ),
          ],
          misura: const Size(360, 780),
          scalaTesto: 1.3,
          tema: tema,
        );
        // La barra con la spia, il nome del club e gli altri pulsanti.
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.sync_problem_outlined), findsOneWidget);

        await _apriRiquadro(tester, Icons.sync_problem_outlined);
        expect(tester.takeException(), isNull);

        // Fino in fondo al riquadro: l'ultimo pulsante si raggiunge.
        await tester.scrollUntilVisible(
          find.text('Ho capito'),
          200,
          scrollable: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Ho capito'), findsOneWidget);
        expect(find.text('Segnala'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // E mentre lavora, anche il pulsante con l'indicatore regge.
        await tester.scrollUntilVisible(
          find.text('Riprova ora'),
          -200,
          scrollable: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(find.text('Riprova ora'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
