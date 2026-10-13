import 'dart:async';

import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/programma_secco.dart';
import 'package:coach_vasca/features/secco/presentation/metti_nel_calendario_screen.dart';
import 'package:coach_vasca/features/secco/presentation/programmi_secco_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/tonal_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: tiene esercizi e programmi, annota cosa si salva e
/// cosa si mette nel calendario.
class _SeccoFinto implements SeccoRepository {
  final esercizi = <EsercizioSecco>[];
  final programmi = <ProgrammaSecco>[];
  final salvati = <ProgrammaSecco>[];
  ({String? gruppoId, List<SedutaInCalendario> calendario, int durataMin})?
  messo;
  final _programmi = StreamController<List<ProgrammaSecco>>.broadcast();
  final _esercizi = StreamController<List<EsercizioSecco>>.broadcast();

  Stream<List<ProgrammaSecco>> flussoProgrammi() async* {
    yield [...programmi];
    yield* _programmi.stream;
  }

  Stream<List<EsercizioSecco>> flussoEsercizi() async* {
    yield [...esercizi];
    yield* _esercizi.stream;
  }

  @override
  Future<ProgrammaSecco> aggiungiProgrammaPronto(
    String clubId,
    ProgrammaPronto pronto,
  ) async {
    for (final m in modelliEsercizi) {
      if (pronto.esercizi.contains(m.chiave)) {
        esercizi.add(
          EsercizioSecco(
            id: 'e_${m.chiave}',
            clubId: clubId,
            nome: m.nome,
            categoria: m.categoria,
            misura: m.misura,
            attrezzo: m.attrezzo,
            descrizione: m.descrizione,
            modello: m.chiave,
          ),
        );
      }
    }
    _esercizi.add([...esercizi]);
    final p = ProgrammaSecco(
      id: 'p1',
      clubId: clubId,
      nome: pronto.nome,
      descrizione: pronto.descrizione,
      durataMin: pronto.durataMin,
      settimane: pronto.settimaneCon({
        for (final e in esercizi) e.modello!: e.id,
      }),
      modello: pronto.chiave,
    );
    programmi.add(p);
    _programmi.add([...programmi]);
    return p;
  }

  @override
  Future<ProgrammaSecco> aggiornaProgramma(ProgrammaSecco p) async {
    salvati.add(p);
    programmi[programmi.indexWhere((x) => x.id == p.id)] = p;
    _programmi.add([...programmi]);
    return p;
  }

