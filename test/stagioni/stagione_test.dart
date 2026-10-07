import 'package:coach_vasca/core/utils/gruppo_visibilita.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('titoloStagione', () {
    test('categoria e date nel formato del coach', () {
      expect(
        titoloStagione(
          categoria: 'U14',
          dataInizio: DateTime(2026, 9, 1),
          dataFine: DateTime(2027, 6, 30),
        ),
        'Campionato U14 - 1/09/2026-30/06/2027',
      );
    });

    test('stagione di club', () {
      expect(
        titoloStagione(
          categoria: etichettaTuttiGliAtleti,
          dataInizio: DateTime(2026, 10, 12),
          dataFine: DateTime(2027, 3, 5),
        ),
        'Campionato Tutti gli atleti - 12/10/2026-5/03/2027',
      );
    });

    test('senza categoria non lascia spazi doppi', () {
      expect(
        titoloStagione(
          categoria: null,
          dataInizio: DateTime(2026, 9, 1),
          dataFine: DateTime(2027, 6, 30),
        ),
        'Campionato - 1/09/2026-30/06/2027',
      );
    });
  });

  group('stagioneCorrenteDiGruppo', () {
    final oggi = DateTime(2026, 10, 15);
    final u14 = _stagione(
      'u14',
      'g-u14',
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );
    final u16 = _stagione(
      'u16',
      'g-u16',
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );
    final club = _stagione(
      'club',
      null,
      DateTime(2026, 9),
      DateTime(2027, 6, 30),
    );
    final finita = _stagione(
      'vecchia',
      'g-u14',
      DateTime(2025, 9),
      DateTime(2026, 6),
    );

    test('preferisce la stagione del gruppo', () {
      expect(
        stagioneCorrenteDiGruppo([club, u16, u14], 'g-u14', oggi: oggi)?.id,
        'u14',
      );
    });

    test('senza stagione del gruppo ripiega sulla stagione di club', () {
      expect(
        stagioneCorrenteDiGruppo([u16, club], 'g-u14', oggi: oggi)?.id,
        'club',
      );
    });

    test('mai la stagione di un altro gruppo', () {
      expect(stagioneCorrenteDiGruppo([u16], 'g-u14', oggi: oggi), isNull);
    });

    test('gruppo nullo: solo stagioni di club', () {
      expect(
        stagioneCorrenteDiGruppo([u14, club], null, oggi: oggi)?.id,
        'club',
      );
      expect(stagioneCorrenteDiGruppo([u14], null, oggi: oggi), isNull);
    });

    test('ignora le stagioni finite', () {
      expect(stagioneCorrenteDiGruppo([finita], 'g-u14', oggi: oggi), isNull);
    });
  });

  group('stagioniDiAtleta', () {
    final u14 = _stagione('u14', 'g-u14', DateTime(2026, 9), DateTime(2027, 6));
    final u16 = _stagione('u16', 'g-u16', DateTime(2026, 9), DateTime(2027, 6));
    final club = _stagione('club', null, DateTime(2026, 9), DateTime(2027, 6));

    test('un U16 vede la sua stagione e quella di club, non quella U14', () {
      expect(stagioniDiAtleta([u14, u16, club], 'g-u16').map((s) => s.id), [
        'u16',
        'club',
      ]);
    });

    test("se nel club c'è solo la stagione U14, un U16 non ne vede", () {
      expect(stagioniDiAtleta([u14], 'g-u16'), isEmpty);
    });

    test('atleta senza gruppo: solo le stagioni di club', () {
      expect(stagioniDiAtleta([u14, club], null).map((s) => s.id), ['club']);
    });
  });

  group('campionatoPerData', () {
    Stagione conCampionato(String id, String? gruppoId, String campionato) =>
        Stagione(
          id: id,
          clubId: 'club',
          nome: id,
          dataInizio: DateTime(2026, 9),
          dataFine: DateTime(2027, 6, 30),
          gruppoId: gruppoId,
          campionato: campionato,
        );
    final u14 = conCampionato('u14', 'g-u14', 'Serie C');
    final u16 = conCampionato('u16', 'g-u16', 'Serie B');
    final club = conCampionato('club', null, 'Coppa');
    final data = DateTime(2026, 11, 3);

    test('la partita di un gruppo eredita dalla stagione del suo gruppo', () {
      expect(campionatoPerData([u16, u14, club], data, 'g-u14'), 'Serie C');
    });

    test('senza stagione del gruppo usa quella di club', () {
      expect(campionatoPerData([u16, club], data, 'g-u14'), 'Coppa');
    });

    test('mai il campionato di un altro gruppo', () {
      expect(campionatoPerData([u16], data, 'g-u14'), isNull);
    });

    test(
      'partita di club: stagione di club, altrimenti la prima che copre',
      () {
        expect(campionatoPerData([u16, club], data, null), 'Coppa');
        expect(campionatoPerData([u16], data, null), 'Serie B');
      },
    );

    test('fuori da ogni stagione: nessun campionato', () {
      expect(
        campionatoPerData([u14, club], DateTime(2028, 1, 1), 'g-u14'),
        isNull,
      );
    });
  });

  group('visibileNelGruppo', () {
    test('senza filtro tutto è visibile', () {
      expect(
        visibileNelGruppo(gruppoDelRecord: 'a', gruppoSelezionato: null),
        isTrue,
      );
    });

    test('record di club visibile a ogni gruppo', () {
      expect(
        visibileNelGruppo(gruppoDelRecord: null, gruppoSelezionato: 'a'),
        isTrue,
      );
    });

    test('record di un altro gruppo non visibile', () {
      expect(
        visibileNelGruppo(gruppoDelRecord: 'b', gruppoSelezionato: 'a'),
        isFalse,
      );
      expect(
        visibileNelGruppo(gruppoDelRecord: 'a', gruppoSelezionato: 'a'),
        isTrue,
      );
    });
  });
}
