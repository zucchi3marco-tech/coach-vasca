import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

SerieScritta _una(String riga) =>
    leggiRigaSerie(riga, blocco: 'principale')!.single;

Serie _salvata(
  int ordine, {
  String blocco = 'principale',
  int ripetute = 1,
  int? distanzaM = 100,
  int? durataS,
  String stile = 'libero',
  String esecuzione = 'nuoto',
  String? zona,
  double? passo,
  int? recupero,
  double? ripartenza,
  String? attrezzatura,
  String? note,
  String? piramideId,
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: durataS == null ? distanzaM : null,
  durataS: durataS,
  stile: stile,
  esecuzione: esecuzione,
  zona: zona,
  passoObiettivoS: passo,
  recuperoS: recupero,
  ripartenzaS: ripartenza,
  attrezzatura: attrezzatura,
  note: note,
  piramideId: piramideId,
);

/// Riletta dal suo testo, ogni serie deve tornare uguale, gruppi compresi.
void _tornaUguale(List<Serie> serie) {
  final testo = testoDaSerie(serie);
  final riletto = interpretaAllenamento(testo);
  expect(riletto.righeNonCapite, 0, reason: testo);
  expect(riletto.serie, hasLength(serie.length), reason: testo);
  for (var i = 0; i < serie.length; i++) {
    expect(
      stessaSerie(riletto.serie[i], serie[i]),
      isTrue,
      reason: 'serie ${i + 1} di:\n$testo',
    );
    expect(
      riletto.serie[i].piramideId == null,
      serie[i].piramideId == null,
      reason: 'gruppo della serie ${i + 1} di:\n$testo',
    );
  }
}

void main() {
  group('una riga', () {
    test('il formato di sempre: ripetute, zona, passo, recupero, stile', () {
      final s = _una('10x100 A2 1:25 r15 sl');
      expect(s.ripetute, 10);
      expect(s.distanzaM, 100);
      expect(s.zona, 'A2');
      expect(s.passoObiettivoS, 85);
      expect(s.recuperoS, 15);
      expect(s.stile, 'libero');
      expect(s.note, isNull);
    });

    test('distanza da sola, ripartenza, esecuzione e attrezzi', () {
      final s = _una('400 do gambe pinne palette @7:30');
      expect(s.ripetute, 1);
      expect(s.distanzaM, 400);
      expect(s.stile, 'dorso');
      expect(s.esecuzione, 'gambe');
      expect(s.attrezzatura, 'pinne, palette');
      expect(s.ripartenzaS, 450);
    });

    test('scritta come si parla: spazi, "volte", metri, stile libero', () {
      final s = _una('8 volte 100 m stile libero con pinne');
      expect(s.ripetute, 8);
      expect(s.distanzaM, 100);
      expect(s.stile, 'libero');
      expect(s.attrezzatura, 'pinne');
      expect(s.note, isNull);
    });

    test('serie a tempo', () {
      expect(_una("10' remate").durataS, 600);
      expect(_una("10' remate").esecuzione, 'remate');
      final s = _una('3 x 5\'30" A1 r1:00');
      expect(s.ripetute, 3);
      expect(s.durataS, 330);
      expect(s.distanzaM, isNull);
      expect(s.recuperoS, 60);
      expect(_una('6x30" D').durataS, 30);
      expect(_una('2x10 min A1').durataS, 600);
      // Le virgolette dopo i secondi non aprono una nota.
      final veloce = _una('6x30" "veloce"');
      expect(veloce.durataS, 30);
      expect(veloce.note, 'veloce');
    });

    test(
      'le parole che non riconosce vanno nelle note, le virgolette pure',
      () {
        final s = _una('8x50 sl B1 "respirazione ogni 3" sciolto');
        expect(s.note, 'respirazione ogni 3 sciolto');
        expect(_una('200 mi [pinne corte]').attrezzatura, 'pinne corte');
      },
    );

    test('un numero da solo è una distanza solo all\'inizio', () {
      expect(leggiRigaSerie('sl 400', blocco: 'principale'), isNull);
      expect(leggiRigaSerie('A2 r15 sl', blocco: 'principale'), isNull);
      expect(leggiRigaSerie('0x100', blocco: 'principale'), isNull);
      expect(leggiRigaSerie('10x0', blocco: 'principale'), isNull);
    });

    test('piramide: una serie per distanza, stesso gruppo', () {
      final serie = leggiRigaSerie(
        '50-100-200-100-50 sl r20',
        blocco: 'principale',
      )!;
      expect(serie.map((s) => s.distanzaM), [50, 100, 200, 100, 50]);
      expect(serie.every((s) => s.ripetute == 1 && s.recuperoS == 20), isTrue);
      expect(serie.map((s) => s.piramideId).toSet(), hasLength(1));
      expect(serie.first.piramideId, isNotNull);
    });

    test(
      'piramide a giri: il secondo recupero solo fra un giro e l\'altro',
      () {
        final serie = leggiRigaSerie(
          '2 x (50-100-200) r15 r30',
          blocco: 'principale',
        )!;
        expect(serie.map((s) => s.distanzaM), [50, 100, 200, 50, 100, 200]);
        expect(serie.map((s) => s.recuperoS), [15, 15, 30, 15, 15, 15]);
      },
    );
  });

  group('detto a voce', () {
    test('"8 da 100", "recupero 20", "ripartenza 1:30", "passo 1:25"', () {
      final s = _una('8 da 100 stile libero B1 recupero 20 ripartenza 1:30');
      expect(s.ripetute, 8);
      expect(s.distanzaM, 100);
      expect(s.zona, 'B1');
      expect(s.recuperoS, 20);
      expect(s.ripartenzaS, 90);
      expect(s.note, isNull);
      expect(_una('4 per 50 dorso passo 0:40').passoObiettivoS, 40);
    });

    test('"20 secondi di recupero" e "ogni 1.30"', () {
      final s = _una('6 volte 50 gambe 15 secondi di recupero');
      expect(s.ripetute, 6);
      expect(s.esecuzione, 'gambe');
      expect(s.recuperoS, 15);
      expect(s.note, isNull);
      expect(_una('10 da 100 ogni 1.30').ripartenzaS, 90);
    });

    test('una frase dettata diventa una riga per serie', () {
      const frase =
          'riscaldamento 400 misti, poi 8 da 100 stile libero B1 recupero '
          '20. 200 dorso sciolto';
      expect(
        righeDaDettato(frase),
        'riscaldamento 400 misti\n8 da 100 stile libero B1 recupero 20\n'
        '200 dorso sciolto',
      );
      final scritto = interpretaAllenamento(righeDaDettato(frase));
      expect(scritto.righeNonCapite, 0);
      expect(scritto.metri, 400 + 800 + 200);
      // Il tempo "1.30" non si spezza.
      expect(righeDaDettato('8 da 100 ogni 1.30'), '8 da 100 ogni 1.30');
    });
  });

  group('tutto l\'allenamento', () {
    const testo = '''
Riscaldamento
400 mi A1
4x50 gambe r15

Principale
2x
3x200 sl B1 @3:00
4x75 do C1 r10

50-100-50 sl A2 r20
defat. 200 sl''';

    test('blocchi, "2x" ripetuto e piramide raggruppati', () {
      final scritto = interpretaAllenamento(testo);
      expect(scritto.righeNonCapite, 0);
      final serie = scritto.serie;
      expect(serie.map((s) => '${s.blocco} ${s.ripetute}x${s.distanzaM}'), [
        'riscaldamento 1x400',
        'riscaldamento 4x50',
        'principale 3x200',
        'principale 4x75',
        'principale 3x200',
        'principale 4x75',
        'principale 1x50',
        'principale 1x100',
        'principale 1x50',
        'defaticamento 1x200',
      ]);
      // Il "2x" è un gruppo, la piramide un altro, il resto da solo.
      expect(serie[0].piramideId, isNull);
      expect(serie.sublist(2, 6).map((s) => s.piramideId).toSet(), {
        serie[2].piramideId,
      });
      expect(serie[6].piramideId, isNot(serie[2].piramideId));
      expect(serie[6].piramideId, serie[8].piramideId);
      expect(serie[9].piramideId, isNull);
      expect(scritto.metri, 400 + 200 + 2 * (600 + 300) + 200 + 200);
    });

    test('ogni riga dice come è stata capita', () {
      final righe = interpretaAllenamento(testo).righe;
      expect(righe.map((r) => r.tipo), [
        TipoRiga.titolo,
        TipoRiga.serie,
        TipoRiga.serie,
        TipoRiga.vuota,
        TipoRiga.titolo,
        TipoRiga.giri,
        TipoRiga.serie,
        TipoRiga.serie,
        TipoRiga.vuota,
        TipoRiga.serie,
        TipoRiga.serie,
      ]);
      expect(righe[6].giri, 2);
      expect(righe[9].giri, 1);
      expect(righe.last.blocco, 'defaticamento');
    });

    test('righe non capite e "2x" senza niente sotto', () {
      final scritto = interpretaAllenamento('400 sl\nrespirazione\n3x\n\n');
      expect(scritto.serie, hasLength(1));
      expect(scritto.righeNonCapite, 2);
      expect(scritto.righe[1].problema, contains('Manca la distanza'));
      expect(scritto.righe[2].problema, contains('nessuna serie'));
    });

    test('senza titoli va tutto nel blocco principale', () {
      expect(
        interpretaAllenamento('400 sl\n8x50 do').serie.map((s) => s.blocco),
        ['principale', 'principale'],
      );
    });
  });

  group('dalle serie al testo, e ritorno', () {
    test('si legge come lo scriverebbe l\'allenatore', () {
      final serie = [
        _salvata(1, blocco: 'riscaldamento', distanzaM: 400, stile: 'misti'),
        _salvata(
          2,
          ripetute: 8,
          distanzaM: 100,
          zona: 'B1',
          recupero: 20,
          ripartenza: 90,
        ),
      ];
      expect(
        testoDaSerie(serie),
        'Riscaldamento\n400 mi\n\nPrincipale\n8x100 sl B1 @1:30 r20',
      );
    });

    test('nel lavoro di pallanuoto e a secco lo stile non si scrive', () {
      expect(
        testoDaSerie([
          _salvata(
            1,
            ripetute: 4,
            durataS: 300,
            esecuzione: 'pallanuoto tecnico-tattico',
            recupero: 60,
          ),
        ]),
        "Principale\n4x5' tecnico-tattico r60",
      );
    });

    test('ogni campo torna uguale', () {
      _tornaUguale([
        _salvata(1, blocco: 'riscaldamento', distanzaM: 400, zona: 'A1'),
        _salvata(
          2,
          ripetute: 6,
          distanzaM: 50,
          stile: 'delfino',
          esecuzione: 'gambe',
          zona: 'C2',
          passo: 85.5,
          recupero: 0,
          attrezzatura: 'pinne, palette',
          note: 'testa giù, gomito alto',
        ),
        _salvata(
          3,
          ripetute: 3,
          durataS: 330,
          esecuzione: 'remate',
          note: 'palla alta',
        ),
        _salvata(4, ripetute: 6, durataS: 30, zona: 'D', note: 'tutta'),
        _salvata(5, distanzaM: 15, stile: 'rana', zona: 'C'),
        _salvata(
          5,
          blocco: 'altro',
          durataS: 600,
          esecuzione: 'pallanuoto tecnico-tattico',
          attrezzatura: 'palloni da 5',
        ),
        _salvata(6, blocco: 'altro', durataS: 900, esecuzione: 'a secco'),
        _salvata(
          7,
          blocco: 'defaticamento',
          distanzaM: 200,
          stile: 'dorso',
          ripartenza: 45.25,
        ),
      ]);
    });

    test('piramidi e "2x" restano gruppi', () {
      _tornaUguale([
        // Piramide a due giri, con il recupero lungo fra i giri.
        for (final (i, d) in [50, 100, 50, 100].indexed)
          _salvata(
            i + 1,
            distanzaM: d,
            zona: 'A2',
            recupero: i == 1 ? 60 : 20,
            piramideId: 'p',
          ),
        // Un "2x" con due serie diverse.
        for (var i = 0; i < 4; i++)
          _salvata(
            5 + i,
            ripetute: i.isEven ? 3 : 4,
            distanzaM: i.isEven ? 200 : 75,
            stile: i.isEven ? 'libero' : 'dorso',
            piramideId: 'g',
          ),
        // Un gruppo che non si ripete né è una piramide.
        _salvata(9, ripetute: 2, distanzaM: 50, piramideId: 'x'),
        _salvata(10, ripetute: 4, distanzaM: 25, piramideId: 'x'),
        _salvata(11, distanzaM: 800),
      ]);
    });
  });

  group('salvataggio', () {
    var contatore = 0;
    String nuovoId() => 'nuovo${++contatore}';

    test('cambiando un numero si aggiorna solo quella serie', () {
      final vecchie = [
        _salvata(1, distanzaM: 400),
        _salvata(2, ripetute: 8, distanzaM: 100, zona: 'B1'),
      ];
      final scritte = interpretaAllenamento(
        testoDaSerie(vecchie).replaceFirst('8x100', '10x100'),
      ).serie;
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: scritte,
        nuovoId: nuovoId,
      );
      expect(piano.crea, isEmpty);
      expect(piano.elimina, isEmpty);
      expect(piano.aggiorna.single.vecchia.id, 's2');
      expect(piano.aggiorna.single.nuova.ripetute, 10);
    });

    test('senza modifiche non si tocca niente, gruppi compresi', () {
      final vecchie = [
        for (var i = 0; i < 4; i++)
          _salvata(i + 1, ripetute: 2, distanzaM: 50, piramideId: 'g'),
      ];
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: interpretaAllenamento(testoDaSerie(vecchie)).serie,
        nuovoId: nuovoId,
      );
      expect(piano.vuoto, isTrue);
    });

    test('righe in più si creano, quelle avanzate si eliminano', () {
      final vecchie = [_salvata(1), _salvata(2), _salvata(3)];
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: interpretaAllenamento('100 sl\n2x\n50 sl\n').serie,
        nuovoId: nuovoId,
      );
      // La 2 diventa il primo 50 del gruppo, la 3 il secondo.
      expect(piano.aggiorna.map((a) => a.vecchia.id), ['s2', 's3']);
      expect(piano.aggiorna.first.piramideId, startsWith('nuovo'));
      expect(piano.aggiorna.last.piramideId, piano.aggiorna.first.piramideId);
      expect(piano.crea, isEmpty);
      expect(piano.elimina, isEmpty);

      final accorciato = pianoSalvataggio(
        vecchie: vecchie,
        nuove: interpretaAllenamento('100 sl').serie,
        nuovoId: nuovoId,
      );
      expect(accorciato.elimina.map((s) => s.id), ['s2', 's3']);
    });
  });

  group('durata stimata', () {
    test('con la ripartenza conta solo quella', () {
      expect(secondiSerie(_una('10x100 sl @1:30')), 900);
    });

    test('senza: passo medio più recupero, gambe più lente', () {
      // 110 s ogni 100 m + 15 s di recupero tipico sui 100.
      expect(secondiPerRipetuta(_una('100 sl')), 110 + 15);
      expect(secondiPerRipetuta(_una('100 sl r10')), 110 + 10);
      expect(secondiPerRipetuta(_una('100 sl 1:20 r10')), 80 + 10);
      expect(secondiPerRipetuta(_una('100 gambe r0')), closeTo(143, 1e-9));
    });

    test('serie a tempo: durata più recupero', () {
      expect(secondiSerie(_una("3x5' r30")), 3 * 330);
    });

    test('minuti dell\'allenamento', () {
      final serie = interpretaAllenamento('10x100 @1:30\n2x\n5\' r60').serie;
      expect(minutiStimati(serie), 15 + 12);
    });
  });
}
