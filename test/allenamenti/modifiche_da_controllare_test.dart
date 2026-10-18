import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/application/passo_riferimento_provider.dart';
import 'package:coach_vasca/features/allenamenti/data/modifiche_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/allenamento_detail_screen.dart';
import 'package:coach_vasca/features/allenamenti/presentation/banner_modifica.dart';
import 'package:coach_vasca/features/allenamenti/presentation/confronto_modifica_screen.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/theme/colori_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: tiene le modifiche e annota quelle segnate come viste.
class _ModificheFinte implements ModificheRepository {
  _ModificheFinte(this.elenco);

  final List<ModificaAllenamento> elenco;
  final viste = <String>[];
  Object? errore;

  @override
  Future<List<ModificaAllenamento>> daControllare(String clubId) async => [
    for (final m in elenco)
      if (!viste.contains(m.id)) m,
  ];

  @override
  Future<ModificaAllenamento?> aperta(String allenamentoId) async => [
    for (final m in elenco)
      if (m.allenamentoId == allenamentoId && !viste.contains(m.id)) m,
  ].firstOrNull;

  @override
  Future<void> segnaVista(String id) async {
    if (errore != null) throw errore!;
    viste.add(id);
  }
}

Map<String, dynamic> _rigaSerie(
  String id,
  int ordine, {
  int ripetute = 4,
  int distanzaM = 100,
  String zona = 'B1',
  String blocco = 'principale',
}) => {
  'id': id,
  'allenamento_id': 'a1',
  'club_id': 'c1',
  'ordine': ordine,
  'blocco': blocco,
  'ripetute': ripetute,
  'distanza_m': distanzaM,
  'durata_s': null,
  'stile': 'libero',
  'esecuzione': 'nuoto',
  'zona': zona,
};

ModificaAllenamento _modifica({
  String id = 'm1',
  String allenamentoId = 'a1',
  List<String> autori = const ['Luca Bianchi'],
  bool nuovo = false,
  Map<String, dynamic>? prima,
  String? titolo = 'Tecnica',
  int minutiFa = 25,
}) {
  final ultima = DateTime.now().toUtc().subtract(Duration(minutes: minutiFa));
  return ModificaAllenamento.fromMap({
    'id': id,
    'allenamento_id': allenamentoId,
    'club_id': 'c1',
    'capo_user_id': 'u-capo',
    'autori': autori,
    'nuovo': nuovo,
    'prima': prima,
    'aperta_at': ultima.toIso8601String(),
    'ultima_at': ultima.toIso8601String(),
    'visto_at': null,
    'allenamenti': {'titolo': titolo, 'data': '2026-10-20', 'gruppo_id': 'g14'},
  });
}

final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 10, 20),
  titolo: 'Tecnica',
  gruppoId: 'g14',
  note: 'Portare le palette',
);

Serie _serie(
  String id,
  int ordine, {
  int ripetute = 4,
  int distanzaM = 100,
  String zona = 'B1',
  String blocco = 'principale',
}) => Serie.fromMap(
  _rigaSerie(
    id,
    ordine,
    ripetute: ripetute,
    distanzaM: distanzaM,
    zona: zona,
    blocco: blocco,
  ),
);

Widget _app(Widget home, {required List<Override> overrides}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // L'acqua animata della testata non si ferma mai: nei test, ferma.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: home)),
  ),
);

