import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/numeri_portiere.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:flutter_test/flutter_test.dart';

var _n = 0;

EventoPartita _tiroSubito(String partita, String esito, {String? portiere}) =>
    EventoPartita(
      id: 't${_n++}',
      partitaId: partita,
      clubId: 'c1',
      tipo: 'tiro',
      squadra: 'avversaria',
      esito: esito,
      portiereId: portiere,
      creatoIl: DateTime(2026, 10, 24, 18, _n % 60),
    );

Partita _partita(String id, {bool inCasa = true}) => Partita(
  id: id,
  clubId: 'c1',
  data: DateTime(2026, 10, 24),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Loro',
  numeroMaxConvocati: 15,
  tracciaTempo: false,
  nostraSquadra: inCasa ? 'casa' : 'trasferta',
);

RefertoPartita _referto(String partita, List<(int, int)> parziali) =>
    RefertoPartita(
      id: 'r$partita',
      partitaId: partita,
      clubId: 'c1',
      squadraCasa: 'Noi',
      squadraTrasferta: 'Loro',
      risultatoCasa: parziali.fold(0, (s, p) => s + p.$1),
      risultatoTrasferta: parziali.fold(0, (s, p) => s + p.$2),
      parziali: [
        for (final (c, t) in parziali) ParzialeReferto(casa: c, trasferta: t),
      ],
      giocatoriCasa: const [],
      giocatoriTrasferta: const [],
    );

void main() {
  test('dal vivo: parate e gol di chi era in porta, anche a metà tempo', () {
    final eventi = [
      _tiroSubito('p1', 'parato', portiere: 'g1'),
      _tiroSubito('p1', 'gol', portiere: 'g1'),
      _tiroSubito('p1', 'palo_fuori', portiere: 'g1'),
      _tiroSubito('p1', 'gol', portiere: 'g2'),
      _tiroSubito('p1', 'parato', portiere: 'g2'),
    ];
    final n = numeriPortiere(
      atletaId: 'g1',
      partite: [_partita('p1')],
      tempiInPorta: {
        'p1': [1, 2],
      },
      eventi: eventi,
      // Il referto c'è ma vince il dal vivo.
      referti: {
        'p1': _referto('p1', [(1, 4), (6, 6), (3, 5), (4, 6)]),
      },
    );
    expect(n.partite, 1);
    expect(n.parate, 1);
    expect(n.golSubiti, 1);
    expect(n.percentualeParate, 50);
  });

  test('solo referto: gol subiti dai parziali avversari dei suoi tempi', () {
    final referti = {
      'casa': _referto('casa', [(1, 4), (6, 6), (3, 5), (4, 6)]),
      'fuori': _referto('fuori', [(2, 0), (1, 1), (0, 3), (5, 2)]),
    };
    final n = numeriPortiere(
      atletaId: 'g1',
      partite: [_partita('casa'), _partita('fuori', inCasa: false)],
      tempiInPorta: {
        'casa': [1, 2],
        'fuori': [3, 4],
      },
      // Tiri senza portiere (prima di questa funzione): non contano.
      eventi: [_tiroSubito('casa', 'gol'), _tiroSubito('casa', 'non_gol')],
      referti: referti,
    );
    // 4 + 6 in casa (colonna trasferta); fuori casa gli avversari sono
    // la squadra di casa: 0 + 5.
    expect(n.partite, 2);
    expect(n.golSubiti, 15);
    expect(n.parate, 0);
    expect(n.percentualeParate, isNull);
  });

  test('chi non è mai stato in porta non ha partite', () {
    final n = numeriPortiere(
      atletaId: 'g3',
      partite: [_partita('p1')],
      tempiInPorta: const {},
      eventi: [_tiroSubito('p1', 'gol', portiere: 'g1')],
      referti: const {},
    );
    expect(n.partite, 0);
    expect(n.golSubiti, 0);
  });
}
