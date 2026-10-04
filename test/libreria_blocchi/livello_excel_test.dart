import 'package:coach_vasca/features/libreria_blocchi/application/selezione_blocchi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('livelloExcelPerGruppo', () {
    test('categorie pallanuoto note', () {
      expect(livelloExcelPerGruppo('U12'), 'Esordienti');
      expect(livelloExcelPerGruppo('Under 14'), 'Ragazzi');
      expect(livelloExcelPerGruppo('U16'), 'Assoluti');
      expect(livelloExcelPerGruppo('Prima squadra'), 'Assoluti');
      expect(livelloExcelPerGruppo('Master'), 'Master');
    });

    test('categorie nuoto note', () {
      expect(livelloExcelPerGruppo('Es.B'), 'Esordienti');
      expect(livelloExcelPerGruppo('Ragazzi'), 'Ragazzi');
      expect(livelloExcelPerGruppo('Juniores'), 'Assoluti');
      expect(livelloExcelPerGruppo('Amatori'), 'Master');
    });

    test('nome di gruppo libero non riconosciuto: nessun filtro', () {
      expect(livelloExcelPerGruppo('Squadra B'), isNull);
      expect(livelloExcelPerGruppo(null), isNull);
    });

    test('confronto case-insensitive', () {
      expect(livelloExcelPerGruppo('under 14 rosso'), 'Ragazzi');
    });
  });

  group('sportRichiestoDaClub', () {
    test('nuoto e pallanuoto si traducono direttamente', () {
      expect(sportRichiestoDaClub('nuoto'), 'nuoto');
      expect(sportRichiestoDaClub('pallanuoto'), 'pallanuoto');
    });

    test('nuoto_pallanuoto o assente: nessun filtro sport', () {
      expect(sportRichiestoDaClub('nuoto_pallanuoto'), isNull);
      expect(sportRichiestoDaClub(null), isNull);
    });
  });
}
