import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/prossimo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:flutter_test/flutter_test.dart';

Allenamento _all(String id, DateTime data, {String? gruppoId}) =>
    Allenamento(id: id, clubId: 'c', data: data, gruppoId: gruppoId);

Serie _serie(int ripetute, int distanzaM, {String blocco = 'principale'}) =>
    Serie(
      id: '$ripetute-$distanzaM-$blocco',
      allenamentoId: 'a',
      clubId: 'c',
      ordine: 1,
      blocco: blocco,
      ripetute: ripetute,
      distanzaM: distanzaM,
      stile: 'libero',
      esecuzione: 'nuoto',
    );

void main() {
  final oggi = DateTime(2026, 9, 21, 15, 30);

  group('prossimoAllenamento', () {
    test('sceglie il primo da oggi in poi, oggi compreso', () {
      final risultato = prossimoAllenamento(
        [
          _all('ieri', DateTime(2026, 9, 20)),
          _all('dopo', DateTime(2026, 9, 25)),
          _all('oggi', DateTime(2026, 9, 21)),
        ],
        null,
        oggi: oggi,
      );
      expect(risultato?.id, 'oggi');
    });

    test('ignora gli allenamenti di altri gruppi ma tiene quelli di club', () {
      final risultato = prossimoAllenamento(
        [
          _all('altro', DateTime(2026, 9, 22), gruppoId: 'g2'),
          _all('club', DateTime(2026, 9, 24)),
          _all('mio', DateTime(2026, 9, 26), gruppoId: 'g1'),
        ],
        'g1',
        oggi: oggi,
      );
      expect(risultato?.id, 'club');
    });

    test('un atleta senza gruppo li vede tutti', () {
      final risultato = prossimoAllenamento(
        [_all('altro', DateTime(2026, 9, 22), gruppoId: 'g2')],
        null,
        oggi: oggi,
      );
      expect(risultato?.id, 'altro');
    });

    test('a parità di data vince l\'id più basso', () {
      final risultato = prossimoAllenamento(
        [_all('b', DateTime(2026, 9, 22)), _all('a', DateTime(2026, 9, 22))],
        null,
        oggi: oggi,
      );
      expect(risultato?.id, 'a');
    });

    test('nessun allenamento in programma: null', () {
      expect(
        prossimoAllenamento(
          [_all('ieri', DateTime(2026, 9, 20))],
          null,
          oggi: oggi,
        ),
        isNull,
      );
      expect(prossimoAllenamento(const [], 'g1', oggi: oggi), isNull);
    });
  });

  group('metri', () {
    test(
      'somma ripetute × distanza di tutte le serie, riscaldamento incluso',
      () {
        final serie = [
          _serie(1, 400, blocco: 'riscaldamento'),
          _serie(8, 100),
          _serie(4, 200),
          _serie(1, 200, blocco: 'defaticamento'),
        ];
        expect(metriTotaliSerie(serie), 400 + 800 + 800 + 200);
      },
    );

    test('nessuna serie: zero', () {
      expect(metriTotaliSerie(const []), 0);
    });

    test('formattaMetri usa il punto per le migliaia', () {
      expect(formattaMetri(0), '0 m');
      expect(formattaMetri(950), '950 m');
      expect(formattaMetri(2400), '2.400 m');
      expect(formattaMetri(12500), '12.500 m');
      expect(formattaMetri(1234567), '1.234.567 m');
    });
  });
}
