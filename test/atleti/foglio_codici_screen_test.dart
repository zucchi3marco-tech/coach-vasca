import 'dart:typed_data';

import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/application/biglietti_codici_pdf.dart';
import 'package:coach_vasca/features/atleti/data/inviti_atleta_repository.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/presentation/foglio_codici_screen.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepositoryFinto implements InvitiAtletaRepository {
  final chiamate = <List<String>>[];
  Object? errore;

  /// Atleti che nel frattempo hanno collegato l'account: il server li salta.
  final saltati = <String>{};

  @override
  Future<List<CodiceFoglio>> generaCodiciFoglio(List<String> atletaIds) async {
    chiamate.add(List.of(atletaIds));
    if (errore != null) throw errore!;
    return [
      for (final id in atletaIds)
        if (!saltati.contains(id))
          (
            atletaId: id,
            codice: 'ABCDE${id.padRight(5, '0').toUpperCase().substring(0, 5)}',
            scade: DateTime(2026, 11, 17),
          ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AzioniFinte extends AzioniFoglio {
  int pdfCreati = 0;
  int stampe = 0;
  int scaricamenti = 0;
  List<BigliettoCodice> ultimiBiglietti = const [];

  @override
  Future<Uint8List> creaPdf({
    required String nomeClub,
    required List<BigliettoCodice> biglietti,
    String? indirizzoApp,
    Uint8List? logo,
  }) async {
    pdfCreati++;
    ultimiBiglietti = biglietti;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> stampa(Uint8List bytes, String nome) async => stampe++;

  @override
  Future<void> scarica(Uint8List bytes, String nomeFile) async =>
      scaricamenti++;
}

Atleta _atleta(
  String id,
  String cognome,
  String nome, {
  String? gruppo,
  bool conAccount = false,
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  gruppoId: gruppo,
  consensoPrivacyFirmato: true,
  attivo: true,
  userId: conAccount ? 'utente-$id' : null,
);

final _atleti = [
  _atleta('r', 'Rossi', 'Mario', gruppo: 'u14'),
  _atleta('b', 'Bianchi', 'Luca', gruppo: 'u14', conAccount: true),
  _atleta('v', 'Verdi', 'Anna', gruppo: 'prima'),
  _atleta('n', 'Neri', 'Paolo', gruppo: 'prima', conAccount: true),
  _atleta('g', 'Gialli', 'Gino'),
];

class _Prova {
  _Prova() : repo = _RepositoryFinto(), azioni = _AzioniFinte();
  final _RepositoryFinto repo;
  final _AzioniFinte azioni;

  Widget app({String? gruppoId, List<String>? soloAtletaIds}) => ProviderScope(
    overrides: [
      currentClubProvider.overrideWith(
        (ref) async => const Club(id: 'c1', nome: 'Club Prova'),
      ),
      gruppiListProvider.overrideWith(
        (ref, clubId) => Stream.value(const [
          Gruppo(id: 'u14', clubId: 'c1', nome: 'Under 14', ordine: 1),
          Gruppo(id: 'prima', clubId: 'c1', nome: 'Prima', ordine: 2),
        ]),
      ),
      atletiListProvider.overrideWith((ref, filtro) => Stream.value(_atleti)),
      invitiAtletaRepositoryProvider.overrideWithValue(repo),
      azioniFoglioProvider.overrideWithValue(azioni),
    ],
    child: MaterialApp(
      theme: AppTheme.chiaro,
      // Il font dei test è quadrato e largo: gli overflow dei testi non
      // dicono nulla sull'app.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: FoglioCodiciScreen(
        gruppoId: gruppoId,
        soloAtletaIds: soloAtletaIds,
      ),
    ),
  );

  Future<void> apri(
    WidgetTester tester, {
    String? gruppoId,
    List<String>? soloAtletaIds,
  }) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final originale = FlutterError.onError;
    FlutterError.onError = (dettagli) {
      if (dettagli.exceptionAsString().contains('overflowed')) return;
      originale?.call(dettagli);
    };
    addTearDown(() => FlutterError.onError = originale);
    await tester.pumpWidget(
      app(gruppoId: gruppoId, soloAtletaIds: soloAtletaIds),
    );
    await tester.pumpAndSettle();
  }

  Future<void> crea(WidgetTester tester) async {
    await tester.tap(find.textContaining('Crea il foglio'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('elenca solo gli atleti senza account', (tester) async {
    final p = _Prova();
    await p.apri(tester);

    expect(find.text('Rossi Mario'), findsOneWidget);
    expect(find.text('Verdi Anna'), findsOneWidget);
    expect(find.text('Gialli Gino'), findsOneWidget);
    expect(find.text('Bianchi Luca'), findsNothing);
    expect(find.text('Neri Paolo'), findsNothing);
    expect(
      find.text('2 hanno già l\'account: non serve il codice.'),
      findsOneWidget,
    );
    expect(find.text('Crea il foglio (3 biglietti)'), findsOneWidget);
    expect(find.textContaining('30 giorni'), findsOneWidget);
  });

  testWidgets('le squadre filtrano l\'elenco', (tester) async {
    final p = _Prova();
    await p.apri(tester);

    await tester.tap(find.widgetWithText(RawChip, 'Prima'));
    await tester.pumpAndSettle();
    expect(find.text('Verdi Anna'), findsOneWidget);
    expect(find.text('Rossi Mario'), findsNothing);
    expect(find.text('Gialli Gino'), findsNothing);
    // Neri ha l'account: resta fuori ma si conta.
    expect(
      find.text('1 ha già l\'account: non serve il codice.'),
      findsOneWidget,
    );
    expect(find.text('Crea il foglio (1 biglietto)'), findsOneWidget);

    await tester.tap(find.widgetWithText(RawChip, 'Tutto il club'));
    await tester.pumpAndSettle();
    expect(find.text('Crea il foglio (3 biglietti)'), findsOneWidget);
  });

  testWidgets('si apre già sulla squadra proposta', (tester) async {
    final p = _Prova();
    await p.apri(tester, gruppoId: 'u14');

    expect(find.text('Rossi Mario'), findsOneWidget);
    expect(find.text('Verdi Anna'), findsNothing);
    await p.crea(tester);
    expect(p.repo.chiamate.single, ['r']);
  });

  testWidgets('togliere la spunta esclude l\'atleta dai codici', (
    tester,
  ) async {
    final p = _Prova();
    await p.apri(tester);

    await tester.tap(find.text('Verdi Anna'));
    await tester.pumpAndSettle();
    expect(find.text('Crea il foglio (2 biglietti)'), findsOneWidget);

    await p.crea(tester);
    expect(p.repo.chiamate, hasLength(1));
    expect(p.repo.chiamate.single, unorderedEquals(['r', 'g']));
  });

  testWidgets('Nessuno disattiva il pulsante, Tutti rimette tutti', (
    tester,
  ) async {
    final p = _Prova();
    await p.apri(tester);

    await tester.tap(find.text('Nessuno'));
    await tester.pumpAndSettle();
    expect(find.text('Crea il foglio (0 biglietti)'), findsOneWidget);
    await tester.tap(find.text('Crea il foglio (0 biglietti)'));
    await tester.pumpAndSettle();
    expect(p.repo.chiamate, isEmpty);

    await tester.tap(find.text('Tutti'));
    await tester.pumpAndSettle();
    expect(find.text('Crea il foglio (3 biglietti)'), findsOneWidget);
  });

  testWidgets('con soloAtletaIds restano solo quegli atleti, senza squadre', (
    tester,
  ) async {
    final p = _Prova();
    await p.apri(tester, soloAtletaIds: ['r', 'b', 'g']);

    expect(find.text('Rossi Mario'), findsOneWidget);
    expect(find.text('Gialli Gino'), findsOneWidget);
    expect(find.text('Verdi Anna'), findsNothing);
    // Bianchi ha l'account: non ha biglietto.
    expect(find.text('Bianchi Luca'), findsNothing);
    expect(find.text('Tutto il club'), findsNothing);
    expect(find.byType(RawChip), findsNothing);

    await p.crea(tester);
    expect(p.repo.chiamate.single, unorderedEquals(['r', 'g']));
  });

  testWidgets('dopo la creazione: foglio pronto, stampare e scaricare non '
      'creano altri codici', (tester) async {
    final p = _Prova();
    await p.apri(tester);
    await p.crea(tester);

    expect(
      find.text('Foglio pronto: 3 biglietti, validi fino al 17/11/2026'),
      findsOneWidget,
    );
    expect(p.azioni.pdfCreati, 1);
    expect([
      for (final b in p.azioni.ultimiBiglietti) b.cognomeNome,
    ], unorderedEquals(['Rossi Mario', 'Verdi Anna', 'Gialli Gino']));
    expect(
      p.azioni.ultimiBiglietti.firstWhere((b) => b.cognome == 'Verdi').squadra,
      'Prima',
    );

    await tester.tap(find.text('Stampa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stampa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scarica il PDF'));
    await tester.pumpAndSettle();

    expect(p.azioni.stampe, 2);
    expect(p.azioni.scaricamenti, 1);
    expect(p.repo.chiamate, hasLength(1));
    expect(p.azioni.pdfCreati, 1);
  });

  testWidgets('«Fai un altro foglio» torna alla scelta', (tester) async {
    final p = _Prova();
    await p.apri(tester);
    await p.crea(tester);

    await tester.tap(find.text('Fai un altro foglio'));
    await tester.pumpAndSettle();
    expect(find.text('Crea il foglio (3 biglietti)'), findsOneWidget);
    expect(p.repo.chiamate, hasLength(1));
  });

  testWidgets('se il server dà meno codici lo dice', (tester) async {
    final p = _Prova();
    p.repo.saltati.add('g');
    await p.apri(tester);
    await p.crea(tester);

    expect(
      find.text('Foglio pronto: 2 biglietti, validi fino al 17/11/2026'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Per 1 atleta il codice non è stato creato'),
      findsOneWidget,
    );
  });

  testWidgets('un errore resta sulla scelta, con un messaggio chiaro', (
    tester,
  ) async {
    final p = _Prova();
    p.repo.errore = Exception('Non autorizzato');
    await p.apri(tester);
    await p.crea(tester);

    expect(find.textContaining('Non autorizzato'), findsOneWidget);
    expect(find.textContaining('Foglio pronto'), findsNothing);
    expect(find.text('Crea il foglio (3 biglietti)'), findsOneWidget);
    expect(p.azioni.pdfCreati, 0);
  });
}
