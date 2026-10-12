import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/test/domain/tastierino_test.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, String cognome, {int anno = 2011}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'X',
  cognome: cognome,
  dataNascita: DateTime(anno),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

TestClub _test({
  UnitaTest unita = UnitaTest.secondi,
  bool piuBassoMeglio = true,
  int prove = 1,
  PunteggioTest punteggio = PunteggioTest.migliore,
}) => TestClub(
  id: 't1',
  clubId: 'c1',
  nome: 'Sprint 15 m',
  unita: unita,
  piuBassoMeglio: piuBassoMeglio,
  prove: prove,
  punteggio: punteggio,
);

RisultatoTest _r(String atleta, DateTime data, List<double> valori) =>
    RisultatoTest(
      id: '$atleta-$data',
      testId: 't1',
      atletaId: atleta,
      clubId: 'c1',
      data: data,
      valori: valori,
    );

void main() {
  test('i valori si leggono come li dice un allenatore', () {
    expect(formattaValore(UnitaTest.secondi, 8.6), '8,60 s');
    expect(formattaValore(UnitaTest.secondi, 65.2), '1:05,20');
    expect(formattaValore(UnitaTest.secondi, 8.62, sigla: false), '8,62');
    expect(formattaValore(UnitaTest.metri, 1250), '1.250 m');
    expect(formattaValore(UnitaTest.kmh, 58.4), '58,4 km/h');
    expect(formattaValore(UnitaTest.kmh, 58), '58 km/h');
    expect(formattaValore(UnitaTest.centimetri, 62), '62 cm');
    expect(formattaValore(UnitaTest.punti, 7), '7 punti');
    expect(formattaPercentuale(6.25), '6,3%');
  });

  test('il punteggio con più prove: migliore, media, somma', () {
    const valori = [8.4, 8.8, 9.2];
    expect(_test(prove: 3).punteggioDi(valori), 8.4);
    expect(
      _test(prove: 3, punteggio: PunteggioTest.media).punteggioDi(valori),
      closeTo(8.8, 1e-9),
    );
    expect(
      _test(prove: 3, punteggio: PunteggioTest.somma).punteggioDi(valori),
      closeTo(26.4, 1e-9),
    );
    // Quando vince il più alto, la migliore è la più alta.
    expect(
      _test(
        unita: UnitaTest.centimetri,
        piuBassoMeglio: false,
        prove: 3,
      ).punteggioDi(const [55, 62, 60]),
      62,
    );
  });

  test("l'indice di affaticamento dice quanto si cala dalla migliore", () {
    final t = _test(prove: 6, punteggio: PunteggioTest.media);
    expect(indiceAffaticamento(t, const [8.0, 8.0, 8.0]), 0);
    // Somma 50,4 su un ideale di 6 × 8,0 = 48: +5%.
    expect(
      indiceAffaticamento(t, const [8.0, 8.2, 8.4, 8.6, 8.6, 8.6]),
      closeTo(5, 1e-9),
    );
    // Con una prova sola non c'è.
    expect(indiceAffaticamento(t, const [8.0]), isNull);
    // Quando vince il più alto si cala scendendo.
    final salto = _test(
      unita: UnitaTest.centimetri,
      piuBassoMeglio: false,
      prove: 2,
    );
    expect(indiceAffaticamento(salto, const [60, 54]), closeTo(5, 1e-9));
  });

  group('classifica', () {
    final atleti = [
      _atleta('a', 'Rossi'),
      _atleta('b', 'Bianchi'),
      _atleta('c', 'Verdi'),
      _atleta('d', 'Neri'),
    ];
    final risultati = [
      _r('a', DateTime(2026, 9, 1), [9.0]),
      _r('a', DateTime(2026, 10, 1), [8.7]),
      _r('b', DateTime(2026, 9, 1), [8.5]),
      _r('b', DateTime(2026, 10, 1), [8.9]),
      _r('c', DateTime(2026, 10, 1), [8.7]),
    ];

    test("l'ultima prova di ognuno, dal più veloce", () {
      final posti = classifica(_test(), risultati, atleti);
      expect(posti.map((p) => p.atleta.id), ['a', 'c', 'b']);
      // Pari merito: stessa posizione.
      expect(posti.map((p) => p.posizione), [1, 1, 3]);
      // Rossi rispetto alla volta prima.
      expect(posti.first.precedente, 9.0);
      expect(posti.last.precedente, 8.5);
      // Chi non ha risultati non c'è.
      expect(posti.any((p) => p.atleta.id == 'd'), isFalse);
    });

    test('la migliore di ognuno', () {
      final posti = classifica(
        _test(),
        risultati,
        atleti,
        modo: ModoClassifica.migliore,
      );
      expect(posti.first.atleta.id, 'b');
      expect(posti.first.punteggio, 8.5);
      expect(posti.first.risultato.data, DateTime(2026, 9, 1));
    });

    test('quando vince il più alto si ordina al contrario', () {
      final posti = classifica(
        _test(unita: UnitaTest.centimetri, piuBassoMeglio: false),
        risultati,
        atleti,
      );
      expect(posti.first.atleta.id, 'b');
    });

    test('il CSV con il punto e virgola e le prove', () {
      final t = _test(prove: 2);
      final posti = classifica(t, [
        _r('a', DateTime(2026, 10, 12), [8.4, 8.6]),
      ], atleti);
      final righe = csvClassifica(t, posti).split('\r\n');
      expect(
        righe.first,
        'Posizione;Atleta;Anno di nascita;Data;Sprint 15 m (s);Prova 1;'
        'Prova 2;Affaticamento %',
      );
      expect(righe[1], '1;Rossi X;2011;12/10/2026;8,40;8,40;8,60;1,2');
    });
  });

  group('tastierino', () {
    String scrivi(UnitaTest u, String tasti) {
      var testo = '';
      for (final t in tasti.split('')) {
        testo = conTasto(u, testo, t);
      }
      return testo;
    }

    test('un tempo si scrive come al cronometro', () {
      expect(
        testoMostrato(UnitaTest.secondi, scrivi(UnitaTest.secondi, '862')),
        '8,62',
      );
      expect(valoreDigitato(UnitaTest.secondi, '862'), 8.62);
      expect(testoMostrato(UnitaTest.secondi, '10520'), '1:05,20');
      expect(valoreDigitato(UnitaTest.secondi, '10520'), closeTo(65.2, 1e-9));
      expect(testoMostrato(UnitaTest.secondi, '5'), '0,05');
      // Oltre il minuto i secondi non passano 59.
      expect(valoreDigitato(UnitaTest.secondi, '17000'), isNull);
      // Per un tempo la virgola non serve.
      expect(conTasto(UnitaTest.secondi, '86', ','), '86');
      // Al massimo sei cifre.
      expect(scrivi(UnitaTest.secondi, '12345678'), '123456');
    });

    test('le altre misure con la virgola dove ha senso', () {
      expect(scrivi(UnitaTest.kmh, '58,47'), '58,47');
      expect(scrivi(UnitaTest.kmh, '58,479'), '58,47');
      expect(valoreDigitato(UnitaTest.kmh, '58,4'), 58.4);
      expect(scrivi(UnitaTest.centimetri, '6,2'), '62');
      expect(scrivi(UnitaTest.punti, '07'), '7');
      expect(valoreDigitato(UnitaTest.punti, ''), isNull);
      expect(conTasto(UnitaTest.punti, '7', '⌫'), '');
    });

    test('una prova registrata si riapre uguale per correggerla', () {
      for (final (u, v) in [
        (UnitaTest.secondi, 8.62),
        (UnitaTest.secondi, 65.2),
        (UnitaTest.kmh, 58.4),
        (UnitaTest.centimetri, 62.0),
      ]) {
        expect(valoreDigitato(u, testoDaValore(u, v)), closeTo(v, 1e-9));
      }
    });
  });

  test('i dati arrivano dal database e dalla copia locale', () {
    final t = TestClub.fromMap({
      'id': 't1',
      'club_id': 'c1',
      'nome': 'Sprint ripetuti',
      'unita': 'secondi',
      'migliore': 'minore',
      'prove': 6,
      'punteggio': 'media',
    });
    expect(t.piuBassoMeglio, isTrue);
    expect(t.comeSiLegge, 'Media di 6 prove');
    expect(t.toPayload()['migliore'], 'minore');
    expect(valoriDa('[8.4, 9]'), [8.4, 9.0]);
    expect(valoriDa(const [8.4, 9]), [8.4, 9.0]);
  });

  test('i test pronti hanno chiavi diverse e misure sensate', () {
    expect(
      modelliTest.map((m) => m.chiave).toSet(),
      hasLength(modelliTest.length),
    );
    for (final m in modelliTest) {
      expect(m.prove, inInclusiveRange(1, 20));
      // Un tempo vince se più basso, tranne la verticale (si tiene di più).
      if (m.unita == UnitaTest.secondi && m.chiave != 'verticale_peso') {
        expect(m.piuBassoMeglio, isTrue, reason: m.nome);
      }
    }
  });
}
