import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../atleti/domain/atleta.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';
import '../domain/staff_distinta.dart';

/// Un convocato come serve al modulo: i dati della distinta (numero,
/// capitano, vice) e quelli dell'atleta (nome, tessera FIN).
typedef ConvocatoModulo = ({DistintaGiocatore giocatore, Atleta atleta});

/// Il nome del file da scaricare: "Formazione Canottieri-Rari Nantes
/// 2026-10-25.xlsx". Dai nomi si tolgono i caratteri che un nome di file
/// non può avere.
String nomeFileDistinta(Partita p) {
  String pulito(String testo) => testo
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final squadre = [
    pulito(p.squadraCasa),
    pulito(p.squadraTrasferta),
  ].where((s) => s.isNotEmpty).join('-');
  final data = '${p.data.year}-${_due(p.data.month)}-${_due(p.data.day)}';
  return '${['Formazione', if (squadre.isNotEmpty) squadre, data].join(' ')}'
      '.xlsx';
}

/// Il modulo della distinta della FIN, come lo usa il coach: un foglio con
/// l'intestazione della partita, i giocatori con numero e tessera, lo staff
/// e lo spazio per le firme. I loghi non ci sono.
///
/// I giocatori vanno in ordine di calottina. Le righe sono tante quante il
/// massimo dei convocati: quelle che avanzano restano vuote, con il bordo,
/// da riempire a mano.
Uint8List generaDistintaExcel({
  required Partita partita,
  required String nomeClub,
  String? nomeSquadra,
  required List<ConvocatoModulo> convocati,
  required StaffDistinta staff,
}) {
  final excel = Excel.createExcel();
  final nomeFoglio = _nomeFoglio(nomeSquadra);
  final predefinito = excel.getDefaultSheet();
  if (predefinito != null) excel.rename(predefinito, nomeFoglio);
  final foglio = excel[nomeFoglio];

  _scriviIntestazione(foglio, partita, nomeClub);
  final rigaVuota = _scriviGiocatori(foglio, partita, convocati);
  _scriviFirme(foglio, staff, rigaVuota + 1);

  for (final (colonna, larghezza) in _larghezze.indexed) {
    foglio.setColumnWidth(colonna, larghezza);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('Impossibile generare il file Excel');
  }
  return Uint8List.fromList(bytes);
}

// ---------------------------------------------------------------------------
// Misure

/// Le larghezze delle colonne A-D, come nel modulo (la C un po' più larga
/// per «Colore Calottina:»).
const _larghezze = [18.5, 32.5, 21.0, 26.0];

const _colonne = 4;

// ---------------------------------------------------------------------------
// Sezioni del foglio

/// Le righe 1-5: federazione, club, partita, campionato, colore, luogo,
/// data e ora.
void _scriviIntestazione(Sheet foglio, Partita partita, String nomeClub) {
  for (var r = 0; r < 3; r++) {
    foglio.merge(_cella(1, r), _cella(2, r));
  }
  _scrivi(
    foglio,
    1,
    0,
    _testo('FEDERAZIONE ITALIANA NUOTO'),
    _stile(dimensione: 14, grassetto: true),
  );
  _scrivi(
    foglio,
    1,
    1,
    _testo(nomeClub.toUpperCase()),
    _stile(dimensione: 14, grassetto: true),
  );
  _scrivi(
    foglio,
    1,
    2,
    _testo('${partita.squadraCasa} - ${partita.squadraTrasferta}'),
    _stile(dimensione: 16, grassetto: true),
  );

  _scrivi(
    foglio,
    1,
    3,
    _testo(_conEtichetta('Campionato:', partita.campionato)),
    _stile(orizzontale: HorizontalAlign.Left),
  );
  _scrivi(
    foglio,
    2,
    3,
    _testo('Colore Calottina:'),
    _stile(dimensione: 14, orizzontale: HorizontalAlign.Left),
  );
  _scrivi(
    foglio,
    3,
    3,
    _testo(_colore(partita.coloreCalottina)),
    _stile(dimensione: 14, orizzontale: HorizontalAlign.Left),
  );

  _scrivi(
    foglio,
    1,
    4,
    _testo(_conEtichetta('Luogo:', partita.luogo)),
    _stile(orizzontale: HorizontalAlign.Left),
  );
  _scrivi(
    foglio,
    2,
    4,
    _testo('DATA: ${_data(partita.data)}'),
    _stile(orizzontale: HorizontalAlign.Left),
  );
  _scrivi(
    foglio,
    3,
    4,
    _testo(_conEtichetta('ORE:', _ora(partita.ora))),
    _stile(orizzontale: HorizontalAlign.Left),
  );

  foglio.setRowHeight(0, 21.75);
  foglio.setRowHeight(1, 21.75);
  foglio.setRowHeight(2, 24);
  foglio.setRowHeight(3, 19.5);
  foglio.setRowHeight(4, 15.75);
}

