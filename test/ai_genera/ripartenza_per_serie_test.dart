import 'package:coach_vasca/features/ai_genera/application/corsie_service.dart';
import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:flutter_test/flutter_test.dart';

PersonalBest _pb(String atletaId, String stile, int dist, double tempoS) =>
    PersonalBest(
      id: '$atletaId-$stile-$dist',
      atletaId: atletaId,
      clubId: 'c',
      stile: stile,
      distanzaM: dist,
      tempoS: tempoS,
    );

void main() {
  group('ripartenzaPerSerie', () {
    test("A1/A2/B1: usa la media del passo dal test di soglia quando c'è", () {
      const assegnazione = AssegnazioneCorsie(
        corsie: [],
        passiSogliaPerAtleta: {
          'a': {'B1': 90.0},
          'b': {'B1': 94.0},
        },
      );
      final r = ripartenzaPerSerie(
        zona: 'B1',
        stile: 'libero',
        distanzaM: 100,
        atletiIds: const ['a', 'b'],
        assegnazione: assegnazione,
      );
      // Media (90+94)/2 = 92, poi la stessa tabella di ripartenzaEPasso.
      expect(r.passoS, closeTo(92.0 * 0.950, 0.001));
    });

    test('A1/A2/B1 senza test: ricade sul modello dai primati (libero)', () {
      final assegnazione = AssegnazioneCorsie(
        corsie: const [],
        pbPerAtleta: {
          'a': [_pb('a', 'libero', 100, 60), _pb('a', 'libero', 200, 126)],
        },
      );
      final r = ripartenzaPerSerie(
        zona: 'B1',
        stile: 'libero',
        distanzaM: 100,
        atletiIds: const ['a'],
        assegnazione: assegnazione,
      );
      // Differenziale = 126-60 = 66, B1 = 66+3.5 = 69.5, coefficiente 100m 0.950.
      expect(r.passoS, closeTo(69.5 * 0.950, 0.001));
    });

    test(
      'B2+: usa il PB nello stile della serie se c\'è, non sempre il libero',
      () {
        final assegnazione = AssegnazioneCorsie(
          corsie: const [],
          pbPerAtleta: {
            'a': [
              _pb('a', 'libero', 100, 60),
              _pb('a', 'libero', 200, 126),
              _pb('a', 'dorso', 100, 70),
              _pb('a', 'dorso', 200, 150),
            ],
          },
        );
        final r = ripartenzaPerSerie(
          zona: 'B2',
          stile: 'dorso',
          distanzaM: 200,
          atletiIds: const ['a'],
          assegnazione: assegnazione,
        );
        // B2 = differenziale nello stile dorso = 150-70 = 80.
        expect(r.passoS, closeTo(80.0, 0.001));
      },
    );

    test('B2+: senza PB nello stile della serie ricade sul libero', () {
      final assegnazione = AssegnazioneCorsie(
        corsie: const [],
        pbPerAtleta: {
          'a': [_pb('a', 'libero', 100, 60), _pb('a', 'libero', 200, 126)],
        },
      );
      final r = ripartenzaPerSerie(
        zona: 'B2',
        stile: 'rana',
        distanzaM: 200,
        atletiIds: const ['a'],
        assegnazione: assegnazione,
      );
      expect(r.passoS, closeTo(66.0, 0.001));
    });

    test('nessun dato: torna null, mai un\'eccezione', () {
      const assegnazione = AssegnazioneCorsie(corsie: []);
      final r = ripartenzaPerSerie(
        zona: 'B1',
        stile: 'libero',
        distanzaM: 100,
        atletiIds: const ['a'],
        assegnazione: assegnazione,
      );
      expect(r.passoS, isNull);
      expect(r.ripartenzaS, isNull);
    });
  });
}
