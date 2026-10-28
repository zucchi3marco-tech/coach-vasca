import 'dart:convert';
import 'dart:typed_data';

import 'package:coach_vasca/features/atleti/application/excel_atleti.dart';
import 'package:coach_vasca/features/atleti/domain/foglio_atleti.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

const _squadre = [
  Gruppo(id: 'g1', clubId: 'c1', nome: 'Esordienti A', ordine: 0),
  Gruppo(id: 'g2', clubId: 'c1', nome: 'Under 14', ordine: 1),
];

Uint8List _csv(String testo, {bool bom = false}) => Uint8List.fromList([
  if (bom) ...[0xEF, 0xBB, 0xBF],
  ...utf8.encode(testo),
]);

/// Il modello con in piu le righe date nel foglio "Atleti".
Uint8List _modelloCon(List<List<CellValue?>> righe) {
  final modello = modelloAtleti(nomiSquadre: ['Esordienti A', 'Under 14']);
  final excel = Excel.decodeBytes(modello);
  for (final r in righe) {
    excel.appendRow('Atleti', r);
  }
  return Uint8List.fromList(excel.encode()!);
}

Object _erroreDi(void Function() f) {
  try {
    f();
  } catch (e) {
    return e;
  }
  fail('Doveva dare un errore');
}