/// La tabella dei giocatori (riga 6 in poi). Dà la riga vuota che la
/// segue.
int _scriviGiocatori(
  Sheet foglio,
  Partita partita,
  List<ConvocatoModulo> convocati,
) {
  const intestazione = [
    'n° calottina',
    'GIOCATORE',
    'n° tessera FIN',
    'formazione',
  ];
  final ordinati = [...convocati]
    ..sort((a, b) {
      final perNumero = a.giocatore.numeroCalottina.compareTo(
        b.giocatore.numeroCalottina,
      );
      return perNumero != 0
          ? perNumero
          : a.atleta.nomeCompleto.compareTo(b.atleta.nomeCompleto);
    });
  final giocatori = math.max(ordinati.length, partita.numeroMaxConvocati);
  final righe = giocatori + 1;

  const primaRiga = 5;
  for (var c = 0; c < _colonne; c++) {
    _scrivi(
      foglio,
      c,
      primaRiga,
      TextCellValue(intestazione[c]),
      _stileTabella(c, 0, righe),
    );
  }
  foglio.setRowHeight(primaRiga, 19.5);

  for (var i = 0; i < giocatori; i++) {
    final riga = primaRiga + 1 + i;
    final convocato = i < ordinati.length ? ordinati[i] : null;
    final valori = <CellValue?>[
      convocato == null
          ? null
          : IntCellValue(convocato.giocatore.numeroCalottina),
      convocato == null ? null : _testo(convocato.atleta.nomeCompleto),
      convocato == null ? null : _tessera(convocato.atleta.numeroTesseraFin),
      convocato == null ? null : _testo(_ruoloInSquadra(convocato.giocatore)),
    ];
    for (var c = 0; c < _colonne; c++) {
      _scrivi(foglio, c, riga, valori[c], _stileTabella(c, i + 1, righe));
    }
    foglio.setRowHeight(riga, 19.5);
  }
  return primaRiga + righe;
}

/// Lo staff, le firme e la nota in fondo. [prima] è la riga del primo
/// membro dello staff; quella sopra resta vuota.
void _scriviFirme(Sheet foglio, StaffDistinta staff, int prima) {
  const ruoli = RuoloStaff.values;
  for (final (i, ruolo) in ruoli.indexed) {
    final persona = staff.di(ruolo);
    final riga = prima + i;
    final valori = <CellValue?>[
      TextCellValue(ruolo.etichetta),
      _testo(persona.nome),
      TextCellValue('n° tessera FIN'),
      _tessera(persona.tessera),
    ];
    for (var c = 0; c < _colonne; c++) {
      _scrivi(
        foglio,
        c,
        riga,
        valori[c],
        _stileTabella(
          c,
          i,
          ruoli.length,
          orizzontale: c == 0 ? HorizontalAlign.Left : HorizontalAlign.Center,
        ),
      );
    }
    foglio.setRowHeight(riga, 19.5);
  }

  // Una riga vuota, poi le firme.
  final rigaVuota = prima + ruoli.length;
  foglio.setRowHeight(rigaVuota, 14.25);
  final firme = rigaVuota + 1;

  final scatola = _stile(
    sinistra: BorderStyle.Medium,
    destra: BorderStyle.Medium,
    sopra: BorderStyle.Medium,
    sotto: BorderStyle.Medium,
  );
  foglio.merge(_cella(1, firme), _cella(1, firme + 2));
  foglio.merge(_cella(3, firme), _cella(3, firme + 2));
  _scrivi(
    foglio,
    0,
    firme,
    TextCellValue('Capitano della squadra'),
    _stile(
      dimensione: 10,
      grassetto: true,
      orizzontale: HorizontalAlign.Left,
      sinistra: BorderStyle.Medium,
      destra: BorderStyle.Medium,
      sopra: BorderStyle.Medium,
    ),
  );
  _scrivi(
    foglio,
    0,
    firme + 1,
    null,
    _stile(sinistra: BorderStyle.Medium, destra: BorderStyle.Medium),
  );
  _scrivi(
    foglio,
    0,
    firme + 2,
    null,
    _stile(
      sinistra: BorderStyle.Medium,
      destra: BorderStyle.Medium,
      sotto: BorderStyle.Medium,
    ),
  );
  _scrivi(
    foglio,
    2,
    firme,
    TextCellValue('ARBITRO'),
    _stile(
      grassetto: true,
      orizzontale: HorizontalAlign.Left,
      sinistra: BorderStyle.Medium,
      destra: BorderStyle.Medium,
      sopra: BorderStyle.Medium,
    ),
  );
  _scrivi(
    foglio,
    2,
    firme + 1,
    null,
    _stile(sinistra: BorderStyle.Medium, destra: BorderStyle.Medium),
  );
  _scrivi(
    foglio,
    2,
    firme + 2,
    null,
    _stile(
      sinistra: BorderStyle.Medium,
      destra: BorderStyle.Medium,
      sotto: BorderStyle.Medium,
    ),
  );
  // Le caselle da firmare: un riquadro unico su tre righe.
  foglio.setMergedCellStyle(_cella(1, firme), scatola);
  foglio.setMergedCellStyle(_cella(3, firme), scatola);
  for (var r = firme; r < firme + 3; r++) {
    foglio.setRowHeight(r, 20);
  }

  final nota = firme + 3;
  _scrivi(
    foglio,
    0,
    nota,
    TextCellValue('Il presente modello è parte integrante del verbale di gara'),
    _stile(orizzontale: HorizontalAlign.Left),
  );
  foglio.setRowHeight(nota, 14.25);
}

