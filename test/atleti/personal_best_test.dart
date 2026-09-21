import 'package:coach_vasca/features/atleti/domain/personal_best.dart';
import 'package:flutter_test/flutter_test.dart';

PersonalBest _pb(String id, String stile, int distanzaM, double tempoS) =>
    PersonalBest(
      id: id,
      atletaId: 'a',
      clubId: 'c',
      stile: stile,
      distanzaM: distanzaM,
      tempoS: tempoS,
    );

void main() {
  final elenco = [
    _pb('l100', 'libero', 100, 65.5),
    _pb('l200', 'libero', 200, 140),
    _pb('d100', 'dorso', 100, 72),
  ];

  group('pbDelloSlot', () {
    test('trova il PB di stile e distanza', () {
      expect(pbDelloSlot(elenco, 'libero', 100)?.id, 'l100');
      expect(pbDelloSlot(elenco, 'dorso', 100)?.id, 'd100');
    });

    test('nessun PB per lo slot', () {
      expect(pbDelloSlot(elenco, 'rana', 100), isNull);
      expect(pbDelloSlot(elenco, 'libero', 50), isNull);
    });
  });

  group('superaPersonalBest', () {
    test('senza PB qualunque tempo lo è', () {
      expect(superaPersonalBest(null, 90), isTrue);
    });

    test('più veloce del PB sì', () {
      expect(superaPersonalBest(elenco.first, 65.4), isTrue);
    });

    test('uguale o più lento no', () {
      expect(superaPersonalBest(elenco.first, 65.5), isFalse);
      expect(superaPersonalBest(elenco.first, 70), isFalse);
    });
  });
}
