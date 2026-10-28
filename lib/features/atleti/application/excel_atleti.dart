import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Un file che l'app non sa leggere; il [message] e' gia' scritto per il
/// coach e si mostra cosi' com'e'.
class FoglioNonLeggibile implements Exception {
  const FoglioNonLeggibile(this.message);

  final String message;

  @override
  String toString() => message;
}

const _messaggioFormatoVecchio =
    'Questo file è nel formato vecchio di Excel: aprilo e salvalo come '
    '.xlsx, poi riprova.';
const _messaggioFormatoSconosciuto =
    'Posso leggere solo file .xlsx o .csv: apri il foglio e salvalo in uno '
    'di questi formati, poi riprova.';
const _messaggioRovinato =
    'Non riesco ad aprire il file: sembra rovinato. Aprilo in Excel, '
    'salvalo di nuovo come .xlsx e riprova.';

/// Legge un file .xlsx o .csv e ne da' la tabella di celle (valori `String`,
/// `int`, `double`, `bool`, `DateTime` o null). Il file resta sul
/// dispositivo: non viene mandato a nessuno.
///
/// Lancia [FoglioNonLeggibile] con un messaggio per il coach.
List<List<Object?>> leggiTabellaAtleti(
  Uint8List bytes, {
  required String nomeFile,
}) {
  final nome = nomeFile.toLowerCase().trim();
  if (nome.endsWith('.xls')) {
    throw const FoglioNonLeggibile(_messaggioFormatoVecchio);
  }
  // Un vecchio .xls rinominato .xlsx: lo si riconosce dalla firma.
  if (bytes.length >= 4 &&
      bytes[0] == 0xD0 &&
      bytes[1] == 0xCF &&
      bytes[2] == 0x11 &&
      bytes[3] == 0xE0) {
    throw const FoglioNonLeggibile(_messaggioFormatoVecchio);
  }
  if (nome.endsWith('.csv')) {
    try {
      return _leggiCsv(bytes);
    } catch (_) {
      throw const FoglioNonLeggibile(_messaggioRovinato);
    }
  }
  if (nome.endsWith('.xlsx') || nome.endsWith('.xlsm')) {
    try {
      return _leggiXlsx(bytes);
    } on FoglioNonLeggibile {
      rethrow;
    } catch (_) {
      throw const FoglioNonLeggibile(_messaggioRovinato);
    }
  }
  throw const FoglioNonLeggibile(_messaggioFormatoSconosciuto);
}

// ---------------------------------------------------------------------------
// xlsx

Object? _valoreCella(CellValue? v) {
  if (v == null) return null;
  return switch (v) {
    TextCellValue() => v.value.toString(),
    IntCellValue() => v.value,
    DoubleCellValue() => v.value,
    BoolCellValue() => v.value,
    DateCellValue() => v.asDateTimeLocal(),
    DateTimeCellValue() => v.asDateTimeLocal(),
    // Una formula non ha qui il valore calcolato.
    FormulaCellValue() => null,
    TimeCellValue() => null,
  };
}

List<List<Object?>> _leggiXlsx(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  for (final foglio in excel.tables.values) {
    final righe = [
      for (final riga in foglio.rows)
        [for (final cella in riga) _valoreCella(cella?.value)],
    ];
    final haDati = righe.any(
      (r) => r.any((c) => c != null && !(c is String && c.trim().isEmpty)),
    );
    if (haDati) return righe;
  }
  return const [];
}

// ---------------------------------------------------------------------------
// csv

List<List<Object?>> _leggiCsv(Uint8List bytes) {
  String testo;
  try {
    testo = utf8.decode(bytes);
  } on FormatException {
    // Excel italiano salva spesso in Windows-1252: latin1 ne e' vicino.
    testo = latin1.decode(bytes);
  }
  if (testo.startsWith('﻿')) testo = testo.substring(1);

  final separatore = _separatoreCsv(testo);
  final righe = <List<Object?>>[];
  var riga = <Object?>[];
  final campo = StringBuffer();
  var tra = false; // dentro le virgolette
  var campoQuotato = false;

  void chiudiCampo() {
    final s = campo.toString();
    riga.add(s.isEmpty && !campoQuotato ? null : s);
    campo.clear();
    campoQuotato = false;
  }

  void chiudiRiga() {
    chiudiCampo();
    righe.add(riga);
    riga = <Object?>[];
  }

  for (var i = 0; i < testo.length; i++) {
    final c = testo[i];
    if (tra) {
      if (c == '"') {
        if (i + 1 < testo.length && testo[i + 1] == '"') {
          campo.write('"');
          i++;
        } else {
          tra = false;
        }
      } else {
        campo.write(c);
      }
      continue;
    }
    if (c == '"') {
      tra = true;
      campoQuotato = true;
    } else if (c == separatore) {
      chiudiCampo();
    } else if (c == '\r') {
      if (i + 1 < testo.length && testo[i + 1] == '\n') i++;
      chiudiRiga();
    } else if (c == '\n') {
      chiudiRiga();
    } else {
      campo.write(c);
    }
  }
  if (campo.isNotEmpty || riga.isNotEmpty || campoQuotato) chiudiRiga();
  return righe;
}

