import 'package:coach_vasca/features/ai_genera/application/controlli_settimana_service.dart';
import 'package:coach_vasca/features/ai_genera/domain/scheda_generata.dart';
import 'package:flutter_test/flutter_test.dart';

SerieGenerata _serie({
  String blocco = 'principale',
  int ripetute = 1,
  int distanzaM = 100,
  String esecuzione = 'nuoto',
  String? zona,
}) => SerieGenerata(
  ordine: 1,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: zona,
);

SchedaGenerata _seduta(List<SerieGenerata> serie, {String titolo = 'x'}) =>
    SchedaGenerata(titolo: titolo, serie: serie);

SedutaPerControllo _sp(DateTime data, SchedaGenerata scheda) => (data, scheda);

void main() {
  group('volumeEntroTolleranza', () {
    test('entro il 10%: ok', () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(distanzaM: 1900)])),
      ];
      expect(volumeEntroTolleranza(sedute, 2000), isTrue);
    });

    test('oltre il 10%: non ok', () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(distanzaM: 1000)])),
      ];
      expect(volumeEntroTolleranza(sedute, 2000), isFalse);
    });
  });

  group('sedutesenzaRiscaldamentoODefaticamento', () {
    test('seduta completa: nessun indice', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([
            _serie(blocco: 'riscaldamento'),
            _serie(blocco: 'principale'),
            _serie(blocco: 'defaticamento'),
          ]),
        ),
      ];
      expect(sedutesenzaRiscaldamentoODefaticamento(sedute), isEmpty);
    });

    test('manca il defaticamento: segnalata', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([
            _serie(blocco: 'riscaldamento'),
            _serie(blocco: 'principale'),
          ]),
        ),
      ];
      expect(sedutesenzaRiscaldamentoODefaticamento(sedute), [0]);
    });
  });

  group('giornateLattacideConsecutive', () {
    test('due giorni lattacidi di fila (per data, non per posizione)', () {
      // Inserite fuori ordine: la seconda per data (3 gen) e' all'indice 0.
      final sedute = [
        _sp(
          DateTime(2026, 1, 3),
          _seduta([_serie(blocco: 'principale', zona: 'C1')]),
        ),
        _sp(
          DateTime(2026, 1, 1),
          _seduta([_serie(blocco: 'principale', zona: 'C2')]),
        ),
      ];
      expect(giornateLattacideConsecutive(sedute), [0]);
    });

    test('un giorno lattacido isolato: nessuna segnalazione', () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(zona: 'A1')])),
        _sp(
          DateTime(2026, 1, 2),
          _seduta([_serie(blocco: 'principale', zona: 'C1')]),
        ),
        _sp(DateTime(2026, 1, 3), _seduta([_serie(zona: 'A2')])),
      ];
      expect(giornateLattacideConsecutive(sedute), isEmpty);
    });
  });

  group('caricoEccessivo', () {
    test('aumento oltre il 15%: eccessivo', () {
      expect(caricoEccessivo(2000, 1000), isTrue);
    });

    test('scarico (volume minore): mai eccessivo', () {
      expect(caricoEccessivo(500, 1000), isFalse);
    });

    test('nessuno storico: mai eccessivo', () {
      expect(caricoEccessivo(5000, null), isFalse);
    });
  });

  group('indiceScaricoMancante', () {
    test('gara importante imminente e ultima seduta piena: segnalata', () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(distanzaM: 2000)])),
        _sp(DateTime(2026, 1, 3), _seduta([_serie(distanzaM: 2000)])),
      ];
      expect(indiceScaricoMancante(sedute, garaAltaImminente: true), 1);
    });

    test("ultima seduta già scarico (sotto l'80% della media): ok", () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(distanzaM: 2000)])),
        _sp(DateTime(2026, 1, 3), _seduta([_serie(distanzaM: 500)])),
      ];
      expect(indiceScaricoMancante(sedute, garaAltaImminente: true), isNull);
    });

    test('nessuna gara imminente: mai segnalato', () {
      final sedute = [
        _sp(DateTime(2026, 1, 1), _seduta([_serie(distanzaM: 2000)])),
      ];
      expect(indiceScaricoMancante(sedute, garaAltaImminente: false), isNull);
    });
  });

  group('pallanuotoNuotoPuroOltre50', () {
    test('oltre il 50% di nuoto puro in pallanuoto: segnalata', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([
            _serie(esecuzione: 'nuoto', distanzaM: 600),
            _serie(esecuzione: 'pallanuoto tecnico-tattico', distanzaM: 200),
          ]),
        ),
      ];
      expect(pallanuotoNuotoPuroOltre50(sedute, sportPallanuoto: true), [0]);
    });

    test('ignorato se non pallanuoto o se richiesto esplicitamente', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([_serie(esecuzione: 'nuoto', distanzaM: 1000)]),
        ),
      ];
      expect(
        pallanuotoNuotoPuroOltre50(sedute, sportPallanuoto: false),
        isEmpty,
      );
      expect(
        pallanuotoNuotoPuroOltre50(
          sedute,
          sportPallanuoto: true,
          richiestoEsplicito: true,
        ),
        isEmpty,
      );
    });
  });

  group('controllaSettimana', () {
    test('un solo problema -> una sola rigenerazione proposta', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([
            _serie(blocco: 'riscaldamento'),
            _serie(blocco: 'principale'),
          ]),
        ),
      ];
      final esito = controllaSettimana(
        sedute: sedute,
        volumeSettimanaleRichiesto: 100,
      );
      expect(esito.avvisi, isNotEmpty);
      expect(esito.indiceDaRigenerare, 0);
      expect(esito.vincoloExtra, isNotNull);
    });

    test('nessun problema: nessun avviso, nessuna rigenerazione', () {
      final sedute = [
        _sp(
          DateTime(2026, 1, 1),
          _seduta([
            _serie(blocco: 'riscaldamento', distanzaM: 500),
            _serie(blocco: 'defaticamento', distanzaM: 500),
          ]),
        ),
      ];
      final esito = controllaSettimana(
        sedute: sedute,
        volumeSettimanaleRichiesto: 1000,
      );
      expect(esito.avvisi, isEmpty);
      expect(esito.indiceDaRigenerare, isNull);
    });
  });
}
