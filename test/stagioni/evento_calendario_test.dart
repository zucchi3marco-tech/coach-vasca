import 'package:coach_vasca/features/stagioni/domain/evento_calendario.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/stagioni/presentation/calendario_stagione_view.dart';
import 'package:flutter_test/flutter_test.dart';

EventoCalendario _evento(String id, DateTime data, String? gruppoId) =>
    EventoCalendario(
      id: id,
      tipo: TipoEventoCalendario.partita,
      data: data,
      gruppoId: gruppoId,
      titolo: id,
      origine: id,
    );

Stagione _stagione(String? gruppoId) => Stagione(
  id: 's',
  clubId: 'club',
  nome: 's',
  dataInizio: DateTime(2026, 9, 1),
  dataFine: DateTime(2027, 6, 30),
  gruppoId: gruppoId,
);

void main() {
  final proprio = _evento('proprio', DateTime(2026, 10, 3), 'u14');
  final altro = _evento('altro', DateTime(2026, 10, 4), 'u16');
  final club = _evento('club', DateTime(2026, 10, 5), null);
  final fuori = _evento('fuori', DateTime(2027, 7, 1), 'u14');
  final ultimoGiorno = _evento('ultimo', DateTime(2027, 6, 30), 'u14');
  final tutti = [proprio, altro, club, fuori, ultimoGiorno];

  group('eventiVisibiliInStagione', () {
    test('stagione di gruppo: eventi del gruppo e di club, mai di altri', () {
      final visibili = eventiVisibiliInStagione(_stagione('u14'), tutti);
      expect(visibili.map((e) => e.id), ['proprio', 'club', 'ultimo']);
    });

    test('stagione di club: tutti gli eventi in periodo', () {
      final visibili = eventiVisibiliInStagione(_stagione(null), tutti);
      expect(visibili.map((e) => e.id), ['proprio', 'altro', 'club', 'ultimo']);
    });

    test('esclude gli eventi fuori dal periodo, ultimo giorno incluso', () {
      final visibili = eventiVisibiliInStagione(_stagione('u14'), [
        fuori,
        ultimoGiorno,
      ]);
      expect(visibili.map((e) => e.id), ['ultimo']);
    });

    test('un evento con ora nel giorno finale resta dentro', () {
      final tardi = _evento('tardi', DateTime(2027, 6, 30, 21, 30), 'u14');
      expect(eventiVisibiliInStagione(_stagione('u14'), [tardi]), hasLength(1));
    });
  });

  group('raggruppaEventiPerGiorno', () {
    test('più eventi nello stesso giorno finiscono insieme', () {
      final mappa = raggruppaEventiPerGiorno([
        _evento('a', DateTime(2026, 10, 3, 9), 'u14'),
        _evento('b', DateTime(2026, 10, 3, 18), null),
        _evento('c', DateTime(2026, 10, 4), 'u14'),
      ]);
      expect(mappa[DateTime(2026, 10, 3)]!.map((e) => e.id), ['a', 'b']);
      expect(mappa[DateTime(2026, 10, 4)], hasLength(1));
    });
  });

  group('meseIniziale', () {
    final primo = DateTime(2026, 9, 1);
    final ultimo = DateTime(2027, 6, 30);

    test('dentro la stagione: il mese corrente', () {
      expect(
        meseIniziale(DateTime(2027, 2, 14), primo, ultimo),
        DateTime(2027, 2),
      );
    });

    test('prima della stagione: il primo mese', () {
      expect(
        meseIniziale(DateTime(2026, 7, 10), primo, ultimo),
        DateTime(2026, 9),
      );
    });

    test('dopo la stagione: l\'ultimo mese', () {
      expect(
        meseIniziale(DateTime(2027, 11, 2), primo, ultimo),
        DateTime(2027, 6),
      );
    });
  });

  group('prossimiEventi', () {
    final oggi = DateTime(2026, 10, 10);
    final passato = _evento('passato', DateTime(2026, 10, 9), 'u14');
    final oggiEv = _evento('oggi', DateTime(2026, 10, 10), 'u14');
    final vicino = _evento('vicino', DateTime(2026, 10, 12), null);
    final lontano = _evento('lontano', DateTime(2026, 12, 1), 'u14');
    final piuLontano = _evento('piulontano', DateTime(2027, 1, 1), 'u14');
    final altroGruppo = _evento('altro', DateTime(2026, 10, 11), 'u16');
    final tutti = [piuLontano, passato, lontano, altroGruppo, vicino, oggiEv];

    test(
      'da oggi in poi, del gruppo e di club, dal più vicino, al massimo 3',
      () {
        final prossimi = prossimiEventi(tutti, 'u14', oggi);
        expect(prossimi.map((e) => e.id), ['oggi', 'vicino', 'lontano']);
      },
    );

    test('il massimo si può cambiare', () {
      expect(prossimiEventi(tutti, 'u14', oggi, massimo: 1).map((e) => e.id), [
        'oggi',
      ]);
    });

    test('atleta senza gruppo: nessun filtro', () {
      expect(prossimiEventi(tutti, null, oggi).map((e) => e.id), [
        'oggi',
        'altro',
        'vicino',
      ]);
    });

    test('nessun evento futuro', () {
      expect(prossimiEventi([passato], 'u14', oggi), isEmpty);
    });
  });
}
