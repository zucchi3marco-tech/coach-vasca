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

    test('un indice gia\' finale non viene mai sovrascritto', () {
      final dopoPrimoEvento = aggiornaSegmenti(
        committatiPrima: const {},
        segmenti: [(indice: 0, finale: true, testo: '8 volte 100 sl')],
      );
      // Il browser ripropone lo stesso indice, testo identico.
      final identico = aggiornaSegmenti(
        committatiPrima: dopoPrimoEvento.committati,
        segmenti: [(indice: 0, finale: true, testo: '8 volte 100 sl')],
      );
      expect(identico.committati, {0: '8 volte 100 sl'});

      // Il browser lo ripropone con una minima differenza: vince sempre
      // la prima versione vista.
      final leggermenteDiverso = aggiornaSegmenti(
        committatiPrima: dopoPrimoEvento.committati,
        segmenti: [(indice: 0, finale: true, testo: '8 volte 100 SL.')],
      );
      expect(leggermenteDiverso.committati, {0: '8 volte 100 sl'});
    });

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
