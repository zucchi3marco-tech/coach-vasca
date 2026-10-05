import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../domain/training_block.dart';

const _intestazioneBlocchi = [
  'ID',
  'Sport',
  'Fase',
  'Obiettivo',
  'Zone',
  'Titolo',
  'Descrizione',
  'Stile principale',
  'Livelli / categorie',
  'Attrezzi',
  'Metri totali',
  'Durata stimata (min)',
  "Note per l'allenatore",
  'Stato',
  'Fonte',
];

const _intestazioneParti = [
  'ID blocco',
  'Ordine',
  'Giri',
  'Ripetizioni',
  'Distanza (m)',
  'Durata (s)',
  'Stile',
  'Esercizio / andatura',
  'Zona',
  'Recupero (s)',
  'Attrezzi',
  'Note',
];

CellValue? _testo(String? valore) =>
    valore == null || valore.isEmpty ? null : TextCellValue(valore);

CellValue? _intero(int? valore) => valore == null ? null : IntCellValue(valore);

String _sportPerExcel(String sport) => switch (sport) {
  'nuoto' => 'Nuoto',
  'pallanuoto' => 'Pallanuoto',
  'entrambi' => 'Entrambi',
  _ => sport,
};

/// Esporta la libreria blocchi di un club nello stesso formato del file
/// Excel originale (fogli "Blocchi" e "Parti", stesse colonne nello
/// stesso ordine) — così il coach può correggerla fuori dall'app e
/// re-importarla. "Metri totali"/"Durata stimata" sono scritti come
/// numeri semplici (non come formule, a differenza del file originale):
/// l'importatore li ricalcola comunque dalle parti, non li legge da qui.
Uint8List generaExcelLibreria(
  List<TrainingBlock> blocchi,
  Map<String, List<TrainingBlockParte>> partiPerBlocco,
) {
  final excel = Excel.createExcel();
  final foglioDefault = excel.getDefaultSheet();
  excel.rename(foglioDefault!, 'Blocchi');

  excel.appendRow('Blocchi', [
    for (final h in _intestazioneBlocchi) TextCellValue(h),
  ]);
  for (final b in blocchi) {
    excel.appendRow('Blocchi', [
      TextCellValue(b.codice),
      TextCellValue(_sportPerExcel(b.sport)),
      TextCellValue(b.fase),
      TextCellValue(b.obiettivo),
      TextCellValue(b.zoneCoinvolte),
      TextCellValue(b.titolo),
      TextCellValue(b.descrizione),
      _testo(b.stilePrincipale),
      TextCellValue(b.livelli),
      _testo(b.attrezzi),
      IntCellValue(b.metriTotali),
      IntCellValue(b.durataStimataMin),
      _testo(b.note),
      TextCellValue(b.stato),
      TextCellValue(b.fonte),
    ]);
  }

  excel.appendRow('Parti', [
    for (final h in _intestazioneParti) TextCellValue(h),
  ]);
  for (final b in blocchi) {
    for (final p in partiPerBlocco[b.id] ?? const <TrainingBlockParte>[]) {
      excel.appendRow('Parti', [
        TextCellValue(b.codice),
        IntCellValue(p.ordine),
        IntCellValue(p.giri),
        IntCellValue(p.ripetizioni),
        _intero(p.distanzaM),
        _intero(p.durataS),
        _testo(p.stile),
        _testo(p.esercizio),
        TextCellValue(p.zona),
        _intero(p.recuperoS),
        _testo(p.attrezzi),
        _testo(p.note),
      ]);
    }
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Impossibile generare il file Excel');
  }
  return Uint8List.fromList(bytes);
}
