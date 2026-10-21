import 'package:coach_vasca/features/pallanuoto/domain/numeri_distinta.dart';
import 'package:coach_vasca/features/pallanuoto/domain/staff_distinta.dart';
import 'package:flutter_test/flutter_test.dart';

ConvocatoScelto _m(String id) => (atletaId: id, portiere: false);
ConvocatoScelto _p(String id) => (atletaId: id, portiere: true);

NellUltimaPartita _u(int numero, {bool c = false, bool v = false}) =>
    (numero: numero, capitano: c, viceCapitano: v);

void main() {
  group('numeriProposti', () {
    test('i portieri prendono 1 e 13 anche se toccati per ultimi, gli altri '
        'dal 2 in su nell\'ordine scelto', () {
      final numeri = numeriProposti(
        occupati: {},
        nuovi: [_m('a'), _m('b'), _p('por1'), _m('c'), _p('por2')],
        massimo: 15,
      );
      expect(numeri, {'por1': 1, 'por2': 13, 'a': 2, 'b': 3, 'c': 4});
    });

    test('ognuno riprende il numero dell\'ultima partita, se è libero', () {
      final numeri = numeriProposti(
        occupati: {7},
        nuovi: [_m('a'), _m('b'), _m('c')],
        ultimaPartita: {'a': _u(9), 'b': _u(7), 'c': _u(4)},
        massimo: 15,
      );
      // b aveva il 7, che ora è di chi è già in distinta: primo libero.
      expect(numeri, {'a': 9, 'c': 4, 'b': 2});
    });

    test('un portiere riprende il suo 13 dell\'ultima partita', () {
      final numeri = numeriProposti(
        occupati: {},
        nuovi: [_p('riserva'), _p('titolare')],
        ultimaPartita: {'riserva': _u(13), 'titolare': _u(1)},
        massimo: 13,
      );
      expect(numeri, {'riserva': 13, 'titolare': 1});
    });

    test('il 13 dell\'ultima partita resta a un giocatore di movimento solo '
        'se non c\'è il secondo portiere', () {
      final unPortiere = numeriProposti(
        occupati: {},
        nuovi: [_m('a'), _p('por')],
        ultimaPartita: {'a': _u(13)},
        massimo: 15,
      );
      expect(unPortiere, {'por': 1, 'a': 13});

      final duePortieri = numeriProposti(
        occupati: {},
        nuovi: [_m('a'), _p('por1'), _p('por2')],
        ultimaPartita: {'a': _u(13)},
        massimo: 15,
      );
      expect(duePortieri, {'por1': 1, 'por2': 13, 'a': 2});
    });

    test('con 13 convocati e un solo portiere il 13 va al dodicesimo di '
        'movimento', () {
      final movimento = [for (var i = 0; i < 12; i++) _m('m$i')];
      final numeri = numeriProposti(
        occupati: {},
        nuovi: [_p('por'), ...movimento],
        massimo: 13,
      );
      expect(numeri.values.toSet(), {for (var n = 1; n <= 13; n++) n});
      expect(numeri['m11'], 13);
    });

    test('con 15 e due portieri i numeri vanno dall\'1 al 15, come nel '
        'modulo', () {
      final movimento = [for (var i = 0; i < 13; i++) _m('m$i')];
      final numeri = numeriProposti(
        occupati: {},
        nuovi: [...movimento, _p('por1'), _p('por2')],
        massimo: 15,
      );
      expect(numeri.values.toSet(), {for (var n = 1; n <= 15; n++) n});
      expect(numeri['por1'], 1);
      expect(numeri['por2'], 13);
      expect(numeri['m11'], 14);
      expect(numeri['m12'], 15);
    });

    test('chi è già in distinta tiene il suo numero', () {
      final numeri = numeriProposti(
        occupati: {1, 2, 3},
        nuovi: [_m('a'), _p('por')],
        massimo: 15,
      );
      expect(numeri, {'por': 13, 'a': 4});
    });
  });

  group('numeriInOrdine', () {
    test('due portieri all\'1 e al 13, gli altri dal 2 nell\'ordine', () {
      final numeri = numeriInOrdine(
        portieri: ['p1', 'p2'],
        altri: [for (var i = 0; i < 13; i++) 'm$i'],
      );
      expect(numeri['p1'], 1);
      expect(numeri['p2'], 13);
      expect(numeri['m0'], 2);
      expect(numeri['m10'], 12);
      expect(numeri['m11'], 14);
      expect(numeri['m12'], 15);
    });

    test('con un solo portiere il 13 è un numero come gli altri', () {
      final numeri = numeriInOrdine(
        portieri: ['p1'],
        altri: [for (var i = 0; i < 12; i++) 'm$i'],
      );
      expect(numeri['p1'], 1);
      expect([for (var i = 0; i < 12; i++) numeri['m$i']], [
        for (var n = 2; n <= 13; n++) n,
      ]);
    });

    test('il terzo portiere sta con gli altri, in fondo all\'ordine', () {
      final numeri = numeriInOrdine(
        portieri: ['p1', 'p2', 'p3'],
        altri: ['a', 'b'],
      );
      expect(numeri, {'p1': 1, 'p2': 13, 'p3': 2, 'a': 3, 'b': 4});
    });
  });

  group('capitaniProposti', () {
    final ultima = {'a': _u(4, c: true), 'b': _u(9, v: true), 'c': _u(2)};

    test('capitano e vice dell\'ultima partita, se convocati', () {
      expect(
        capitaniProposti(convocati: ['a', 'b', 'c'], ultimaPartita: ultima),
        (capitano: 'a', vice: 'b'),
      );
      expect(
        capitaniProposti(convocati: ['b', 'c'], ultimaPartita: ultima),
        (capitano: null, vice: 'b'),
      );
    });

    test('non cambia quelli che la distinta ha già', () {
      expect(
        capitaniProposti(
          convocati: ['a', 'b'],
          ultimaPartita: ultima,
          haGiaCapitano: true,
          haGiaVice: true,
        ),
        (capitano: null, vice: null),
      );
    });
  });

  test('"Come l\'ultima partita" li dà in ordine di numero', () {
    expect(
      convocatiUltimaPartita({'a': _u(9), 'b': _u(1), 'c': _u(4)}),
      ['b', 'c', 'a'],
    );
  });

  group('StaffDistinta', () {
    test('dal database e ritorno, solo le righe compilate', () {
      final staff = StaffDistinta.fromJson({
        'tecnico': {'nome': ' Rossi Marco ', 'tessera': '167499'},
        'medico': {'nome': '', 'tessera': ''},
        'sconosciuto': {'nome': 'X'},
      });
      expect(staff.di(RuoloStaff.tecnico).nome, 'Rossi Marco');
      expect(staff.di(RuoloStaff.medico).vuota, isTrue);
      expect(staff.toJson(), {
        'tecnico': {'nome': 'Rossi Marco', 'tessera': '167499'},
      });
      expect(StaffDistinta.fromJson(staff.toJson()), staff);
    });

    test('quello che non si legge resta vuoto', () {
      expect(StaffDistinta.fromJson(null).senzaNessuno, isTrue);
      expect(StaffDistinta.fromJson('rotto').senzaNessuno, isTrue);
      expect(
        StaffDistinta.fromJson({'tecnico': 'non una mappa'}).senzaNessuno,
        isTrue,
      );
    });

    test('due staff con le stesse persone sono uguali', () {
      const a = StaffDistinta({
        RuoloStaff.tecnico: PersonaStaff(nome: 'Rossi', tessera: '1'),
      });
      final b = StaffDistinta.vuoto.con(
        RuoloStaff.tecnico,
        const PersonaStaff(nome: 'Rossi ', tessera: '1'),
      );
      expect(a, b);
      expect(
        a == b.con(RuoloStaff.medico, const PersonaStaff(nome: 'Bianchi')),
        isFalse,
      );
    });
  });
}
