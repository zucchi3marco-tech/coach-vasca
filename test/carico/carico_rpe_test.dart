import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/presentation/carico_settimane.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/theme/tokens_dominio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SerieCarico _serie(
  int ripetute, {
  String allenamentoId = 'a1',
  int? distanzaM,
  int? durataS,
  String? zona,
  String esecuzione = 'nuoto',
  int? recuperoS,
}) => SerieCarico(
  allenamentoId: allenamentoId,
  ripetute: ripetute,
  esecuzione: esecuzione,
  distanzaM: distanzaM,
  durataS: durataS,
  zona: zona,
  recuperoS: recuperoS,
);

void main() {
  group('carico di una seduta (RPE × minuti)', () {
    // 8x100 B1: 110" ogni 100 al passo medio più 15" di recupero = 1000";
    // 2x10' a secco senza recupero = 1200". In tutto 2200" = 37'.
    final serie = [
      _serie(8, distanzaM: 100, zona: 'B1'),
      _serie(2, durataS: 600, esecuzione: 'a secco', recuperoS: 0),
    ];

    test('con la risposta dell\'atleta: RPE per i minuti stimati', () {
      final c = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 7, 18),
        serie: serie,
        rpe: 6,
      );
      expect(c.minuti, 37);
      expect(c.stimato, isFalse);
      expect(c.totale, closeTo(222, 0.001));
      // Il secco ha la sua parte: 1200" su 2200".
      expect(c.secco, closeTo(222 * 1200 / 2200, 0.001));
      expect(c.acqua, closeTo(222 * 1000 / 2200, 0.001));
      expect(c.partita, 0);
      expect(c.giorno, DateTime(2026, 10, 7));
    });

    test('senza risposta l\'RPE si stima dalle serie, pesate per durata', () {
      final c = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 7),
        serie: [
          // A1: (110 + 20) × 8 = 1040".
          _serie(8, distanzaM: 100, zona: 'A1'),
          _serie(2, durataS: 600, esecuzione: 'a secco', recuperoS: 0),
        ],
      );
      expect(c.stimato, isTrue);
      expect(c.rpe, closeTo((1040 * 3 + 1200 * 5) / 2240, 0.001));
    });

    test('un allenamento senza serie vale una seduta tipo, tutta in acqua', () {
      final c = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 7),
        serie: const [],
        rpe: 7,
      );
      expect(c.minuti, minutiAllenamentoSenzaSerie);
      expect(c.acqua, 7 * minutiAllenamentoSenzaSerie);
      expect(c.secco, 0);
    });

    test('una partita conta nel carico, anche senza risposta', () {
      final data = DateTime(2026, 10, 4);
      final conRisposta = caricoPartita(id: 'p1', giorno: data, rpe: 8);
      expect(conRisposta.partita, 8 * minutiPartita);
      expect(conRisposta.acqua + conRisposta.secco, 0);

      final stimata = caricoPartita(id: 'p1', giorno: data);
      expect(stimata.stimato, isTrue);
      expect(stimata.partita, rpeStimatoPartita * minutiPartita);
    });
  });

  test('quali sedute contano per un atleta', () {
    final giorno = DateTime(2026, 10, 1);
    final sedute = seduteDiAtleta(
      dataAllenamenti: {
        'presente': giorno,
        'assente': giorno,
        'solo_rpe': giorno,
        'non_segnato': giorno,
      },
      seriePerAllenamento: const {},
      statoPresenze: const {'presente': 'presente', 'assente': 'assente'},
      dataPartite: {
        'giocata': DateTime(2026, 10, 4),
        'futura': DateTime(2026, 10, 20),
        'rpe_senza_distinta': DateTime(2026, 10, 5),
      },
      partiteConvocato: const {'giocata', 'futura'},
      rpe: const {
        ('allenamento', 'assente'): 6,
        ('allenamento', 'solo_rpe'): 4,
        ('partita', 'rpe_senza_distinta'): 7,
      },
      oggi: DateTime(2026, 10, 10),
    );
    expect(sedute.map((s) => s.eventoId).toSet(), {
      'presente',
      'solo_rpe',
      'giocata',
      'rpe_senza_distinta',
    });
    // Dalla più vecchia.
    expect(sedute.first.giorno, giorno);
    expect(sedute.last.eventoId, 'rpe_senza_distinta');
  });

  group('ACWR', () {
    final oggi = DateTime(2026, 10, 28);
    List<CaricoSeduta> giorni(int da, int a, int rpe) => [
      for (var i = da; i <= a; i++)
        caricoPartita(id: 'p$i', giorno: DateTime(2026, 10, 28 - i), rpe: rpe),
    ];

    test('carico costante: rapporto 1, nella norma', () {
      final acwr = calcolaAcwr(giorni(0, 27, 5), oggi: oggi)!;
      expect(acwr.acuto, 7 * 300);
      expect(acwr.cronico, 7 * 300);
      expect(acwr.rapporto, 1);
      expect(acwr.fascia, FasciaAcwr.norma);
    });

    test('una settimana doppia: molto sopra il solito', () {
      final acwr = calcolaAcwr([
        ...giorni(0, 6, 10),
        ...giorni(7, 27, 5),
      ], oggi: oggi)!;
      expect(acwr.acuto, 7 * 600);
      expect(acwr.cronico, (21 * 300 + 7 * 600) / 4);
      expect(acwr.rapporto, closeTo(1.6, 0.001));
      expect(acwr.fascia, FasciaAcwr.alto);
      expect(formattaAcwr(acwr.rapporto!), '1,60');
    });

    test('meno di tre settimane di sedute: nessuna fascia', () {
      final acwr = calcolaAcwr(giorni(0, 9, 5), oggi: oggi)!;
      expect(acwr.affidabile, isFalse);
      expect(acwr.fascia, isNull);
    });

    test('nessuna seduta: niente ACWR', () {
      expect(calcolaAcwr(const [], oggi: oggi), isNull);
    });
  });

  test('il carico per settimana tiene anche le settimane vuote', () {
    final settimane = caricoPerSettimana(
      [
        caricoPartita(id: 'p1', giorno: DateTime(2026, 10, 4), rpe: 5),
        caricoAllenamento(
          id: 'a1',
          giorno: DateTime(2026, 10, 7),
          serie: const [],
          rpe: 4,
        ),
      ],
      settimane: 3,
      oggi: DateTime(2026, 10, 10),
    );
    expect(settimane.map((s) => s.lunedi), [
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 5),
    ]);
    expect(settimane[0].carico.totale, 0);
    expect(settimane[1].carico.partita, 300);
    expect(settimane[2].carico.acqua, 4 * minutiAllenamentoSenzaSerie);
  });

  test('l\'RPE si legge con le parole della scala', () {
    expect(descriviRpe(0), '0 · Riposo');
    expect(descriviRpe(6), '6 · Duro');
    expect(descriviRpe(8), '8 · Molto duro');
    expect(descriviRpe(10), '10 · Al massimo');
  });

  testWidgets('le colonne del carico si vedono, divise per tipo', (
    tester,
  ) async {
    final oggi = DateTime(2026, 10, 10);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CaricoSettimane(
              oggi: oggi,
              settimane: 2,
              obiettivoDi: (lunedi) => 1000,
              sedute: [
                caricoAllenamento(
                  id: 'a1',
                  giorno: DateTime(2026, 10, 6),
                  serie: [
                    _serie(8, distanzaM: 100, zona: 'B1'),
                    _serie(
                      2,
                      durataS: 600,
                      esecuzione: 'a secco',
                      recuperoS: 0,
                    ),
                  ],
                  rpe: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Acqua e secco ci sono, la partita no: in legenda solo i primi due.
    expect(find.text('Acqua'), findsOneWidget);
    expect(find.text('Secco'), findsOneWidget);
    expect(find.text('Partita'), findsNothing);
    expect(find.text('Obiettivo della fase'), findsOneWidget);
    // I due pezzi colorati sono larghi quanto la colonna, non zero.
    final dominio = tester.element(find.byType(CaricoSettimane)).dominio;
    final pezzi = find.byWidgetPredicate(
      (w) =>
          w is ColoredBox &&
          (w.color == dominio.evidenzaCiano ||
              w.color == dominio.evidenzaViola),
    );
    expect(pezzi, findsNWidgets(2));
    for (final e in pezzi.evaluate()) {
      expect(tester.getSize(find.byWidget(e.widget)).width, greaterThan(15));
    }
    expect(find.text('Obiettivo 1.000 · 22% fatto'), findsOneWidget);
    expect(find.text('acqua 101 · secco 121'), findsOneWidget);
  });
}
