// Prove sui numeri (piano, punto 15): un "2x" non si moltiplica due volte.
//
// Nel testo, "2x" sopra un gruppo di righe lo ripete. Le serie lette
// (`AllenamentoScritto.serie`) hanno già le ripetizioni, una riga di testo
// (`RigaScritta.serie`) le ha una volta sola e `RigaScritta.giri` dice
// quante volte si ripete: chi conta i metri non deve né saltare i giri né
// contarli due volte (una volta nelle serie ripetute, un'altra con i giri).
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/libreria_blocchi/application/excel_export.dart';
import 'package:coach_vasca/features/libreria_blocchi/application/excel_import.dart';
import 'package:coach_vasca/features/libreria_blocchi/domain/training_block.dart';
import 'package:flutter_test/flutter_test.dart';

AllenamentoScritto _leggi(String testo) {
  final scritto = interpretaAllenamento(testo);
  expect(scritto.righeNonCapite, 0, reason: testo);
  return scritto;
}

/// Metri di ogni blocco del testo, nell'ordine.
List<int> _metriPerBlocco(AllenamentoScritto scritto) => [
  for (final b in volumiPerBlocco(scritto).values) b.blocco.metri,
];

/// Metri di tutte le righe di serie del testo con i loro giri: come
/// `volumiPerBlocco`, ma senza guardare i titoli.
int _metriDelleRighe(AllenamentoScritto scritto) => scritto.righe
    .where((r) => r.tipo == TipoRiga.serie)
    .fold<int>(0, (t, r) => t + r.giri * volumeDi(r.serie).metri);

/// Le serie riscritte a testo e rilette: stesse righe, stessi metri.
void _andataERitorno(AllenamentoScritto scritto) {
  final riscritto = testoDaSerie(scritto.serie);
  final dopo = _leggi(riscritto);
  expect(dopo.serie.length, scritto.serie.length, reason: riscritto);
  for (var i = 0; i < scritto.serie.length; i++) {
    expect(
      stessaSerie(dopo.serie[i], scritto.serie[i]),
      isTrue,
      reason: 'serie $i in\n$riscritto',
    );
    expect(
      dopo.serie[i].piramideId == null,
      scritto.serie[i].piramideId == null,
      reason: 'gruppo della serie $i in\n$riscritto',
    );
  }
  expect(dopo.metri, scritto.metri, reason: riscritto);
  expect(_metriPerBlocco(dopo), _metriPerBlocco(scritto), reason: riscritto);
  // E una seconda volta il testo non cambia.
  expect(testoDaSerie(dopo.serie), riscritto);
}

