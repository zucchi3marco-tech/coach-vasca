import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/staff_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/excel/distinta_excel.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

// Il modulo della distinta FIN in Excel: intestazione, giocatori, staff e
// firme, come nel foglio che il coach usa oggi. Nomi e numeri inventati.

Partita _partita({
  String? ora = '18:30',
  String? luogo = 'Piscina Comunale',
  String? campionato = 'Under 16 regionale',
  String? colore = 'blu',
  int massimo = 15,
  String casa = 'Canottieri',
  String trasferta = 'Rari Nantes',
}) => Partita(
  id: 'p1',
  clubId: 'c1',
  gruppoId: 'g1',
  data: DateTime(2026, 10, 25),
  ora: ora,
  luogo: luogo,
  campionato: campionato,
  coloreCalottina: colore,
  squadraCasa: casa,
  squadraTrasferta: trasferta,
  numeroMaxConvocati: massimo,
);

ConvocatoModulo _convocato(
  String cognome,
  String nome,
  int numero, {
  String? tessera,
  bool capitano = false,
  bool vice = false,
}) => (
  giocatore: DistintaGiocatore(
    id: 'd$numero',
    partitaId: 'p1',
    atletaId: 'a$numero',
    clubId: 'c1',
    numeroCalottina: numero,
    capitano: capitano,
    viceCapitano: vice,
    portiere: numero == 1 || numero == 13,
    fuoriquota: false,
  ),
  atleta: Atleta(
    id: 'a$numero',
    clubId: 'c1',
    nome: nome,
    cognome: cognome,
    dataNascita: DateTime(2010, 5, 1),
    sport: 'pallanuoto',
    consensoPrivacyFirmato: true,
    attivo: true,
    numeroTesseraFin: tessera,
  ),
);

/// Quattro convocati, dati fuori ordine.
List<ConvocatoModulo> _squadra() => [
  _convocato('Verdi', 'Luca', 7, tessera: '700002'),
  _convocato('Rossi', 'Mario', 4, tessera: '700001', capitano: true),
  _convocato('Bianchi', 'Anna', 9, tessera: '0123', vice: true),
  _convocato('Neri', 'Paolo', 1),
];

StaffDistinta _staff() => const StaffDistinta({
  RuoloStaff.tecnico: PersonaStaff(nome: 'Gialli Carlo', tessera: '800001'),
  RuoloStaff.accompagnatore: PersonaStaff(nome: 'Blu Elisa'),
  RuoloStaff.medico: PersonaStaff(tessera: '800009'),
});

Sheet _foglio({
  Partita? partita,
  String nomeClub = 'Club Nuoto Test',
  String? nomeSquadra = 'U16 Allievi',
  List<ConvocatoModulo>? convocati,
  StaffDistinta? staff,
}) {
  final bytes = generaDistintaExcel(
    partita: partita ?? _partita(),
    nomeClub: nomeClub,
    nomeSquadra: nomeSquadra,
    convocati: convocati ?? _squadra(),
    staff: staff ?? _staff(),
  );
  final excel = Excel.decodeBytes(bytes);
  return excel.tables.values.single;
}

/// La cella con l'indirizzo di Excel ("B3").
CellValue? _v(Sheet foglio, String indirizzo) =>
    foglio.cell(CellIndex.indexByString(indirizzo)).value;

/// Il testo di una cella; stringa vuota se è vuota.
String _t(Sheet foglio, String indirizzo) => switch (_v(foglio, indirizzo)) {
  TextCellValue(:final value) => value.text ?? '',
  null => '',
  final altro => '$altro',
};

/// La riga (da 1) in cui compare questo testo nella colonna A.
int _rigaDi(Sheet foglio, String testo) {
  for (var r = 1; r <= foglio.maxRows; r++) {
    if (_t(foglio, 'A$r') == testo) return r;
  }
  fail('«$testo» non c\'è nella colonna A');
}

