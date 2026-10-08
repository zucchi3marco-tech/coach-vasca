import 'package:coach_vasca/features/ai_genera/data/generazione_ai_repository.dart';
import 'package:coach_vasca/features/ai_genera/data/generazioni_ai_repository.dart';
import 'package:coach_vasca/features/ai_genera/domain/scheda_generata.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/grafico_intensita.dart';
import 'package:coach_vasca/features/allenamenti/presentation/scrivi_allenamento_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GenerazioneFinta implements GenerazioneAiRepository {
  String? testoRicevuto;

  @override
  Future<SchedaGenerata> generaDaDettatura({
    required String testo,
    required String clubId,
    String? gruppo,
  }) async {
    testoRicevuto = testo;
    return const SchedaGenerata(
      titolo: 'ignorato',
      serie: [
        SerieGenerata(
          ordine: 1,
          blocco: 'defaticamento',
          ripetute: 1,
          distanzaM: 200,
          stile: 'dorso',
          esecuzione: 'nuoto',
          zona: 'A1',
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StoricoFinto implements GenerazioniAiRepository {
  @override
  Future<String> registraGenerazione({
    required String clubId,
    required Map<String, dynamic> parametri,
    required String esito,
    Map<String, dynamic>? scheda,
    String? messaggioErrore,
  }) async => 'g1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SerieFinta implements SerieRepository {
  final operazioni = <String>[];
  final create = <Map<String, Object?>>[];
  final aggiornate = <Map<String, Object?>>[];

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
  }) async {
    operazioni.add('crea $ordine');
    create.add({
      'ordine': ordine,
      'blocco': blocco,
      'ripetute': ripetute,
      'distanzaM': distanzaM,
      'zona': zona,
      'piramideId': piramideId,
    });
    return _serie(ordine, ripetute: ripetute, distanzaM: distanzaM ?? 100);
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
  }) async {
    operazioni.add('aggiorna $id');
    aggiornate.add({'id': id, 'ripetute': ripetute, 'distanzaM': distanzaM});
    return _serie(ordine, ripetute: ripetute, distanzaM: distanzaM ?? 100);
  }

  @override
  Future<void> deleteSerie(String id) async => operazioni.add('elimina $id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Serie _serie(
  int ordine, {
  String blocco = 'principale',
  int ripetute = 1,
  int distanzaM = 100,
  String? zona,
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: 'nuoto',
  zona: zona,
);

final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 10, 8),
);

/// Apre la schermata da una pagina vuota, così si vede se si chiude.
Future<void> _apri(
  WidgetTester tester, {
  required _SerieFinta repository,
  List<Serie> serie = const [],
  _GenerazioneFinta? generazione,
  ThemeData? tema,
  Size schermo = const Size(400, 1600),
}) async {
  tester.view.physicalSize = schermo;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serieRepositoryProvider.overrideWithValue(repository),
        generazioneAiRepositoryProvider.overrideWithValue(
          generazione ?? _GenerazioneFinta(),
        ),
        generazioniAiRepositoryProvider.overrideWithValue(_StoricoFinto()),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: tema ?? AppTheme.chiaro,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ScriviAllenamentoScreen(
                      allenamento: _allenamento,
                      serie: serie,
                    ),
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('apri'));
  await tester.pumpAndSettle();
}

Finder get _testo => find.byKey(const Key('testo-allenamento'));

String _testoScritto(WidgetTester tester) =>
    tester.widget<TextField>(_testo).controller!.text;

void main() {
  testWidgets('si apre con le serie già scritte e salva solo quella cambiata', (
    tester,
  ) async {
    final repository = _SerieFinta();
    await _apri(
      tester,
      repository: repository,
      serie: [
        _serie(1, blocco: 'riscaldamento', distanzaM: 400),
        _serie(2, ripetute: 8, zona: 'B1'),
      ],
    );

    expect(
      _testoScritto(tester),
      'Riscaldamento\n400 sl\n\nPrincipale\n8x100 sl B1',
    );
    expect(find.text('Come le ho capite'), findsOneWidget);
    expect(find.text('8×100m Libero'), findsOneWidget);
    expect(find.byType(GraficoIntensita), findsOneWidget);

    await tester.enterText(
      _testo,
      'Riscaldamento\n400 sl\n\nPrincipale\n10x100 sl B1',
    );
    await tester.pump();
    expect(find.text('10×100m Libero'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(repository.operazioni, ['aggiorna s2']);
    expect(repository.aggiornate.single['ripetute'], 10);
    expect(find.byType(ScriviAllenamentoScreen), findsNothing);
  });

  testWidgets('un "2x" diventa un gruppo; le righe non capite si segnalano', (
    tester,
  ) async {
    final repository = _SerieFinta();
    await _apri(tester, repository: repository, tema: AppTheme.scuro);

    await tester.enterText(_testo, '2x\n4x50 sl A2\n100 do\n\nboh');
    await tester.pump();

    expect(find.text('2×'), findsOneWidget);
    expect(find.textContaining('non diventa una serie'), findsOneWidget);
    // 2 × (200 + 100) metri.
    expect(find.textContaining('600 m'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('Una riga non è stata capita'), findsOneWidget);
    await tester.tap(find.text('Salva lo stesso'));
    await tester.pumpAndSettle();

    expect(repository.create.map((c) => c['distanzaM']), [50, 100, 50, 100]);
    final gruppi = repository.create.map((c) => c['piramideId']).toSet();
    expect(gruppi, hasLength(1));
    expect(gruppi.single, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quello che si detta lo trasforma l\'AI e va in fondo al testo', (
    tester,
  ) async {
    final generazione = _GenerazioneFinta();
    await _apri(
      tester,
      repository: _SerieFinta(),
      generazione: generazione,
      serie: [_serie(1, distanzaM: 400)],
    );

    await tester.tap(find.text('Detta o descrivi a parole'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextFormField),
      ),
      'per finire 200 dorso sciolto',
    );
    await tester.tap(find.text('Trasforma in serie'));
    await tester.pumpAndSettle();

    expect(generazione.testoRicevuto, 'per finire 200 dorso sciolto');
    expect(
      _testoScritto(tester),
      'Principale\n400 sl\n\nDefaticamento\n200 do A1',
    );
  });

  testWidgets('su schermo largo testo e anteprima stanno affiancati', (
    tester,
  ) async {
    await _apri(
      tester,
      repository: _SerieFinta(),
      schermo: const Size(1280, 900),
      serie: [_serie(1, distanzaM: 400, zona: 'A1')],
    );
    expect(tester.takeException(), isNull);
    final testo = tester.getRect(_testo);
    final anteprima = tester.getTopLeft(find.text('Come le ho capite'));
    expect(anteprima.dx, greaterThan(testo.right));
    expect(anteprima.dy, lessThan(testo.bottom));
  });

  testWidgets('uscendo con modifiche non salvate chiede conferma', (
    tester,
  ) async {
    await _apri(tester, repository: _SerieFinta());
    await tester.enterText(_testo, '400 sl');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Uscire senza salvare?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriviAllenamentoScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    expect(find.byType(ScriviAllenamentoScreen), findsNothing);
  });
}
