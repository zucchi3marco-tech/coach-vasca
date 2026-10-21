import 'dart:async';

import 'package:coach_vasca/core/video/lettore_youtube.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/secco/application/secco_providers.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/presentation/seduta_secco_atleta_screen.dart';
import 'package:coach_vasca/features/secco/presentation/seduta_secco_screen.dart';
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

/// Il server finto: tiene esercizi e righe della seduta, annota cosa si
/// salva.
class _SeccoFinto implements SeccoRepository {
  final esercizi = <EsercizioSecco>[];
  final righe = <EsercizioSeduta>[];
  final aggiornate = <EsercizioSeduta>[];
  final _cambi = StreamController<List<EsercizioSeduta>>.broadcast();

  Stream<List<EsercizioSeduta>> flusso() async* {
    yield [...righe];
    yield* _cambi.stream;
  }

  @override
  Future<EsercizioSecco> creaEsercizio(EsercizioSecco e) async {
    final creato = EsercizioSecco(
      id: 'e${esercizi.length + 1}',
      clubId: e.clubId,
      nome: e.nome,
      categoria: e.categoria,
      misura: e.misura,
      attrezzo: e.attrezzo,
      descrizione: e.descrizione,
      modello: e.modello,
    );
    esercizi.add(creato);
    return creato;
  }

  @override
  Future<EsercizioSeduta?> ultimaVolta(String esercizioId) async => null;

  @override
  Future<String> aggiungiAllaSeduta(EsercizioSeduta r) async {
    final id = r.id.isEmpty ? 'r${righe.length + 1}' : r.id;
    righe.add(r.copyWith(id: id));
    _cambi.add([...righe]);
    return id;
  }

  @override
  Future<void> aggiornaRiga(EsercizioSeduta r) async => aggiornate.add(r);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// L'acqua animata della testata non si ferma mai: nei test, ferma.
Widget _senzaAnimazioni(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(context).copyWith(disableAnimations: true),
  child: child!,
);

void _schermoGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("l'allenatore sceglie gli esercizi nell'ordine e li cambia", (
    tester,
  ) async {
    _schermoGrande(tester);
    final finto = _SeccoFinto();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seccoRepositoryProvider.overrideWithValue(finto),
          // Il club parte senza esercizi: si scelgono da quelli pronti.
          eserciziSeccoProvider.overrideWith(
            (ref, clubId) => Stream.value(finto.esercizi),
          ),
          eserciziSedutaProvider.overrideWith((ref, id) => finto.flusso()),
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value([_seduta]),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          builder: _senzaAnimazioni,
          home: SedutaSeccoScreen(allenamento: _seduta),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prevenzione spalla'), findsOneWidget);
    expect(find.text('Nessun esercizio'), findsOneWidget);
    expect(find.text("40'"), findsOneWidget);
    await tester.tap(find.text('Aggiungi esercizi').last);
    await tester.pumpAndSettle();

    // Prima il plank, poi l'extrarotazione: il numero dice l'ordine.
    await tester.tap(find.text('Plank frontale'));
    await tester.pump();
    await tester.tap(find.text('Extrarotazione con elastico'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Aggiungi 2 esercizi'));
    await tester.pumpAndSettle();

    expect(
      [for (final e in finto.esercizi) e.modello],
      ['plank_frontale', 'extrarotazione_elastico'],
    );
    expect(finto.righe.map((r) => r.ordine), [1, 2]);
    // Con la prescrizione dell'esercizio pronto.
    expect(finto.righe.first.durataS, 40);
    expect(finto.righe.last.ripetizioni, 15);
    expect(find.text('2 esercizi aggiunti'), findsOneWidget);
    // Di nuovo nella seduta, con gli esercizi.
    expect(find.text("3 × 40'' · recupero 30''"), findsOneWidget);
    expect(find.text("3 × 15 · recupero 45''"), findsOneWidget);

    // Un tocco sull'esercizio: una serie in più e il carico.
    await tester.tap(find.text("3 × 15 · recupero 45''"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Più').first);
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Carico (facoltativo)'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(TextField),
      ),
      'elastico rosso',
    );
    await tester.tap(find.text('Salva esercizio'));
    await tester.pumpAndSettle();
    expect(finto.aggiornate.single.serie, 4);
    expect(finto.aggiornate.single.ripetizioni, 15);
    expect(finto.aggiornate.single.carico, 'elastico rosso');
  });

  testWidgets("l'atleta legge gli esercizi e come si fanno", (tester) async {
    _schermoGrande(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eserciziSedutaAtletaProvider.overrideWith(
            (ref, id) async => [
              const EsercizioSedutaAtleta(
                esercizio: EsercizioSecco(
                  id: 'e1',
                  clubId: '',
                  nome: 'Plank frontale',
                  categoria: CategoriaEsercizio.core,
                  misura: MisuraEsercizio.tempo,
                  descrizione: 'Sugli avambracci, il corpo in linea.',
                  videoYoutube: 'dQw4w9WgXcQ',
                  videoDaS: 15,
                ),
                riga: EsercizioSeduta(
                  id: 'r1',
                  allenamentoId: 's1',
                  clubId: '',
                  esercizioId: 'e1',
                  ordine: 1,
                  durataS: 40,
                  recuperoS: 30,
                ),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          builder: _senzaAnimazioni,
          home: SedutaSeccoAtletaScreen(allenamento: _seduta),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plank frontale'), findsOneWidget);
    expect(find.text("3 × 40'' · recupero 30''"), findsOneWidget);
    // Nella riga si vede che c'è il video.
    expect(find.text('video'), findsOneWidget);
    await tester.tap(find.text('Plank frontale'));
    await tester.pumpAndSettle();
    expect(find.text('Sugli avambracci, il corpo in linea.'), findsOneWidget);
    // Il video si carica solo quando lo si chiede.
    expect(find.byType(LettoreYoutube), findsNothing);
    await tester.tap(find.text('Guarda il video'));
    await tester.pumpAndSettle();
    final lettore = tester.widget<LettoreYoutube>(find.byType(LettoreYoutube));
    expect((lettore.videoId, lettore.inizio), ('dQw4w9WgXcQ', 15));
  });
}
