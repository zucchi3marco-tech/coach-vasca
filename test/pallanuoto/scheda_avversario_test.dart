import 'package:coach_vasca/features/campionati/data/campionati_repository.dart';
import 'package:coach_vasca/features/campionati/domain/campionato_fin.dart';
import 'package:coach_vasca/features/campionati/domain/lettore_fin.dart';
import 'package:coach_vasca/features/campionati/presentation/classifica_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/scheda_avversario.dart';
import 'package:coach_vasca/features/pallanuoto/presentation/scheda_avversario_screen.dart';
import 'package:coach_vasca/features/referti/data/referti_repository.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../campionati/pagine_fin_vere.dart';

Partita _partita(
  String id,
  DateTime data, {
  String? gruppoId = 'u14',
  String avversario = 'PN Monza',
  bool inCasa = true,
  String? calottina,
}) => Partita(
  id: id,
  clubId: 'c1',
  gruppoId: gruppoId,
  data: data,
  squadraCasa: inCasa ? 'Canottieri Milano' : avversario,
  squadraTrasferta: inCasa ? avversario : 'Canottieri Milano',
  numeroMaxConvocati: 14,
  nostraSquadra: inCasa ? 'casa' : 'trasferta',
  coloreCalottina: calottina,
);

RefertoPartita _referto(
  Partita p, {
  required int casa,
  required int trasferta,
  List<GiocatoreReferto> loro = const [],
}) => RefertoPartita(
  id: 'r-${p.id}',
  partitaId: p.id,
  clubId: 'c1',
  squadraCasa: p.squadraCasa,
  squadraTrasferta: p.squadraTrasferta,
  risultatoCasa: casa,
  risultatoTrasferta: trasferta,
  parziali: const [],
  giocatoriCasa: p.inCasa ? const [] : loro,
  giocatoriTrasferta: p.inCasa ? loro : const [],
);

EventoPartita _evento(
  String id,
  String partitaId, {
  required String tipo,
  required String squadra,
  String? esito,
  int? numero,
}) => EventoPartita(
  id: id,
  partitaId: partitaId,
  clubId: 'c1',
  tipo: tipo,
  squadra: squadra,
  esito: esito,
  numeroCalottinaAvversario: numero,
  creatoIl: DateTime(2026, 10, 1),
);

class _Referti implements RefertiRepository {
  _Referti(this.referti);
  final List<RefertoPartita> referti;

