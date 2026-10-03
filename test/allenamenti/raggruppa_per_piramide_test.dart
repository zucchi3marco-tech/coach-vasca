import 'package:coach_vasca/features/allenamenti/domain/riordino_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:flutter_test/flutter_test.dart';

Serie _serie(String id, int ordine, {String? piramideId}) => Serie(
  id: id,
  allenamentoId: 'a',
  clubId: 'c',
  ordine: ordine,
  blocco: 'principale',
  ripetute: 1,
  distanzaM: 100,
  stile: 'libero',
  esecuzione: 'nuoto',
  piramideId: piramideId,
);

void main() {
  group('raggruppaPerPiramide', () {
    test('righe normali restano gruppi singoli', () {
      final serie = [_serie('a', 1), _serie('b', 2), _serie('c', 3)];
      final gruppi = raggruppaPerPiramide(serie);
      expect(gruppi, hasLength(3));
      expect(gruppi.every((g) => g.length == 1), isTrue);
    });

    test('righe consecutive con lo stesso piramideId sono un unico gruppo', () {
      final serie = [
        _serie('a', 1),
        _serie('b', 2, piramideId: 'p1'),
        _serie('c', 3, piramideId: 'p1'),
        _serie('d', 4, piramideId: 'p1'),
        _serie('e', 5),
      ];
      final gruppi = raggruppaPerPiramide(serie);
      expect(gruppi, hasLength(3));
      expect(gruppi[0].map((s) => s.id), ['a']);
      expect(gruppi[1].map((s) => s.id), ['b', 'c', 'd']);
      expect(gruppi[2].map((s) => s.id), ['e']);
    });

    test('due piramidi distinte consecutive restano due gruppi', () {
      final serie = [
        _serie('a', 1, piramideId: 'p1'),
        _serie('b', 2, piramideId: 'p1'),
        _serie('c', 3, piramideId: 'p2'),
        _serie('d', 4, piramideId: 'p2'),
      ];
      final gruppi = raggruppaPerPiramide(serie);
      expect(gruppi, hasLength(2));
      expect(gruppi[0].map((s) => s.id), ['a', 'b']);
      expect(gruppi[1].map((s) => s.id), ['c', 'd']);
    });

    test(
      'lo stesso piramideId non consecutivo (caso limite) non si raggruppa',
      () {
        final serie = [
          _serie('a', 1, piramideId: 'p1'),
          _serie('b', 2),
          _serie('c', 3, piramideId: 'p1'),
        ];
        final gruppi = raggruppaPerPiramide(serie);
        expect(gruppi, hasLength(3));
      },
    );
  });

  group('spostaSerie generico', () {
    test('funziona anche con tipi diversi da Serie (es. List<int>)', () {
      expect(spostaSerie([1, 2, 3], 0, 2), [2, 3, 1]);
      expect(spostaSerie([1, 2, 3], 2, 0), [3, 1, 2]);
    });

    test('sposta un intero gruppo (List<Serie>) come un solo elemento', () {
      final gruppi = [
        [_serie('a', 1)],
        [_serie('b', 2, piramideId: 'p1'), _serie('c', 3, piramideId: 'p1')],
        [_serie('d', 4)],
      ];
      final riordinati = spostaSerie(gruppi, 1, 0);
      expect(riordinati[0].map((s) => s.id), ['b', 'c']);
      expect(riordinati[1].map((s) => s.id), ['a']);
      expect(riordinati[2].map((s) => s.id), ['d']);
    });
  });
}
