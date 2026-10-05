import 'package:coach_vasca/features/libreria_blocchi/application/excel_export.dart';
import 'package:coach_vasca/features/libreria_blocchi/application/excel_import.dart';
import 'package:coach_vasca/features/libreria_blocchi/domain/training_block.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingBlock _blocco({
  required String id,
  required String codice,
  String sport = 'nuoto',
  String livelli = 'Ragazzi, Assoluti',
}) => TrainingBlock(
  id: id,
  clubId: 'c',
  codice: codice,
  sport: sport,
  fase: 'Serie principale',
  obiettivo: 'Aerobico',
  zoneCoinvolte: 'A2',
  titolo: '3x400 MX A2',
  descrizione: '3x400 misti [A2] rec 30"',
  stilePrincipale: 'Misti',
  livelli: livelli,
  attrezzi: null,
  metriTotali: 1200,
  durataStimataMin: 20,
  note: null,
  stato: 'approvato',
  fonte: 'Allenatore',
  modificatoInApp: true,
);

TrainingBlockParte _parte({
  required String bloccoId,
  int? distanzaM,
  int? durataS,
  String zona = 'A2',
  String esecuzione = 'nuoto',
}) => TrainingBlockParte(
  id: 'p-$bloccoId',
  bloccoId: bloccoId,
  clubId: 'c',
  ordine: 1,
  giri: 1,
  ripetizioni: 3,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'Misti',
  esercizio: 'misti A2',
  zona: zona,
  esecuzione: esecuzione,
  recuperoS: 30,
  attrezzi: null,
  note: null,
);

void main() {
  test('esporta e re-importa: i dati tornano gli stessi (round-trip)', () {
    final blocchi = [
      _blocco(id: 'b1', codice: 'N-900'),
      _blocco(id: 'b2', codice: 'P-900', sport: 'pallanuoto'),
    ];
    final parti = {
      'b1': [_parte(bloccoId: 'b1', distanzaM: 400)],
      'b2': [_parte(bloccoId: 'b2', durataS: 600, zona: 'A1')],
    };

    final bytes = generaExcelLibreria(blocchi, parti);
    final risultato = parseLibreriaExcel(bytes);

    expect(risultato.errori, isEmpty);
    expect(risultato.blocchi, hasLength(2));

    final n900 = risultato.blocchi.firstWhere((b) => b.codice == 'N-900');
    expect(n900.sport, 'nuoto');
    expect(n900.titolo, '3x400 MX A2');
    expect(n900.parti, hasLength(1));
    expect(n900.parti.single.distanzaM, 400);
    expect(n900.parti.single.durataS, isNull);

    final p900 = risultato.blocchi.firstWhere((b) => b.codice == 'P-900');
    expect(p900.sport, 'pallanuoto');
    expect(p900.parti.single.durataS, 600);
    expect(p900.parti.single.distanzaM, isNull);
  });

  test('blocco senza parti non viene esportato come riga orfana', () {
    final blocchi = [_blocco(id: 'b1', codice: 'N-901')];
    final bytes = generaExcelLibreria(blocchi, const {});
    final risultato = parseLibreriaExcel(bytes);
    // Senza parti il blocco viene scartato dall'importatore (richiede
    // almeno una parte): nessun errore comunque fatale.
    expect(risultato.blocchi, isEmpty);
  });
}
