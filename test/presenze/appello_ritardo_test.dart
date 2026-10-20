import 'package:coach_vasca/core/utils/date_italiane.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/application/personal_best_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:coach_vasca/features/benessere/application/benessere_providers.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/benessere/domain/segnale_benessere.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/data/presenze_repository.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/presentation/presenze_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Mario',
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  gruppoId: 'u14',
  consensoPrivacyFirmato: true,
  attivo: true,
);

final _oggi = DateTime.now();
final _mezzanotte = DateTime(_oggi.year, _oggi.month, _oggi.day);

/// L'appello di stasera, più due sedute di stamattina nella stessa
/// settimana e nello stesso mese: i conti non dipendono dal giorno in cui
/// gira il test.
final _stasera = Allenamento(
  id: 'stasera',
  clubId: 'c1',
  data: DateTime(_oggi.year, _oggi.month, _oggi.day, 23, 30),
  gruppoId: 'u14',
);
final _mattine = [
  Allenamento(id: 'm1', clubId: 'c1', data: _mezzanotte, gruppoId: 'u14'),
  Allenamento(
    id: 'm2',
    clubId: 'c1',
    data: _mezzanotte.add(const Duration(minutes: 1)),
    gruppoId: 'u14',
  ),
];

Presenza _presenza(String atleta, String allenamento, String stato) => Presenza(
  id: '$atleta-$allenamento',
  allenamentoId: allenamento,
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

SchedaBenessere _scheda(
  String atleta, {
  bool dolori = false,
  List<String> zone = const [],
  int? intensita,
  List<String> sintomi = const [],
}) => SchedaBenessere(
  id: 'scheda-$atleta',
  atletaId: atleta,
  clubId: 'c1',
  data: _mezzanotte,
  dolori: dolori,
  zoneDolore: zone,
  intensitaDolore: intensita,
  oreSonno: 8,
  compilataIl: _oggi,
  qualitaSonno: 4,
  energia: 4,
  muscoli: 4,
  stress: 4,
  umore: 4,
  sintomi: sintomi,
);

/// Registra cosa si segna, senza toccare il database.
class _Archivio implements PresenzeRepository {
  final segnate = <(String, String)>[];

  @override
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    segnate.add((atletaId, stato));
    return _presenza(atletaId, allenamentoId, stato);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(ThemeData tema, _Archivio archivio, Widget figlio) => ProviderScope(
  overrides: [
    presenzeRepositoryProvider.overrideWithValue(archivio),
    atletiListProvider.overrideWith(
      (ref, filtro) => Stream.value([
        _atleta('r', 'Rossi'),
        _atleta('b', 'Bianchi'),
        _atleta('v', 'Verdi'),
        _atleta('n', 'Neri'),
      ]),
    ),
    // Stasera: Rossi in ritardo, Bianchi presente, Verdi assente, Neri da
    // segnare.
    presenzeListProvider.overrideWith(
      (ref, id) => Stream.value([
        _presenza('r', 'stasera', 'ritardo'),
        _presenza('b', 'stasera', 'presente'),
        _presenza('v', 'stasera', 'assente'),
      ]),
    ),
    allenamentiListProvider.overrideWith(
      (ref, clubId) => Stream.value([..._mattine, _stasera]),
    ),
    presenzeClubProvider.overrideWith(
      (ref, clubId) => Stream.value([
        _presenza('r', 'm1', 'presente'),
        _presenza('r', 'm2', 'assente'),
        _presenza('b', 'm1', 'assente'),
        _presenza('b', 'm2', 'assente'),
        _presenza('v', 'm1', 'presente'),
        _presenza('v', 'm2', 'presente'),
        // L'archivio ha ancora il vecchio appello di stasera: conta quello
        // che si vede sullo schermo.
        _presenza('r', 'stasera', 'assente'),
      ]),
    ),
    // Rossi: dolore al ginocchio, ma la prontezza è buona. Verdi: febbre.
    // Bianchi sta bene, Neri non ha compilato.
    schedeBenessereClubProvider.overrideWith(
      (ref, clubId) => Stream.value([
        _scheda('r', dolori: true, zone: const ['ginocchio'], intensita: 3),
        _scheda('b'),
        _scheda('v', sintomi: const ['febbre']),
      ]),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value([
        const Gruppo(id: 'u14', clubId: 'c1', nome: 'Under 14', ordine: 1),
      ]),
    ),
    personalBestClubProvider.overrideWith(
      (ref, clubId) => Stream.value(const <PersonalBest>[]),
    ),
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

Future<_Archivio> _apri(WidgetTester tester, ThemeData tema) async {
  SharedPreferences.setMockInitialValues({});
  // 360 di larghezza, alto abbastanza da vedere tutte e quattro le righe.
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final archivio = _Archivio();
  await tester.pumpWidget(
    _app(tema, archivio, PresenzeScreen(allenamento: _stasera)),
  );
  await tester.pumpAndSettle();
  return archivio;
}

// Sempre lo stesso ProviderScope: la barra del club nascosta dalla
// schermata si rimette a posto prima che i provider spariscano.
Future<void> _chiudi(WidgetTester tester, ThemeData tema) =>
    tester.pumpWidget(_app(tema, _Archivio(), const SizedBox()));

void main() {
  for (final (nome, tema) in [
    ('chiaro', AppTheme.chiaro),
    ('scuro', AppTheme.scuro),
  ]) {
    group('l\'appello a 360 px con il testo al 130%, tema $nome', () {
      testWidgets('quattro stati per ogni atleta, tutti toccabili', (
        tester,
      ) async {
        final archivio = await _apri(tester, tema);
        expect(tester.takeException(), isNull);

        for (final etichetta in [
          'Presente',
          'In ritardo',
          'Assente',
          'Giustificato',
        ]) {
          expect(find.text(etichetta), findsNWidgets(4), reason: etichetta);
        }
        // Grandi bersagli: nessun bottone sotto i 64.
        for (final etichetta in [
          'Presente',
          'In ritardo',
          'Assente',
          'Giustificato',
        ]) {
          for (var i = 0; i < 4; i++) {
            final bottone = find
                .ancestor(
                  of: find.text(etichetta).at(i),
                  matching: find.byType(InkWell),
                )
                .first;
            expect(tester.getSize(bottone).height, greaterThanOrEqualTo(64));
          }
        }

        // Neri è il quarto: da segnare, lo segno in ritardo.
        await tester.tap(find.text('In ritardo').at(3));
        await tester.pump();
        expect(archivio.segnate, [('n', 'ritardo')]);
        await tester.tap(find.text('Giustificato').at(3));
        await tester.pump();
        expect(archivio.segnate.last, ('n', 'giustificato'));
        await tester.tap(find.text('Assente').at(0));
        await tester.pump();
        expect(archivio.segnate.last, ('r', 'assente'));
        await tester.tap(find.text('Presente').at(0));
        await tester.pump();
        expect(archivio.segnate.last, ('r', 'presente'));
        expect(tester.takeException(), isNull);
        await _chiudi(tester, tema);
      });

      testWidgets('il riepilogo: chi è in ritardo è tra i presenti', (
        tester,
      ) async {
        await _apri(tester, tema);
        expect(find.text('di cui 1 in ritardo'), findsOneWidget);
        // Presenti 2 (Bianchi e Rossi in ritardo), assenti 1, da segnare 1.
        final numeri = [
          for (final t in tester.widgetList<Text>(find.byType(Text)))
            if (RegExp(r'^\d$').hasMatch(t.data ?? '')) t.data,
        ];
        expect(numeri.take(4), ['2', '1', '0', '1']);
        expect(find.text('Segna presente l\'ultimo'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _chiudi(tester, tema);
      });

      testWidgets('accanto al nome: questa settimana e questo mese', (
        tester,
      ) async {
        await _apri(tester, tema);
        final mese = inMese(_stasera.data);
        // Rossi: stamattina presente e assente, stasera in ritardo.
        // Bianchi: assente due volte, stasera presente. Verdi: presente due
        // volte, stasera assente. Neri: due sedute da segnare e stasera.
        expect(find.text('2 su 3 questa settimana'), findsNWidgets(2));
        expect(find.text('2 su 3 $mese'), findsNWidgets(2));
        expect(find.text('1 su 3 $mese'), findsOneWidget);
        expect(find.text('1 su 3 questa settimana'), findsOneWidget);
        expect(find.text('0 su 3 questa settimana'), findsOneWidget);
        expect(find.textContaining('su 3 questa settimana'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await _chiudi(tester, tema);
      });

      testWidgets('il punto del benessere solo per chi sta peggio', (
        tester,
      ) async {
        await _apri(tester, tema);
        // Rossi: dolore al ginocchio con la prontezza buona. Verdi: febbre.
        expect(find.byKey(const ValueKey('benessere-r')), findsOneWidget);
        expect(find.byKey(const ValueKey('benessere-v')), findsOneWidget);
        // Bianchi sta bene, Neri non ha compilato.
        expect(find.byKey(const ValueKey('benessere-b')), findsNothing);
        expect(find.byKey(const ValueKey('benessere-n')), findsNothing);
        expect(
          find.byTooltip('Benessere da seguire: dolore ginocchio 3/10'),
          findsOneWidget,
        );
        expect(find.byTooltip('Benessere da sentire: febbre'), findsOneWidget);
        // Bersaglio da almeno 48.
        final misura = tester.getSize(
          find.byKey(const ValueKey('benessere-r')),
        );
        expect(misura.width, greaterThanOrEqualTo(48));
        expect(misura.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await _chiudi(tester, tema);
      });
    });
  }

  group('il segnale di benessere', () {
    final oggi = DateTime(2026, 10, 20);
    SchedaBenessere scheda({
      int voce = 4,
      double sonno = 8,
      bool dolori = false,
      List<String> zone = const [],
      int? intensita,
      List<String> sintomi = const [],
    }) => SchedaBenessere(
      id: 's',
      atletaId: 'a',
      clubId: 'c1',
      data: oggi,
      dolori: dolori,
      zoneDolore: zone,
      intensitaDolore: intensita,
      oreSonno: sonno,
      compilataIl: oggi,
      qualitaSonno: voce,
      energia: voce,
      muscoli: voce,
      stress: voce,
      umore: voce,
      sintomi: sintomi,
    );

    SegnaleBenessere? segnale(SchedaBenessere? s) =>
        segnaleBenessere(s, s == null ? null : calcolaPunteggio(s));

    test('niente scheda, niente punto', () {
      expect(segnale(null), isNull);
    });

    test('una scheda a posto, niente punto', () {
      expect(segnale(scheda()), isNull);
    });

    test('un dolore con la prontezza buona: giallo', () {
      final s = segnale(
        scheda(dolori: true, zone: const ['spalla'], intensita: 2),
      );
      expect(s?.livello, 1);
      expect(s?.testo, 'Benessere da seguire: dolore spalla 2/10');
    });

    test('da seguire: giallo, con il motivo', () {
      final s = segnale(scheda(voce: 3, sonno: 7));
      expect(s?.livello, 1);
      expect(s?.testo, 'Benessere da seguire: sonno 7 h (obiettivo 8 h)');
    });

    test('da sentire: rosso', () {
      final s = segnale(scheda(sintomi: const ['febbre']));
      expect(s?.livello, 2);
      expect(s?.testo, 'Benessere da sentire: febbre');
    });

    test('dolore forte: rosso, con la zona e l\'intensità', () {
      final s = segnale(
        scheda(dolori: true, zone: const ['spalla', 'gomito'], intensita: 8),
      );
      expect(s?.livello, 2);
      expect(s?.testo, 'Benessere da sentire: dolore spalla, gomito 8/10');
    });
  });
}