// ---------------------------------------------------------------------------
// Stili

/// Uno stile del modulo: Calibri (il carattere predefinito di Excel), con
/// i bordi che servono; senza bordo se il lato non è indicato.
CellStyle _stile({
  int dimensione = 11,
  bool grassetto = false,
  HorizontalAlign orizzontale = HorizontalAlign.Center,
  VerticalAlign verticale = VerticalAlign.Center,
  BorderStyle? sinistra,
  BorderStyle? destra,
  BorderStyle? sopra,
  BorderStyle? sotto,
}) => CellStyle(
  fontFamily: 'Calibri',
  fontSize: dimensione,
  bold: grassetto,
  horizontalAlign: orizzontale,
  verticalAlign: verticale,
  leftBorder: Border(borderStyle: sinistra),
  rightBorder: Border(borderStyle: destra),
  topBorder: Border(borderStyle: sopra),
  bottomBorder: Border(borderStyle: sotto),
);

/// La cella [colonna], [riga] di una tabella di [righe] righe: bordo medio
/// attorno alla tabella, sottile dentro, grassetto.
CellStyle _stileTabella(
  int colonna,
  int riga,
  int righe, {
  HorizontalAlign orizzontale = HorizontalAlign.Center,
}) => _stile(
  grassetto: true,
  orizzontale: orizzontale,
  sinistra: colonna == 0 ? BorderStyle.Medium : BorderStyle.Thin,
  destra: colonna == _colonne - 1 ? BorderStyle.Medium : BorderStyle.Thin,
  sopra: riga == 0 ? BorderStyle.Medium : BorderStyle.Thin,
  sotto: riga == righe - 1 ? BorderStyle.Medium : BorderStyle.Thin,
);

// ---------------------------------------------------------------------------
// Celle e testi

CellIndex _cella(int colonna, int riga) =>
    CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: riga);

void _scrivi(
  Sheet foglio,
  int colonna,
  int riga,
  CellValue? valore,
  CellStyle stile,
) => foglio.updateCell(_cella(colonna, riga), valore, cellStyle: stile);

/// I caratteri di controllo (tranne a capo e tabulazione) non sono ammessi
/// in un file Excel.
final _controllo = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

/// Il testo; una cella vuota se non c'è nulla da scrivere.
CellValue? _testo(String? valore) {
  if (valore == null) return null;
  final pulito = valore.replaceAll(_controllo, '').trim();
  return pulito.isEmpty ? null : TextCellValue(pulito);
}

/// "Luogo: Piscina Sud"; solo "Luogo:" se non c'è altro.
String _conEtichetta(String etichetta, String? valore) {
  final testo = (valore ?? '').replaceAll(_controllo, '').trim();
  return testo.isEmpty ? etichetta : '$etichetta $testo';
}

/// La tessera FIN: un numero, come nel modulo, se è fatta solo di cifre
/// (e non comincia per 0, che in un numero andrebbe perso); altrimenti
/// com'è scritta.
CellValue? _tessera(String? tessera) {
  final testo = (tessera ?? '').trim();
  if (testo.isEmpty) return null;
  if (RegExp(r'^[1-9]\d{0,14}$').hasMatch(testo)) {
    return IntCellValue(int.parse(testo));
  }
  return _testo(testo);
}

/// "CAP" per il capitano, "VICE" per il vice, altrimenti niente.
String? _ruoloInSquadra(DistintaGiocatore g) => g.capitano
    ? 'CAP'
    : g.viceCapitano
    ? 'VICE'
    : null;

/// Il colore della calottina in maiuscolo; niente se non è indicato.
String _colore(String? colore) => switch (colore?.trim().toLowerCase()) {
  null || '' => '',
  'blu' => 'BLU',
  'bianca' => 'BIANCA',
  final altro => altro.toUpperCase(),
};

String _due(int n) => n.toString().padLeft(2, '0');

String _data(DateTime d) => '${_due(d.day)}/${_due(d.month)}/${d.year}';

/// "18:30" da "18:30", "8:30" o "18:30:00"; null se non c'è un'ora.
String? _ora(String? ora) {
  final trovata = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(ora ?? '');
  if (trovata == null) return null;
  return '${trovata.group(1)!.padLeft(2, '0')}:${trovata.group(2)}';
}

/// "Formazione U16 Allievi": al massimo 31 caratteri e senza `[]:*?/\`,
/// che Excel non accetta in un nome di foglio.
String _nomeFoglio(String? squadra) {
  final pulita = (squadra ?? '')
      .replaceAll(_controllo, '')
      .replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  var nome = pulita.isEmpty ? 'Formazione' : 'Formazione $pulita';
  if (nome.length > 31) nome = nome.substring(0, 31);
  // Un apice in fondo non è ammesso, e uno spazio non si vedrebbe.
  return nome.replaceAll(RegExp(r"['\s]+$"), '');
}
