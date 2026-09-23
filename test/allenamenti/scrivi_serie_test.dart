import 'package:coach_vasca/features/ai_genera/data/generazione_ai_repository.dart';
import 'package:coach_vasca/features/ai_genera/data/generazioni_ai_repository.dart';
import 'package:coach_vasca/features/ai_genera/domain/scheda_generata.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/scrivi_serie_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GenerazioneFinta implements GenerazioneAiRepository {
  Object? errore;

  @override
  Future<SchedaGenerata> generaDaDettatura({
    required String testo,
    String? gruppo,
  }) async {
    if (errore != null) throw errore!;
    return const SchedaGenerata(
      titolo: 'ignorato',
      serie: [
        SerieGenerata(
          ordine: 1,
          blocco: 'riscaldamento',
          ripetute: 1,
          distanzaM: 400,
          stile: 'misti',
          esecuzione: 'nuoto',
        ),
        SerieGenerata(
          ordine: 2,
          blocco: 'principale',
          ripetute: 8,
          distanzaM: 100,
          stile: 'libero',
          esecuzione: 'nuoto',
          zona: 'B1',
          recuperoS: 20,
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
  final create = <Map<String, dynamic>>[];
  Object? errore;

  @override
  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    required int distanzaM,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
  }) async {
    if (errore != null) throw errore!;
    create.add({
      'allenamentoId': allenamentoId,
      'ordine': ordine,
      'blocco': blocco,
    });
    return Serie(
      id: 's$ordine',
      allenamentoId: allenamentoId,
      clubId: 'c1',
      ordine: ordine,
      blocco: blocco,
      ripetute: ripetute,
      distanzaM: distanzaM,
      stile: stile,
      esecuzione: esecuzione,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _allenamento = Allenamento(
  id: 'a1',
  clubId: 'c1',
  data: DateTime(2026, 9, 23),
);

Widget _app({
  required _GenerazioneFinta generazione,
  required _SerieFinta serie,
}) => ProviderScope(
  overrides: [
    generazioneAiRepositoryProvider.overrideWithValue(generazione),
    generazioniAiRepositoryProvider.overrideWithValue(_StoricoFinto()),
    serieRepositoryProvider.overrideWithValue(serie),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    home: ScriviSerieScreen(allenamento: _allenamento, ordineSuccessivo: 1),
  ),
);

void main() {
  testWidgets('interpreta il testo, mostra l\'anteprima e aggiunge le serie '
      'all\'allenamento esistente', (tester) async {
    final generazione = _GenerazioneFinta();
    final serie = _SerieFinta();
    await tester.pumpWidget(_app(generazione: generazione, serie: serie));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'riscaldamento 400 misti, poi 8x100 libero soglia rec 20',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 serie interpretate'), findsOneWidget);
    expect(find.textContaining('400m'), findsOneWidget);
    expect(find.textContaining('100m'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Aggiungi 2 serie'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi 2 serie'));
    await tester.pumpAndSettle();

    expect(serie.create.length, 2);
    expect(serie.create[0]['allenamentoId'], 'a1');
    expect(serie.create[0]['ordine'], 1);
    expect(serie.create[1]['ordine'], 2);
  });

  testWidgets('un testo vuoto non chiama la generazione', (tester) async {
    final generazione = _GenerazioneFinta();
    final serie = _SerieFinta();
    await tester.pumpWidget(_app(generazione: generazione, serie: serie));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.pumpAndSettle();

    expect(find.text('Scrivi o detta prima le serie'), findsOneWidget);
    expect(find.textContaining('serie interpretate'), findsNothing);
  });

  testWidgets('se l\'interpretazione fallisce mostra l\'errore', (
    tester,
  ) async {
    final generazione = _GenerazioneFinta()..errore = Exception('boom');
    final serie = _SerieFinta();
    await tester.pumpWidget(_app(generazione: generazione, serie: serie));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'qualcosa');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Interpreta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('serie interpretate'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
