import 'package:coach_vasca/features/stagioni/domain/fasi_a_ritroso.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:flutter_test/flutter_test.dart';

// La stagione U16 vera: dal 1° settembre 2026 al 30 giugno 2027, con le
// sei partite del girone di qualificazione (tutte di sabato).
final _inizio = DateTime(2026, 9, 1);
final _fine = DateTime(2027, 6, 30);
final _partite = [
  DateTime(2026, 10, 24),
  DateTime(2026, 10, 31),
  DateTime(2026, 11, 7),
  DateTime(2026, 11, 14),
  DateTime(2026, 11, 21),
  DateTime(2026, 11, 28),
];
final _finali = ObiettivoStagione(
  nome: 'Finali nazionali',
  data: DateTime(2027, 6, 19),
);

/// "Nome dd/mm–dd/mm" per leggere le fasi a colpo d'occhio.
List<String> _leggi(List<FaseProposta> fasi) => [
  for (final f in fasi)
    '${f.nome} ${_d(f.dataInizio)}–${_d(f.dataFine)}${f.bloccata ? ' 🔒' : ''}',
];

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Una dopo l'altra, senza buchi, dentro la stagione.
void _contigue(List<FaseProposta> fasi, DateTime inizio, DateTime fine) {
  expect(fasi.first.dataInizio, inizio);
  expect(fasi.last.dataFine, fine);
  for (var i = 1; i < fasi.length; i++) {
    expect(
      fasi[i].dataInizio,
      fasi[i - 1].dataFine.add(const Duration(days: 1)),
      reason: 'fra ${fasi[i - 1].nome} e ${fasi[i].nome}',
    );
  }
  for (final f in fasi) {
    expect(f.dataFine.isBefore(f.dataInizio), isFalse, reason: f.nome);
  }
}

