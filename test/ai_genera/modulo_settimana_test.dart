import 'package:coach_vasca/features/ai_genera/domain/modulo_settimana_compilato.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModuloSettimanaCompilato.fromMap', () {
    test('legge giorni, focus per giorno e dettagli', () {
      final m = ModuloSettimanaCompilato.fromMap({
        'volumeSettimanaleMetri': 12000,
        'giorni': [5, 1, 3, 3],
        'focusPerGiorno': [
          {
            'giorno': 3,
            'focus': ['tecnica'],
          },
          {
            'giorno': 5,
            'focus': ['gambe'],
          },
        ],
        'metriGambe': 500,
        'attrezziGambe': ['pinne'],
        'vincoli': ' no rana ',
      });
      expect(m.volumeSettimanaleMetri, 12000);
      expect(m.giorni, [1, 3, 5]);
      expect(m.focusPerGiorno[3], ['tecnica']);
      expect(m.focusPerGiorno[5], ['gambe']);
      expect(m.gambe?.metri, 500);
      expect(m.gambe?.attrezzatura, ['pinne']);
      expect(m.braccia, isNull);
      expect(m.vincoli, 'no rana');
      expect(m.vuoto, isFalse);
    });

    test('scarta giorni fuori 1-7 e voci focus malformate', () {
      final m = ModuloSettimanaCompilato.fromMap({
        'giorni': [0, 8, 2],
        'focusPerGiorno': [
          {
            'giorno': 9,
            'focus': ['gambe'],
          },
          {'giorno': 2, 'focus': <String>[]},
          'non una mappa',
        ],
      });
      expect(m.giorni, [2]);
      expect(m.focusPerGiorno, isEmpty);
    });

    test('mappa vuota è vuota', () {
      expect(ModuloSettimanaCompilato.fromMap({}).vuoto, isTrue);
    });
  });
}
