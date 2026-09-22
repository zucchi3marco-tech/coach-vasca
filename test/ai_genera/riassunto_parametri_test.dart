import 'package:coach_vasca/features/ai_genera/domain/riassunto_parametri.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('riassuntoParametriGenerazione', () {
    test('dal form a parametri: unisce gruppo, volume e focus', () {
      final riassunto = riassuntoParametriGenerazione({
        'gruppo': 'U14',
        'volumeMetri': 3000,
        'focus': 'soglia',
      });
      expect(riassunto, 'U14 · 3000 m · soglia');
    });

    test('salta i campi mancanti senza lasciare separatori vuoti', () {
      expect(riassuntoParametriGenerazione({'focus': 'tecnica'}), 'tecnica');
    });

    test('dalla dettatura: anteponi il microfono al testo', () {
      final riassunto = riassuntoParametriGenerazione({
        'modalita': 'dettatura',
        'testo': 'Riscaldamento 400 misti',
      });
      expect(riassunto, '🎙️ Riscaldamento 400 misti');
    });

    test('dalla dettatura: tronca i testi lunghi con i puntini', () {
      final testoLungo = 'a' * 100;
      final riassunto = riassuntoParametriGenerazione({
        'modalita': 'dettatura',
        'testo': testoLungo,
      });
      expect(riassunto, '🎙️ ${'a' * 60}…');
    });
  });
}
