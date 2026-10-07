import 'package:coach_vasca/features/pallanuoto/presentation/geometria_frecce.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _vicino(Offset atteso, [double tolleranza = 0.5]) => predicate<Offset>(
  (o) => (o - atteso).distance <= tolleranza,
  'vicino a $atteso',
);

void main() {
  group('puntoSuCurva', () {
    test('parte dall\'inizio e arriva alla fine, dritta o curva', () {
      const a = Offset(0, 0);
      const b = Offset(100, 0);
      for (final c in [null, const Offset(50, 80)]) {
        expect(puntoSuCurva(a, c, b, 0), a);
        expect(puntoSuCurva(a, c, b, 1), b);
      }
    });

    test('senza controllo è una retta', () {
      expect(
        puntoSuCurva(Offset.zero, null, const Offset(100, 40), 0.5),
        const Offset(50, 20),
      );
    });
  });

  test('controlloPerPuntoMedio: la curva passa per il punto trascinato', () {
    const a = Offset(0, 0);
    const b = Offset(100, 0);
    const medio = Offset(50, 30);
    final c = controlloPerPuntoMedio(a, medio, b);
    expect(puntoSuCurva(a, c, b, 0.5), _vicino(medio, 1e-9));
  });

  group('controlloDaTraccia', () {
    test('un tratto quasi dritto resta una freccia dritta', () {
      final traccia = [
        for (var x = 0.0; x <= 200; x += 10) Offset(x, x % 20 == 0 ? 0 : 3),
      ];
      expect(controlloDaTraccia(traccia), isNull);
    });

    test('un tratto ad arco diventa una curva che passa per il suo centro', () {
      // Semicerchio schiacciato da (0,0) a (200,0), che sale fino a y=-60.
      final traccia = [
        for (var i = 0; i <= 40; i++)
          Offset(i * 5.0, -60 * (1 - ((i - 20) / 20) * ((i - 20) / 20))),
      ];
      final c = controlloDaTraccia(traccia);
      expect(c, isNotNull);
      final medio = puntoSuCurva(traccia.first, c, traccia.last, 0.5);
      expect(medio, _vicino(const Offset(100, -60), 2));
    });

    test('troppo pochi punti: dritta', () {
      expect(controlloDaTraccia(const [Offset.zero, Offset(10, 10)]), isNull);
    });
  });

  test('distanzaDaCurva: vicino alla curva piegata, lontano dalla corda', () {
    const a = Offset(0, 0);
    const b = Offset(100, 0);
    final c = controlloPerPuntoMedio(a, const Offset(50, 40), b);
    expect(distanzaDaCurva(const Offset(50, 40), a, c, b), lessThan(1));
    expect(distanzaDaCurva(const Offset(50, 0), a, c, b), greaterThan(30));
  });

  test('percorsoTroncato toglie la lunghezza chiesta dalla fine', () {
    final punti = campionaCurva(Offset.zero, null, const Offset(100, 0));
    final troncati = percorsoTroncato(punti, 20);
    expect(troncati.first, Offset.zero);
    expect(troncati.last, _vicino(const Offset(80, 0)));
  });
}
