import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/editor_testo_allenamento.dart';
import 'package:flutter_test/flutter_test.dart';

Serie _salvata(
  int ordine, {
  int ripetute = 1,
  int distanzaM = 100,
  String? zona,
  String? piramideId,
  int? recuperoDopo,
  String blocco = 'principale',
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: 'nuoto',
  zona: zona,
  piramideId: piramideId,
  recuperoDopoS: recuperoDopo,
);

void main() {
  group('recupero fra una serie e la successiva', () {
    test('una riga con solo il recupero va dopo la serie sopra', () {
      final scritto = interpretaAllenamento(
        "4x100 B1\nrec 2'\n4x50 C1\npausa 1:30\n200 A1\nr30''\n"
        "100 sciolto\n2' di recupero",
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie.map((s) => s.recuperoDopoS), [120, 90, 30, 120]);
      expect(scritto.righe[1].tipo, TipoRiga.recupero);
      expect(scritto.righe[1].recuperoS, 120);
      // Il recupero non è una serie e non cambia i metri.
      expect(scritto.serie, hasLength(4));
      expect(scritto.metri, 400 + 200 + 200 + 100);
    });

    test('dentro un "2x" si ripete a ogni giro', () {
      final scritto = interpretaAllenamento(
        "2x\n4x100 B1\nrec 1'\n4x50 C1\nrec 2'\n\nrec 3'\n200 A1",
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie.map((s) => s.recuperoDopoS), [
        60,
        120,
        60,
        // Dopo l'ultimo giro, il recupero scritto fuori dal gruppo.
        180,
        null,
      ]);
    });

    test('senza una serie sopra è un errore, "400 recupero" no', () {
      final senza = interpretaAllenamento("rec 2'\n400 A1");
      expect(senza.righe.first.tipo, TipoRiga.errore);
      expect(senza.serie.single.recuperoDopoS, isNull);

      final gruppoVuoto = interpretaAllenamento("2x\nrec 1'\n4x50");
      expect(gruppoVuoto.righe[1].tipo, TipoRiga.errore);

      // Un numero senza unità prima di "recupero" non è un recupero.
      expect(
        interpretaAllenamento('400 recupero').righe.single.tipo,
        isNot(TipoRiga.recupero),
      );
    });

    test('il testo riscritto rimette i recuperi dove stavano', () {
      final serie = [
        _salvata(1, ripetute: 4, zona: 'B1', recuperoDopo: 120),
        _salvata(2, ripetute: 4, distanzaM: 50, zona: 'C1'),
        // Un "2x" con 1' fra i giri e 3' dopo l'ultimo.
        _salvata(3, piramideId: 'g', recuperoDopo: 60),
        _salvata(4, piramideId: 'g', recuperoDopo: 180),
        _salvata(5, distanzaM: 200, recuperoDopo: 30, blocco: 'defaticamento'),
      ];
      final testo = testoDaSerie(serie);
      expect(testo, contains("rec 2'"));
      expect(testo, contains("rec 30''"));
      final riletto = interpretaAllenamento(testo);
      expect(riletto.righeNonCapite, 0, reason: testo);
      expect(
        riletto.serie.map((s) => s.recuperoDopoS),
        serie.map((s) => s.recuperoDopoS),
        reason: testo,
      );
    });

    test('salvando, cambiare solo il recupero aggiorna la serie', () {
      final vecchie = [_salvata(1, ripetute: 4)];
      final nuove = interpretaAllenamento("4x100\nrec 1'").serie;
      final piano = pianoSalvataggio(
        vecchie: vecchie,
        nuove: nuove,
        nuovoId: () => 'x',
      );
      expect(piano.aggiorna.single.nuova.recuperoDopoS, 60);
    });

    test('il recupero conta nella durata stimata', () {
      final senza = interpretaAllenamento("10x100 @1:30\n10x100 @1:30").serie;
      final con = interpretaAllenamento("10x100 @1:30\nrec 3'\n10x100 @1:30")
          .serie;
      expect(minutiStimati(con), minutiStimati(senza) + 3);
    });

    test('a voce "recupero 20" resta della serie, "pausa" va fra le serie', () {
      expect(
        righeDaDettato('8 da 100 stile libero, recupero 20'),
        '8 da 100 stile libero recupero 20',
      );
      final scritto = interpretaAllenamento(
        righeDaDettato('8 da 100 stile libero, pausa 2 minuti, 4 da 50'),
      );
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie.first.recuperoDopoS, 120);
      expect(scritto.serie.first.recuperoS, isNull);
    });
  });

  group('volume dei blocchi nel compilatore', () {
    const testo =
        'Riscaldamento\n400 mix A1\n4x50 gambe\n\n'
        "Principale\n2x\n4x100 B1\nrec 1'\n\n10' palleggio\n\n"
        'Defaticamento 200 sciolto';

    test('ogni titolo ha il volume del suo blocco e il totale fin lì', () {
      final scritto = interpretaAllenamento(testo);
      final volumi = volumiPerBlocco(scritto);
      expect(volumi.keys, [0, 4, 11]);
      expect(volumi[0]!.blocco.metri, 600);
      expect(volumi[4]!.blocco.metri, 800);
      expect(volumi[4]!.blocco.secondi, 600);
      expect(volumi[4]!.totale.metri, 1400);
      // Titolo e serie sulla stessa riga.
      expect(volumi[11]!.blocco.metri, 200);
      expect(volumi[11]!.totale.metri, 1600);

      expect(etichettaBlocco(volumi[0]!), '600 m');
      expect(etichettaBlocco(volumi[4]!), "800 m + 10' · totale 1.400 m + 10'");
    });

    test('le serie prima del primo titolo contano solo nel totale', () {
      final volumi = volumiPerBlocco(
        interpretaAllenamento('400 A1\nPrincipale\n4x100'),
      );
      expect(volumi.keys, [1]);
      expect(volumi[1]!.blocco.metri, 400);
      expect(volumi[1]!.totale.metri, 800);
    });
  });
}