void main() {
  group('intestazione', () {
    test('federazione, club in maiuscolo e partita', () {
      final f = _foglio();
      expect(_t(f, 'B1'), 'FEDERAZIONE ITALIANA NUOTO');
      expect(_t(f, 'B2'), 'CLUB NUOTO TEST');
      expect(_t(f, 'B3'), 'Canottieri - Rari Nantes');
    });

    test('campionato, colore, luogo, data e ora', () {
      final f = _foglio();
      expect(_t(f, 'B4'), 'Campionato: Under 16 regionale');
      expect(_t(f, 'C4'), 'Colore Calottina:');
      expect(_t(f, 'D4'), 'BLU');
      expect(_t(f, 'B5'), 'Luogo: Piscina Comunale');
      expect(_t(f, 'C5'), 'DATA: 25/10/2026');
      expect(_t(f, 'D5'), 'ORE: 18:30');
    });

    test('la calottina bianca e quella non indicata', () {
      expect(_t(_foglio(partita: _partita(colore: 'bianca')), 'D4'), 'BIANCA');
      expect(_t(_foglio(partita: _partita(colore: null)), 'D4'), '');
    });

    test('senza campionato, luogo e ora resta solo l\'etichetta', () {
      final f = _foglio(
        partita: _partita(campionato: null, luogo: '  ', ora: null),
      );
      expect(_t(f, 'B4'), 'Campionato:');
      expect(_t(f, 'B5'), 'Luogo:');
      expect(_t(f, 'D5'), 'ORE:');
      expect(_t(f, 'C5'), 'DATA: 25/10/2026');
    });

    test('l\'ora con i secondi o senza zero davanti si legge bene', () {
      expect(
        _t(_foglio(partita: _partita(ora: '18:30:00')), 'D5'),
        'ORE: 18:30',
      );
      expect(_t(_foglio(partita: _partita(ora: '9:05')), 'D5'), 'ORE: 09:05');
    });

    test('le righe da B1 a B3 sono unite su B:C', () {
      final f = _foglio();
      expect(f.spannedItems, containsAll(['B1:C1', 'B2:C2', 'B3:C3']));
    });
  });

  group('giocatori', () {
    test('le intestazioni della tabella', () {
      final f = _foglio();
      expect(_t(f, 'A6'), 'n° calottina');
      expect(_t(f, 'B6'), 'GIOCATORE');
      expect(_t(f, 'C6'), 'n° tessera FIN');
      expect(_t(f, 'D6'), 'formazione');
    });

    test('in ordine di calottina, con cognome e nome e la tessera', () {
      final f = _foglio();
      expect(
        [for (var r = 7; r <= 10; r++) _v(f, 'A$r')],
        [
          const IntCellValue(1),
          const IntCellValue(4),
          const IntCellValue(7),
          const IntCellValue(9),
        ],
      );
      expect(_t(f, 'B7'), 'Neri Paolo');
      expect(_t(f, 'B8'), 'Rossi Mario');
      expect(_t(f, 'B9'), 'Verdi Luca');
      expect(_t(f, 'B10'), 'Bianchi Anna');
      // La tessera è un numero; senza tessera la cella resta vuota.
      expect(_v(f, 'C8'), const IntCellValue(700001));
      expect(_v(f, 'C9'), const IntCellValue(700002));
      expect(_v(f, 'C7'), isNull);
    });

    test('una tessera che comincia per zero resta un testo', () {
      expect(_v(_foglio(), 'C10'), TextCellValue('0123'));
    });

    test('CAP al capitano, VICE al vice, agli altri niente', () {
      final f = _foglio();
      expect(_t(f, 'D8'), 'CAP');
      expect(_t(f, 'D10'), 'VICE');
      expect(_t(f, 'D7'), '');
      expect(_t(f, 'D9'), '');
    });

    test('le righe arrivano al massimo dei convocati, le altre sono vuote', () {
      final f = _foglio(partita: _partita(massimo: 15));
      // Dalla riga 7 alla 21: quindici giocatori.
      expect(_t(f, 'B21'), '');
      for (var r = 11; r <= 21; r++) {
        for (final c in ['A', 'B', 'C', 'D']) {
          expect(_v(f, '$c$r'), isNull, reason: '$c$r');
        }
      }
      // E la riga dopo la tabella è vuota: lo staff comincia due righe sotto.
      expect(_t(f, 'A22'), '');
      expect(_t(f, 'A23'), 'Tecnico');
    });

    test('con più convocati del massimo non se ne perde nessuno', () {
      final f = _foglio(partita: _partita(massimo: 2), convocati: _squadra());
      expect(_t(f, 'B10'), 'Bianchi Anna');
      expect(_t(f, 'A11'), '');
      expect(_t(f, 'A12'), 'Tecnico');
    });

    test('le righe vuote hanno comunque il bordo, da riempire a mano', () {
      final f = _foglio();
      final vuota = f.cell(CellIndex.indexByString('B15')).cellStyle;
      expect(vuota, isNotNull);
      expect(vuota!.leftBorder.borderStyle, BorderStyle.Thin);
      expect(vuota.rightBorder.borderStyle, BorderStyle.Thin);
      final ultima = f.cell(CellIndex.indexByString('B21')).cellStyle!;
      expect(ultima.bottomBorder.borderStyle, BorderStyle.Medium);
      final bordo = f.cell(CellIndex.indexByString('D15')).cellStyle!;
      expect(bordo.rightBorder.borderStyle, BorderStyle.Medium);
    });
  });

  group('staff e firme', () {
    test('le cinque righe dello staff con nomi e tessere', () {
      final f = _foglio();
      final riga = _rigaDi(f, 'Tecnico');
      expect(_rigaDi(f, 'Vice tecnico'), riga + 1);
      expect(_rigaDi(f, 'Accompagnatore'), riga + 2);
      expect(_rigaDi(f, 'Dirigente di servizio'), riga + 3);
      expect(_rigaDi(f, 'Medico di servizio'), riga + 4);

      expect(_t(f, 'B$riga'), 'Gialli Carlo');
      expect(_t(f, 'C$riga'), 'n° tessera FIN');
      expect(_v(f, 'D$riga'), const IntCellValue(800001));
      // Vice tecnico non compilato: etichette sì, nome e tessera no.
      expect(_t(f, 'C${riga + 1}'), 'n° tessera FIN');
      expect(_t(f, 'B${riga + 1}'), '');
      expect(_v(f, 'D${riga + 1}'), isNull);
      // Nome senza tessera e tessera senza nome.
      expect(_t(f, 'B${riga + 2}'), 'Blu Elisa');
      expect(_v(f, 'D${riga + 2}'), isNull);
      expect(_t(f, 'B${riga + 4}'), '');
      expect(_v(f, 'D${riga + 4}'), const IntCellValue(800009));
    });

    test('con lo staff vuoto le righe ci sono lo stesso', () {
      final f = _foglio(staff: StaffDistinta.vuoto);
      final riga = _rigaDi(f, 'Tecnico');
      expect(_t(f, 'A${riga + 4}'), 'Medico di servizio');
      expect(_t(f, 'C${riga + 4}'), 'n° tessera FIN');
    });

    test('Capitano della squadra, ARBITRO e la riga finale', () {
      final f = _foglio();
      final firme = _rigaDi(f, 'Capitano della squadra');
      expect(_t(f, 'C$firme'), 'ARBITRO');
      expect(
        _t(f, 'A${firme + 3}'),
        'Il presente modello è parte integrante del verbale di gara',
      );
      // Le due caselle da firmare sono unite su tre righe.
      expect(
        f.spannedItems,
        containsAll(['B$firme:B${firme + 2}', 'D$firme:D${firme + 2}']),
      );
      // Fra lo staff e le firme c'è una riga vuota.
      final medico = _rigaDi(f, 'Medico di servizio');
      expect(firme, medico + 2);
      expect(_t(f, 'A${medico + 1}'), '');
    });
  });

  group('file', () {
    test('un solo foglio, "Formazione" con il nome della squadra', () {
      final bytes = generaDistintaExcel(
        partita: _partita(),
        nomeClub: 'Club',
        nomeSquadra: 'U16 Allievi',
        convocati: _squadra(),
        staff: _staff(),
      );
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.keys.toList(), ['Formazione U16 Allievi']);
    });

    test('senza squadra il foglio si chiama solo "Formazione"', () {
      final bytes = generaDistintaExcel(
        partita: _partita(),
        nomeClub: 'Club',
        convocati: const [],
        staff: StaffDistinta.vuoto,
      );
      expect(Excel.decodeBytes(bytes).tables.keys.toList(), ['Formazione']);
    });

    test('il nome del foglio è corto e senza caratteri vietati', () {
      final bytes = generaDistintaExcel(
        partita: _partita(),
        nomeClub: 'Club',
        nomeSquadra: 'Under/16: [Allievi] regionali? *molto* lunga \\ davvero',
        convocati: const [],
        staff: StaffDistinta.vuoto,
      );
      final nome = Excel.decodeBytes(bytes).tables.keys.single;
      expect(nome.length, lessThanOrEqualTo(31));
      expect(nome, isNot(matches(r'[\[\]:*?/\\]')));
      expect(nome, startsWith('Formazione Under'));
    });

    test(
      'senza convocati il modulo resta intero, con le righe da riempire',
      () {
        final f = _foglio(convocati: const []);
        expect(_t(f, 'A6'), 'n° calottina');
        expect(_t(f, 'A23'), 'Tecnico');
        expect(
          _t(f, 'A${_rigaDi(f, 'Capitano della squadra')}'),
          'Capitano della squadra',
        );
      },
    );
  });

  group('nomeFileDistinta', () {
    test('le squadre e il giorno', () {
      expect(
        nomeFileDistinta(
          _partita(casa: 'Canottieri', trasferta: 'Rari Nantes'),
        ),
        'Formazione Canottieri-Rari Nantes 2026-10-25.xlsx',
      );
    });

    test('toglie i caratteri che un file non può avere', () {
      final nome = nomeFileDistinta(
        _partita(casa: 'A/B: "C"', trasferta: '<D>?|*  E'),
      );
      expect(nome, 'Formazione AB C-D E 2026-10-25.xlsx');
      expect(nome, isNot(matches(r'[\\/:*?"<>|]')));
    });

    test('senza nomi resta la data', () {
      expect(
        nomeFileDistinta(_partita(casa: '?', trasferta: ' ')),
        'Formazione 2026-10-25.xlsx',
      );
    });
  });
}
