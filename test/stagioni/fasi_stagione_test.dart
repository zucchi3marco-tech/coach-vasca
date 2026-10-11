import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:flutter_test/flutter_test.dart';

Stagione _stagione(String id, String? gruppoId, List<FaseStagione> fasi) =>
    Stagione(
      id: id,
      clubId: 'c1',
      nome: id,
      dataInizio: DateTime(2026, 9, 1),
      dataFine: DateTime(2027, 6, 30),
      gruppoId: gruppoId,
      fasi: fasi,
    );

FaseStagione _fase(String nome, DateTime da, DateTime a, {int? metri}) =>
    FaseStagione(
      nome: nome,
      dataInizio: da,
      dataFine: a,
      obiettivoMetri: metri,
    );

void main() {
  final preparazione = _fase(
    'Preparazione',
    DateTime(2026, 9, 1),
    DateTime(2026, 10, 7),
    metri: 20000,
  );
  final andata = _fase(
    'Andata',
    DateTime(2026, 10, 8),
    DateTime(2027, 1, 31),
    metri: 15000,
  );
  final diClub = _fase(
    'Club',
    DateTime(2026, 9, 1),
    DateTime(2027, 6, 30),
    metri: 10000,
  );

  test('la fase che copre più giorni della settimana', () {
    final stagioni = [
      _stagione('u16', 'g16', [preparazione, andata]),
    ];
    // Settimana 5-11 ottobre: 3 giorni di preparazione, 4 di andata.
    expect(
      faseDellaSettimana(stagioni, 'g16', DateTime(2026, 10, 5))?.nome,
      'Andata',
    );
    expect(
      faseDellaSettimana(stagioni, 'g16', DateTime(2026, 9, 28))?.nome,
      'Preparazione',
    );
    expect(faseDellaSettimana(stagioni, 'g16', DateTime(2027, 3, 1)), isNull);
  });

  test('prima le fasi del gruppo, poi quelle di club, mai di un altro', () {
    final stagioni = [
      _stagione('club', null, [diClub]),
      _stagione('u16', 'g16', [andata]),
    ];
    final settimana = DateTime(2026, 11, 2);
    expect(faseDellaSettimana(stagioni, 'g16', settimana)?.nome, 'Andata');
    expect(faseDellaSettimana(stagioni, 'g14', settimana)?.nome, 'Club');
    expect(faseDellaSettimana(stagioni, null, settimana)?.nome, 'Club');
    // Dove il gruppo non ha fasi vale quella di club.
    expect(
      faseDellaSettimana(stagioni, 'g16', DateTime(2027, 3, 1))?.nome,
      'Club',
    );
  });

  test('una fase si salva e si rilegge, e si sposta con la stagione', () {
    final f = FaseStagione(
      nome: 'Andata',
      dataInizio: DateTime(2026, 10, 8),
      dataFine: DateTime(2027, 1, 31),
      obiettivoCarico: 2400,
    );
    final mappa = f.toMap();
    expect(mappa, {
      'nome': 'Andata',
      'data_inizio': '2026-10-08',
      'data_fine': '2027-01-31',
      'obiettivo_carico': 2400,
    });
    final riletta = FaseStagione.fromMap(mappa);
    expect(riletta.obiettivoMetri, isNull);
    expect(riletta.obiettivoCarico, 2400);

    final anno = f.spostata(364);
    expect(anno.dataInizio, DateTime(2027, 10, 7));
    expect(anno.dataFine, DateTime(2028, 1, 30));
  });
}
