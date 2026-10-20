import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/application/passo_riferimento_provider.dart';
import 'package:coach_vasca/features/allenamenti/data/modifiche_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/allenamento_detail_screen.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Prove sui numeri, famiglia «una serie finisce nel gruppo sbagliato o nel
// posto sbagliato» dopo una modifica: si apre il dettaglio di un
// allenamento con un registro finto delle serie, si preme il menu di un
// gruppo (Sposta, Duplica, Elimina, Cambia blocco) e si guarda lo stato
// FINALE delle serie, non le chiamate fatte.

/// Il registro delle serie finto: tiene l'elenco in memoria e lo
/// ripropone (ordinato) alla schermata dopo ogni modifica. Imita il
/// registro vero: `updateSerie` lascia com'è quello che non si passa
/// (piramide, recupero dopo, destinatari, momento) e non tocca mai
/// l'esito; `createSerie` crea sempre una serie senza esito.
class _SerieFinte implements SerieRepository {
  _SerieFinte(List<Serie> iniziali) : _serie = List.of(iniziali);

  List<Serie> _serie;
  final _flusso = StreamController<List<Serie>>.broadcast();
  var _contatore = 0;

  /// L'elenco com'è adesso, per ordine.
  List<Serie> get elenco => _ordinate();

  List<Serie> _ordinate() =>
      List.of(_serie)..sort((a, b) => a.ordine.compareTo(b.ordine));

  void _emetti() => _flusso.add(_ordinate());

  /// Per `serieListProvider`: l'elenco di ora, poi ogni cambiamento.
  Stream<List<Serie>> osserva() async* {
    yield _ordinate();
    yield* _flusso.stream;
  }

  @override
  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
    String? piramideId,
    int? recuperoDopoS,
    Destinatari destinatari = Destinatari.tutti,
    String? momentoId,
  }) async {
    final nuova = Serie(
      id: 'nuova${++_contatore}',
      allenamentoId: allenamentoId,
      clubId: 'c1',
      ordine: ordine,
      blocco: blocco,
      ripetute: ripetute,
      distanzaM: distanzaM,
      durataS: durataS,
      stile: stile,
      esecuzione: esecuzione,
      zona: zona,
      passoObiettivoS: passoObiettivoS,
      recuperoS: recuperoS,
      ripartenzaS: ripartenzaS,
      attrezzatura: attrezzatura,
      note: note,
      piramideId: piramideId,
      recuperoDopoS: recuperoDopoS,
      destinatari: destinatari,
      momentoId: momentoId,
    );
    _serie = [..._serie, nuova];
    _emetti();
    return nuova;
  }

  @override
  Future<Serie> updateSerie({
    required String id,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
    ({String? id})? piramide,
    ({int? secondi})? recuperoDopo,
    Destinatari? destinatari,
    ({String? id})? momento,
  }) async {
    final vecchia = _serie.firstWhere((s) => s.id == id);
    final aggiornata = Serie(
      id: vecchia.id,
      allenamentoId: vecchia.allenamentoId,
      clubId: vecchia.clubId,
      ordine: ordine,
      blocco: blocco,
      ripetute: ripetute,
      distanzaM: distanzaM,
      durataS: durataS,
      stile: stile,
      esecuzione: esecuzione,
      zona: zona,
      passoObiettivoS: passoObiettivoS,
      recuperoS: recuperoS,
      ripartenzaS: ripartenzaS,
      attrezzatura: attrezzatura,
      note: note,
      // Quello che non si passa resta com'è.
      piramideId: piramide == null ? vecchia.piramideId : piramide.id,
      recuperoDopoS: recuperoDopo == null
          ? vecchia.recuperoDopoS
          : recuperoDopo.secondi,
      destinatari: destinatari ?? vecchia.destinatari,
      momentoId: momento == null ? vecchia.momentoId : momento.id,
      // L'esito non lo tocca mai.
      esito: vecchia.esito,
    );
    _serie = [
      for (final s in _serie)
        if (s.id == id) aggiornata else s,
    ];
    _emetti();
    return aggiornata;
  }

  @override
  Future<void> deleteSerie(String id) async {
    _serie = [
      for (final s in _serie)
        if (s.id != id) s,
    ];
    _emetti();
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

// Una data passata: l'avviso per il dolore alla spalla (che chiederebbe le
// schede di benessere al server) non compare.
final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2020, 1, 15),
  titolo: 'Misto',
  gruppoId: 'g14',
);

Serie _s(
  String id,
  int ordine, {
  required String blocco,
  int ripetute = 1,
  required int distanzaM,
  String esecuzione = 'nuoto',
  String? piramideId,
  String? momentoId,
  Destinatari destinatari = Destinatari.tutti,
  String? esito,
}) => Serie(
  id: id,
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: 'B1',
  piramideId: piramideId,
  momentoId: momentoId,
  destinatari: destinatari,
  esito: esito,
);

