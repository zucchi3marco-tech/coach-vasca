import 'package:coach_vasca/features/export/domain/periodo_dati.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodoDati', () {
    test('"Tutto" comprende ogni giorno', () {
      const tutto = PeriodoDati.tutto();
      expect(tutto.eTutto, isTrue);
      expect(tutto.comprende(DateTime(1999, 1, 1)), isTrue);
      expect(tutto.comprende(DateTime(2040, 12, 31)), isTrue);
      expect(tutto.etichetta, 'Tutto');
      expect(tutto.descrizione, 'Tutti i dati');
    });

    test('una stagione va dal 1 settembre al 31 agosto, estremi compresi', () {
      const stagione = PeriodoDati.stagione(2026);
      expect(stagione.eTutto, isFalse);
      expect(stagione.comprende(DateTime(2026, 9, 1)), isTrue);
      expect(stagione.comprende(DateTime(2027, 8, 31)), isTrue);
      expect(stagione.comprende(DateTime(2026, 12, 25)), isTrue);
      expect(stagione.comprende(DateTime(2026, 8, 31)), isFalse);
      expect(stagione.comprende(DateTime(2027, 9, 1)), isFalse);
    });

    test('conta il giorno, non l\'ora', () {
      const stagione = PeriodoDati.stagione(2026);
      // L'ultimo giorno a tarda sera è ancora dentro, il giorno prima del
      // primo a un minuto dalla mezzanotte è ancora fuori.
      expect(stagione.comprende(DateTime(2027, 8, 31, 23, 59, 59)), isTrue);
      expect(stagione.comprende(DateTime(2026, 8, 31, 23, 59, 59)), isFalse);
      expect(stagione.comprende(DateTime(2026, 9, 1, 0, 0, 1)), isTrue);
    });

    test('un orario in UTC si conta nel giorno del telefono', () {
      const stagione = PeriodoDati.stagione(2026);
      final locale = DateTime(2026, 9, 1, 12);
      expect(stagione.comprende(locale.toUtc()), isTrue);
    });

    test('etichetta e descrizione di una stagione', () {
      const stagione = PeriodoDati.stagione(2026);
      expect(stagione.etichetta, 'Stagione 2026-2027');
      expect(stagione.descrizione, 'dal 01/09/2026 al 31/08/2027');
    });

    test('uguaglianza e hashCode', () {
      expect(const PeriodoDati.tutto(), const PeriodoDati.tutto());
      expect(
        const PeriodoDati.stagione(2026),
        const PeriodoDati.stagione(2026),
      );
      expect(
        const PeriodoDati.stagione(2026).hashCode,
        const PeriodoDati.stagione(2026).hashCode,
      );
      expect(
        const PeriodoDati.stagione(2026) == const PeriodoDati.stagione(2025),
        isFalse,
      );
      expect(
        const PeriodoDati.tutto() == const PeriodoDati.stagione(2026),
        isFalse,
      );
      final periodi = [
        const PeriodoDati.stagione(2026),
        const PeriodoDati.stagione(2026),
        const PeriodoDati.tutto(),
      ];
      expect(periodi.toSet(), hasLength(2));
    });
  });

  group('annoInizioStagione', () {
    test('da settembre è l\'anno stesso, prima è quello prima', () {
      expect(annoInizioStagione(DateTime(2026, 9, 1)), 2026);
      expect(annoInizioStagione(DateTime(2026, 12, 31)), 2026);
      expect(annoInizioStagione(DateTime(2027, 1, 1)), 2026);
      expect(annoInizioStagione(DateTime(2027, 8, 31)), 2026);
    });
  });

  group('periodiDisponibili', () {
    test('"Tutto" per primo, poi la stagione in corso e la precedente', () {
      final periodi = periodiDisponibili(DateTime(2026, 10, 18));
      expect(periodi, [
        const PeriodoDati.tutto(),
        const PeriodoDati.stagione(2026),
        const PeriodoDati.stagione(2025),
      ]);
    });

    test(
      'prima di settembre la stagione in corso è iniziata l\'anno prima',
      () {
        final periodi = periodiDisponibili(DateTime(2027, 3, 10));
        expect(periodi, [
          const PeriodoDati.tutto(),
          const PeriodoDati.stagione(2026),
          const PeriodoDati.stagione(2025),
        ]);
      },
    );

    test('torna indietro fino alla stagione in cui è nato il club', () {
      final periodi = periodiDisponibili(
        DateTime(2026, 10, 18),
        daQuando: DateTime(2024, 11, 3),
      );
      expect(periodi, [
        const PeriodoDati.tutto(),
        const PeriodoDati.stagione(2026),
        const PeriodoDati.stagione(2025),
        const PeriodoDati.stagione(2024),
      ]);
    });

    test('un club nato nell\'ultima stagione ha solo quella', () {
      final periodi = periodiDisponibili(
        DateTime(2026, 10, 18),
        daQuando: DateTime(2026, 9, 20),
      );
      expect(periodi, [
        const PeriodoDati.tutto(),
        const PeriodoDati.stagione(2026),
      ]);
    });

    test('un club nato prima del 1 settembre conta già la stagione prima', () {
      final periodi = periodiDisponibili(
        DateTime(2026, 10, 18),
        daQuando: DateTime(2026, 8, 31),
      );
      expect(periodi, [
        const PeriodoDati.tutto(),
        const PeriodoDati.stagione(2026),
        const PeriodoDati.stagione(2025),
      ]);
    });

    test('al massimo sei stagioni, le più recenti', () {
      final periodi = periodiDisponibili(
        DateTime(2026, 10, 18),
        daQuando: DateTime(2000, 5, 5),
      );
      expect(periodi, hasLength(7));
      expect(periodi.first, const PeriodoDati.tutto());
      expect(periodi[1], const PeriodoDati.stagione(2026));
      expect(periodi.last, const PeriodoDati.stagione(2021));
    });

    test('una data di nascita nel futuro lascia la stagione in corso', () {
      final periodi = periodiDisponibili(
        DateTime(2026, 10, 18),
        daQuando: DateTime(2030, 1, 1),
      );
      expect(periodi, [
        const PeriodoDati.tutto(),
        const PeriodoDati.stagione(2026),
      ]);
    });
  });
}