/// ';' o ',' (o tab): quello piu' usato nella prima riga, fuori dalle
/// virgolette.
String _separatoreCsv(String testo) {
  final conteggi = {';': 0, ',': 0, '\t': 0};
  var tra = false;
  for (var i = 0; i < testo.length; i++) {
    final c = testo[i];
    if (c == '"') {
      tra = !tra;
    } else if (!tra && (c == '\n' || c == '\r')) {
      if (conteggi.values.any((n) => n > 0)) break;
    } else if (!tra && conteggi.containsKey(c)) {
      conteggi[c] = conteggi[c]! + 1;
    }
  }
  var migliore = ';';
  var max = 0;
  for (final e in conteggi.entries) {
    if (e.value > max) {
      max = e.value;
      migliore = e.key;
    }
  }
  return migliore;
}

// ---------------------------------------------------------------------------
// Modello

const _titoliModello = [
  'Cognome',
  'Nome',
  'Data di nascita',
  'Squadra',
  'Ruolo',
  'Sesso',
  'Tessera FIN',
  'Email genitore',
  'Telefono genitore',
  'Visita medica',
  'Consenso privacy',
  'Note',
];

const _ruoliPallanuoto = [
  'Portiere',
  'Centroboa',
  'Marcatore',
  'Esterno',
  'Movimento',
];

/// Il modello da compilare: un foglio "Atleti" con i titoli e un foglio
/// "Come si compila" con le istruzioni, le squadre del club e i ruoli.
Uint8List modelloAtleti({required List<String> nomiSquadre}) {
  final excel = Excel.createExcel();
  final predefinito = excel.getDefaultSheet();
  if (predefinito != null) excel.rename(predefinito, 'Atleti');

  const titoli = _titoliModello;
  final grassetto = CellStyle(bold: true);

  final atleti = excel['Atleti'];
  for (var c = 0; c < titoli.length; c++) {
    final cella = atleti.cell(
      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
    );
    cella.value = TextCellValue(titoli[c]);
    cella.cellStyle = grassetto;
    atleti.setColumnWidth(c, titoli[c] == 'Note' ? 32 : 20);
  }

  final guida = excel['Come si compila'];
  guida.setColumnWidth(0, 22);
  guida.setColumnWidth(1, 16);
  guida.setColumnWidth(2, 80);
  var riga = 0;
  void scrivi(List<String> celle, {bool titolo = false}) {
    for (var c = 0; c < celle.length; c++) {
      final cella = guida.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: riga),
      );
      cella.value = TextCellValue(celle[c]);
      if (titolo) cella.cellStyle = grassetto;
    }
    riga++;
  }

  scrivi(['Colonna', 'Obbligatoria?', 'Come si scrive'], titolo: true);
  scrivi(['Cognome', 'Obbligatoria', 'Il cognome. Esempio: Rossi.']);
  scrivi(['Nome', 'Obbligatoria', 'Il nome. Esempio: Mario.']);
  scrivi([
    'Data di nascita',
    'Obbligatoria',
    'Giorno, mese e anno. Esempio: 12/03/2012.',
  ]);
  scrivi([
    'Squadra',
    'Facoltativa',
    'Il nome della squadra come sta nell\'app (le trovi qui sotto). '
        'Se la lasci vuota, l\'atleta resta senza squadra.',
  ]);
  scrivi([
    'Ruolo',
    'Facoltativa',
    'Portiere, Centroboa, Marcatore, Esterno o Movimento.',
  ]);
  scrivi(['Sesso', 'Facoltativa', 'M oppure F.']);
  scrivi([
    'Tessera FIN',
    'Facoltativa',
    'Il numero della tessera della federazione.',
  ]);
  scrivi([
    'Email genitore',
    'Facoltativa',
    'L\'indirizzo email, per esempio mario.rossi@gmail.com.',
  ]);
  scrivi([
    'Telefono genitore',
    'Facoltativa',
    'Il numero di telefono, per esempio 333 1234567.',
  ]);
  scrivi([
    'Visita medica',
    'Facoltativa',
    'La data in cui scade il certificato. Esempio: 30/09/2027.',
  ]);
  scrivi([
    'Consenso privacy',
    'Facoltativa',
    'Scrivi "sì" se il modulo è firmato. Se è vuoto, conta come non '
        'firmato.',
  ]);
  scrivi(['Note', 'Facoltativa', 'Quello che vuoi ricordare dell\'atleta.']);

  riga++;
  scrivi(['Le squadre del club'], titolo: true);
  scrivi(['Scrivile esattamente così nella colonna Squadra:']);
  if (nomiSquadre.isEmpty) {
    scrivi(['(il club non ha ancora squadre)']);
  } else {
    for (final nome in nomiSquadre) {
      scrivi([nome]);
    }
  }

  riga++;
  scrivi(['I ruoli'], titolo: true);
  for (final r in _ruoliPallanuoto) {
    scrivi([r]);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw const FoglioNonLeggibile('Non riesco a preparare il modello.');
  }
  return Uint8List.fromList(bytes);
}
