import 'package:coach_vasca/core/dettatura/aggiorna_segmenti.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aggiornaSegmenti', () {
    test('conferma i segmenti finali e tiene l\'ultimo interim', () {
      final r = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [
          (indice: 0, finale: true, testo: '400 riscaldamento'),
          (indice: 1, finale: false, testo: '8 volte'),
        ],
      );
      expect(r.committati, {0: '400 riscaldamento'});
      expect(r.interim, '8 volte');
    });

    test('riproporre lo stesso indice con testo identico non cambia nulla', () {
      final dopoPrimoEvento = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [(indice: 0, finale: true, testo: '8 volte 100 sl')],
      );
      final identico = aggiornaSegmenti(
        committatiPrima: dopoPrimoEvento.committati,
        segmenti: [(indice: 0, finale: true, testo: '8 volte 100 sl')],
      );
      expect(identico.committati, {0: '8 volte 100 sl'});
    });

    test(
      'una versione più completa (indice nuovo o lo stesso) sostituisce '
      'quella precedente se ne è la crescita — il motore vocale del '
      'coach segna ogni aggiornamento come "finale" fin da subito, mai '
      'come provvisorio: qui arriva la revisione con la maiuscola giusta',
      () {
        final dopoPrimoEvento = aggiornaSegmenti(
          committatiPrima: const {},
          segmenti: [(indice: 0, finale: true, testo: '8 volte 100 sl')],
        );
        final rivisto = aggiornaSegmenti(
          committatiPrima: dopoPrimoEvento.committati,
          segmenti: [(indice: 1, finale: true, testo: '8 volte 100 SL.')],
        );
        expect(rivisto.committati, {0: '8 volte 100 SL.'});
      },
    );

    test('lo stesso testo riconfermato sotto un indice nuovo (non riusato) '
        'viene scartato se e\' consecutivo all\'ultimo confermato — il caso '
        'reale osservato dal coach: "400 di riscaldamento poi" ripetuto '
        'identico più volte, ogni volta con un indice diverso', () {
      var stato = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [
          (indice: 0, finale: true, testo: '400 di riscaldamento poi'),
        ],
      );
      for (final nuovoIndice in [1, 2, 3, 4, 5]) {
        stato = aggiornaSegmenti(
          committatiPrima: stato.committati,
          segmenti: [
            (
              indice: nuovoIndice,
              finale: true,
              testo: '400 di riscaldamento poi',
            ),
          ],
        );
      }
      expect(stato.committati, {0: '400 di riscaldamento poi'});

      // Dopo il duplicato, una frase diversa si aggiunge normalmente.
      final finale = aggiornaSegmenti(
        committatiPrima: stato.committati,
        segmenti: [(indice: 6, finale: true, testo: '8 per cento')],
      );
      expect(
        testoCommittato(finale.committati),
        '400 di riscaldamento poi 8 per cento',
      );
    });

    test(
      'una frase ripetuta piu\' avanti, con qualcos\'altro nel mezzo, resta',
      () {
        final stato = aggiornaSegmenti(
          committatiPrima: const {},
          segmenti: [
            (indice: 0, finale: true, testo: '200 dorso'),
            (indice: 1, finale: true, testo: '200 rana'),
            (indice: 2, finale: true, testo: '200 dorso'),
          ],
        );
        expect(stato.committati, {
          0: '200 dorso',
          1: '200 rana',
          2: '200 dorso',
        });
      },
    );

    test('segmenti non consecutivi restano tutti, ognuno una volta', () {
      final primoEvento = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [
          (indice: 0, finale: true, testo: '200 dorso'),
          (indice: 1, finale: true, testo: '200 rana'),
        ],
      );
      // Un evento successivo ripropone l'indice 0 (non consecutivo
      // all'indice 1 già confermato) insieme a un nuovo indice 2.
      final secondoEvento = aggiornaSegmenti(
        committatiPrima: primoEvento.committati,
        segmenti: [
          (indice: 0, finale: true, testo: '200 dorso'),
          (indice: 2, finale: true, testo: '200 delfino'),
        ],
      );
      expect(secondoEvento.committati, {
        0: '200 dorso',
        1: '200 rana',
        2: '200 delfino',
      });
      expect(
        testoCommittato(secondoEvento.committati),
        '200 dorso 200 rana 200 delfino',
      );
    });

    test('i segmenti vuoti (anche solo spazi) sono ignorati', () {
      final r = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [
          (indice: 0, finale: true, testo: '  '),
          (indice: 1, finale: false, testo: ''),
        ],
      );
      expect(r.committati, isEmpty);
      expect(r.interim, isEmpty);
    });

    test(
      'un interim precedente non resta se il nuovo evento non lo ripete',
      () {
        final r = aggiornaSegmenti(
          committatiPrima: const {},
          segmenti: [(indice: 0, finale: true, testo: '400 misti')],
        );
        expect(r.interim, isEmpty);
      },
    );

    test(
      'sequenza reale mandata dal coach: crescita parola per parola, '
      'tutta "finale", indice sempre nuovo — deve restare una frase sola',
      () {
        // Riprodotto esattamente dal log tecnico dell'app (evento dopo
        // evento, ognuno con TUTTI i segmenti visti finora perché
        // `event.results` dell'API del browser è cumulativo).
        const eventi = [
          [''],
          ['', ''],
          ['', '', ''],
          ['', '', '', ''],
          ['', '', '', '', 'Quattrocento'],
          ['', '', '', '', 'Quattrocento', 'Quattrocento'],
          [
            '',
            '',
            '',
            '',
            'Quattrocento',
            'Quattrocento',
            'Quattrocento metri',
          ],
          [
            '',
            '',
            '',
            '',
            'Quattrocento',
            'Quattrocento',
            'Quattrocento metri',
            'Quattrocento metri di',
          ],
          [
            '',
            '',
            '',
            '',
            'Quattrocento',
            'Quattrocento',
            'Quattrocento metri',
            'Quattrocento metri di',
            'Quattrocento metri di riscaldamento',
          ],
        ];
        var stato = (committati: <int, String>{}, interim: '');
        for (final testi in eventi) {
          stato = aggiornaSegmenti(
            committatiPrima: stato.committati,
            segmenti: [
              for (var i = 0; i < testi.length; i++)
                (indice: i, finale: true, testo: testi[i]),
            ],
          );
        }
        expect(
          testoCommittato(stato.committati),
          'Quattrocento metri di riscaldamento',
        );
        expect(stato.committati.length, 1);
      },
    );
  });

  group('testoCommittato', () {
    test('mappa vuota da\' stringa vuota', () {
      expect(testoCommittato(const {}), '');
    });

    test('unisce nell\'ordine degli indici, non di inserimento', () {
      expect(testoCommittato({2: 'c', 0: 'a', 1: 'b'}), 'a b c');
    });
  });
}