void main() {
  group('modello', () {
    test('ha i due fogli e niente Sheet1', () {
      final excel = Excel.decodeBytes(
        modelloAtleti(nomiSquadre: ['Esordienti A']),
      );
      expect(excel.tables.keys, ['Atleti', 'Come si compila']);
    });

    test('titoli in grassetto, senza righe di esempio', () {
      final excel = Excel.decodeBytes(modelloAtleti(nomiSquadre: []));
      final atleti = excel.tables['Atleti']!;
      expect(atleti.maxRows, 1);
      final titoli = [for (final c in atleti.rows.first) c!.value.toString()];
      expect(titoli, [
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
      ]);
      expect(
        atleti.rows.first.every((c) => c!.cellStyle?.isBold ?? false),
        isTrue,
      );
    });

    test('la guida elenca le squadre del club e i ruoli', () {
      final excel = Excel.decodeBytes(
        modelloAtleti(nomiSquadre: ['Esordienti A', 'Under 14']),
      );
      final guida = [
        for (final r in excel.tables['Come si compila']!.rows)
          for (final c in r) c?.value.toString(),
      ];
      expect(guida, containsAll(['Esordienti A', 'Under 14']));
      expect(guida, containsAll(['Portiere', 'Centroboa', 'Marcatore']));
      expect(
        guida.whereType<String>().any((t) => t.contains('12/03/2012')),
        isTrue,
      );
    });
  });

  group('xlsx', () {
    test('il modello compilato si rilegge e si analizza', () {
      final bytes = _modelloCon([
        [
          TextCellValue('Rossi'),
          TextCellValue('Mario'),
          const DateCellValue(year: 2012, month: 3, day: 12),
          TextCellValue('Esordienti A'),
          TextCellValue('portiere'),
          TextCellValue('M'),
          const IntCellValue(123456),
          TextCellValue('papa@mail.it'),
          const IntCellValue(3331234567),
          const DateCellValue(year: 2027, month: 9, day: 30),
          TextCellValue('sì'),
          TextCellValue('mancino'),
        ],
        [
          TextCellValue('VERDI'),
          TextCellValue('anna'),
          TextCellValue('01/05/2011'),
        ],
        [],
        [
          TextCellValue('Bianchi'),
          TextCellValue('Luca'),
          const DoubleCellValue(40980),
        ],
      ]);

      final tabella = leggiTabellaAtleti(bytes, nomeFile: 'atleti.xlsx');
      expect(tabella.first.take(3), ['Cognome', 'Nome', 'Data di nascita']);

      final f = analizzaFoglioAtleti(
        tabella,
        squadre: _squadre,
        esistenti: const [],
        oggi: DateTime(2026, 10, 18),
      );
      expect(f.ok, isTrue, reason: f.errore);
      expect(f.escluse, isEmpty);
      expect(f.nuovi, hasLength(3));
      final rossi = f.nuovi[0];
      expect(rossi.cognome, 'Rossi');
      expect(rossi.dataNascita, DateTime(2012, 3, 12));
      expect(rossi.squadraId, 'g1');
      expect(rossi.ruolo, 'portiere');
      expect(rossi.sesso, 'M');
      expect(rossi.tessera, '123456');
      expect(rossi.telefono, '3331234567');
      expect(rossi.visitaMedica, DateTime(2027, 9, 30));
      expect(rossi.consenso, isTrue);
      expect(rossi.note, 'mancino');
      expect(f.nuovi[1].cognome, 'Verdi');
      expect(f.nuovi[1].nome, 'Anna');
      expect(f.nuovi[1].dataNascita, DateTime(2011, 5, 1));
      expect(f.nuovi[2].dataNascita, DateTime(2012, 3, 12));
      // Il foglio di istruzioni non viene letto per sbaglio.
      expect(f.colonneNonUsate, isEmpty);
    });

    test('legge il primo foglio che ha dei dati', () {
      final excel = Excel.createExcel();
      excel.rename(excel.getDefaultSheet()!, 'Vuoto');
      excel.appendRow('Dati', [
        TextCellValue('Cognome'),
        TextCellValue('Nome'),
        TextCellValue('Data di nascita'),
      ]);
      excel.appendRow('Dati', [
        TextCellValue('Rossi'),
        TextCellValue('Mario'),
        TextCellValue('12/03/2012'),
      ]);
      final tabella = leggiTabellaAtleti(
        Uint8List.fromList(excel.encode()!),
        nomeFile: 'Atleti.XLSX',
      );
      expect(tabella, hasLength(2));
      expect(tabella[1][0], 'Rossi');
    });

    test('un valore booleano e i numeri restano numeri e booleani', () {
      final bytes = _modelloCon([
        [
          TextCellValue('Rossi'),
          TextCellValue('Mario'),
          TextCellValue('12/03/2012'),
          null,
          null,
          null,
          const IntCellValue(7),
          null,
          null,
          null,
          const BoolCellValue(true),
        ],
      ]);
      final riga = leggiTabellaAtleti(bytes, nomeFile: 'a.xlsx')[1];
      expect(riga[6], isA<num>());
      expect(riga[10], true);
    });

    test('un file rovinato da un messaggio chiaro', () {
      final e = _erroreDi(
        () => leggiTabellaAtleti(
          Uint8List.fromList(utf8.encode('non sono un foglio')),
          nomeFile: 'atleti.xlsx',
        ),
      );
      expect(e, isA<FoglioNonLeggibile>());
      expect(e.toString(), contains('rovinato'));
    });
  });

  group('csv', () {
    test('con il punto e virgola e il BOM', () {
      final tabella = leggiTabellaAtleti(
        _csv(
          'Cognome;Nome;Data di nascita;Note\r\n'
          'Rossi;Mario;12/03/2012;"ha detto ""ciao""; poi è uscito"\r\n'
          '\r\n'
          'Verdi;Anna;01/05/2011;\r\n',
          bom: true,
        ),
        nomeFile: 'atleti.csv',
      );
      expect(tabella[0], ['Cognome', 'Nome', 'Data di nascita', 'Note']);
      expect(tabella[1][0], 'Rossi');
      expect(tabella[1][3], 'ha detto "ciao"; poi è uscito');
      expect(tabella[3], ['Verdi', 'Anna', '01/05/2011', null]);
    });

    test('con la virgola', () {
      final tabella = leggiTabellaAtleti(
        _csv('Cognome,Nome,Data di nascita\nRossi,Mario,12/03/2012'),
        nomeFile: 'atleti.CSV',
      );
      expect(tabella, [
        ['Cognome', 'Nome', 'Data di nascita'],
        ['Rossi', 'Mario', '12/03/2012'],
      ]);
    });

    test('la virgola dentro le virgolette non separa', () {
      final tabella = leggiTabellaAtleti(
        _csv('Cognome;Nome;Data di nascita\n"Rossi, Verdi";Mario;12/03/2012'),
        nomeFile: 'a.csv',
      );
      expect(tabella[1][0], 'Rossi, Verdi');
    });

    test('Windows-1252: le lettere accentate restano', () {
      final tabella = leggiTabellaAtleti(
        Uint8List.fromList(
          latin1.encode('Cognome;Nome;Data di nascita\nNicolò;José;12/03/2012'),
        ),
        nomeFile: 'a.csv',
      );
      expect(tabella[1][0], 'Nicolò');
      expect(tabella[1][1], 'José');
    });

    test('si analizza come un xlsx', () {
      final tabella = leggiTabellaAtleti(
        _csv(
          'Cognome;Nome;Data di nascita;Squadra\n'
          'Rossi;Mario;12/03/2012;Under 14\n',
          bom: true,
        ),
        nomeFile: 'a.csv',
      );
      final f = analizzaFoglioAtleti(
        tabella,
        squadre: _squadre,
        esistenti: const [],
        oggi: DateTime(2026, 10, 18),
      );
      expect(f.nuovi.single.squadraId, 'g2');
    });
  });

  group('formati che non si leggono', () {
    test('.xls: il formato vecchio', () {
      final e = _erroreDi(
        () => leggiTabellaAtleti(Uint8List(10), nomeFile: 'atleti.xls'),
      );
      expect(e, isA<FoglioNonLeggibile>());
      expect(
        e.toString(),
        'Questo file è nel formato vecchio di Excel: aprilo e salvalo come '
        '.xlsx, poi riprova.',
      );
    });

    test('un vecchio .xls rinominato .xlsx si riconosce dalla firma', () {
      final bytes = Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0, 0, 0, 0, 0]);
      final e = _erroreDi(
        () => leggiTabellaAtleti(bytes, nomeFile: 'atleti.xlsx'),
      );
      expect(e.toString(), contains('formato vecchio'));
    });

    test('altre estensioni', () {
      final e = _erroreDi(
        () => leggiTabellaAtleti(Uint8List(10), nomeFile: 'atleti.pdf'),
      );
      expect(e, isA<FoglioNonLeggibile>());
      expect(e.toString(), contains('.xlsx o .csv'));
    });
  });
}