/// La seduta di partenza:
/// 1 riscaldamento 1x400 (fatta); 2-5 un «2x» (4x50, 1x100, 4x50, 1x100);
/// 6-8 un momento in parallelo (tutti 8x100 fatta, tutti 4x50, i portieri
/// 6x50 gambe); 9 defaticamento 1x200 (saltata).
List<Serie> _partenza() => [
  _s('risc', 1, blocco: 'riscaldamento', distanzaM: 400, esito: 'fatta'),
  _s(
    'g1a',
    2,
    blocco: 'principale',
    ripetute: 4,
    distanzaM: 50,
    piramideId: 'g1',
  ),
  _s('g1b', 3, blocco: 'principale', distanzaM: 100, piramideId: 'g1'),
  _s(
    'g1c',
    4,
    blocco: 'principale',
    ripetute: 4,
    distanzaM: 50,
    piramideId: 'g1',
  ),
  _s('g1d', 5, blocco: 'principale', distanzaM: 100, piramideId: 'g1'),
  _s(
    'm1a',
    6,
    blocco: 'principale',
    ripetute: 8,
    distanzaM: 100,
    momentoId: 'm1',
    esito: 'fatta',
  ),
  _s(
    'm1b',
    7,
    blocco: 'principale',
    ripetute: 4,
    distanzaM: 50,
    momentoId: 'm1',
  ),
  _s(
    'm1p',
    8,
    blocco: 'principale',
    ripetute: 6,
    distanzaM: 50,
    esecuzione: 'gambe',
    momentoId: 'm1',
    destinatari: const Destinatari(ruolo: 'portiere'),
  ),
  _s('defa', 9, blocco: 'defaticamento', distanzaM: 200, esito: 'saltata'),
];

const _righe2x = ['g1a', 'g1b', 'g1c', 'g1d'];
const _righeMomento = ['m1a', 'm1b', 'm1p'];

void _schermo(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Aspetta che l'azione (più chiamate una dopo l'altra) sia finita e la
/// schermata ridisegnata.
Future<void> _finito(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await _passa(tester);
  }
}

/// Il numero «Metri» della testata (i metri del gruppo, cioè di un
/// giocatore di movimento: i portieri hanno il loro numero a parte).
Finder _metriInTestata(String valore) => find.text(valore);

Future<_SerieFinte> _apri(WidgetTester tester) async {
  _schermo(tester);
  final registro = _SerieFinte(_partenza());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serieRepositoryProvider.overrideWithValue(registro),
        modificheRepositoryProvider.overrideWithValue(_ModificheVuote()),
        serieListProvider.overrideWith((ref, id) => registro.osserva()),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        atletiListProvider.overrideWith((ref, chiave) => Stream.value([])),
        passoRiferimentoProvider.overrideWith((ref, chiave) => null),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        // L'acqua animata della testata non si ferma mai: nei test, ferma.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: AllenamentoDetailScreen(allenamento: _allenamento),
      ),
    ),
  );
  await _finito(tester);
  return registro;
}

/// Il pulsante ⋮ di un gruppo, riconosciuto dal suggerimento.
Finder _menuDel2x() => find.byWidgetPredicate(
  (w) =>
      w is Tooltip &&
      (w.message == 'Azioni sul gruppo' ||
          w.message == 'Azioni sulla piramide'),
);

Finder _menuDelMomento() => find.byTooltip('Azioni sul lavoro in parallelo');

Future<void> _scegli(WidgetTester tester, Finder menu, String voce) async {
  expect(menu, findsOneWidget);
  await tester.tap(menu);
  await _passa(tester);
  await tester.tap(find.text(voce));
  await _finito(tester);
}

// ----- Controlli sullo stato finale -----

List<String> _ids(List<Serie> serie) => [for (final s in serie) s.id];

/// Il numero d'ordine è esattamente 1..n, senza buchi né doppioni.
void _ordineSenzaBuchi(List<Serie> serie) {
  expect(
    [for (final s in serie) s.ordine],
    [for (var i = 1; i <= serie.length; i++) i],
    reason: "il numero d'ordine deve essere 1..${serie.length}",
  );
}

