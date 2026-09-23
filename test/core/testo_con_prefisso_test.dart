import 'package:coach_vasca/core/dettatura/testo_con_prefisso.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('testoConPrefisso', () {
    test('unisce prefisso e testo della sessione con uno spazio', () {
      expect(
        testoConPrefisso('Riscaldamento 400 misti', '8 volte 100 libero'),
        'Riscaldamento 400 misti 8 volte 100 libero',
      );
    });

    test('senza prefisso resta solo il testo della sessione', () {
      expect(testoConPrefisso('', '8 volte 100 libero'), '8 volte 100 libero');
    });

    test('senza testo di sessione resta solo il prefisso', () {
      expect(
        testoConPrefisso('Riscaldamento 400 misti', ''),
        'Riscaldamento 400 misti',
      );
    });

    // Il bug segnalato dal coach: la stessa frase compariva ripetuta più
    // volte. La difesa qui è l'idempotenza — chiamare con lo stesso
    // testoSessione più volte di fila (come farebbe DettatoreVocale se il
    // browser rimandasse lo stesso risultato) non fa crescere il testo.
    test('idempotente: la stessa sessione ripetuta non duplica nulla', () {
      const prefisso = 'Riscaldamento 400 misti';
      const sessione = '8 volte 100 libero soglia';
      final primo = testoConPrefisso(prefisso, sessione);
      final secondo = testoConPrefisso(prefisso, sessione);
      final terzo = testoConPrefisso(prefisso, sessione);
      expect(primo, secondo);
      expect(secondo, terzo);
      expect(primo, 'Riscaldamento 400 misti 8 volte 100 libero soglia');
    });
  });
}