void _schermo(WidgetTester tester, {double larghezza = 400}) {
  tester.view.physicalSize = Size(larghezza, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Il colore di fondo della riga che porta questo testo (null se nessuno).
Color? _sfondoDi(WidgetTester tester, String testo) {
  final colori = find
      .ancestor(of: find.text(testo), matching: find.byType(Container))
      .evaluate()
      .map((e) => (e.widget as Container).color)
      .whereType<Color>();
  return colori.firstOrNull;
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  group('banner', () {
    Future<_ModificheFinte> apri(
      WidgetTester tester,
      List<ModificaAllenamento> modifiche,
    ) async {
      _schermo(tester);
      final server = _ModificheFinte(modifiche);
      await tester.pumpWidget(
        _app(
          BannerModifica(allenamento: _allenamento),
          overrides: [modificheRepositoryProvider.overrideWithValue(server)],
        ),
      );
      await _passa(tester);
      return server;
    }

    testWidgets('con una modifica aperta dice chi e quando', (tester) async {
      await apri(tester, [
        _modifica(autori: ['Luca Bianchi', 'Anna Verdi']),
      ]);

      expect(
        find.textContaining('Modificato da Luca Bianchi e Anna Verdi'),
        findsOneWidget,
      );
      expect(find.textContaining('25 minuti fa'), findsOneWidget);
      expect(find.text('Cosa è cambiato'), findsOneWidget);
      expect(find.text('Visto'), findsOneWidget);
    });

    testWidgets('un allenamento aggiunto: «Aggiunto da» e niente confronto', (
      tester,
    ) async {
      await apri(tester, [_modifica(nuovo: true)]);

      expect(find.textContaining('Aggiunto da Luca Bianchi'), findsOneWidget);
      expect(find.text('Cosa è cambiato'), findsNothing);
      expect(find.text('Visto'), findsOneWidget);
    });

    testWidgets('senza modifiche non c\'è niente', (tester) async {
      await apri(tester, []);
      expect(find.textContaining('Modificato da'), findsNothing);
      expect(find.text('Visto'), findsNothing);
    });

    testWidgets('la modifica di un altro allenamento non compare', (
      tester,
    ) async {
      await apri(tester, [_modifica(allenamentoId: 'a2')]);
      expect(find.text('Visto'), findsNothing);
    });

    testWidgets('«Visto» lo segna, toglie la fascia e dà l\'avviso', (
      tester,
    ) async {
      final server = await apri(tester, [_modifica()]);

      await tester.tap(find.text('Visto'));
      await _passa(tester);

      expect(server.viste, ['m1']);
      expect(find.text('Segnato come visto'), findsOneWidget);
      // Riletta: non c'è più.
      expect(find.textContaining('Modificato da'), findsNothing);
    });

    testWidgets('se «Visto» non riesce, un avviso e la fascia resta', (
      tester,
    ) async {
      final server = await apri(tester, [_modifica()]);
      server.errore = Exception('rete');

      await tester.tap(find.text('Visto'));
      await _passa(tester);

      expect(server.viste, isEmpty);
      expect(find.textContaining('Non è stato segnato'), findsOneWidget);
      expect(find.textContaining('Modificato da'), findsOneWidget);
    });

    testWidgets('nel dettaglio dell\'allenamento sta sotto la testata', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = _ModificheFinte([_modifica()]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            modificheRepositoryProvider.overrideWithValue(server),
            serieListProvider.overrideWith(
              (ref, id) => Stream.value([_serie('s1', 1)]),
            ),
            gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
            atletiListProvider.overrideWith((ref, chiave) => Stream.value([])),
            passoRiferimentoProvider.overrideWith((ref, chiave) => null),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: AllenamentoDetailScreen(allenamento: _allenamento),
          ),
        ),
      );
      await _passa(tester);

      expect(find.textContaining('Modificato da Luca Bianchi'), findsOneWidget);
      expect(find.text('Cosa è cambiato'), findsOneWidget);
    });
  });

  group('confronto', () {
    final prima = {
      'allenamento': {
        'titolo': 'Tecnica',
        'data': '2026-10-20',
        'note': 'Portare le palette',
      },
      'serie': [
        _rigaSerie(
          's1',
          1,
          ripetute: 1,
          distanzaM: 400,
          blocco: 'riscaldamento',
        ),
        _rigaSerie('s2', 2, ripetute: 4, distanzaM: 100, zona: 'B1'),
        _rigaSerie('s3', 3, ripetute: 8, distanzaM: 50, zona: 'A2'),
      ],
      'esercizi': [],
    };

    Future<_ModificheFinte> apri(
      WidgetTester tester, {
      required List<Serie> ora,
      Allenamento? allenamento,
      Map<String, dynamic>? primaDi,
      double larghezza = 400,
    }) async {
      _schermo(tester, larghezza: larghezza);
      final server = _ModificheFinte([_modifica()]);
      final a = allenamento ?? _allenamento;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            modificheRepositoryProvider.overrideWithValue(server),
            serieListProvider.overrideWith((ref, id) => Stream.value(ora)),
            allenamentiListProvider.overrideWith(
              (ref, clubId) => Stream.value([a]),
            ),
            atletiListProvider.overrideWith((ref, chiave) => Stream.value([])),
            eserciziSedutaProvider.overrideWith((ref, id) => Stream.value([])),
            eserciziSeccoProvider.overrideWith((ref, id) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ConfrontoModificaScreen(
              modifica: _modifica(prima: primaDi ?? prima),
              allenamento: a,
            ),
          ),
        ),
      );
      await _passa(tester);
      return server;
    }

    // Ora: la B1 diventa B2, la serie da 50 è tolta e se ne aggiunge una.
    final ora = [
      _serie('s1', 1, ripetute: 1, distanzaM: 400, blocco: 'riscaldamento'),
      _serie('s2', 2, ripetute: 4, distanzaM: 100, zona: 'B2'),
      _serie('s4', 3, ripetute: 6, distanzaM: 200, zona: 'C1'),
    ];

    testWidgets('la testata e il confronto: Prima e Ora con le righe segnate', (
      tester,
    ) async {
      await apri(tester, ora: ora);
      const colori = ColoriApp.chiaro;

      expect(find.text('Cosa è cambiato'), findsOneWidget);
      expect(find.text('Tecnica'), findsWidgets);
      expect(
        find.textContaining('Modificato da Luca Bianchi · 25 minuti fa'),
        findsOneWidget,
      );
      expect(find.text('Prima'), findsOneWidget);
      expect(find.text('Ora'), findsOneWidget);

      // Le righe uguali non sono segnate…
      expect(find.text('400 sl B1'), findsNWidgets(2));
      expect(_sfondoDi(tester, '400 sl B1'), isNull);
      // …quelle tolte sono tinte in «Prima», quelle aggiunte in «Ora».
      expect(find.text('4x100 sl B1'), findsOneWidget);
      expect(_sfondoDi(tester, '4x100 sl B1'), colori.rossoTenue);
      expect(find.text('8x50 sl A2'), findsOneWidget);
      expect(_sfondoDi(tester, '8x50 sl A2'), colori.rossoTenue);
      expect(find.text('4x100 sl B2'), findsOneWidget);
      expect(_sfondoDi(tester, '4x100 sl B2'), colori.okTenue);
      expect(find.text('6x200 sl C1'), findsOneWidget);
      expect(_sfondoDi(tester, '6x200 sl C1'), colori.okTenue);
    });

    testWidgets('su telefono Prima sta sopra Ora, su schermo largo di lato', (
      tester,
    ) async {
      await apri(tester, ora: ora);
      final primaStretto = tester.getTopLeft(find.text('Prima'));
      final oraStretto = tester.getTopLeft(find.text('Ora'));
      expect(oraStretto.dy, greaterThan(primaStretto.dy));
      expect(oraStretto.dx, primaStretto.dx);

      await apri(tester, ora: ora, larghezza: 1280);
      final primaLargo = tester.getTopLeft(find.text('Prima'));
      final oraLargo = tester.getTopLeft(find.text('Ora'));
      expect(oraLargo.dy, primaLargo.dy);
      expect(oraLargo.dx, greaterThan(primaLargo.dx));
    });

    testWidgets('titolo, data e note cambiati: «Prima → Ora»', (tester) async {
      final cambiato = Allenamento(
        id: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 22),
        titolo: 'Tecnica e virate',
        gruppoId: 'g14',
        note: 'Portare le palette',
      );
      await apri(tester, ora: ora, allenamento: cambiato);

      expect(find.text('Dati'), findsOneWidget);
      expect(find.text('Titolo'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('martedì 20 ott'), findsOneWidget);
      expect(find.text('giovedì 22 ott'), findsOneWidget);
      expect(find.text('Tecnica e virate'), findsWidgets);
      // Le note non sono cambiate.
      expect(find.text('Note'), findsNothing);
    });

    testWidgets('niente di cambiato nelle serie: lo dice', (tester) async {
      final uguali = [
        _serie('s1', 1, ripetute: 1, distanzaM: 400, blocco: 'riscaldamento'),
        _serie('s2', 2, ripetute: 4, distanzaM: 100, zona: 'B1'),
        _serie('s3', 3, ripetute: 8, distanzaM: 50, zona: 'A2'),
      ];
      await apri(tester, ora: uguali);
      expect(find.text('Le serie non sono cambiate.'), findsOneWidget);
      expect(find.text('Dati'), findsNothing);
    });

    testWidgets('una seduta a secco: gli esercizi, una riga ciascuno', (
      tester,
    ) async {
      final secco = Allenamento(
        id: 'a1',
        clubId: 'c1',
        data: DateTime(2026, 10, 20),
        titolo: 'Tecnica',
        gruppoId: 'g14',
        tipo: 'secco',
      );
      _schermo(tester);
      final primaSecco = {
        'allenamento': {'titolo': 'Tecnica', 'data': '2026-10-20'},
        'serie': [],
        'esercizi': [
          {
            'id': 'r1',
            'allenamento_id': 'a1',
            'club_id': 'c1',
            'esercizio_id': 'e1',
            'ordine': 1,
            'serie': 3,
            'ripetizioni': 12,
            'carico': '60 kg',
          },
          {
            'id': 'r2',
            'allenamento_id': 'a1',
            'club_id': 'c1',
            'esercizio_id': 'e2',
            'ordine': 2,
            'serie': 3,
            'durata_s': 30,
          },
        ],
      };
      const squat = EsercizioSecco(
        id: 'e1',
        clubId: 'c1',
        nome: 'Squat',
        categoria: CategoriaEsercizio.forza,
        misura: MisuraEsercizio.ripetizioni,
      );
      const plank = EsercizioSecco(
        id: 'e2',
        clubId: 'c1',
        nome: 'Plank',
        categoria: CategoriaEsercizio.core,
        misura: MisuraEsercizio.tempo,
      );
      const oraSecco = [
        EsercizioSeduta(
          id: 'r1',
          allenamentoId: 'a1',
          clubId: 'c1',
          esercizioId: 'e1',
          ordine: 1,
          serie: 4,
          ripetizioni: 12,
          carico: '60 kg',
        ),
        EsercizioSeduta(
          id: 'r2',
          allenamentoId: 'a1',
          clubId: 'c1',
          esercizioId: 'e2',
          ordine: 2,
          serie: 3,
          durataS: 30,
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allenamentiListProvider.overrideWith(
              (ref, clubId) => Stream.value([secco]),
            ),
            eserciziSedutaProvider.overrideWith(
              (ref, id) => Stream.value(oraSecco),
            ),
            eserciziSeccoProvider.overrideWith(
              (ref, id) => Stream.value([squat, plank]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ConfrontoModificaScreen(
              modifica: _modifica(prima: primaSecco),
              allenamento: secco,
            ),
          ),
        ),
      );
      await _passa(tester);
      const colori = ColoriApp.chiaro;

      expect(find.text('Esercizi'), findsOneWidget);
      expect(find.text('Squat 3×12 60 kg'), findsOneWidget);
      expect(_sfondoDi(tester, 'Squat 3×12 60 kg'), colori.rossoTenue);
      expect(find.text('Squat 4×12 60 kg'), findsOneWidget);
      expect(_sfondoDi(tester, 'Squat 4×12 60 kg'), colori.okTenue);
      expect(find.text("Plank 3×30''"), findsNWidgets(2));
      expect(_sfondoDi(tester, "Plank 3×30''"), isNull);
    });

    testWidgets('«Visto» in fondo lo segna e torna indietro', (tester) async {
      final server = _ModificheFinte([_modifica()]);
      _schermo(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            modificheRepositoryProvider.overrideWithValue(server),
            serieListProvider.overrideWith((ref, id) => Stream.value(ora)),
            allenamentiListProvider.overrideWith(
              (ref, clubId) => Stream.value([_allenamento]),
            ),
            atletiListProvider.overrideWith((ref, chiave) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ConfrontoModificaScreen(
                        modifica: _modifica(prima: prima),
                        allenamento: _allenamento,
                      ),
                    ),
                  ),
                  child: const Text('apri'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await _passa(tester);
      expect(find.text('Cosa è cambiato'), findsOneWidget);

      await tester.tap(find.text('Visto'));
      await _passa(tester);
      await _passa(tester);

      expect(server.viste, ['m1']);
      // Tornato alla pagina di prima.
      expect(find.text('apri'), findsOneWidget);
      expect(find.text('Cosa è cambiato'), findsNothing);
    });
  });
}
