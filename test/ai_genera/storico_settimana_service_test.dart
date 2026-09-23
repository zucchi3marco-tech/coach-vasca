import 'package:coach_vasca/features/ai_genera/application/storico_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:flutter_test/flutter_test.dart';

Allenamento _allenamento(String id, DateTime data) =>
    Allenamento(id: id, clubId: 'c1', data: data);

Serie _serie(
  String allenamentoId, {
  int ripetute = 4,
  int distanzaM = 100,
  String blocco = 'principale',
  String stile = 'libero',
  String esecuzione = 'nuoto',
  String? zona = 'B1',
  String? attrezzatura,
}) => Serie(
  id: '$allenamentoId-${blocco}_${stile}_$esecuzione',
  allenamentoId: allenamentoId,
  clubId: 'c1',
  ordine: 1,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: stile,
  esecuzione: esecuzione,
  zona: zona,
  attrezzatura: attrezzatura,
);

void main() {
  group('copre60Giorni', () {
    test('nessun allenamento: false', () {
      expect(copre60Giorni(const [], const {}), isFalse);
    });

    test('allenamenti senza serie non contano', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final a2 = _allenamento('a2', DateTime(2026, 4, 1));
      expect(copre60Giorni([a1, a2], const {}), isFalse);
    });

    test('esattamente 60 giorni: vero', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final a2 = _allenamento('a2', DateTime(2026, 3, 2)); // 60 giorni dopo
      final serie = {
        'a1': [_serie('a1')],
        'a2': [_serie('a2')],
      };
      expect(copre60Giorni([a1, a2], serie), isTrue);
    });

    test('59 giorni: falso', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final a2 = _allenamento('a2', DateTime(2026, 3, 1)); // 59 giorni dopo
      final serie = {
        'a1': [_serie('a1')],
        'a2': [_serie('a2')],
      };
      expect(copre60Giorni([a1, a2], serie), isFalse);
    });

    test('un allenamento in mezzo non serve: contano solo il più vecchio e '
        'il più recente con serie', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final aMezzo = _allenamento('aMezzo', DateTime(2026, 1, 20));
      final a2 = _allenamento('a2', DateTime(2026, 3, 2));
      final serie = {
        'a1': [_serie('a1')],
        // aMezzo senza serie: non deve influire.
        'a2': [_serie('a2')],
      };
      expect(copre60Giorni([a1, aMezzo, a2], serie), isTrue);
    });
  });

  group('calcolaRiassunto', () {
    test('nessun allenamento: valori a zero, nessuna eccezione', () {
      final riassunto = calcolaRiassunto(const [], const {});
      expect(riassunto.sedutePerSettimanaMedia, 0);
      expect(riassunto.volumeMedioPerSedutaM, 0);
      expect(riassunto.percentualeMetriPerZona, isEmpty);
      expect(riassunto.attrezzaturaFrequente, isEmpty);
    });

    test('le percentuali per zona sommano a 100', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final serie = {
        'a1': [
          _serie('a1', zona: 'A1', distanzaM: 400, ripetute: 1),
          _serie('a1', zona: 'B1', distanzaM: 100, ripetute: 8),
        ],
      };
      final riassunto = calcolaRiassunto([a1], serie);
      final somma = riassunto.percentualeMetriPerZona.values.fold(
        0.0,
        (t, v) => t + v,
      );
      expect(somma, closeTo(100, 0.01));
    });

    test('l\'attrezzatura più usata viene prima nella classifica', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final serie = {
        'a1': [
          _serie('a1', attrezzatura: 'pull'),
          _serie('a1', attrezzatura: 'pull'),
          _serie('a1', attrezzatura: 'pinne'),
        ],
      };
      final riassunto = calcolaRiassunto([a1], serie);
      expect(riassunto.attrezzaturaFrequente.first, 'pull');
    });

    test('volume medio e sedute/settimana su più allenamenti', () {
      final a1 = _allenamento('a1', DateTime(2026, 1, 1));
      final a2 = _allenamento('a2', DateTime(2026, 1, 8)); // una settimana dopo
      final serie = {
        'a1': [_serie('a1', ripetute: 4, distanzaM: 100)], // 400m
        'a2': [_serie('a2', ripetute: 4, distanzaM: 100)], // 400m
      };
      final riassunto = calcolaRiassunto([a1, a2], serie);
      expect(riassunto.volumeMedioPerSedutaM, 400);
      // 8 giorni coperti -> poco più di una settimana, 2 sedute
      expect(riassunto.sedutePerSettimanaMedia, closeTo(2, 0.5));
    });
  });
}
