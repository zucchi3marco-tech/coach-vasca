import 'package:coach_vasca/features/ai_genera/presentation/genera_allenamento_form_screen.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/application/passo_riferimento_provider.dart';
import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/allenamento_detail_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AllenamentiFinti implements AllenamentiRepository {
  final creati = <DateTime>[];

  @override
  Future<Allenamento> createAllenamento({
    required String clubId,
    required DateTime data,
    String? titolo,
    String? gruppoId,
    String? note,
  }) async {
    creati.add(data);
    return Allenamento(id: 'nuovo', clubId: clubId, data: data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SerieFinte implements SerieRepository {
  final create = <String>[];
  final gruppi = <String?>[];

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
    create.add('$allenamentoId $ordine $blocco ${ripetute}x$distanzaM');
    gruppi.add(piramideId);
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

void main() {
  testWidgets(
    'Scrivi o detta: totali che crescono e allenamento creato senza AI',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final allenamenti = _AllenamentiFinti();
      final serie = _SerieFinte();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allenamentiRepositoryProvider.overrideWithValue(allenamenti),
            serieRepositoryProvider.overrideWithValue(serie),
            gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
            passoRiferimentoProvider.overrideWith((ref, chiave) => null),
            serieListProvider.overrideWith((ref, id) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            home: const GeneraAllenamentoFormScreen(clubId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Si apre su "Scrivi o detta": niente da creare finché non si
      // scrive una serie.
      final crea = find.widgetWithText(FilledButton, "Crea l'allenamento");
      expect(tester.widget<FilledButton>(crea).onPressed, isNull);
      Finder totali(String metri) =>
          find.bySemanticsLabel(RegExp('^Allenamento: $metri metri'));
      expect(totali('0'), findsOneWidget);

      final testo = find.byKey(const Key('testo-allenamento'));
      await tester.enterText(testo, 'Riscaldamento\n400 mi');
      await tester.pump();
      expect(totali('400'), findsOneWidget);

      await tester.enterText(
        testo,
        'Riscaldamento\n400 mi\n\nPrincipale\n2x\n4x50 sl B1 r15\n100 do\n',
      );
      await tester.pump();
      // 400 + 2 × (200 + 100).
      expect(totali('1.000'), findsOneWidget);
      expect(find.text('Come le ho capite'), findsOneWidget);

      await tester.ensureVisible(crea);
      await tester.tap(crea);
      // Il dettaglio ha l'acqua animata in testata: non si ferma mai.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(allenamenti.creati, hasLength(1));
      expect(serie.create, [
        'nuovo 1 riscaldamento 1x400',
        'nuovo 2 principale 4x50',
        'nuovo 3 principale 1x100',
        'nuovo 4 principale 4x50',
        'nuovo 5 principale 1x100',
      ]);
      // Il "2x" è un gruppo solo.
      expect(serie.gruppi.first, isNull);
      expect(serie.gruppi.skip(1).toSet(), hasLength(1));
      expect(find.byType(AllenamentoDetailScreen), findsOneWidget);
    },
  );
}