/// Ogni serie che c'era prima ha ancora tutto com'era, tranne l'ordine
/// (e, se serve, il blocco): esito, gruppo, momento, destinatari.
void _restanoComeErano(
  List<Serie> dopo,
  List<Serie> prima, {
  Set<String> bloccoCambiato = const {},
}) {
  for (final p in prima) {
    final d = dopo.where((s) => s.id == p.id).firstOrNull;
    if (d == null) continue; // eliminata: la controlla il test
    expect(d.esito, p.esito, reason: 'esito di ${p.id}');
    expect(d.piramideId, p.piramideId, reason: 'piramideId di ${p.id}');
    expect(d.momentoId, p.momentoId, reason: 'momentoId di ${p.id}');
    expect(d.destinatari, p.destinatari, reason: 'destinatari di ${p.id}');
    expect(d.ripetute, p.ripetute, reason: 'ripetute di ${p.id}');
    expect(d.distanzaM, p.distanzaM, reason: 'distanza di ${p.id}');
    expect(d.esecuzione, p.esecuzione, reason: 'esecuzione di ${p.id}');
    if (!bloccoCambiato.contains(p.id)) {
      expect(d.blocco, p.blocco, reason: 'blocco di ${p.id}');
    }
  }
}

/// Le righe del gruppo stanno una dopo l'altra, in quest'ordine.
void _contigue(List<Serie> serie, List<String> ids) {
  final posizioni = [for (final id in ids) _ids(serie).indexOf(id)];
  expect(posizioni.contains(-1), isFalse, reason: 'manca una riga di $ids');
  expect(posizioni, [
    for (var i = 0; i < ids.length; i++) posizioni.first + i,
  ], reason: 'le righe di $ids devono restare insieme');
}

