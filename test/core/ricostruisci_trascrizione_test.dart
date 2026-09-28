import 'package:coach_vasca/core/dettatura/ricostruisci_trascrizione.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ricostruisciTrascrizione', () {
    test('unisce i segmenti con uno spazio', () {
      expect(
        ricostruisciTrascrizione(['400 riscaldamento', '8 volte 100 sl']),
        '400 riscaldamento 8 volte 100 sl',
      );
    });

    test('scarta i segmenti vuoti (spazi inclusi)', () {
      expect(
        ricostruisciTrascrizione(['400 riscaldamento', '  ', '', '8x100']),
        '400 riscaldamento 8x100',
      );
    });

    test('collassa una ripetizione consecutiva dello stesso segmento', () {
      expect(
        ricostruisciTrascrizione([
          '8 volte 100 stile libero',
          '8 volte 100 stile libero',
          '8 volte 100 stile libero',
        ]),
        '8 volte 100 stile libero',
      );
    });

    test('il confronto ignora maiuscole e spazi ai bordi', () {
      expect(
        ricostruisciTrascrizione([' 200 dorso ', '200 DORSO', '200 dorso']),
        '200 dorso',
      );
    });

    test('non collassa la stessa frase se non è consecutiva', () {
      expect(
        ricostruisciTrascrizione(['200 dorso', '200 rana', '200 dorso']),
        '200 dorso 200 rana 200 dorso',
      );
    });

    test('lista vuota dà stringa vuota', () {
      expect(ricostruisciTrascrizione(const []), '');
    });
  });
}
