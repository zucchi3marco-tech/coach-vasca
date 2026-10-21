import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/destinatari.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/application/carico_providers.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/data/presenze_repository.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/serie_fatte_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/serie_fatta.dart';
import 'package:coach_vasca/features/secco/presentation/registra_secco_screen.dart';
import 'package:coach_vasca/features/secco/presentation/tablet_squadra_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'serie_finte.dart';

final _seduta = Allenamento(
  id: 's1',
  clubId: 'c1',
  data: DateTime(2026, 10, 14),
  titolo: 'Spalla del tiratore',
  tipo: 'secco',
  durataMin: 30,
);

Atleta _atleta(String id, String cognome, String nome, {bool attivo = true}) =>
    Atleta(
      id: id,
      clubId: 'c1',
      nome: nome,
      cognome: cognome,
      dataNascita: DateTime(2010, 3, 1),
      sport: 'pallanuoto',
      consensoPrivacyFirmato: true,
      attivo: attivo,
    );

final _atleti = [
  _atleta('rossi', 'Rossi', 'Marco'),
  _atleta('bianchi', 'Bianchi', 'Luca'),
  _atleta('verdi', 'Verdi', 'Anna'),
  _atleta('neri', 'Neri', 'Zoe'),
  // Archiviato: non compare.
  _atleta('gialli', 'Gialli', 'Piero', attivo: false),
];

EsercizioSeduta _riga(
  String id,
  int ordine,
  String esercizio, {
  int serie = 3,
  String? varianteDi,
  Destinatari destinatari = Destinatari.tutti,
  String? note,
  int? recupero,
}) => EsercizioSeduta(
  id: id,
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: esercizio,
  ordine: ordine,
  serie: serie,
  ripetizioni: 10,
  recuperoS: recupero,
  varianteDi: varianteDi,
  destinatari: destinatari,
  note: note,
);

/// Lancio e plank per tutti; Rossi (spalla) fa l'extrarotazione al posto
/// del lancio; Bianchi non fa il plank.
final _righe = [
  _riga('lancio', 1, 'palla', note: 'Rossi piano'),
  _riga(
    'plank',
    2,
    'plank',
    serie: 1,
    destinatari: const Destinatari(tranneAtleti: ['bianchi']),
  ),
  _riga(
    'extra',
    1,
    'extra',
    serie: 2,
    varianteDi: 'lancio',
    destinatari: const Destinatari.solo(['rossi']),
  ),
];

/// Come [_righe], ma con 30'' di recupero dopo ogni serie dell'extrarotazione.
final _righeConRecupero = [
  for (final r in _righe)
    r.id == 'extra'
        ? _riga(
            'extra',
            1,
            'extra',
            serie: 2,
            varianteDi: 'lancio',
            destinatari: const Destinatari.solo(['rossi']),
            recupero: 30,
          )
        : r,
];

const _catalogo = [
  EsercizioSecco(
    id: 'palla',
    clubId: 'c1',
    nome: 'Lancio palla medica',
    categoria: CategoriaEsercizio.core,
  ),
  EsercizioSecco(
    id: 'plank',
    clubId: 'c1',
    nome: 'Plank frontale',
    categoria: CategoriaEsercizio.core,
  ),
  EsercizioSecco(
    id: 'extra',
    clubId: 'c1',
    nome: 'Extrarotazione con elastico',
    categoria: CategoriaEsercizio.scapole,
  ),
];

SerieFatta _fatta(String atleta, String riga, String esercizio, int serie) =>
    SerieFatta(
      id: '$atleta-$riga-$serie',
      atletaId: atleta,
      clubId: 'c1',
      allenamentoId: 's1',
      rigaId: riga,
      esercizioId: esercizio,
      serie: serie,
      ripetizioni: 10,
      fattaIl: DateTime(2026, 10, 14, 18, serie),
    );

