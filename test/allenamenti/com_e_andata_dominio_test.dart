import 'package:coach_vasca/features/allenamenti/domain/com_e_andata.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

/// Una serie a distanza (o, con [durataS], a tempo).
Serie _serie({
  int ripetute = 1,
  int? distanzaM,
  int? durataS,
  String? zona,
  String? esito,
  int? metriFatti,
  int? secondiFatti,
  String id = 's',
}) => Serie(
  id: id,
  allenamentoId: 'a',
  clubId: 'c',
  ordine: 1,
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: durataS == null ? 'nuoto' : 'partita',
  zona: zona,
  esito: esito,
  metriFatti: metriFatti,
  secondiFatti: secondiFatti,
);

void main() {
  group('opzioniInParte: una serie a distanza con più ripetute', () {
    test('le ripetute fatte, da 1 a N-1, con i metri sotto', () {
      final o = opzioniInParte(_serie(ripetute: 10, distanzaM: 100));
      expect(o.domanda, 'Quante ripetute di 10?');
      expect(o.scelte.map((s) => s.etichetta), [
        for (var k = 1; k <= 9; k++) '$k',
      ]);
      expect(o.scelte.first.unita, '100 m');
      expect(o.scelte.first.metriFatti, 100);
      expect(o.scelte.first.secondiFatti, isNull);
      expect(o.scelte[5].etichetta, '6');
      expect(o.scelte[5].unita, '600 m');
      expect(o.scelte[5].metriFatti, 600);
      // I metri sopra il mille hanno il punto.
      expect(o.scelte.last.unita, '900 m');
      final lunga = opzioniInParte(_serie(ripetute: 4, distanzaM: 500));
      expect(lunga.scelte.last.unita, '1.500 m');
    });

    test('con due ripetute c\'è una scelta sola', () {
      final o = opzioniInParte(_serie(ripetute: 2, distanzaM: 50));
      expect(o.scelte.map((s) => s.etichetta), ['1']);
      expect(o.scelte.single.metriFatti, 50);
    });
  });

  group('opzioniInParte: una serie a tempo', () {
    test('i minuti fatti, da 1 a T-1', () {
      // 3×5' = 15 minuti.
      final o = opzioniInParte(_serie(ripetute: 3, durataS: 300));
      expect(o.domanda, 'Quanti minuti di 15?');
      expect(o.scelte, hasLength(14));
      expect(o.scelte.first.etichetta, '1');
      expect(o.scelte.first.unita, 'min');
      expect(o.scelte.first.secondiFatti, 60);
      expect(o.scelte.first.metriFatti, isNull);
      expect(o.scelte.last.etichetta, '14');
      expect(o.scelte.last.secondiFatti, 840);
    });

    test('con due minuti in tutto c\'è un minuto solo', () {
      final o = opzioniInParte(_serie(durataS: 120));
      expect(o.domanda, 'Quanti minuti di 2?');
      expect(o.scelte.map((s) => s.secondiFatti), [60]);
    });

    test('i minuti sono quelli interi: 2\'30" di lavoro sono 2 minuti', () {
      final o = opzioniInParte(_serie(durataS: 150));
      expect(o.domanda, 'Quanti minuti di 2?');
      expect(o.scelte.map((s) => s.secondiFatti), [60]);
    });

    test('sotto i due minuti in tutto si contano le ripetute', () {
      // 3×30" = 90 secondi: T = 1.
      final o = opzioniInParte(_serie(ripetute: 3, durataS: 30));
      expect(o.domanda, 'Quante ripetute di 3?');
      expect(o.scelte.map((s) => s.etichetta), ['1', '2']);
      expect(o.scelte.map((s) => s.secondiFatti), [30, 60]);
      expect(o.scelte.map((s) => s.unita), ['30"', "1'"]);
    });

    test('un solo minuto o meno, una ripetuta sola: niente da scegliere', () {
      expect(opzioniInParte(_serie(durataS: 60)).vuote, isTrue);
      expect(opzioniInParte(_serie(durataS: 90)).vuote, isTrue);
      expect(opzioniInParte(_serie(durataS: 30)).vuote, isTrue);
    });

    test('oltre i 60 minuti si va a salti di cinque', () {
      final o = opzioniInParte(_serie(durataS: 90 * 60));
      expect(o.domanda, 'Quanti minuti di 90?');
      expect(o.scelte.first.etichetta, '5');
      expect(o.scelte.last.etichetta, '85');
      expect(o.scelte, hasLength(17));
      // A 60 minuti si va ancora uno a uno.
      expect(opzioniInParte(_serie(durataS: 60 * 60)).scelte, hasLength(59));
    });
  });

  group('opzioniInParte: una distanza sola', () {
    List<int?> metri(Serie s) =>
        opzioniInParte(s).scelte.map((c) => c.metriFatti).toList();

    test('fino a 200 m a passi di 25', () {
      expect(metri(_serie(distanzaM: 200)), [25, 50, 75, 100, 125, 150, 175]);
      expect(metri(_serie(distanzaM: 100)), [25, 50, 75]);
      expect(metri(_serie(distanzaM: 50)), [25]);
    });

    test('fino a 800 m a passi di 50', () {
      expect(metri(_serie(distanzaM: 400)), [50, 100, 150, 200, 250, 300, 350]);
      expect(metri(_serie(distanzaM: 800)), hasLength(15));
      expect(metri(_serie(distanzaM: 800)).last, 750);
    });

    test('sopra gli 800 m a passi di 100', () {
      final o = opzioniInParte(_serie(distanzaM: 1500));
      expect(o.domanda, 'Quanti metri di 1.500?');
      expect(o.scelte.first.metriFatti, 100);
      expect(o.scelte.last.metriFatti, 1400);
      expect(o.scelte.last.etichetta, '1.400');
      expect(o.scelte.last.unita, 'm');
      expect(o.scelte, hasLength(14));
    });

    test('con la domanda scritta come la dice l\'allenatore', () {
      expect(
        opzioniInParte(_serie(distanzaM: 800)).domanda,
        'Quanti metri di 800?',
      );
    });

    test('25 m o meno: niente da scegliere', () {
      expect(opzioniInParte(_serie(distanzaM: 25)).vuote, isTrue);
    });
  });

  test('una serie senza distanza né durata non ha scelte', () {
    expect(opzioniInParte(_serie(ripetute: 4)).vuote, isTrue);
    expect(ammetteInParte(_serie(ripetute: 4)), isFalse);
    expect(ammetteInParte(_serie(ripetute: 4, distanzaM: 50)), isTrue);
  });

  test('una scelta sa se è quella già segnata sulla serie', () {
    final scelte = opzioniInParte(_serie(ripetute: 10, distanzaM: 100)).scelte;
    final inParte = _serie(
      ripetute: 10,
      distanzaM: 100,
      esito: 'fatta',
      metriFatti: 600,
    );
    expect(
      [for (final s in scelte) s.eDi(inParte)].where((e) => e),
      hasLength(1),
    );
    expect(scelte[5].eDi(inParte), isTrue);
    expect(scelte[4].eDi(inParte), isFalse);
  });

  group('descriviFatto', () {
    test('ripetute: «6 di 10»', () {
      expect(
        descriviFatto(
          _serie(ripetute: 10, distanzaM: 100, esito: 'fatta', metriFatti: 600),
        ),
        'In parte · 6 di 10',
      );
    });

    test('una distanza sola: «600 di 800 m»', () {
      expect(
        descriviFatto(_serie(distanzaM: 800, esito: 'fatta', metriFatti: 600)),
        'In parte · 600 di 800 m',
      );
      expect(
        descriviFatto(
          _serie(distanzaM: 1500, esito: 'fatta', metriFatti: 1400),
        ),
        'In parte · 1.400 di 1.500 m',
      );
    });

    test('a tempo: «12\' di 30\'»', () {
      expect(
        descriviFatto(
          _serie(ripetute: 6, durataS: 300, esito: 'fatta', secondiFatti: 720),
        ),
        "In parte · 12' di 30'",
      );
    });

    test('a tempo ma breve: si contano le ripetute', () {
      expect(
        descriviFatto(
          _serie(ripetute: 3, durataS: 30, esito: 'fatta', secondiFatti: 60),
        ),
        'In parte · 2 di 3',
      );
    });

    test('metri che non sono ripetute intere: i metri', () {
      // La serie è stata riscritta dopo: 150 non è un multiplo di 100.
      expect(
        descriviFatto(
          _serie(ripetute: 4, distanzaM: 100, esito: 'fatta', metriFatti: 150),
        ),
        'In parte · 150 di 400 m',
      );
    });

    test('una serie che non è in parte non dice niente', () {
      expect(descriviFatto(_serie(distanzaM: 100, esito: 'fatta')), '');
      expect(descriviFatto(_serie(distanzaM: 100)), '');
    });
  });

  group('esitoDopoTocco', () {
    final nessuna = _serie(distanzaM: 100);
    final tutta = _serie(distanzaM: 100, esito: 'fatta');
    final inParte = _serie(
      ripetute: 4,
      distanzaM: 100,
      esito: 'fatta',
      metriFatti: 200,
    );
    final saltata = _serie(distanzaM: 100, esito: 'saltata');

    test('«Fatta» segna, e su una fatta tutta toglie', () {
      expect(esitoDopoTocco(nessuna, 'fatta'), 'fatta');
      expect(esitoDopoTocco(tutta, 'fatta'), isNull);
      expect(esitoDopoTocco(saltata, 'fatta'), 'fatta');
    });

    test('«Fatta» su una fatta in parte la fa diventare fatta tutta', () {
      expect(esitoDopoTocco(inParte, 'fatta'), 'fatta');
    });

    test('«Saltata» segna, e su una saltata toglie', () {
      expect(esitoDopoTocco(nessuna, 'saltata'), 'saltata');
      expect(esitoDopoTocco(saltata, 'saltata'), isNull);
      expect(esitoDopoTocco(tutta, 'saltata'), 'saltata');
      expect(esitoDopoTocco(inParte, 'saltata'), 'saltata');
    });
  });

  test('famigliaZona raggruppa le zone', () {
    expect(famigliaZona('A1'), 'A');
    expect(famigliaZona('A2'), 'A');
    expect(famigliaZona('B1'), 'B');
    expect(famigliaZona('B2'), 'B');
    expect(famigliaZona('C'), 'C');
    expect(famigliaZona('C1'), 'C');
    expect(famigliaZona('C2'), 'C');
    expect(famigliaZona('C3'), 'C');
    expect(famigliaZona('D'), 'D');
    expect(famigliaZona(null), isNull);
    expect(famigliaZona('X9'), isNull);
  });

  group('scartoPerFamiglia', () {
    test('per famiglia, nell\'ordine A B C D e senza zona', () {
      final scarto = scartoPerFamiglia([
        _serie(distanzaM: 100, zona: 'D'),
        _serie(distanzaM: 200),
        _serie(distanzaM: 300, zona: 'C2'),
        _serie(distanzaM: 400, zona: 'A1'),
        _serie(distanzaM: 500, zona: 'B1'),
        _serie(distanzaM: 600, zona: 'A2'),
      ]);
      expect(scarto.map((e) => e.famiglia), ['A', 'B', 'C', 'D', null]);
      expect(scarto.first.scritto.metri, 1000);
      expect(scarto.first.fatto.metri, 1000);
    });

    test('lo scritto e il fatto: saltata e in parte', () {
      final scarto = scartoPerFamiglia([
        _serie(
          ripetute: 10,
          distanzaM: 100,
          zona: 'A2',
          esito: 'fatta',
          metriFatti: 600,
        ),
        _serie(distanzaM: 400, zona: 'A1', esito: 'saltata'),
        _serie(distanzaM: 200, zona: 'B1', esito: 'fatta'),
        _serie(distanzaM: 200, zona: 'B2'),
      ]);
      final a = scarto.firstWhere((e) => e.famiglia == 'A');
      expect(a.scritto.metri, 1400);
      expect(a.fatto.metri, 600);
      final b = scarto.firstWhere((e) => e.famiglia == 'B');
      expect(b.scritto.metri, 400);
      expect(b.fatto.metri, 400);
    });

    test('il lavoro a tempo è in secondi e non diventa metri', () {
      final scarto = scartoPerFamiglia([
        _serie(
          ripetute: 4,
          durataS: 300,
          zona: 'C1',
          esito: 'fatta',
          secondiFatti: 720,
        ),
        _serie(distanzaM: 100, zona: 'C1'),
      ]);
      expect(scarto, hasLength(1));
      expect(scarto.single.scritto.metri, 100);
      expect(scarto.single.scritto.secondi, 1200);
      expect(scarto.single.fatto.secondi, 720);
    });

    test('una famiglia senza lavoro scritto non c\'è', () {
      expect(scartoPerFamiglia(<Serie>[]), isEmpty);
      expect(scartoPerFamiglia([_serie(zona: 'A1')]), isEmpty);
    });
  });

  group('i numeri da scrivere', () {
    const scritto = VolumeAllenamento(metri: 3200, secondi: 1800);
    const fatto = VolumeAllenamento(metri: 2600, secondi: 1500);

    test('fattoDiScritto', () {
      expect(fattoDiScritto(scritto, fatto), "2.600 di 3.200 m · 25' di 30'");
      expect(
        fattoDiScritto(scritto, fatto, aTempo: true),
        "2.600 di 3.200 m · 25' di 30' a tempo",
      );
      expect(
        fattoDiScritto(
          const VolumeAllenamento(metri: 400),
          const VolumeAllenamento(metri: 250),
        ),
        '250 di 400 m',
      );
      expect(
        fattoDiScritto(
          const VolumeAllenamento(secondi: 1800),
          const VolumeAllenamento(secondi: 1500),
          aTempo: true,
        ),
        "25' di 30' a tempo",
      );
    });

    test('scartoScritto', () {
      expect(scartoScritto(scritto, fatto), "−600 · −5'");
      expect(
        scartoScritto(
          const VolumeAllenamento(metri: 1400),
          const VolumeAllenamento(metri: 1200),
        ),
        '−200',
      );
      expect(
        scartoScritto(
          const VolumeAllenamento(secondi: 1800),
          const VolumeAllenamento(secondi: 1500),
        ),
        "−5'",
      );
      expect(scartoScritto(scritto, scritto), isNull);
    });
  });

  group('riassuntoEsiti di una piramide', () {
    Serie conEsito(String? esito, {int? metriFatti}) => _serie(
      ripetute: 2,
      distanzaM: 100,
      esito: esito,
      metriFatti: metriFatti,
    );

    test('niente segnato: niente da dire', () {
      expect(riassuntoEsiti([conEsito(null), conEsito(null)]), isNull);
    });

    test('tutte fatte tutte, tutte saltate', () {
      expect(riassuntoEsiti([conEsito('fatta'), conEsito('fatta')]), 'fatta');
      expect(
        riassuntoEsiti([conEsito('saltata'), conEsito('saltata')]),
        'saltata',
      );
    });

    test('un misto: le parti che ci sono', () {
      expect(
        riassuntoEsiti([
          conEsito('fatta'),
          conEsito('fatta'),
          conEsito('fatta', metriFatti: 100),
          conEsito('saltata'),
        ]),
        '2 fatte, 1 in parte, 1 saltata',
      );
      expect(
        riassuntoEsiti([conEsito('fatta', metriFatti: 100), conEsito(null)]),
        '1 in parte',
      );
      expect(
        riassuntoEsiti([
          conEsito('fatta'),
          conEsito('saltata'),
          conEsito('saltata'),
        ]),
        '1 fatta, 2 saltate',
      );
      expect(
        riassuntoEsiti([
          conEsito('fatta', metriFatti: 100),
          conEsito('fatta', metriFatti: 100),
        ]),
        '2 in parte',
      );
    });
  });

  group('riepilogoComEAndata', () {
    test('10x100 con 6 fatte, una da 400 saltata e una da 200 non segnata', () {
      final r = riepilogoComEAndata([
        _serie(ripetute: 10, distanzaM: 100, esito: 'fatta', metriFatti: 600),
        _serie(distanzaM: 400, esito: 'saltata'),
        _serie(distanzaM: 200),
      ]);
      expect(r.scritto.metri, 1600);
      expect(r.fatto.metri, 800);
      expect(r.inParte, 1);
      expect(r.saltate, 1);
      expect(r.fatteTutte, 0);
      expect(r.nonSegnate, 1);
    });

    test('il lavoro a tempo a parte', () {
      final r = riepilogoComEAndata([
        _serie(ripetute: 6, durataS: 300, esito: 'fatta', secondiFatti: 1500),
        _serie(distanzaM: 400, esito: 'fatta'),
      ]);
      expect(r.scritto.secondi, 1800);
      expect(r.fatto.secondi, 1500);
      expect(r.fatto.metri, 400);
      expect(r.fatteTutte, 1);
      expect(r.inParte, 1);
    });
  });
}
