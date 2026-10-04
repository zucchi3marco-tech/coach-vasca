import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/serie_labels.dart';
import 'package:flutter_test/flutter_test.dart';

Serie _serie({int? distanzaM, int? durataS}) => Serie(
  id: 's',
  allenamentoId: 'a',
  clubId: 'c',
  ordine: 1,
  blocco: 'principale',
  ripetute: 3,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: 'a secco',
);

void main() {
  group('Serie a tempo', () {
    test('aTempo è vero solo con durataS', () {
      expect(_serie(distanzaM: 100).aTempo, isFalse);
      expect(_serie(durataS: 60).aTempo, isTrue);
    });

    test('distanzaTotaleM non conta le serie a tempo (0, non una stima)', () {
      expect(_serie(durataS: 60).distanzaTotaleM, 0);
      expect(_serie(distanzaM: 100).distanzaTotaleM, 300);
    });

    test('labelVolumeSerie distingue distanza e durata', () {
      expect(labelVolumeSerie(_serie(distanzaM: 100)), '3×100m');
      expect(labelVolumeSerie(_serie(durataS: 90)), '3×1\'30"');
    });
  });
}