Presenza _presenza(String atleta, String stato) => Presenza(
  id: 'p-$atleta',
  allenamentoId: 's1',
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

/// Le presenze: annota cosa si segna.
class _PresenzeFinte implements PresenzeRepository {
  /// Le presenze già scritte quando si apre il tablet.
  var iniziali = <Presenza>[];
  final segnate = <(String, String, String)>[];

  @override
  Stream<List<Presenza>> watchPerAllenamento(String allenamentoId) =>
      Stream.value([
        ...iniziali,
        for (final (_, atleta, stato) in segnate)
          Presenza(
            id: 'nuova-$atleta',
            allenamentoId: allenamentoId,
            atletaId: atleta,
            clubId: 'c1',
            stato: stato,
          ),
      ]);

  @override
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    segnate.add((allenamentoId, atletaId, stato));
    return Presenza(
      id: 'nuova-$atletaId',
      allenamentoId: allenamentoId,
      atletaId: atletaId,
      clubId: 'c1',
      stato: stato,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Un pulsante che apre la schermata, come fa la seduta dell'allenatore.
class _Apri extends StatelessWidget {
  const _Apri({required this.schermata});

  final Widget schermata;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => schermata)),
      child: const Text('Apri'),
    ),
  );
}

Widget _app({
  required SerieFinte serie,
  required _PresenzeFinte presenze,
  List<Presenza> presenzeIniziali = const [],
  List<EsercizioSeduta>? righe,
  List<Atleta>? atleti,
  ThemeData? tema,
  double testo = 1,
}) {
  presenze.iniziali = presenzeIniziali;
  return ProviderScope(
    overrides: [
      serieFatteRepositoryProvider.overrideWithValue(serie),
      presenzeRepositoryProvider.overrideWithValue(presenze),
      atletiListProvider.overrideWith(
        (ref, filtro) => Stream.value([
          for (final a in atleti ?? _atleti)
            if (filtro.includeInactive || a.attivo) a,
        ]),
      ),
      eserciziSedutaProvider.overrideWith(
        (ref, id) => Stream.value(righe ?? _righe),
      ),
      eserciziSeccoProvider.overrideWith((ref, id) => Stream.value(_catalogo)),
      serieFatteSedutaProvider.overrideWith(
        (ref, id) => serie.watchPerSeduta(id),
      ),
      serieFatteAtletaProvider.overrideWith(
        (ref, id) => serie.watchPerAtleta(id),
      ),
      presenzeListProvider.overrideWith(
        (ref, id) => presenze.watchPerAllenamento(id),
      ),
      rpeAtletaProvider.overrideWith((ref, id) => Stream.value(const [])),
      seduteCaricoProvider.overrideWith((ref, chiave) async => const []),
    ],
    child: MaterialApp(
      theme: tema ?? AppTheme.chiaro,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(testo)),
        child: child!,
      ),
      home: _Apri(schermata: TabletSquadraScreen(allenamento: _seduta)),
    ),
  );
}

