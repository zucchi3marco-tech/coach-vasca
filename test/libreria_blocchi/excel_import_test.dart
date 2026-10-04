import 'dart:io';

import 'package:coach_vasca/features/libreria_blocchi/application/excel_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseLibreriaExcel sul file reale', () {
    late RisultatoParsingLibreria risultato;

    setUpAll(() {
      final bytes = File('libreria_blocchi_nuoto_pallanuoto.xlsx')
          .readAsBytesSync();
      risultato = parseLibreriaExcel(bytes);
    });

    test('nessun errore, 350 blocchi e 389 parti in totale', () {
      expect(risultato.errori, isEmpty);
      expect(risultato.blocchi, hasLength(350));
      final totaleParti = risultato.blocchi.fold<int>(
        0,
        (t, b) => t + b.parti.length,
      );
      expect(totaleParti, 389);
    });

    test('N-001: sport Entrambi, 3 parti tutte A1 a distanza', () {
      final b = risultato.blocchi.firstWhere((b) => b.codice == 'N-001');
      expect(b.sport, 'entrambi');
      expect(b.parti, hasLength(3));
      expect(b.parti.every((p) => p.zona == 'A1' && !p.aTempo), isTrue);
    });

    test('metri totali e durata stimata ricalcolati dalle parti (celle-formula nel file)', () {
      final n001 = risultato.blocchi.firstWhere((b) => b.codice == 'N-001');
      expect(n001.metriTotali, 400);
      expect(n001.durataStimataMin, 7);

      final n002 = risultato.blocchi.firstWhere((b) => b.codice == 'N-002');
      expect(n002.metriTotali, 300);
      expect(n002.durataStimataMin, 6);
    });

    test(
      'P-003 parte 1: a tempo (600s), esecuzione dedotta "gambe" dal testo',
      () {
        final b = risultato.blocchi.firstWhere((b) => b.codice == 'P-003');
        final p = b.parti.first;
        expect(p.durataS, 600);
        expect(p.distanzaM, isNull);
        expect(p.zona, 'A1');
        expect(p.esecuzione, 'gambe');
      },
    );

    test('P-007: le parti in zona T diventano esecuzione "tecnica"', () {
      final b = risultato.blocchi.firstWhere((b) => b.codice == 'P-007');
      final parteT = b.parti.where((p) => p.zona == 'T');
      expect(parteT, isNotEmpty);
      expect(parteT.every((p) => p.esecuzione == 'tecnica'), isTrue);
    });

    test(
      'S-002 (fase "A secco"): esecuzione dedotta dalla fase del blocco',
      () {
        final b = risultato.blocchi.firstWhere((b) => b.codice == 'S-002');
        expect(b.fase, 'A secco');
        expect(b.parti.single.esecuzione, 'a secco');
      },
    );

    test('P-044 (fase "Tiro", nessuna parola chiave): esecuzione tattica', () {
      final b = risultato.blocchi.firstWhere((b) => b.codice == 'P-044');
      expect(b.fase, 'Tiro');
      final p = b.parti.single;
      expect(p.zona, 'C1');
      expect(p.distanzaM, 15);
      expect(p.ripetizioni, 10);
      expect(p.esecuzione, 'pallanuoto tecnico-tattico');
    });

    test('ogni parte usa distanza o durata, mai entrambe o nessuna', () {
      for (final b in risultato.blocchi) {
        for (final p in b.parti) {
          expect(
            (p.distanzaM == null) != (p.durataS == null),
            isTrue,
            reason: '${b.codice} parte ${p.ordine}',
          );
        }
      }
    });
  });

  group('deduciEsecuzione', () {
    test('zona T vince su tutto', () {
      expect(
        deduciEsecuzione(
          zona: 'T',
          esercizio: 'gambe veloci',
          faseBlocco: 'Tiro',
        ),
        'tecnica',
      );
    });

    test('zona TT vince su tutto', () {
      expect(
        deduciEsecuzione(
          zona: 'TT',
          esercizio: null,
          faseBlocco: 'Riscaldamento',
        ),
        'pallanuoto tecnico-tattico',
      );
    });

    test('braccia senza pull nel testo', () {
      expect(
        deduciEsecuzione(
          zona: 'A2',
          esercizio: '8x50 braccia respirazione',
          faseBlocco: 'Serie principale',
        ),
        'braccia',
      );
    });

    test('braccia con pull nel testo diventa pull', () {
      expect(
        deduciEsecuzione(
          zona: 'A2',
          esercizio: 'braccia con pull buoy',
          faseBlocco: 'Serie principale',
        ),
        'pull',
      );
    });

    test('fase "Nuoto specifico" e "Condizionamento" cadono su nuoto', () {
      expect(
        deduciEsecuzione(
          zona: 'A1',
          esercizio: null,
          faseBlocco: 'Nuoto specifico',
        ),
        'nuoto',
      );
      expect(
        deduciEsecuzione(
          zona: 'A1',
          esercizio: null,
          faseBlocco: 'Condizionamento',
        ),
        'nuoto',
      );
    });
  });
}
