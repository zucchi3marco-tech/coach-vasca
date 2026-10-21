import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/destinatari.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/application/benessere_providers.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/varianti_secco.dart';
import 'package:coach_vasca/features/secco/presentation/secco_widgets.dart';
import 'package:coach_vasca/features/secco/presentation/seduta_secco_screen.dart';
import 'package:coach_vasca/features/secco/presentation/variante_atleta_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _seduta = Allenamento(
  id: 's1',
  clubId: 'c1',
  data: DateTime(2026, 10, 14),
  titolo: 'Prevenzione spalla',
  tipo: 'secco',
  durataMin: 40,
);

const _squat = EsercizioSecco(
  id: 'e1',
  clubId: 'c1',
  nome: 'Squat',
  categoria: CategoriaEsercizio.forza,
  misura: MisuraEsercizio.ripetizioni,
);
const _extra = EsercizioSecco(
  id: 'e2',
  clubId: 'c1',
  nome: 'Extrarotazione con elastico',
  categoria: CategoriaEsercizio.spalla,
  misura: MisuraEsercizio.ripetizioni,
  modello: 'extrarotazione_elastico',
);
const _plank = EsercizioSecco(
  id: 'e3',
  clubId: 'c1',
  nome: 'Plank frontale',
  categoria: CategoriaEsercizio.core,
  misura: MisuraEsercizio.tempo,
  modello: 'plank_frontale',
);

