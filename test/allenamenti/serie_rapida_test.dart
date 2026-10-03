import 'package:coach_vasca/features/allenamenti/domain/serie_rapida.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSerieRapida — ripetute×distanza', () {
    test('formato base', () {
      final serie = parseSerieRapida('10x100 A2 1:25 r15 sl');
      expect(serie, hasLength(1));
      final s = serie!.single;
      expect(s.ripetute, 10);
      expect(s.distanzaM, 100);
      expect(s.zona, 'A2');
      expect(s.passoObiettivoS, 85);
      expect(s.recuperoS, 15);
      expect(s.stile, 'libero');
    });

    test('senza ripetute×distanza torna null', () {
      expect(parseSerieRapida('A2 r15 sl'), isNull);
    });

    test('ripetute o distanza a zero torna null', () {
      expect(parseSerieRapida('0x100'), isNull);
      expect(parseSerieRapida('10x0'), isNull);
    });

    test('token non riconosciuto viene ignorato', () {
      final serie = parseSerieRapida('10x100 boh sl');
      expect(serie!.single.stile, 'libero');
    });
  });

  group('parseSerieRapida — piramide', () {
    test('piramide classica, una serie per distanza', () {
      final serie = parseSerieRapida('50-100-200-100-50 sl r20');
      expect(serie, hasLength(5));
      expect(serie!.map((s) => s.distanzaM), [50, 100, 200, 100, 50]);
      for (final s in serie) {
        expect(s.ripetute, 1);
        expect(s.stile, 'libero');
        expect(s.recuperoS, 20);
      }
    });

    test('scaletta di due distanze', () {
      final serie = parseSerieRapida('100-200');
      expect(serie!.map((s) => s.distanzaM), [100, 200]);
    });

    test('zona e passo condivisi da tutte le serie della piramide', () {
      final serie = parseSerieRapida('50-100-50 B1 1:30');
      expect(serie!.every((s) => s.zona == 'B1'), isTrue);
      expect(serie.every((s) => s.passoObiettivoS == 90), isTrue);
    });

    test('una distanza a zero nella piramide torna null', () {
      expect(parseSerieRapida('50-0-50'), isNull);
    });

    test('la piramide vince su un eventuale NxM nella stessa riga', () {
      // Caso limite non ambiguo in pratica (il coach non scrive
      // entrambi i formati insieme), ma il parser non deve confondersi:
      // il primo pattern a comparire e combaciare è la piramide.
      final serie = parseSerieRapida('50-100-50');
      expect(serie, hasLength(3));
    });
  });

  group('parseSerieRapida — piramide con giri', () {
    test('2 giri: r1 tra le distanze, r2 solo tra un giro e l\'altro', () {
      final serie = parseSerieRapida('2x(50-100-200-100-50) sl r15 r30');
      expect(serie, hasLength(10));
      expect(serie!.map((s) => s.distanzaM), [
        50,
        100,
        200,
        100,
        50,
        50,
        100,
        200,
        100,
        50,
      ]);
      expect(serie.every((s) => s.ripetute == 1), isTrue);
      expect(serie.every((s) => s.stile == 'libero'), isTrue);
      // Dentro ogni giro: r1 su tutte tranne l'ultima distanza del giro.
      expect(serie.sublist(0, 4).every((s) => s.recuperoS == 15), isTrue);
      // Ultima distanza del primo giro (non l'ultimo giro): r2.
      expect(serie[4].recuperoS, 30);
      expect(serie.sublist(5, 9).every((s) => s.recuperoS == 15), isTrue);
      // Ultima distanza dell'ultimo giro: r1, come una serie normale.
      expect(serie[9].recuperoS, 15);
    });

    test(
      'un solo giro con due recuperi scritti: sempre r1, anche l\'ultima',
      () {
        final serie = parseSerieRapida('50-100-50 sl r15 r30');
        expect(serie, hasLength(3));
        expect(serie!.every((s) => s.recuperoS == 15), isTrue);
      },
    );

    test('senza il secondo recupero, tra i giri ricade sul primo', () {
      final serie = parseSerieRapida('2x(50-100-50) r10');
      expect(serie!.map((s) => s.recuperoS), [10, 10, 10, 10, 10, 10]);
    });

    test('0 giri o una distanza a zero torna null', () {
      expect(parseSerieRapida('0x(50-100-50)'), isNull);
      expect(parseSerieRapida('2x(50-0-50)'), isNull);
    });

    test('un solo giro senza parentesi resta il formato piramide semplice', () {
      final serie = parseSerieRapida('50-100-200-100-50 sl r15');
      expect(serie, hasLength(5));
      expect(serie!.every((s) => s.recuperoS == 15), isTrue);
    });
  });
}
