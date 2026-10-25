import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/distinta_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/referti/application/referti_providers.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/referti/presentation/chi_era_in_porta.dart';
import 'package:coach_vasca/features/referti/presentation/referto_partita_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DistintaFinta implements DistintaRepository {
  /// Cosa è stato salvato: id della riga di distinta → tempi.
  final salvati = <String, List<int>>{};

  @override
  Future<void> impostaTempiInPorta(String id, List<int> tempi) async {
    salvati[id] = tempi;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _partita = Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 24),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: 'casa',
);

DistintaGiocatore _riga(
  String id,
  int numero, {
  bool portiere = true,
  List<int> tempi = const [],
}) => DistintaGiocatore(
  id: 'd$id',
  partitaId: 'p1',
  atletaId: id,
  clubId: 'c1',
  numeroCalottina: numero,
  capitano: false,
  viceCapitano: false,
  portiere: portiere,
  fuoriquota: false,
  tempiInPorta: tempi,
);

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Marco',
  cognome: cognome,
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  ruolo: 'portiere',
  consensoPrivacyFirmato: true,
  attivo: true,
);

const _referto = RefertoPartita(
  id: 'r1',
  partitaId: 'p1',
  clubId: 'c1',
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  risultatoCasa: 8,
  risultatoTrasferta: 6,
  parziali: [
    ParzialeReferto(casa: 2, trasferta: 1),
    ParzialeReferto(casa: 2, trasferta: 2),
    ParzialeReferto(casa: 2, trasferta: 1),
    ParzialeReferto(casa: 2, trasferta: 2),
  ],
  giocatoriCasa: [],
  giocatoriTrasferta: [],
);

void main() {
  late _DistintaFinta repo;
  final chiave = GlobalKey<ChiEraInPortaState>();

  setUp(() => repo = _DistintaFinta());

  Future<void> apri(
    WidgetTester tester,
    List<DistintaGiocatore> distinta, {
    bool schermataReferto = false,
  }) async {
    tester.view.physicalSize = const Size(500, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          distintaRepositoryProvider.overrideWithValue(repo),
          distintaListProvider.overrideWith(
            (ref, id) => Stream.value(distinta),
          ),
          atletiListProvider.overrideWith(
            (ref, filtro) =>
                Stream.value([_atleta('1', 'Bianchi'), _atleta('2', 'Verdi')]),
          ),
          refertoPerPartitaProvider.overrideWith((ref, id) async => _referto),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          // Come "Riduci movimento": l'acqua della testata è animata.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: schermataReferto
              ? RefertoPartitaScreen(partita: _partita)
              : Scaffold(
                  body: SingleChildScrollView(
                    child: ChiEraInPorta(
                      key: chiave,
                      partita: _partita,
                      tempi: 4,
                    ),
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La scelta del tempo [t]: il chip con quel nome nella riga del tempo.
  Finder chip(int t, String nome) => find.descendant(
    of: find.ancestor(of: find.text('Tempo $t'), matching: find.byType(Row)),
    matching: find.text(nome),
  );

  testWidgets('due portieri: si sceglie tempo per tempo e si salva', (
    tester,
  ) async {
    await apri(tester, [_riga('1', 1), _riga('2', 13)]);

    expect(find.text('Chi era in porta?'), findsOneWidget);
    for (var t = 1; t <= 4; t++) {
      expect(find.text('Tempo $t'), findsOneWidget);
    }
    for (final t in [1, 2]) {
      await tester.tap(chip(t, '1 · Bianchi'));
      await tester.pump();
    }
    for (final t in [3, 4]) {
      await tester.tap(chip(t, '13 · Verdi'));
      await tester.pump();
    }

    await chiave.currentState!.salva();

    expect(repo.salvati, {
      'd1': [1, 2],
      'd2': [3, 4],
    });
  });

  testWidgets('un solo portiere e niente segnato: scelto per tutti i tempi', (
    tester,
  ) async {
    await apri(tester, [_riga('1', 1), _riga('3', 5, portiere: false)]);

    await chiave.currentState!.salva();

    expect(repo.salvati, {
      'd1': [1, 2, 3, 4],
    });
  });

  testWidgets('parte da quanto è già segnato e tiene i tempi oltre il 4', (
    tester,
  ) async {
    await apri(tester, [
      _riga('1', 1, tempi: [1, 2, 5]),
      _riga('2', 13, tempi: [3, 4]),
    ]);

    // Il secondo tempo passa al secondo portiere.
    await tester.tap(chip(2, '13 · Verdi'));
    await tester.pump();
    await chiave.currentState!.salva();

    expect(repo.salvati, {
      'd1': [1, 5],
      'd2': [2, 3, 4],
    });
  });

  testWidgets('un cambio a metà tempo dal vivo resta, se non lo tocchi', (
    tester,
  ) async {
    // Dal vivo il 2° tempo è di tutti e due.
    await apri(tester, [
      _riga('1', 1, tempi: [1, 2]),
      _riga('2', 13, tempi: [2, 3, 4]),
    ]);

    // Si cambia solo il 4° tempo.
    await tester.tap(chip(4, '1 · Bianchi'));
    await tester.pump();
    await chiave.currentState!.salva();

    expect(repo.salvati, {
      'd1': [1, 2, 4],
      'd2': [2, 3],
    });
  });

  testWidgets('senza modifiche non scrive nulla', (tester) async {
    await apri(tester, [
      _riga('1', 1, tempi: [1, 2]),
      _riga('2', 13, tempi: [3, 4]),
    ]);

    await chiave.currentState!.salva();

    expect(repo.salvati, isEmpty);
  });

  testWidgets('senza portieri in distinta lo dice', (tester) async {
    await apri(tester, [_riga('3', 5, portiere: false)]);

    expect(
      find.text('Segna un portiere nella distinta per contare i gol subiti.'),
      findsOneWidget,
    );
    expect(find.text('Tempo 1'), findsNothing);
    await chiave.currentState!.salva();
    expect(repo.salvati, isEmpty);
  });

  testWidgets('nel referto salvato: scelta e pulsante «Salva»', (tester) async {
    await apri(tester, [_riga('1', 1), _riga('2', 13)], schermataReferto: true);

    expect(find.text('Chi era in porta?'), findsOneWidget);
    final salva = find.text('Salva chi era in porta');
    await tester.ensureVisible(salva);
    // Niente da salvare finché non si sceglie.
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Salva chi era in porta'),
          )
          .onPressed,
      isNull,
    );

    for (final t in [1, 2, 3, 4]) {
      final c = chip(t, t <= 2 ? '1 · Bianchi' : '13 · Verdi');
      await tester.ensureVisible(c);
      await tester.tap(c);
      await tester.pump();
    }
    await tester.ensureVisible(salva);
    await tester.tap(salva);
    await tester.pumpAndSettle();

    expect(repo.salvati, {
      'd1': [1, 2],
      'd2': [3, 4],
    });
    expect(find.text('Portieri salvati.'), findsOneWidget);
  });
}
