import 'package:coach_vasca/features/pallanuoto/domain/elenco_partite.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:flutter_test/flutter_test.dart';

Partita _partita(String id, DateTime data, String? gruppoId, {String? ora}) =>
    Partita(
      id: id,
      clubId: 'club',
      gruppoId: gruppoId,
      data: data,
      ora: ora,
      squadraCasa: 'A',
      squadraTrasferta: 'B',
      numeroMaxConvocati: 15,
    );

Stagione _stagione(
  String id,
  String? gruppoId,
  DateTime inizio,
  DateTime fine,
) => Stagione(
  id: id,
  clubId: 'club',
  nome: id,
  dataInizio: inizio,
  dataFine: fine,
  gruppoId: gruppoId,
);

void main() {
  group('partiteDellaStagione', () {
    final stagione = _stagione(
      's',
      'u14',
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );

    test('dalla più vecchia alla più recente, per ora a parità di giorno', () {
      final elenco = partiteDellaStagione(stagione, [
        _partita('c', DateTime(2026, 11, 20), 'u14'),
        _partita('b2', DateTime(2026, 10, 5), 'u14', ora: '18:00'),
        _partita('b1', DateTime(2026, 10, 5), 'u14', ora: '10:30'),
        _partita('a', DateTime(2026, 9, 12), null),
      ], 'u14');
      expect(elenco.map((p) => p.id), ['a', 'b1', 'b2', 'c']);
    });

    test('esclude partite fuori stagione e di altri gruppi', () {
      final elenco = partiteDellaStagione(stagione, [
        _partita('dentro', DateTime(2026, 10, 1), 'u14'),
        _partita('club', DateTime(2026, 10, 2), null),
        _partita('altro', DateTime(2026, 10, 3), 'u16'),
        _partita('prima', DateTime(2026, 8, 31), 'u14'),
        _partita('dopo', DateTime(2027, 7, 1), 'u14'),
      ], 'u14');
      expect(elenco.map((p) => p.id), ['dentro', 'club']);
    });

    test('senza gruppo selezionato tutte le partite del periodo', () {
      final elenco = partiteDellaStagione(stagione, [
        _partita('a', DateTime(2026, 10, 3), 'u16'),
        _partita('b', DateTime(2026, 10, 4), 'u14'),
      ], null);
      expect(elenco, hasLength(2));
    });
  });

  group('stagionePerElenco', () {
    final oggi = DateTime(2026, 10, 15);
    final u14 = _stagione(
      'u14',
      'g14',
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );
    final u14Vecchia = _stagione(
      'u14v',
      'g14',
      DateTime(2025, 9),
      DateTime(2026, 6, 30),
    );
    final u16 = _stagione(
      'u16',
      'g16',
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );
    final club = _stagione(
      'club',
      null,
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );

    test('la stagione in corso del gruppo', () {
      expect(
        stagionePerElenco([u14Vecchia, u14, u16], 'g14', oggi: oggi)?.id,
        'u14',
      );
    });

    test('senza stagione in corso: la più recente visibile', () {
      expect(
        stagionePerElenco([u14Vecchia, u16], 'g14', oggi: oggi)?.id,
        'u14v',
      );
    });

    test('ripiega sulla stagione di club', () {
      expect(stagionePerElenco([u16, club], 'g14', oggi: oggi)?.id, 'club');
    });

    test('nessuna stagione visibile', () {
      expect(stagionePerElenco([u16], 'g14', oggi: oggi), isNull);
      expect(stagionePerElenco([], 'g14', oggi: oggi), isNull);
    });
  });
}