  @override
  Future<List<RefertoPartita>> perPartite(List<String> partitaIds) async => [
    for (final r in referti)
      if (partitaIds.contains(r.partitaId)) r,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Eventi implements EventiPartitaRepository {
  _Eventi(this.eventi);
  final List<EventoPartita> eventi;

  @override
  Future<List<EventoPartita>> perPartite(List<String> partitaIds) async => [
    for (final e in eventi)
      if (partitaIds.contains(e.partitaId)) e,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Campionati implements CampionatiRepository {
  @override
  Future<List<GironeCollegato>> collegati(String clubId) async => const [
    GironeCollegato(
      id: 'g1',
      clubId: 'c1',
      gruppoId: 'u14',
      cmpId: 259,
      stagione: '2026-2027',
      campionato: 'Ragazzi (M/F)',
      fase: 'Qualificazioni',
      girone: 'Girone 6',
      squadra: 'CANOTTIERI MILANO',
    ),
  ];

  @override
  Future<LetturaGirone> girone(int cmpId) async => LetturaGirone(
    girone: leggiGironeFin(paginaGironeVera, cmpId: cmpId),
    lettoIl: DateTime(2026, 10, 27, 9),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('lo stesso avversario scritto in modi diversi', () {
    test('sigle, punti e maiuscole non contano', () {
      expect(chiaveSquadra('P.N. Monza'), 'pallanuoto monza');
      expect(chiaveSquadra('PALLANUOTO  MONZA'), 'pallanuoto monza');
      expect(chiaveSquadra('NC Monza'), 'nuoto club monza');
      expect(chiaveSquadra('R.N. Camogli'), 'rari nantes camogli');
    });

    test('la sigla giusta fra due Monza', () {
      const girone = ['PALLANUOTO MONZA', 'NUOTO CLUB MONZA'];
      expect(stessaSquadraFra('PN Monza', girone), ['PALLANUOTO MONZA']);
      expect(stessaSquadraFra('NC Monza', girone), ['NUOTO CLUB MONZA']);
      // «Monza» da solo può essere tutte e due: nessuna.
      expect(stessaSquadraFra('Monza', girone), isEmpty);
      // Con una Monza sola il tipo di società non serve.
      expect(stessaSquadraFra('Nuoto Monza', ['PALLANUOTO MONZA']), [
        'PALLANUOTO MONZA',
      ]);
    });

    test('la squadra 2 resta un\'altra squadra', () {
      const girone = ['AN BRESCIA TEAM', 'AN BRESCIA TEAM 2'];
      expect(stessaSquadraFra('AN Brescia Team', girone), ['AN BRESCIA TEAM']);
      expect(stessaSquadraFra('AN Brescia Team 2', girone), [
        'AN BRESCIA TEAM 2',
      ]);
    });
  });

  group('la scheda dalle nostre partite', () {
    final oggi = DateTime(2026, 11, 20);
    final andata = _partita('p1', DateTime(2026, 10, 25), calottina: 'bianca');
    final ritorno = _partita('p2', DateTime(2026, 11, 15), inCasa: false);
    final prossima = _partita('p3', DateTime(2026, 12, 6));
    final u16 = _partita('p4', DateTime(2026, 10, 24), gruppoId: 'u16');
    final altra = _partita('p5', DateTime(2026, 11, 1), avversario: 'SG Arese');

    test('solo le partite della squadra contro di loro', () {
      final contro = partiteControAvversario(
        nome: 'PALLANUOTO MONZA',
        gruppoId: 'u14',
        partite: [andata, ritorno, prossima, u16, altra],
      );
      expect([for (final p in contro) p.id], ['p1', 'p2', 'p3']);
    });

    test('risultati, bilancio e i loro marcatori', () {
      final scheda = schedaAvversario(
        nome: 'PN Monza',
        partite: [andata, ritorno, prossima],
        referti: [
          _referto(
            andata,
            casa: 11,
            trasferta: 3,
            loro: const [
              GiocatoreReferto(
                numeroCalottina: 7,
                nome: 'Rossi Luca',
                reti: 2,
                espulsioni: 1,
              ),
              GiocatoreReferto(
                numeroCalottina: 3,
                nome: 'Bianchi',
                reti: 1,
                espulsioni: 0,
              ),
              GiocatoreReferto(
                numeroCalottina: 5,
                nome: 'Verdi',
                reti: 0,
                espulsioni: 0,
              ),
            ],
          ),
        ],
        // Il ritorno senza referto: il risultato dagli eventi (in
        // trasferta, 1 a 2 per loro).
        eventi: [
          _evento('e1', 'p2', tipo: 'tiro', squadra: 'nostra', esito: 'gol'),
          _evento(
            'e2',
            'p2',
            tipo: 'tiro',
            squadra: 'avversaria',
            esito: 'gol',
          ),
          _evento(
            'e3',
            'p2',
            tipo: 'tiro',
            squadra: 'avversaria',
            esito: 'gol',
          ),
          _evento(
            'e4',
            'p2',
            tipo: 'espulsione',
            squadra: 'avversaria',
            numero: 9,
          ),
        ],
        oggi: oggi,
      );

      expect([for (final g in scheda.giocate) g.partita.id], ['p2', 'p1']);
      expect(scheda.giocate.first.punteggio, '1-2');
      expect(scheda.giocate.first.daReferto, isFalse);
      expect(scheda.giocate.last.punteggio, '11-3');
      expect(scheda.giocate.last.daReferto, isTrue);
      expect([for (final p in scheda.prossime) p.id], ['p3']);
      expect((scheda.vinte, scheda.pari, scheda.perse), (1, 0, 1));
      expect((scheda.golFatti, scheda.golSubiti), (12, 5));
      // Chi non ha segnato né preso espulsioni non c'è.
      expect(
        [for (final g in scheda.giocatori) g.nome],
        ['Rossi Luca', 'Bianchi'],
      );
      expect(scheda.giocatori.first.numero, 7);
      expect(scheda.partiteDalVivo, 1);
      expect(scheda.dalVivo.golSubiti, 2);
      expect(scheda.espulsioniPerNumero, {9: 1});
    });

    test('oggi senza risultato è ancora da giocare', () {
      final scheda = schedaAvversario(
        nome: 'PN Monza',
        partite: [prossima],
        referti: const [],
        eventi: const [],
        oggi: DateTime(2026, 12, 6, 10),
      );
      expect(scheda.giocate, isEmpty);
      expect(scheda.prossime.single.id, 'p3');
    });

    test('gli avversari della squadra, prima chi si incontra presto', () {
      final elenco = avversariDellaSquadra(
        gruppoId: 'u14',
        partite: [andata, ritorno, prossima, u16, altra],
        oggi: oggi,
      );
      expect(
        [for (final a in elenco) (a.nome, a.partite)],
        [('PN Monza', 3), ('SG Arese', 1)],
      );
      expect(elenco.first.prossima, DateTime(2026, 12, 6));
    });
  });

  test('nel girone FIN vero: PN Monza è PALLANUOTO MONZA', () {
    final girone = leggiGironeFin(paginaGironeVera, cmpId: 259);
    final monza = avversarioNelGirone(
      girone,
      nome: 'PN Monza',
      nostra: 'CANOTTIERI MILANO',
    )!;
    expect(monza.nomeFin, 'PALLANUOTO MONZA');
    expect(monza.riga!.posizione, 3);
    expect(monza.riga!.golSubiti, 11);
    expect(monza.ultimi, hasLength(1));
    expect(monza.esitoDi(monza.ultimi.first), 'P');
    expect(monza.punteggioDi(monza.ultimi.first), '3-11');
    expect(monza.controChi(monza.ultimi.first), 'CANOTTIERI MILANO');
    // La nostra squadra non è mai l'avversario.
    expect(
      avversarioNelGirone(
        girone,
        nome: 'Canottieri Milano',
        nostra: 'CANOTTIERI MILANO',
      ),
      isNull,
    );
  });

  group('la pagina', () {
    final oggi = DateTime.now();
    final giocata = _partita(
      'p1',
      oggi.subtract(const Duration(days: 2)),
      calottina: 'bianca',
    );
    final prossima = _partita('p2', oggi.add(const Duration(days: 12)));

    Future<void> apri(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(420, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partiteListProvider.overrideWith(
              (ref, clubId) => Stream.value([giocata, prossima]),
            ),
            refertiRepositoryProvider.overrideWithValue(
              _Referti([
                _referto(
                  giocata,
                  casa: 11,
                  trasferta: 3,
                  loro: const [
                    GiocatoreReferto(
                      numeroCalottina: 7,
                      nome: 'Rossi Luca',
                      reti: 2,
                      espulsioni: 1,
                    ),
                  ],
                ),
              ]),
            ),
            eventiPartitaRepositoryProvider.overrideWithValue(_Eventi([])),
            campionatiRepositoryProvider.overrideWithValue(_Campionati()),
            gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void controllaScheda() {
      expect(find.text('PN Monza'), findsOneWidget);
      expect(find.text('Scheda dell\'avversario'), findsOneWidget);
      // Il bilancio in testata.
      expect(find.text('Vinte'), findsOneWidget);
      expect(find.text('11–3'), findsOneWidget);
      expect(find.text('Da giocare'), findsOneWidget);
      expect(find.text('Precedenti'), findsOneWidget);
      expect(find.text('11-3'), findsOneWidget);
      expect(find.textContaining('dal referto'), findsOneWidget);
      expect(find.text('Rossi Luca'), findsOneWidget);
      expect(find.text('2 gol in 1 partita · 1 espulsione'), findsOneWidget);
      // Il girone FIN della squadra.
      expect(
        find.text('Ragazzi (M/F) · Qualificazioni · Girone 6'),
        findsOneWidget,
      );
      expect(find.text('PALLANUOTO MONZA'), findsOneWidget);
      expect(find.text('3° di 3'), findsOneWidget);
      expect(find.text('vs CANOTTIERI MILANO'), findsOneWidget);
    }

    testWidgets('dalla partita', (tester) async {
      await apri(
        tester,
        const SchedaAvversarioScreen(
          clubId: 'c1',
          gruppoId: 'u14',
          nome: 'PN Monza',
          vistaStaff: true,
        ),
      );
      controllaScheda();
    });

    testWidgets('dalla classifica, con il nome del sito FIN', (tester) async {
      await apri(tester, const ClassificaScreen(clubId: 'c1', gruppoId: 'u14'));
      await tester.tap(find.text('PALLANUOTO MONZA'));
      await tester.pumpAndSettle();
      controllaScheda();
      // La nostra squadra in classifica non apre niente.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANOTTIERI MILANO').first);
      await tester.pumpAndSettle();
      expect(find.text('Scheda dell\'avversario'), findsNothing);
    });

    testWidgets('un avversario senza partite con la squadra', (tester) async {
      await apri(
        tester,
        const SchedaAvversarioScreen(
          clubId: 'c1',
          gruppoId: 'u14',
          nome: 'AN BRESCIA TEAM 2',
        ),
      );
      expect(
        find.text(
          'Con questa squadra non ci sono ancora partite contro di loro.',
        ),
        findsOneWidget,
      );
      expect(find.text('2° di 3'), findsOneWidget);
    });
  });
}