String? _unico(Iterable<String?> valori) {
  final insieme = valori.toSet();
  expect(insieme.length, 1, reason: 'valori diversi: $insieme');
  return insieme.single;
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('la seduta di partenza: 2.200 m, il gruppo è la colonna di '
      'tutti e i 300 m dei portieri non contano', (tester) async {
    final registro = await _apri(tester);

    // 400 + «2x» 600 + momento (tutti: 800 + 200) + 200.
    expect(_metriInTestata('2.200'), findsOneWidget);
    expect(registro.elenco, hasLength(9));
  });

  testWidgets('Sposta giù il «2x»: va dopo il momento, le sue 4 righe '
      'restano insieme e tutto il resto è com\'era', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;
    expect(_metriInTestata('2.200'), findsOneWidget);

    await _scegli(tester, _menuDel2x(), 'Sposta giù');

    final dopo = registro.elenco;
    expect(_ids(dopo), ['risc', ..._righeMomento, ..._righe2x, 'defa']);
    _contigue(dopo, _righe2x);
    _contigue(dopo, _righeMomento);
    expect(
      _unico([
        for (final id in _righe2x)
          dopo.firstWhere((s) => s.id == id).piramideId,
      ]),
      'g1',
    );
    _ordineSenzaBuchi(dopo);
    _restanoComeErano(dopo, prima);
    // Il momento e il «2x» hanno cambiato posto, non misura.
    expect(_metriInTestata('2.200'), findsOneWidget);
  });

  testWidgets('Sposta su il momento: sale intero sopra il «2x», con lo '
      'stesso momento e gli stessi destinatari', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;

    await _scegli(tester, _menuDelMomento(), 'Sposta su');

    final dopo = registro.elenco;
    expect(_ids(dopo), ['risc', ..._righeMomento, ..._righe2x, 'defa']);
    _contigue(dopo, _righeMomento);
    _contigue(dopo, _righe2x);
    expect(
      _unico([
        for (final id in _righeMomento)
          dopo.firstWhere((s) => s.id == id).momentoId,
      ]),
      'm1',
    );
    expect(
      dopo.firstWhere((s) => s.id == 'm1p').destinatari,
      const Destinatari(ruolo: 'portiere'),
    );
    _ordineSenzaBuchi(dopo);
    _restanoComeErano(dopo, prima);
    expect(_metriInTestata('2.200'), findsOneWidget);
  });

  testWidgets('Duplica il momento: 3 righe nuove subito dopo, con UN solo '
      'momento nuovo, destinatari copiati e nessun esito', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;
    expect(_metriInTestata('2.200'), findsOneWidget);

    await _scegli(tester, _menuDelMomento(), 'Duplica');

    final dopo = registro.elenco;
    expect(dopo, hasLength(12));
    _ordineSenzaBuchi(dopo);

    // Le righe originali restano com'erano, nello stesso ordine…
    expect(_ids(dopo).take(8), ['risc', ..._righe2x, ..._righeMomento]);
    // …seguite da 3 copie e, ultimo, il defaticamento.
    expect(dopo.last.id, 'defa');
    final copie = dopo.sublist(8, 11);
    expect(copie.every((s) => s.id.startsWith('nuova')), isTrue);

    final momentoNuovo = _unico([for (final s in copie) s.momentoId]);
    expect(momentoNuovo, isNotNull);
    expect(momentoNuovo, isNot('m1'));
    // Le copie corrispondono alle originali, riga per riga.
    for (final (i, id) in _righeMomento.indexed) {
      final originale = prima.firstWhere((s) => s.id == id);
      final copia = copie[i];
      expect(copia.destinatari, originale.destinatari, reason: 'per chi: $id');
      expect(copia.ripetute, originale.ripetute);
      expect(copia.distanzaM, originale.distanzaM);
      expect(copia.esecuzione, originale.esecuzione);
      expect(copia.blocco, originale.blocco);
      expect(copia.esito, isNull, reason: 'la copia di $id parte senza esito');
      expect(copia.piramideId, isNull);
    }
    expect(copie[2].destinatari, const Destinatari(ruolo: 'portiere'));

    _restanoComeErano(dopo, prima);
    // Il momento copiato conta ancora 1.000 m (800 + 200) per il gruppo.
    expect(_metriInTestata('3.200'), findsOneWidget);
  });

  testWidgets('Duplica il «2x»: 4 righe nuove subito dopo, con UN solo '
      'gruppo nuovo e nessun esito', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;

    await _scegli(tester, _menuDel2x(), 'Duplica');

    final dopo = registro.elenco;
    expect(dopo, hasLength(13));
    _ordineSenzaBuchi(dopo);
    expect(_ids(dopo).take(5), ['risc', ..._righe2x]);
    final copie = dopo.sublist(5, 9);
    expect(copie.every((s) => s.id.startsWith('nuova')), isTrue);
    // Poi il momento e il defaticamento, come prima.
    expect(_ids(dopo).sublist(9), [..._righeMomento, 'defa']);

    final gruppoNuovo = _unico([for (final s in copie) s.piramideId]);
    expect(gruppoNuovo, isNotNull);
    expect(gruppoNuovo, isNot('g1'));
    for (final (i, id) in _righe2x.indexed) {
      final originale = prima.firstWhere((s) => s.id == id);
      expect(copie[i].ripetute, originale.ripetute);
      expect(copie[i].distanzaM, originale.distanzaM);
      expect(
        copie[i].esito,
        isNull,
        reason: 'la copia di $id parte senza esito',
      );
      expect(copie[i].momentoId, isNull);
    }
    // Le originali tengono il loro gruppo.
    expect(
      _unico([
        for (final id in _righe2x)
          dopo.firstWhere((s) => s.id == id).piramideId,
      ]),
      'g1',
    );
    _restanoComeErano(dopo, prima);
    expect(_metriInTestata('2.800'), findsOneWidget);
  });

  testWidgets('Elimina il «2x»: via le 4 righe, ordine 1..5 senza buchi e '
      'le altre serie non cambiano', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;
    expect(_metriInTestata('2.200'), findsOneWidget);

    await _scegli(tester, _menuDel2x(), 'Elimina');
    // Il dialogo di conferma.
    await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
    await _finito(tester);

    final dopo = registro.elenco;
    expect(_ids(dopo), ['risc', ..._righeMomento, 'defa']);
    _ordineSenzaBuchi(dopo);
    _restanoComeErano(dopo, prima);
    expect(
      _unico([
        for (final id in _righeMomento)
          dopo.firstWhere((s) => s.id == id).momentoId,
      ]),
      'm1',
    );
    expect(
      dopo.firstWhere((s) => s.id == 'm1p').destinatari,
      const Destinatari(ruolo: 'portiere'),
    );
    expect(_metriInTestata('1.600'), findsOneWidget);
  });

  testWidgets('Cambia blocco del momento in «Altro»: le 3 righe cambiano '
      'blocco e tengono momento e destinatari', (tester) async {
    final registro = await _apri(tester);
    final prima = registro.elenco;

    await _scegli(tester, _menuDelMomento(), 'Cambia blocco');
    await tester.tap(find.text('Altro'));
    await _finito(tester);

    final dopo = registro.elenco;
    for (final id in _righeMomento) {
      expect(dopo.firstWhere((s) => s.id == id).blocco, 'altro', reason: id);
    }
    // Stesso posto, stessi gruppi: nient'altro si muove.
    expect(_ids(dopo), _ids(prima));
    _contigue(dopo, _righeMomento);
    expect(
      _unico([
        for (final id in _righeMomento)
          dopo.firstWhere((s) => s.id == id).momentoId,
      ]),
      'm1',
    );
    expect(
      dopo.firstWhere((s) => s.id == 'm1p').destinatari,
      const Destinatari(ruolo: 'portiere'),
    );
    _ordineSenzaBuchi(dopo);
    _restanoComeErano(dopo, prima, bloccoCambiato: _righeMomento.toSet());
    expect(_metriInTestata('2.200'), findsOneWidget);
  });
}