void _schermo(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Un test dei widget che alla fine chiude le schermate aperte: la barra
/// del club si rimette a posto quando la schermata si chiude, e deve farlo
/// prima che i provider spariscano.
void _prova(String nome, Future<void> Function(WidgetTester tester) corpo) =>
    testWidgets(nome, (tester) async {
      await corpo(tester);
      final navigatori = find.byType(Navigator);
      if (navigatori.evaluate().isEmpty) return;
      tester.state<NavigatorState>(navigatori.first).popUntil((r) => r.isFirst);
      await tester.pumpAndSettle();
    });

Future<void> _apriTablet(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

void main() {
  group('l\'elenco', () {
    _prova('gli atleti nell\'ordine giusto, con le serie fatte', (
      tester,
    ) async {
      _schermo(tester, const Size(400, 1600));
      // Rossi: extrarotazione (2) + plank (1), una serie fatta. Neri ha
      // finito (lancio 3 + plank 1). Bianchi non fa il plank.
      final serie = SerieFinte([
        _fatta('rossi', 'extra', 'extra', 1),
        for (var s = 1; s <= 3; s++) _fatta('neri', 'lancio', 'palla', s),
        _fatta('neri', 'plank', 'plank', 1),
      ]);
      await tester.pumpWidget(
        _app(
          serie: serie,
          presenze: _PresenzeFinte(),
          presenzeIniziali: [
            _presenza('rossi', statoPresente),
            _presenza('neri', statoRitardo),
            _presenza('verdi', statoAssente),
          ],
        ),
      );
      await _apriTablet(tester);

      expect(find.text('Tablet della squadra'), findsOneWidget);
      expect(find.textContaining('Spalla del tiratore'), findsOneWidget);
      expect(find.text('Gialli Piero'), findsNothing);

      // Prima chi c'è (Neri, Rossi), poi Bianchi (da segnare), in fondo
      // Verdi (assente).
      double y(String nome) => tester.getTopLeft(find.text(nome)).dy;
      expect(y('Neri Zoe'), lessThan(y('Rossi Marco')));
      expect(y('Rossi Marco'), lessThan(y('Bianchi Luca')));
      expect(y('Bianchi Luca'), lessThan(y('Verdi Anna')));

      // La variante di Rossi è nella sua lista: 2 + 1 serie, non 3 + 1.
      expect(find.text('1 di 3 serie'), findsOneWidget);
      // Bianchi: solo il lancio.
      expect(find.text('0 di 3 serie'), findsOneWidget);
      // Verdi è assente ma si vede, con le sue 4 serie.
      expect(find.text('Assente · 0 di 4 serie'), findsOneWidget);
      // Neri ha finito.
      expect(find.text('Finito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    _prova('senza esercizi, una schermata vuota che spiega', (tester) async {
      _schermo(tester, const Size(400, 1000));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte(), righe: []),
      );
      await _apriTablet(tester);
      expect(find.text('Nessun esercizio nella seduta'), findsOneWidget);
    });

    _prova('senza atleti, una schermata vuota che spiega', (tester) async {
      _schermo(tester, const Size(400, 1000));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte(), atleti: []),
      );
      await _apriTablet(tester);
      expect(find.text('Nessun atleta nel gruppo'), findsOneWidget);
    });

    _prova('una tessera apre la registrazione di quell\'atleta, con '
        'i suoi esercizi e senza le note', (tester) async {
      _schermo(tester, const Size(400, 1600));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte()),
      );
      await _apriTablet(tester);

      await tester.tap(find.text('Rossi Marco'));
      await tester.pumpAndSettle();

      // Il nome in alto, l'esercizio della sua variante al posto del lancio.
      expect(find.text('Rossi Marco'), findsOneWidget);
      expect(find.text('Esercizio 1 di 2'), findsOneWidget);
      expect(find.text('Extrarotazione con elastico'), findsOneWidget);
      expect(find.text('Lancio palla medica'), findsNothing);
      expect(find.text('0 serie su 3'), findsOneWidget);
      final registra = tester.widget<RegistraSeccoScreen>(
        find.byType(RegistraSeccoScreen),
      );
      expect(registra.daTablet, isTrue);
      expect(registra.esercizi.map((e) => e.riga.note), [null, null]);

      // Indietro: di nuovo l'elenco.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Tablet della squadra'), findsOneWidget);
    });
  });

  group('chiuso a chiave', () {
    _prova('«indietro» non esce e dice come si fa', (tester) async {
      _schermo(tester, const Size(400, 1600));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte()),
      );
      await _apriTablet(tester);
      expect(find.byType(BackButton), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Tablet della squadra'), findsOneWidget);
      expect(find.text('Per uscire tieni premuto «Esci»'), findsOneWidget);
    });

    _prova('un tocco su «Esci» ricorda di tenere premuto', (tester) async {
      _schermo(tester, const Size(400, 1600));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte()),
      );
      await _apriTablet(tester);

      await tester.tap(find.text('Esci'));
      await tester.pump();
      expect(find.text('Tieni premuto «Esci» per uscire'), findsOneWidget);
      expect(find.text('Uscire dal tablet della squadra?'), findsNothing);
    });

    _prova('tenuto meno di due secondi non fa niente', (tester) async {
      _schermo(tester, const Size(400, 1600));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte()),
      );
      await _apriTablet(tester);

      final dito = await tester.startGesture(
        tester.getCenter(find.text('Esci')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await dito.up();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Uscire dal tablet della squadra?'), findsNothing);
      expect(find.text('Tablet della squadra'), findsOneWidget);
    });

    _prova('tenuto due secondi chiede conferma: «Resta» resta, '
        '«Esci» esce', (tester) async {
      _schermo(tester, const Size(400, 1600));
      await tester.pumpWidget(
        _app(serie: SerieFinte(), presenze: _PresenzeFinte()),
      );
      await _apriTablet(tester);

      var dito = await tester.startGesture(tester.getCenter(find.text('Esci')));
      // Il conto parte dal primo fotogramma dopo il tocco.
      await tester.pump();
      await tester.pump(durataTenutaEsci);
      await dito.up();
      await tester.pumpAndSettle();
      expect(find.text('Uscire dal tablet della squadra?'), findsOneWidget);
      expect(
        find.text('Tornerai alla seduta, dove ci sono i dati di tutti.'),
        findsOneWidget,
      );
      // Alzare il dito dopo la tenuta non fa comparire il suggerimento.
      expect(find.text('Tieni premuto «Esci» per uscire'), findsNothing);

      await tester.tap(find.text('Resta'));
      await tester.pumpAndSettle();
      expect(find.text('Uscire dal tablet della squadra?'), findsNothing);
      expect(find.text('Tablet della squadra'), findsOneWidget);

      dito = await tester.startGesture(tester.getCenter(find.text('Esci')));
      await tester.pump();
      await tester.pump(durataTenutaEsci);
      await dito.up();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Esci'));
      await tester.pumpAndSettle();
      expect(find.text('Apri'), findsOneWidget);
      expect(find.text('Tablet della squadra'), findsNothing);
    });
  });

  group('la presenza', () {
    _prova('chi ha registrato una serie e non era segnato è presente; '
        'chi era assente resta com\'è', (tester) async {
      _schermo(tester, const Size(400, 1600));
      final serie = SerieFinte();
      final presenze = _PresenzeFinte();
      await tester.pumpWidget(
        _app(
          serie: serie,
          presenze: presenze,
          presenzeIniziali: [_presenza('verdi', statoAssente)],
        ),
      );
      await _apriTablet(tester);

      // Bianchi: non era segnato, fa una serie e torna all'elenco.
      await tester.tap(find.text('Bianchi Luca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatta'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(presenze.segnate, [('s1', 'bianchi', statoPresente)]);
      expect(find.text('1 di 3 serie'), findsOneWidget);

      // Verdi: assente, fa una serie: la presenza non si tocca.
      await tester.tap(find.textContaining('Verdi Anna'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fatta'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(presenze.segnate, hasLength(1));

      // Rossi apre e torna senza fare niente: niente presenza.
      await tester.tap(find.text('Rossi Marco'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(presenze.segnate, hasLength(1));
    });
  });

  group('senza overflow, a 360 con il testo grande', () {
    for (final (nome, tema) in [
      ('chiaro', AppTheme.chiaro),
      ('scuro', AppTheme.scuro),
    ]) {
      _prova('elenco e registrazione, tema $nome', (tester) async {
        _schermo(tester, const Size(360, 740));
        final serie = SerieFinte([
          _fatta('neri', 'plank', 'plank', 1),
          for (var s = 1; s <= 3; s++) _fatta('neri', 'lancio', 'palla', s),
        ]);
        await tester.pumpWidget(
          _app(
            serie: serie,
            presenze: _PresenzeFinte(),
            presenzeIniziali: [
              _presenza('verdi', statoGiustificato),
              _presenza('neri', statoPresente),
            ],
            // Un cognome lungo, per spingere i limiti.
            atleti: [
              ..._atleti,
              _atleta('lungo', 'Del Conte di Montefalcone', 'Massimiliano'),
            ],
            righe: _righeConRecupero,
            tema: tema,
            testo: 1.3,
          ),
        );
        await _apriTablet(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Tablet della squadra'), findsOneWidget);
        expect(find.text('Esci'), findsOneWidget);

        await tester.tap(find.text('Rossi Marco'));
        await tester.pumpAndSettle();
        expect(find.text('Esercizio 1 di 2'), findsOneWidget);
        // Una serie fatta: il recupero e, sotto, il voto.
        await tester.tap(find.text('Fatta'));
        await tester.pump();
        // L'avviso «Serie segnata» sparisce da solo dopo 4 secondi.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Recupero'), findsOneWidget);
        expect(find.text('Com\'è andata la serie 1?'), findsOneWidget);
        await tester.tap(find.text('Giusta'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(serie.salvate.last.voto, VotoSerie.giusta);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