  @override
  Future<int> mettiNelCalendario({
    required ProgrammaSecco programma,
    required String? gruppoId,
    required List<SedutaInCalendario> calendario,
    required int durataMin,
  }) async {
    messo = (gruppoId: gruppoId, calendario: calendario, durataMin: durataMin);
    return calendario.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// L'acqua animata della testata non si ferma mai: nei test, ferma.
Widget _senzaAnimazioni(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child!,
);

Future<void> _apri(
  WidgetTester tester,
  _SeccoFinto finto,
  Widget schermata,
) async {
  tester.view.physicalSize = const Size(1280, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seccoRepositoryProvider.overrideWithValue(finto),
        programmiSeccoProvider.overrideWith(
          (ref, clubId) => finto.flussoProgrammi(),
        ),
        eserciziSeccoProvider.overrideWith(
          (ref, clubId) => finto.flussoEsercizi(),
        ),
        allenamentiListProvider.overrideWith(
          (ref, clubId) => Stream.value(const []),
        ),
        gruppiListProvider.overrideWith(
          (ref, clubId) => Stream.value(const [
            Gruppo(id: 'u14', clubId: 'c1', nome: 'Under 14', ordine: 1),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: _senzaAnimazioni,
        home: schermata,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("dal programma pronto alla settimana nuova, poi nel calendario", (
    tester,
  ) async {
    final finto = _SeccoFinto();
    await _apri(tester, finto, const ProgrammiSeccoScreen(clubId: 'c1'));

    expect(find.text('Programmi pronti'), findsOneWidget);
    expect(find.text("6 settimane · 2 sedute da 15'"), findsOneWidget);
    expect(find.text("4 settimane · 2 sedute da 20'"), findsNWidgets(3));
    await tester.tap(find.text('Spalla del tiratore'));
    await tester.pumpAndSettle();

    // Il programma, aperto sulla prima settimana.
    expect(find.text('Settimana 1 di 6'), findsOneWidget);
    expect(find.text('Seduta A'), findsOneWidget);
    expect(find.text('Seduta B'), findsOneWidget);
    expect(find.text('Extrarotazione con elastico'), findsOneWidget);
    expect(find.text("2 × 30'' · recupero 15''"), findsNWidgets(2));

    // La quarta è di scarico.
    await tester.tap(find.widgetWithText(TonalChip, '4 · scarico'));
    await tester.pumpAndSettle();
    expect(find.text('Settimana 4 di 6'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.text('Togli una serie a ogni esercizio'), findsOneWidget);

    // Una settimana in più: la sesta con un po' di più, la mobilità no.
    await tester.tap(find.text('Aggiungi la settimana 7'));
    await tester.pumpAndSettle();
    final sette = finto.salvati.last.settimane;
    expect(sette, hasLength(7));
    final extra = sette[6].sedute[0][0];
    expect((extra.serie, extra.ripetizioni), (4, 15));
    expect(extra.carico, 'elastico più duro');
    final sleeper = sette[6].sedute[0][3];
    expect((sleeper.serie, sleeper.durataS), (2, 30));
    expect(find.text('Settimana 7 di 7'), findsOneWidget);
    expect(
      find.text("4 × 15, elastico più duro · recupero 45''"),
      findsWidgets,
    );

    // Un tocco sull'esercizio: una serie in meno.
    await tester.tap(find.text('Extrarotazione con elastico'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Meno').first);
    await tester.pump();
    await tester.tap(find.text('Salva esercizio'));
    await tester.pumpAndSettle();
    expect(finto.salvati.last.settimane[6].sedute[0][0].serie, 3);
    expect(finto.salvati.last.settimane[6].sedute[0][1].serie, 4);

    // Nel calendario: 7 settimane, martedì e giovedì.
    await tester.tap(find.text('Metti nel calendario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metti 14 sedute nel calendario'));
    await tester.pumpAndSettle();
    expect(finto.messo?.calendario, hasLength(14));
    expect(finto.messo?.durataMin, 15);
    expect(finto.messo?.gruppoId, isNull);
    expect(find.text('14 sedute messe nel calendario'), findsOneWidget);
  });

  testWidgets('le date di ogni settimana, i giorni e la squadra', (
    tester,
  ) async {
    final finto = _SeccoFinto();
    const dose = DoseEsercizio(esercizioId: 'e1', serie: 3, ripetizioni: 12);
    await _apri(
      tester,
      finto,
      MettiNelCalendarioScreen(
        oggi: DateTime(2026, 10, 13),
        programma: const ProgrammaSecco(
          id: 'p1',
          clubId: 'c1',
          nome: 'Core',
          durataMin: 20,
          settimane: [
            SettimanaProgramma(
              sedute: [
                [dose],
                [dose],
              ],
            ),
            SettimanaProgramma(
              scarico: true,
              sedute: [
                [dose],
                [],
              ],
            ),
          ],
        ),
      ),
    );

    // Dal lunedì dopo, martedì e giovedì.
    expect(find.text('lunedì 19 ott'), findsOneWidget);
    expect(find.text('A mar 20 ott, B gio 22 ott'), findsOneWidget);
    expect(find.text('Settimana 2 · scarico'), findsOneWidget);
    expect(find.text('A mar 27 ott, B gio 29 ott'), findsOneWidget);
    expect(
      find.text('Una seduta non ha esercizi (settimana 2): si crea vuota.'),
      findsOneWidget,
    );

    // Un giorno solo non basta.
    await tester.tap(find.widgetWithText(TonalChip, 'Gio'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli ancora un giorno.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Scegli i giorni'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(TonalChip, 'Ven'));
    await tester.pumpAndSettle();
    expect(find.text('A mar 20 ott, B ven 23 ott'), findsOneWidget);

    // Per l'Under 14.
    await tester.tap(find.text('Tutto il club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Under 14').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metti 4 sedute nel calendario'));
    await tester.pumpAndSettle();
    expect(finto.messo?.gruppoId, 'u14');
    expect(
      [for (final c in finto.messo!.calendario) c.data],
      [
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 30),
      ],
    );
    expect(finto.messo?.durataMin, 20);
  });
}