void main() {
  group('"2x" sopra due righe', () {
    const testo = 'Principale\n2x\n4x50 sl\n100 sl';

    test('le serie sono quattro, dello stesso gruppo: 600 m', () {
      final scritto = _leggi(testo);
      expect(scritto.serie, hasLength(4));
      expect([for (final s in scritto.serie) s.ripetute], [4, 1, 4, 1]);
      expect([for (final s in scritto.serie) s.distanzaM], [50, 100, 50, 100]);
      expect({for (final s in scritto.serie) s.piramideId}, hasLength(1));
      expect(scritto.serie.first.piramideId, isNotNull);
      expect(scritto.metri, 600);
    });

    test('il blocco conta 600 e non 1200', () {
      final scritto = _leggi(testo);
      final volumi = volumiPerBlocco(scritto);
      expect(volumi, hasLength(1));
      expect(volumi.values.single.blocco.metri, 600);
      expect(volumi.values.single.totale.metri, 600);
    });

    test('la riga "2x" e le righe dentro contano una volta sola', () {
      final scritto = _leggi(testo);
      final righe = scritto.righe;
      expect(righe.map((r) => r.tipo), [
        TipoRiga.titolo,
        TipoRiga.giri,
        TipoRiga.serie,
        TipoRiga.serie,
      ]);
      expect(righe[1].giri, 2);
      // Ogni riga di serie ha la sua serie una volta e i giri a parte.
      expect(righe[2].serie, hasLength(1));
      expect(righe[2].giri, 2);
      expect(righe[3].serie, hasLength(1));
      expect(righe[3].giri, 2);
      // 2 × 200 + 2 × 100: la riga "2x" non aggiunge nulla.
      expect(_metriDelleRighe(scritto), 600);
      expect(righe[1].serie, isEmpty);
    });

    test('riscritto e riletto: stesse righe, stessi metri', () {
      _andataERitorno(_leggi(testo));
    });

    test('riscritto è un "2x" solo, non due gruppi', () {
      final riscritto = testoDaSerie(_leggi(testo).serie);
      expect(riscritto, testo);
    });
  });

  group('altri "Nx"', () {
    test('3x sopra una riga sola: 300 m, non 900', () {
      final scritto = _leggi('Principale\n3x\n100 sl');
      expect(scritto.serie, hasLength(3));
      expect({for (final s in scritto.serie) s.piramideId}, hasLength(1));
      expect(scritto.metri, 300);
      expect(_metriPerBlocco(scritto), [300]);
      _andataERitorno(scritto);
    });

    test('2x sopra una riga che ha già le ripetizioni: 400 m', () {
      final scritto = _leggi('Principale\n2x\n4x50 sl');
      // Due volte "4×50": due serie, non otto né quattro.
      expect(scritto.serie, hasLength(2));
      expect([for (final s in scritto.serie) s.ripetute], [4, 4]);
      expect(scritto.metri, 400);
      expect(_metriPerBlocco(scritto), [400]);
      _andataERitorno(scritto);
    });

    test('un "2x" dopo un "8x100" non si porta dietro i suoi metri', () {
      final scritto = _leggi('Principale\n8x100 sl\n\n2x\n4x50 sl');
      expect(scritto.metri, 800 + 400);
      expect(_metriPerBlocco(scritto), [1200]);
      _andataERitorno(scritto);
    });

    test('due "2x" di seguito hanno gruppi diversi: 200 + 400', () {
      final scritto = _leggi('Principale\n2x\n100 sl\n\n2x\n200 sl');
      expect(scritto.serie, hasLength(4));
      final gruppi = [for (final s in scritto.serie) s.piramideId];
      expect(gruppi[0], gruppi[1]);
      expect(gruppi[2], gruppi[3]);
      expect(gruppi[0], isNot(gruppi[2]));
      expect(scritto.metri, 600);
      expect(_metriPerBlocco(scritto), [600]);
      _andataERitorno(scritto);
    });

    test('"1x" non ripete e non fa un gruppo', () {
      final scritto = _leggi('Principale\n1x\n100 sl');
      expect(scritto.serie, hasLength(1));
      expect(scritto.serie.single.piramideId, isNull);
      expect(scritto.metri, 100);
    });

    test('"2x" con un recupero dopo la serie: i metri non cambiano', () {
      final scritto = _leggi("Principale\n2x\n4x50 sl\nrec 1'\n100 sl");
      expect(scritto.metri, 600);
      expect(_metriPerBlocco(scritto), [600]);
      _andataERitorno(scritto);
    });

    test('"2x" dentro un blocco con titolo e dopo altri blocchi: i totali', () {
      final scritto = _leggi(
        'Riscaldamento\n400 sl\n\n'
        'Principale\n2x\n4x50 sl\n100 sl\n\n'
        'Defaticamento\n200 sl',
      );
      expect(scritto.metri, 400 + 600 + 200);
      final volumi = volumiPerBlocco(scritto).values.toList();
      expect([for (final b in volumi) b.blocco.metri], [400, 600, 200]);
      // Il totale è la somma di quanto c'è fino a lì, non di più.
      expect([for (final b in volumi) b.totale.metri], [400, 1000, 1200]);
      _andataERitorno(scritto);
    });
  });

  group('piramidi', () {
    test('50-100-200-100-50 sono 500 m, una volta sola', () {
      final scritto = _leggi('Principale\n50-100-200-100-50 sl');
      expect(scritto.serie, hasLength(5));
      expect({for (final s in scritto.serie) s.piramideId}, hasLength(1));
      expect(scritto.metri, 500);
      expect(_metriPerBlocco(scritto), [500]);
      expect(scritto.righe.last.giri, 1);
      _andataERitorno(scritto);
    });

    test('2x(50-100) con i giri sono 300 m', () {
      final scritto = _leggi('Principale\n2x(50-100) sl');
      expect([for (final s in scritto.serie) s.distanzaM], [50, 100, 50, 100]);
      expect({for (final s in scritto.serie) s.piramideId}, hasLength(1));
      expect(scritto.metri, 300);
      // I giri sono già nelle righe: la riga ne ha 1, non 2.
      expect(scritto.righe.last.giri, 1);
      expect(_metriPerBlocco(scritto), [300]);
      _andataERitorno(scritto);
    });

    test('una piramide dentro un "2x" conta due volte, non quattro', () {
      final scritto = _leggi('Principale\n2x\n50-100-50 sl');
      expect(scritto.serie, hasLength(6));
      expect(scritto.metri, 2 * 200);
      expect(_metriPerBlocco(scritto), [400]);
      _andataERitorno(scritto);
    });

    test('2x(50-100) dentro un "2x": 2 × 300 = 600 m', () {
      final scritto = _leggi('Principale\n2x\n2x(50-100) sl');
      expect(scritto.serie, hasLength(8));
      expect(scritto.metri, 600);
      expect(_metriPerBlocco(scritto), [600]);
      _andataERitorno(scritto);
    });
  });

  group('blocchi della libreria', () {
    TrainingBlock blocco({required int metriScritti}) => TrainingBlock(
      id: 'b1',
      clubId: 'c',
      codice: 'N-901',
      sport: 'nuoto',
      fase: 'Serie principale',
      obiettivo: 'Aerobico',
      zoneCoinvolte: 'A2',
      titolo: '2 giri di 4x50',
      descrizione: '2 giri di 4x50 sl',
      stilePrincipale: 'Libero',
      livelli: 'Ragazzi',
      attrezzi: null,
      metriTotali: metriScritti,
      durataStimataMin: 10,
      note: null,
      stato: 'approvato',
      fonte: 'Allenatore',
      modificatoInApp: true,
    );

    TrainingBlockParte parte(
      int ordine, {
      required int giri,
      required int ripetizioni,
      required int distanzaM,
    }) => TrainingBlockParte(
      id: 'p$ordine',
      bloccoId: 'b1',
      clubId: 'c',
      ordine: ordine,
      giri: giri,
      ripetizioni: ripetizioni,
      distanzaM: distanzaM,
      stile: 'Libero',
      esercizio: 'libero',
      zona: 'A2',
      esecuzione: 'nuoto',
      recuperoS: 20,
    );

    BloccoImportato importa(List<TrainingBlockParte> parti) {
      // Il numero scritto nella cella è sbagliato di proposito: l'importazione
      // lo ricalcola dalle parti.
      final bytes = generaExcelLibreria(
        [blocco(metriScritti: 9999)],
        {'b1': parti},
      );
      final risultato = parseLibreriaExcel(bytes);
      expect(risultato.errori, isEmpty);
      return risultato.blocchi.single;
    }

    test('giri 2 × 4 ripetizioni × 50 m = 400 m, non 200 né 1600', () {
      final b = importa([parte(1, giri: 2, ripetizioni: 4, distanzaM: 50)]);
      expect(b.parti.single.giri, 2);
      expect(b.parti.single.ripetizioni, 4);
      expect(b.metriTotali, 400);
    });

    test('più parti con giri diversi si sommano: 400 + 100 = 500 m', () {
      final b = importa([
        parte(1, giri: 2, ripetizioni: 4, distanzaM: 50),
        parte(2, giri: 1, ripetizioni: 1, distanzaM: 100),
      ]);
      expect(b.metriTotali, 500);
    });

    test('il blocco scritto da un "2x" del testo vale quanto il testo', () {
      // Le righe di "2x(4x50)" salvate come parti: un giro per riga, come
      // fa "Salva come blocco" (giri 1 e le ripetizioni della serie).
      final scritto = _leggi('Principale\n2x\n4x50 sl');
      final parti = [
        for (final (i, s) in scritto.serie.indexed)
          parte(i + 1, giri: 1, ripetizioni: s.ripetute, distanzaM: 50),
      ];
      expect(importa(parti).metriTotali, scritto.metri);
    });
  });
}
