import 'package:coach_vasca/core/utils/pace_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDurataS', () {
    test('sotto il minuto, in secondi', () {
      expect(formatDurataS(45), '45"');
    });

    test('minuti esatti, senza i secondi', () {
      expect(formatDurataS(600), "10'");
    });

    test("minuti e secondi, con lo zero davanti", () {
      expect(formatDurataS(630), '10\'30"');
    });
  });

  group('formatDurataMmSs', () {
    test('va e torna con parsePaceMmSs', () {
      expect(formatDurataMmSs(630), '10:30');
      expect(parsePaceMmSs(formatDurataMmSs(630))?.round(), 630);
    });
  });
}
