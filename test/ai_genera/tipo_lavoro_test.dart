import 'package:coach_vasca/features/ai_genera/domain/tipo_lavoro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ogni zona di ordineTipiLavoro ha una voce in tipiLavoro', () {
    for (final zona in ordineTipiLavoro) {
      expect(tipiLavoro.containsKey(zona), isTrue, reason: 'manca $zona');
    }
  });

  test('ogni voce ha un nome, un a-cosa-serve e dei riferimenti non vuoti', () {
    for (final tipo in tipiLavoro.values) {
      expect(tipo.nome, isNotEmpty);
      expect(tipo.aCosaServe, isNotEmpty);
      expect(tipo.riferimenti, isNotEmpty);
    }
  });

  test('C3 non ha un range di frequenza cardiaca (sforzo massimale breve)', () {
    expect(tipiLavoro['C3']!.fcMaxMinPct, isNull);
    expect(tipiLavoro['C3']!.fcMaxMaxPct, isNull);
  });

  test(
    'la spiegazione include sempre il disclaimer sulla frequenza cardiaca',
    () {
      for (final tipo in tipiLavoro.values) {
        expect(
          tipo.spiegazione,
          contains('non registra la frequenza cardiaca'),
        );
      }
    },
  );

  group('etichettaTipoLavoro', () {
    test('coi codici mostra la sigla', () {
      expect(etichettaTipoLavoro('B1', mostraCodici: true), 'B1');
    });

    test('coi nomi mostra il nome descrittivo', () {
      expect(
        etichettaTipoLavoro('B1', mostraCodici: false),
        'Soglia anaerobica',
      );
    });

    test('una zona non mappata (storica) ripiega sulla sigla', () {
      expect(etichettaTipoLavoro('C', mostraCodici: false), 'C');
    });
  });
}
