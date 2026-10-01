import 'package:coach_vasca/features/ripartenze/domain/calcolo_ripartenze.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arrotondaSu5s', () {
    test('arrotonda per eccesso al multiplo di 5 più vicino', () {
      expect(arrotondaSu5s(107.4), 110);
      expect(arrotondaSu5s(100), 100);
      expect(arrotondaSu5s(100.1), 105);
    });

    test('esempio del coach: 1\'32"4 + 15s -> 1\'50"', () {
      const tempoTarget = 92.4; // 1:32.4
      expect(arrotondaSu5s(tempoTarget + 15), 110); // 1:50
    });
  });

  group('tempoGaraStimato (modello CSS)', () {
    // Esempio reale dal documento del coach: differenziale tra 1'48" e
    // 48" = 1'00" (T100=48s, T200=108s, differenziale=60s).
    const differenzialeS = 60.0;
    const tempo200S = 108.0;

    test('autoconsistente: ridà esattamente T100 e T200', () {
      expect(
        tempoGaraStimato(
          differenzialeS: differenzialeS,
          tempo200S: tempo200S,
          distanzaM: 100,
        ),
        closeTo(48, 0.001),
      );
      expect(
        tempoGaraStimato(
          differenzialeS: differenzialeS,
          tempo200S: tempo200S,
          distanzaM: 200,
        ),
        closeTo(108, 0.001),
      );
    });

    test('stima un tempo gara coerente per una distanza diversa', () {
      // 400m: più lento del doppio del passo sui 200 (l'atleta rallenta).
      final t400 = tempoGaraStimato(
        differenzialeS: differenzialeS,
        tempo200S: tempo200S,
        distanzaM: 400,
      );
      expect(t400, greaterThan(tempo200S * 2));
    });
  });

  group('passoBasePerZona', () {
    const differenzialeS = 60.0;
    const passo100S = 48.0;

    test('B2 = differenziale', () {
      expect(
        passoBasePerZona(
          'B2',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        60.0,
      );
    });

    test(
      'B1 = differenziale + 3.5 (offset fisso, nessun profilo dinamico)',
      () {
        expect(
          passoBasePerZona(
            'B1',
            passo100S: passo100S,
            differenzialeS: differenzialeS,
          ),
          63.5,
        );
      },
    );

    test('A2 = B1 + 5.0, A1 = B1 + 12.0', () {
      expect(
        passoBasePerZona(
          'A2',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        68.5,
      );
      expect(
        passoBasePerZona(
          'A1',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        75.5,
      );
    });

    test('C1 = passo100 + 1.5, C2 = passo100', () {
      expect(
        passoBasePerZona(
          'C1',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        49.5,
      );
      expect(
        passoBasePerZona(
          'C2',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        48.0,
      );
    });

    test('C3 e D non hanno un passo base da questa funzione', () {
      expect(
        passoBasePerZona(
          'C3',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        isNull,
      );
      expect(
        passoBasePerZona(
          'D',
          passo100S: passo100S,
          differenzialeS: differenzialeS,
        ),
        isNull,
      );
    });

    test('senza differenziale, le zone che ne hanno bisogno tornano null', () {
      expect(
        passoBasePerZona('B1', passo100S: passo100S, differenzialeS: null),
        isNull,
      );
      expect(
        passoBasePerZona('B2', passo100S: passo100S, differenzialeS: null),
        isNull,
      );
    });
  });

  group('ripartenzaEPasso — tabella B1', () {
    const differenzialeS = 60.0; // P_B1 = 63.5

    test('100m: coefficiente 0.950, recupero 15s', () {
      final r = ripartenzaEPasso(
        zona: 'B1',
        passo100S: 48.0,
        differenzialeS: differenzialeS,
        distanzaM: 100,
      );
      const passoAtteso = 63.5 * 0.950; // 60.325
      expect(r.passoS, closeTo(passoAtteso, 0.001));
      const tempoTarget = passoAtteso; // d/100 = 1
      expect(r.ripartenzaS, arrotondaSu5s(tempoTarget + 15));
    });

    test('50m: coefficiente 0.900, recupero 12s', () {
      final r = ripartenzaEPasso(
        zona: 'B1',
        passo100S: 48.0,
        differenzialeS: differenzialeS,
        distanzaM: 50,
      );
      const passoAtteso = 63.5 * 0.900;
      const tempoTarget = passoAtteso * 0.5;
      expect(r.ripartenzaS, arrotondaSu5s(tempoTarget + 12));
    });

    test('400m: coefficiente 1.010, recupero 30s', () {
      final r = ripartenzaEPasso(
        zona: 'B1',
        passo100S: 48.0,
        differenzialeS: differenzialeS,
        distanzaM: 400,
      );
      const passoAtteso = 63.5 * 1.010;
      const tempoTarget = passoAtteso * 4;
      expect(r.ripartenzaS, arrotondaSu5s(tempoTarget + 30));
    });
  });

  group('ripartenzaEPasso — altre zone', () {
    test('C3: nessun calcolo', () {
      final r = ripartenzaEPasso(
        zona: 'C3',
        passo100S: 48.0,
        differenzialeS: 60.0,
        distanzaM: 50,
      );
      expect(r.passoS, isNull);
      expect(r.ripartenzaS, isNull);
    });

    test('D senza tempo200S: nessun calcolo', () {
      final r = ripartenzaEPasso(
        zona: 'D',
        passo100S: 48.0,
        differenzialeS: 60.0,
        distanzaM: 200,
      );
      expect(r.ripartenzaS, isNull);
    });

    test('D con tempo200S: usa il modello CSS', () {
      final r = ripartenzaEPasso(
        zona: 'D',
        passo100S: 48.0,
        differenzialeS: 60.0,
        tempo200S: 108.0,
        distanzaM: 200,
      );
      expect(r.passoS, isNotNull);
      expect(r.ripartenzaS, isNotNull);
    });

    test('C2 usa il recupero fisso di default (180s), non la tabella B1', () {
      final r = ripartenzaEPasso(
        zona: 'C2',
        passo100S: 48.0,
        differenzialeS: 60.0,
        distanzaM: 50,
      );
      // passo C2 = passo100 = 48 -> tempo target 50m = 24s, +180s = 204
      expect(r.ripartenzaS, arrotondaSu5s(24 + 180));
    });
  });
}