Atleta _atleta(String id, String cognome, String nome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

final _rossi = _atleta('rossi', 'Rossi', 'Marco');
final _bianchi = _atleta('bianchi', 'Bianchi', 'Luca');
final _neri = _atleta('neri', 'Neri', 'Paolo');

/// Squat per tutti (3 × 10, 60 kg) e plank (3 × 40'').
const _rigaSquat = EsercizioSeduta(
  id: 'r1',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'e1',
  ordine: 1,
  ripetizioni: 10,
  carico: '60 kg',
);
const _rigaPlank = EsercizioSeduta(
  id: 'r2',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'e3',
  ordine: 2,
  durataS: 40,
);

/// L'extrarotazione di Rossi al posto dello squat.
const _varianteRossi = EsercizioSeduta(
  id: 'v1',
  allenamentoId: 's1',
  clubId: 'c1',
  esercizioId: 'e2',
  ordine: 1,
  serie: 2,
  ripetizioni: 10,
  carico: 'elastico giallo',
  varianteDi: 'r1',
  destinatari: Destinatari.solo(['rossi']),
);

/// Rossi ha segnato il dolore alla spalla due giorni prima della seduta.
final _doloreRossi = SchedaBenessere(
  id: 'sb1',
  atletaId: 'rossi',
  clubId: 'c1',
  data: DateTime(2026, 10, 12),
  dolori: true,
  zoneDolore: const ['spalla'],
  oreSonno: 8,
  compilataIl: DateTime(2026, 10, 12, 20),
);

/// Il server finto: tiene le righe della seduta, annota cosa gli si chiede
/// e fa i cambi come li farebbe il vero (le varianti vanno e vengono).
class _SeccoFinto implements SeccoRepository {
  _SeccoFinto(List<EsercizioSeduta> iniziali) : righe = [...iniziali];

  final List<EsercizioSeduta> righe;
  final chiamate = <String>[];
  final aggiornate = <EsercizioSeduta>[];
  final aggiunte = <({EsercizioSeduta riga, EsercizioSeduta variante})>[];
  final escluse = <({EsercizioSeduta riga, String atleta})>[];
  final comeTuttiChiesto = <({EsercizioSeduta riga, String atleta})>[];
  final riordinate = <({List<String> ordinate, List<String> tutte})>[];
  final eliminate = <String>[];
  Object? errore;
  final _cambi = StreamController<List<EsercizioSeduta>>.broadcast();

  Stream<List<EsercizioSeduta>> flusso() async* {
    yield [...righe];
    yield* _cambi.stream;
  }

  void _emetti() => _cambi.add([...righe]);

  void _guasto() {
    if (errore case final e?) throw e;
  }

  @override
  Future<EsercizioSeduta?> ultimaVolta(String esercizioId) async => null;

  @override
  Future<void> aggiornaRiga(EsercizioSeduta r) async {
    aggiornate.add(r);
  }

  @override
  Future<void> aggiungiVariante(
    EsercizioSeduta riga,
    EsercizioSeduta variante,
  ) async {
    _guasto();
    chiamate.add('aggiungiVariante');
    aggiunte.add((riga: riga, variante: variante));
    righe.add(variante.copyWith(id: 'nuova${aggiunte.length}'));
    _emetti();
  }

  @override
  Future<void> escludiAtleta(
    EsercizioSeduta riga,
    String atletaId, {
    required Iterable<EsercizioSeduta> varianti,
  }) async {
    _guasto();
    chiamate.add('escludiAtleta');
    escluse.add((riga: riga, atleta: atletaId));
    righe.removeWhere(
      (r) =>
          r.varianteDi == riga.id &&
          r.destinatari.soloAtleti.contains(atletaId),
    );
    final i = righe.indexWhere((r) => r.id == riga.id);
    righe[i] = conEscluso(righe[i], atletaId);
    _emetti();
  }

  @override
  Future<void> comeTutti(
    EsercizioSeduta riga,
    String atletaId, {
    required Iterable<EsercizioSeduta> varianti,
  }) async {
    _guasto();
    chiamate.add('comeTutti');
    comeTuttiChiesto.add((riga: riga, atleta: atletaId));
    righe.removeWhere(
      (r) =>
          r.varianteDi == riga.id &&
          r.destinatari.soloAtleti.contains(atletaId),
    );
    final i = righe.indexWhere((r) => r.id == riga.id);
    righe[i] = senzaEscluso(righe[i], atletaId);
    _emetti();
  }

  @override
  Future<void> riordina(
    List<EsercizioSeduta> ordinate, {
    Iterable<EsercizioSeduta> tutte = const [],
  }) async {
    riordinate.add((
      ordinate: [for (final r in ordinate) r.id],
      tutte: [for (final r in tutte) r.id],
    ));
  }

  @override
  Future<void> eliminaRiga(String id) async {
    eliminate.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// L'acqua animata della testata non si ferma mai: nei test, ferma. Con
/// [scala] il testo si ingrandisce come sul telefono di chi vede male.
TransitionBuilder _senzaAnimazioni({double scala = 1}) =>
    (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(scala)),
      child: child!,
    );

Widget _app(
  _SeccoFinto finto, {
  required Widget home,
  List<SchedaBenessere> schede = const [],
  ThemeData? tema,
  double scala = 1,
}) => ProviderScope(
  overrides: [
    seccoRepositoryProvider.overrideWithValue(finto),
    eserciziSeccoProvider.overrideWith(
      (ref, clubId) => Stream.value(const [_squat, _extra, _plank]),
    ),
    eserciziSedutaProvider.overrideWith((ref, id) => finto.flusso()),
    allenamentiListProvider.overrideWith(
      (ref, clubId) => Stream.value([_seduta]),
    ),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
    atletiListProvider.overrideWith(
      (ref, filtro) => Stream.value([_bianchi, _neri, _rossi]),
    ),
    schedeBenessereClubProvider.overrideWith(
      (ref, clubId) => Stream.value(schede),
    ),
  ],
  child: MaterialApp(
    theme: tema ?? AppTheme.chiaro,
    builder: _senzaAnimazioni(scala: scala),
    home: home,
  ),
);

void _schermo(WidgetTester tester, {Size grande = const Size(1280, 2400)}) {
  tester.view.physicalSize = grande;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _apriSeduta(
  WidgetTester tester,
  _SeccoFinto finto, {
  List<SchedaBenessere> schede = const [],
}) async {
  _schermo(tester);
  await tester.pumpWidget(
    _app(
      finto,
      schede: schede,
      home: SedutaSeccoScreen(
        allenamento: _seduta,
        adesso: () => DateTime(2026, 10, 14, 9),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _apriVariante(
  WidgetTester tester,
  _SeccoFinto finto, {
  String? rigaId,
}) async {
  _schermo(tester);
  await tester.pumpWidget(
    _app(
      finto,
      home: VarianteAtletaScreen(
        allenamento: _seduta,
        atleta: _rossi,
        rigaId: rigaId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Un tocco e il tempo che il foglio o la schermata si aprano.
Future<void> _tocca(WidgetTester tester, Finder cosa) async {
  await tester.tap(cosa);
  await tester.pumpAndSettle();
}

void main() {
  group('la seduta con le varianti', () {
    testWidgets('gli esercizi di tutti sono numerati, le varianti stanno '
        'sotto', (tester) async {
      final finto = _SeccoFinto([
        _rigaSquat,
        _varianteRossi,
        _rigaPlank.copyWith(
          destinatari: const Destinatari(tranneAtleti: ['bianchi']),
        ),
      ]);
      await _apriSeduta(tester, finto);

      // Due esercizi di tutti, numerati 1 e 2: la variante non conta.
      expect(
        [
          for (final r in tester.widgetList<RigaEsercizio>(
            find.byType(RigaEsercizio),
          ))
            r.numero,
        ],
        [1, 2],
      );
      // La testata conta due esercizi, non tre.
      expect(find.text('3'), findsNothing);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Plank frontale'), findsOneWidget);
      // Le varianti e chi non fa un esercizio, con il nome breve.
      expect(
        find.text(
          'Rossi: Extrarotazione con elastico · 2 × 10, elastico giallo',
        ),
        findsOneWidget,
      );
      expect(find.text('Bianchi: non lo fa'), findsOneWidget);
    });

    testWidgets('un tocco sulla variante: cambiarla o farla fare come tutti', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _varianteRossi, _rigaPlank]);
      await _apriSeduta(tester, finto);

      const riga =
          'Rossi: Extrarotazione con elastico · 2 × 10, elastico giallo';
      await _tocca(tester, find.text(riga));
      expect(find.text('Cambia'), findsOneWidget);
      expect(find.text('Lo stesso, più leggero'), findsOneWidget);
      expect(find.text('Un altro esercizio'), findsOneWidget);
      expect(find.text('Non lo fa'), findsOneWidget);

      // Cambia: il foglio dell'esercizio, sulla riga della variante.
      await _tocca(tester, find.text('Cambia'));
      await _tocca(tester, find.byTooltip('Più').first);
      await _tocca(tester, find.text('Salva esercizio'));
      expect(finto.aggiornate.single.id, 'v1');
      expect(finto.aggiornate.single.serie, 3);
      expect(finto.aggiornate.single.varianteDi, 'r1');

      // Fallo fare come tutti: la variante se ne va.
      await _tocca(tester, find.text(riga));
      await _tocca(tester, find.text('Fallo fare come tutti'));
      expect(finto.comeTuttiChiesto.single.riga.id, 'r1');
      expect(finto.comeTuttiChiesto.single.atleta, 'rossi');
      expect(find.text(riga), findsNothing);
    });

    testWidgets("«Sposta» passa tutte le righe, così le varianti seguono", (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _varianteRossi, _rigaPlank]);
      await _apriSeduta(tester, finto);

      await _tocca(tester, find.byTooltip('Azioni dell\'esercizio').last);
      await _tocca(tester, find.text('Sposta su'));
      expect(finto.riordinate, hasLength(1));
      expect(finto.riordinate.single.ordinate, ['r2', 'r1']);
      expect(finto.riordinate.single.tutte, containsAll(['r1', 'v1', 'r2']));
    });

    testWidgets('togliere un esercizio con varianti lo dice e le porta via', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _varianteRossi, _rigaPlank]);
      await _apriSeduta(tester, finto);

      await _tocca(tester, find.byTooltip('Azioni dell\'esercizio').first);
      await _tocca(tester, find.text('Togli dalla seduta'));
      expect(find.text('Si tolgono anche le varianti per Rossi.'), findsOne);
      await _tocca(tester, find.text('Togli'));
      expect(finto.eliminate, ['r1']);
      // Il plank diventa il primo; le varianti seguono i loro esercizi.
      expect(finto.riordinate.single.ordinate, ['r2']);
      expect(finto.riordinate.single.tutte, contains('v1'));
    });

    testWidgets('«Variante per un atleta» chiede per chi e dice cosa fa '
        'ognuno', (tester) async {
      final finto = _SeccoFinto([
        _rigaSquat.copyWith(
          destinatari: const Destinatari(tranneAtleti: ['neri']),
        ),
        _varianteRossi,
      ]);
      await _apriSeduta(tester, finto, schede: [_doloreRossi]);

      await _tocca(tester, find.byTooltip('Azioni dell\'esercizio').first);
      await _tocca(tester, find.text('Variante per un atleta'));
      expect(
        find.text(
          'variante: Extrarotazione con elastico · '
          'dolore alla spalla il 12 ottobre',
        ),
        findsOneWidget,
      );
      expect(find.text('come tutti'), findsOneWidget);
      expect(find.text('non lo fa'), findsOneWidget);

      // Rossi è il primo: ha il dolore. Si apre la sua schermata.
      await _tocca(tester, find.text('Rossi').last);
      expect(find.text('Variante per Rossi'), findsOneWidget);
    });
  });

  group("l'avviso della spalla", () {
    const testo = 'Rossi ha segnato un dolore alla spalla il 12 ottobre';

    testWidgets('c\'è per chi ha male e non ha ancora una variante', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _rigaPlank]);
      await _apriSeduta(tester, finto, schede: [_doloreRossi]);

      expect(find.text(testo), findsOneWidget);
      await _tocca(tester, find.text('Prepara la variante'));
      expect(find.text('Variante per Rossi'), findsOneWidget);
      // Tutti gli esercizi, ognuno con quello che fa Rossi.
      expect(find.text('Come tutti · 3 × 10, 60 kg'), findsOneWidget);
    });

    testWidgets('non c\'è in una seduta già passata', (tester) async {
      // Come in acqua: una seduta passata non si cambia più.
      final finto = _SeccoFinto([_rigaSquat, _rigaPlank]);
      _schermo(tester);
      await tester.pumpWidget(
        _app(
          finto,
          schede: [_doloreRossi],
          home: SedutaSeccoScreen(
            allenamento: _seduta,
            adesso: () => DateTime(2026, 10, 15, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testo), findsNothing);
    });

    testWidgets('sparisce quando ha una variante', (tester) async {
      final finto = _SeccoFinto([_rigaSquat, _varianteRossi, _rigaPlank]);
      await _apriSeduta(tester, finto, schede: [_doloreRossi]);

      expect(find.text(testo), findsNothing);
      expect(find.text('Prepara la variante'), findsNothing);
    });

    testWidgets('sparisce anche se salta un esercizio, e non c\'è senza il '
        'dolore', (tester) async {
      final finto = _SeccoFinto([
        _rigaSquat.copyWith(
          destinatari: const Destinatari(tranneAtleti: ['rossi']),
        ),
        _rigaPlank,
      ]);
      await _apriSeduta(tester, finto, schede: [_doloreRossi]);
      expect(find.text(testo), findsNothing);

      final senza = _SeccoFinto([_rigaSquat, _rigaPlank]);
      await _apriSeduta(tester, senza);
      expect(find.text('Prepara la variante'), findsNothing);
    });

    testWidgets('più atleti: un riquadro, un pulsante per ciascuno', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat]);
      await _apriSeduta(
        tester,
        finto,
        schede: [
          _doloreRossi,
          SchedaBenessere(
            id: 'sb2',
            atletaId: 'neri',
            clubId: 'c1',
            data: DateTime(2026, 10, 13),
            dolori: true,
            zoneDolore: const ['spalla'],
            oreSonno: 8,
            compilataIl: DateTime(2026, 10, 13, 20),
          ),
        ],
      );
      expect(find.text('Prepara la variante'), findsNWidgets(2));
      expect(
        find.text('Neri ha segnato un dolore alla spalla il 13 ottobre'),
        findsOneWidget,
      );
    });
  });

  group('la schermata della variante', () {
    testWidgets('dice cosa fa l\'atleta di ogni esercizio', (tester) async {
      final finto = _SeccoFinto([
        _rigaSquat,
        _varianteRossi,
        _rigaPlank.copyWith(
          destinatari: const Destinatari(tranneAtleti: ['rossi']),
        ),
      ]);
      await _apriVariante(tester, finto);

      expect(find.text('Variante per Rossi'), findsOneWidget);
      expect(find.text('Prevenzione spalla · mercoledì 14 ott'), findsOne);
      expect(
        find.text(
          'Al posto: Extrarotazione con elastico 2 × 10, elastico giallo',
        ),
        findsOneWidget,
      );
      expect(find.text('Non lo fa'), findsOneWidget);
      expect(
        find.text(
          'Gli altri vedono l\'esercizio di sempre; Rossi vede solo il suo, '
          'anche sul tablet della squadra.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      '«Lo stesso, più leggero» salva la variante con i suoi valori',
      (tester) async {
        final finto = _SeccoFinto([_rigaSquat, _rigaPlank]);
        await _apriVariante(tester, finto);

        await _tocca(tester, find.text('Squat'));
        await _tocca(tester, find.text('Lo stesso, più leggero'));
        // Dal foglio con quello di tutti: una serie in meno e un altro carico.
        await _tocca(tester, find.byTooltip('Meno').first);
        await _tocca(tester, find.text('Salva esercizio'));

        expect(finto.chiamate, ['aggiungiVariante']);
        final (:riga, :variante) = finto.aggiunte.single;
        expect(riga.id, 'r1');
        expect(variante.varianteDi, 'r1');
        expect(variante.destinatari.soloAtleti, ['rossi']);
        expect(variante.esercizioId, 'e1');
        expect(variante.ordine, 1);
        expect(variante.serie, 2);
        expect(variante.ripetizioni, 10);
        expect(variante.carico, '60 kg');
        expect(find.text('Variante per Rossi aggiunta'), findsOneWidget);
        // La riga adesso dice cosa fa.
        expect(find.text('Lo stesso, più leggero · 2 × 10, 60 kg'), findsOne);
      },
    );

    testWidgets('«Lo stesso, più leggero» su una sua variante dello stesso '
        'esercizio la cambia e basta', (tester) async {
      // Toglierla e rifarla cancellerebbe le serie che ha già registrato.
      final piuLeggera = _rigaSquat
          .conPrescrizione(
            serie: 2,
            ripetizioni: 10,
            durataS: null,
            carico: '40 kg',
            recuperoS: 60,
            note: null,
          )
          .copyWith(
            id: 'v-leggera',
            varianteDi: 'r1',
            destinatari: const Destinatari.solo(['rossi']),
          );
      final finto = _SeccoFinto([_rigaSquat, piuLeggera, _rigaPlank]);
      await _apriVariante(tester, finto);

      await _tocca(tester, find.text('Squat'));
      await _tocca(tester, find.text('Lo stesso, più leggero'));
      await _tocca(tester, find.byTooltip('Meno').first);
      await _tocca(tester, find.text('Salva esercizio'));

      expect(finto.chiamate, isNot(contains('comeTutti')));
      expect(finto.chiamate, isNot(contains('aggiungiVariante')));
      expect(finto.aggiornate.single.id, 'v-leggera');
      expect(finto.aggiornate.single.serie, 1);
      expect(finto.aggiornate.single.varianteDi, 'r1');
      expect(finto.aggiornate.single.destinatari.soloAtleti, ['rossi']);
    });

    testWidgets('«Un altro esercizio» sceglie dall\'elenco e propone la '
        'prescrizione', (tester) async {
      final finto = _SeccoFinto([_rigaSquat, _rigaPlank]);
      await _apriVariante(tester, finto);

      await _tocca(tester, find.text('Squat'));
      await _tocca(tester, find.text('Un altro esercizio'));
      expect(find.text('Scegli un esercizio'), findsOneWidget);
      // Niente pulsante in fondo: un tocco sceglie.
      expect(find.text('Scegli gli esercizi'), findsNothing);
      await _tocca(tester, find.text('Extrarotazione con elastico'));

      expect(finto.chiamate, ['aggiungiVariante']);
      final v = finto.aggiunte.single.variante;
      final proposta = prescrizioneProposta(_extra);
      expect(v.esercizioId, 'e2');
      expect(v.varianteDi, 'r1');
      expect(v.destinatari.soloAtleti, ['rossi']);
      expect(v.ordine, 1);
      expect(v.serie, proposta.serie);
      expect(v.ripetizioni, proposta.ripetizioni);
      expect(v.recuperoS, proposta.recuperoS);
      // Di nuovo sulla schermata, con l'avviso e il modo di cambiarla.
      expect(find.text('Variante per Rossi'), findsOneWidget);
      expect(find.text('Variante per Rossi aggiunta'), findsOneWidget);
      await _tocca(tester, find.text('Cambia'));
      await _tocca(tester, find.byTooltip('Più').first);
      await _tocca(tester, find.text('Salva esercizio'));
      expect(finto.aggiornate.single.id, 'nuova1');
      expect(finto.aggiornate.single.serie, proposta.serie + 1);
    });

    testWidgets('se ha già una variante la sostituisce: prima «come tutti»', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _varianteRossi, _rigaPlank]);
      await _apriVariante(tester, finto);

      await _tocca(tester, find.text('Squat'));
      await _tocca(tester, find.text('Un altro esercizio'));
      await _tocca(tester, find.text('Plank frontale'));

      expect(finto.chiamate, ['comeTutti', 'aggiungiVariante']);
      expect(finto.comeTuttiChiesto.single.atleta, 'rossi');
      expect(finto.aggiunte.single.variante.esercizioId, 'e3');
      // A tempo, perché il plank si fa a tempo.
      expect(finto.aggiunte.single.variante.durataS, isNotNull);
      expect(finto.aggiunte.single.variante.ripetizioni, isNull);
    });

    testWidgets('«Non lo fa» e «Come tutti» chiamano il repository giusto', (
      tester,
    ) async {
      final finto = _SeccoFinto([_rigaSquat, _rigaPlank]);
      await _apriVariante(tester, finto);

      await _tocca(tester, find.text('Plank frontale'));
      expect(find.text('Come tutti'), findsNothing);
      await _tocca(tester, find.text('Non lo fa'));
      expect(finto.escluse.single.riga.id, 'r2');
      expect(finto.escluse.single.atleta, 'rossi');
      expect(find.text('Rossi non fa Plank frontale'), findsOneWidget);
      // Il suo plank adesso è saltato.
      expect(find.text('Non lo fa'), findsOneWidget);

      await _tocca(tester, find.text('Plank frontale'));
      expect(find.text('Non lo fa'), findsOneWidget);
      await _tocca(tester, find.text('Come tutti'));
      expect(finto.comeTuttiChiesto.single.riga.id, 'r2');
      expect(finto.comeTuttiChiesto.single.atleta, 'rossi');
      expect(find.text('Non lo fa'), findsNothing);
    });

    testWidgets('un errore è un avviso, non un crash', (tester) async {
      final finto = _SeccoFinto([_rigaSquat, _rigaPlank])
        ..errore = Exception('boom');
      await _apriVariante(tester, finto);

      await _tocca(tester, find.text('Plank frontale'));
      await _tocca(tester, find.text('Non lo fa'));
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(finto.escluse, isEmpty);
    });

    testWidgets('con una riga indicata la porta in vista e la evidenzia', (
      tester,
    ) async {
      // Una seduta lunga, su uno schermo basso: l'ultimo esercizio sta fuori.
      final finto = _SeccoFinto([
        for (var i = 1; i <= 12; i++) _rigaSquat.copyWith(id: 'r$i', ordine: i),
      ]);
      _schermo(tester, grande: const Size(400, 600));
      await tester.pumpWidget(
        _app(
          finto,
          home: VarianteAtletaScreen(
            allenamento: _seduta,
            atleta: _rossi,
            rigaId: 'r12',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12'), findsWidgets);
      final numero = tester.getTopLeft(find.text('12').last);
      expect(numero.dy, lessThan(600));
    });
  });

  group('su un telefono stretto', () {
    for (final (nome, tema) in [
      ('chiaro', AppTheme.chiaro),
      ('scuro', AppTheme.scuro),
    ]) {
      testWidgets('la seduta con varianti e avviso, tema $nome', (
        tester,
      ) async {
        final finto = _SeccoFinto([
          _rigaSquat.copyWith(
            destinatari: const Destinatari(tranneAtleti: ['bianchi']),
          ),
          _varianteRossi.copyWith(
            destinatari: const Destinatari.solo(['neri']),
          ),
          _rigaPlank,
        ]);
        _schermo(tester, grande: const Size(360, 1500));
        await tester.pumpWidget(
          _app(
            finto,
            tema: tema,
            scala: 1.3,
            schede: [_doloreRossi],
            home: SedutaSeccoScreen(
              allenamento: _seduta,
              adesso: () => DateTime(2026, 10, 14, 9),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Prepara la variante'), findsOneWidget);
        expect(find.textContaining('Bianchi: non lo fa'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // I fogli: per chi, e le scelte per una variante.
        await _tocca(tester, find.byTooltip('Azioni dell\'esercizio').first);
        await _tocca(tester, find.text('Variante per un atleta'));
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await _tocca(tester, find.textContaining('Neri: Extrarotazione'));
        expect(find.text('Fallo fare come tutti'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('la schermata della variante, tema $nome', (tester) async {
        final finto = _SeccoFinto([
          _rigaSquat,
          _varianteRossi,
          _rigaPlank.copyWith(
            destinatari: const Destinatari(tranneAtleti: ['rossi']),
          ),
        ]);
        _schermo(tester, grande: const Size(360, 800));
        await tester.pumpWidget(
          _app(
            finto,
            tema: tema,
            scala: 1.3,
            home: VarianteAtletaScreen(
              allenamento: _seduta,
              atleta: _rossi,
              rigaId: 'r2',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Variante per Rossi'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _tocca(tester, find.text('Squat'));
        expect(find.text('Un altro esercizio'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
