import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gare/domain/elenco_gare.dart';
import 'package:coach_vasca/features/gare/domain/gara.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:flutter_test/flutter_test.dart';

Gara _gara(String id, DateTime data, String? gruppoId, {String? ora}) => Gara(
  id: id,
  clubId: 'club',
  gruppoId: gruppoId,
  data: data,
  nome: id,
  ora: ora,
);

Atleta _atleta(
  String id,
  String cognome,
  String? gruppoId, {
  bool attivo = true,
}) => Atleta(
  id: id,
  clubId: 'club',
  nome: 'X',
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  gruppoId: gruppoId,
  consensoPrivacyFirmato: true,
  attivo: attivo,
);

void main() {
  final stagione = Stagione(
    id: 's',
    clubId: 'club',
    nome: 's',
    dataInizio: DateTime(2026, 9),
    dataFine: DateTime(2027, 6, 30),
    gruppoId: 'u14',
  );

  test('dalla più vecchia alla più recente, per ora a parità di giorno', () {
    final elenco = gareDellaStagione(stagione, [
      _gara('c', DateTime(2026, 12, 1), 'u14'),
      _gara('b2', DateTime(2026, 10, 5), 'u14', ora: '17:00'),
      _gara('b1', DateTime(2026, 10, 5), 'u14', ora: '09:00'),
      _gara('a', DateTime(2026, 9, 20), null),
    ], 'u14');
    expect(elenco.map((g) => g.id), ['a', 'b1', 'b2', 'c']);
  });

  test('gare di club visibili a ogni gruppo, di altri gruppi no', () {
    final elenco = gareDellaStagione(stagione, [
      _gara('proprio', DateTime(2026, 10, 1), 'u14'),
      _gara('club', DateTime(2026, 10, 2), null),
      _gara('altro', DateTime(2026, 10, 3), 'u16'),
    ], 'u14');
    expect(elenco.map((g) => g.id), ['proprio', 'club']);
  });

  test('esclude le gare fuori dalla stagione', () {
    final elenco = gareDellaStagione(stagione, [
      _gara('prima', DateTime(2026, 8, 31), 'u14'),
      _gara('dopo', DateTime(2027, 7, 1), 'u14'),
      _gara('ultimo', DateTime(2027, 6, 30), 'u14'),
    ], 'u14');
    expect(elenco.map((g) => g.id), ['ultimo']);
  });

  group('atletiPerIscrizione', () {
    final garaGruppo = Gara(
      id: 'g',
      clubId: 'club',
      gruppoId: 'u14',
      data: DateTime(2026, 10, 3),
      nome: 'Trofeo',
    );
    final garaClub = Gara(
      id: 'gc',
      clubId: 'club',
      gruppoId: null,
      data: DateTime(2026, 10, 3),
      nome: 'Regionale',
    );
    final atleti = [
      _atleta('z', 'Zanetti', 'u14'),
      _atleta('a', 'Abate', 'u14'),
      _atleta('l', 'Libero', null),
      _atleta('o', 'Altrove', 'u16'),
      _atleta('i', 'Inattivo', 'u14', attivo: false),
    ];

    test('gara di gruppo: attivi del gruppo e senza gruppo, per cognome', () {
      final elenco = atletiPerIscrizione(garaGruppo, atleti, {});
      expect(elenco.map((a) => a.id), ['a', 'l', 'z']);
    });

    test('gara di club: tutti gli attivi', () {
      final elenco = atletiPerIscrizione(garaClub, atleti, {});
      expect(elenco.map((a) => a.id), ['a', 'o', 'l', 'z']);
    });

    test(
      'un iscritto resta in elenco anche se di un altro gruppo o inattivo',
      () {
        final elenco = atletiPerIscrizione(garaGruppo, atleti, {'o', 'i'});
        expect(elenco.map((a) => a.id), ['a', 'o', 'i', 'l', 'z']);
      },
    );
  });
}