void main() {
  test(
    'U16: preparazione, andata e ritorno dalle partite, scarico, finali',
    () {
      final fasi = proponiFasi(
        inizioStagione: _inizio,
        fineStagione: _fine,
        partite: _partite,
        obiettivi: [_finali],
      );
      expect(_leggi(fasi), [
        // Fino alla domenica prima della settimana della prima partita.
        'Preparazione 01/09–18/10',
        // Tre partite di andata: il ritorno parte la settimana dopo il 7/11.
        'Andata 19/10–08/11',
        'Ritorno 09/11–13/06',
        // Una settimana di scarico: quella delle finali, da lunedì.
        'Scarico 14/06–18/06',
        'Finali nazionali 19/06–19/06 🔒',
        'Fine stagione 20/06–30/06',
      ]);
      _contigue(fasi, _inizio, _fine);
    },
  );

  test('due settimane di scarico partono un lunedì prima', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [_finali],
      settimaneScarico: 2,
    );
    expect(_leggi(fasi)[2], 'Ritorno 09/11–06/06');
    expect(_leggi(fasi)[3], 'Scarico 07/06–18/06');
  });

  test('un obiettivo di lunedì: lo scarico è la settimana prima', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [
        ObiettivoStagione(nome: 'Torneo', data: DateTime(2027, 6, 14)),
      ],
    );
    expect(_leggi(fasi).sublist(3), [
      'Scarico 07/06–13/06',
      'Torneo 14/06–14/06 🔒',
      'Fine stagione 15/06–30/06',
    ]);
  });

  test('due obiettivi: «Verso» e «Scarico 2» fra l\'uno e l\'altro', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [
        _finali,
        ObiettivoStagione(
          nome: 'Finali regionali',
          data: DateTime(2027, 5, 15),
        ),
      ],
    );
    expect(_leggi(fasi), [
      'Preparazione 01/09–18/10',
      'Andata 19/10–08/11',
      'Ritorno 09/11–09/05',
      'Scarico 10/05–14/05',
      'Finali regionali 15/05–15/05 🔒',
      'Verso Finali nazionali 16/05–13/06',
      'Scarico 2 14/06–18/06',
      'Finali nazionali 19/06–19/06 🔒',
      'Fine stagione 20/06–30/06',
    ]);
    _contigue(fasi, _inizio, _fine);
  });

  test('una partita scelta come obiettivo non conta nell\'andata', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: [..._partite, DateTime(2027, 6, 19)],
      obiettivi: [_finali],
    );
    expect(_leggi(fasi)[1], 'Andata 19/10–08/11');
  });

  test('senza obiettivi: il campionato finisce con l\'ultima partita', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: const [],
    );
    expect(_leggi(fasi), [
      'Preparazione 01/09–18/10',
      'Andata 19/10–08/11',
      'Ritorno 09/11–29/11',
      'Fine stagione 30/11–30/06',
    ]);
    _contigue(fasi, _inizio, _fine);
  });

  test('senza partite: preparazione fino allo scarico', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: const [],
      obiettivi: [_finali],
    );
    expect(_leggi(fasi), [
      'Preparazione 01/09–13/06',
      'Scarico 14/06–18/06',
      'Finali nazionali 19/06–19/06 🔒',
      'Fine stagione 20/06–30/06',
    ]);
  });

  test('obiettivi fuori stagione, doppi o più di tre si saltano', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [
        ObiettivoStagione(nome: 'Fuori', data: DateTime(2027, 7, 10)),
        ObiettivoStagione(nome: 'A', data: DateTime(2027, 3, 6)),
        ObiettivoStagione(nome: 'A bis', data: DateTime(2027, 3, 6)),
        ObiettivoStagione(nome: 'B', data: DateTime(2027, 4, 10)),
        ObiettivoStagione(nome: 'C', data: DateTime(2027, 5, 15)),
        _finali,
      ],
    );
    expect(
      [
        for (final f in fasi)
          if (f.bloccata) f.nome,
      ],
      ['A', 'B', 'C'],
    );
    _contigue(fasi, _inizio, _fine);
  });

  group('spostaConfine', () {
    final fasi = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [_finali],
    );

    test('una settimana in più di preparazione: l\'andata parte dopo', () {
      final spostate = spostaConfine(fasi, 0, 7)!;
      expect(_leggi(spostate).take(2), [
        'Preparazione 01/09–25/10',
        'Andata 26/10–08/11',
      ]);
    });

    test('il giorno dell\'obiettivo non si sposta', () {
      // 3 = fra Scarico e Finali, 4 = fra Finali e Fine stagione.
      expect(spostaConfine(fasi, 3, -7), isNull);
      expect(spostaConfine(fasi, 4, 7), isNull);
    });

    test('una fase non resta senza giorni', () {
      // Lo scarico dura 5 giorni: allungare il ritorno di una settimana
      // lo cancellerebbe.
      expect(spostaConfine(fasi, 2, 7), isNull);
      expect(spostaConfine(fasi, 2, -7), isNotNull);
    });
  });

  test('le fasi con lo stesso nome tengono scopo, obiettivi e righe', () {
    final attuali = [
      FaseStagione(
        nome: 'Andata',
        dataInizio: DateTime(2026, 11, 30),
        dataFine: DateTime(2027, 2, 7),
        obiettivoCarico: 2400,
        scopo: 'Vincere le partite in casa',
        righeSettimane: {
          DateTime(2026, 11, 2): 'Settimana della partita con Arese',
          DateTime(2027, 1, 4): 'Fuori dalla nuova andata',
        },
      ),
    ];
    final proposte = proponiFasi(
      inizioStagione: _inizio,
      fineStagione: _fine,
      partite: _partite,
      obiettivi: [_finali],
    );
    final fasi = fasiDaProposta(proposte, attuali);
    final andata = fasi.firstWhere((f) => f.nome == 'Andata');
    expect(andata.dataInizio, DateTime(2026, 10, 19));
    expect(andata.dataFine, DateTime(2026, 11, 8));
    expect(andata.scopo, 'Vincere le partite in casa');
    expect(andata.obiettivoCarico, 2400);
    expect(andata.righeSettimane, {
      DateTime(2026, 11, 2): 'Settimana della partita con Arese',
    });
    final preparazione = fasi.first;
    expect(preparazione.scopo, isNull);
    expect(fasi, hasLength(proposte.length));
  });
}
