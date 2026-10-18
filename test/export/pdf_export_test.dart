import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/export/pdf_allenamento.dart';
import 'package:coach_vasca/features/export/pdf_export.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le serie come le salva l'app: id, ordine e ogni campo copiato dal testo.
List<Serie> serieDaTesto(String testo) {
  final scritte = interpretaAllenamento(testo).serie;
  return [
    for (final (i, s) in scritte.indexed)
      Serie(
        id: 's$i',
        allenamentoId: 'a',
        clubId: 'c',
        ordine: i + 1,
        blocco: s.blocco,
        ripetute: s.ripetute,
        distanzaM: s.distanzaM,
        durataS: s.durataS,
        stile: s.stile,
        esecuzione: s.esecuzione,
        zona: s.zona,
        passoObiettivoS: s.passoObiettivoS,
        recuperoS: s.recuperoS,
        ripartenzaS: s.ripartenzaS,
        attrezzatura: s.attrezzatura,
        note: s.note,
        piramideId: s.piramideId,
        recuperoDopoS: s.recuperoDopoS,
        destinatari: s.destinatari,
        momentoId: s.momentoId,
      ),
  ];
}

const testoCompleto = '''
Riscaldamento
6x100 sl A2 @2:00 "ultimo 25 mix a rotazione no sl"
4x100 sl A2 @2:15 "ultimo 25 gambe"

Principale
3x
50 sl A1 sciolto
6x100 sl B1 @1:40 "1°serie ultimo 25 forte, 2°serie ultimo 25 no respiro, 3°serie 2 salti all'inizio di ogni 25"

Tutti
10' palleggio
10' tiri A2
Centroboa
20' gambe spostamenti con cinture

Tutti
30' tecnico-tattico A2 "gioco a una porta, pressing in anticipo"

Defaticamento
200 sl A1 lungo
''';

RigaPdf riga(ElementoPdf e) => e as RigaPdf;

void main() {
  group('sezioniPdf', () {
    final sezioni = sezioniPdf(serieDaTesto(testoCompleto));

    test('una sezione per blocco, nell\'ordine delle serie', () {
      expect(sezioni.map((s) => s.titolo), [
        'Riscaldamento',
        'Principale',
        'Defaticamento',
      ]);
    });

    test('i metri del blocco sono quelli del gruppo', () {
      expect(sezioni[0].metri, 1000);
      // 3 × (50 + 6×100) = 1950, senza il lavoro dei centroboa.
      expect(sezioni[1].metri, 1950);
      expect(sezioni[2].metri, 200);
      expect(sezioni[0].riepilogo, '1.000 m');
      // 10' palleggio + 10' tiri + 30' tecnico-tattico a tempo.
      expect(sezioni[1].riepilogo, "1.950 m + 50'");
    });

    test('volume: niente "1×", durate, ripartenza e recupero', () {
      final risc = sezioni[0].elementi.cast<RigaPdf>();
      expect(risc[0].volume, '6×100');
      expect(risc[0].lavoro, 'Libero');
      expect(risc[0].zona, 'A2');
      expect(risc[0].partenza, '@2:00');
      expect(risc[1].partenza, '@2:15');
      expect(risc[0].note, 'ultimo 25 mix a rotazione no sl');

      final defat = sezioni[2].elementi.cast<RigaPdf>().single;
      expect(defat.volume, '200');

      final serie = serieDaTesto('Principale\n4x50 r15 gambe\n3x5\' tiri r1\'');
      final righe = sezioniPdf(serie).single.elementi.cast<RigaPdf>();
      expect(righe[0].volume, '4×50');
      expect(righe[0].lavoro, 'Libero gambe');
      expect(righe[0].partenza, "r15''");
      expect(righe[1].volume, "3×5'");
      expect(righe[1].partenza, "r1'");
    });

    test('un "3x" si vede una volta, con il suo periodo rientrato', () {
      final principale = sezioni[1].elementi;
      final ripeti = principale.whereType<RipetiPdf>().single;
      expect(ripeti.volte, 3);
      expect(ripeti.testo, '3×');
      final i = principale.indexOf(ripeti);
      expect(riga(principale[i + 1]).volume, '50');
      expect(riga(principale[i + 1]).livello, 1);
      expect(riga(principale[i + 2]).volume, '6×100');
      expect(riga(principale[i + 2]).partenza, '@1:40');
      expect(riga(principale[i + 2]).livello, 1);
      // Le copie non ci sono: le due righe del periodo e, dopo il
      // momento in parallelo, il tecnico-tattico.
      expect(principale.whereType<RigaPdf>().length, 3);
    });

    test('un momento è diviso in colonne con la loro testata', () {
      final parallela = sezioni[1].elementi.whereType<ParallelaPdf>().single;
      expect(parallela.colonne.map((c) => c.titolo), ['Tutti', 'Centroboa']);
      final tutti = parallela.colonne[0].elementi.cast<RigaPdf>();
      expect(tutti.map((r) => r.volume), ["10'", "10'"]);
      expect(tutti.map((r) => r.lavoro), ['Palleggio', 'Tiri']);
      expect(tutti[1].zona, 'A2');
      final centroboa = parallela.colonne[1].elementi.cast<RigaPdf>().single;
      expect(centroboa.volume, "20'");
      expect(centroboa.lavoro, 'Libero gambe');
      expect(parallela.colonne[0].minuti, greaterThan(0));
    });

    test('le serie dopo il momento tornano a una riga sola', () {
      final dopo = sezioni[1].elementi.last as RigaPdf;
      expect(dopo.volume, "30'");
      expect(dopo.lavoro, 'Tecnico-tattico');
      expect(dopo.zona, 'A2');
      expect(dopo.note, 'gioco a una porta, pressing in anticipo');
    });
  });

  group('casi particolari', () {
    test('il recupero dopo una serie è una riga a parte', () {
      final serie = serieDaTesto("Principale\n4x100 B1\nrec 2'\n200 A1");
      final elementi = sezioniPdf(serie).single.elementi;
      expect(elementi[0], isA<RigaPdf>());
      expect((elementi[1] as RecuperoPdf).testo, "Recupero 2'");
      expect(riga(elementi[2]).volume, '200');
    });

    test('una piramide è una riga sola', () {
      final serie = serieDaTesto('Principale\n50-100-200-100-50 sl B1 r20');
      final elementi = sezioniPdf(serie).single.elementi;
      expect(elementi, hasLength(1));
      expect(riga(elementi.single).volume, '50-100-200-100-50');
      expect(riga(elementi.single).partenza, "r20''");
    });

    test('una serie per i soli portieri ha l\'etichetta nelle note', () {
      final serie = serieDaTesto(
        'Principale\n8x100 A2 "forte"\nPortieri\n3x6\' parate',
      );
      final righe = sezioniPdf(serie).single.elementi;
      // Con "Portieri" subito dopo è un momento in parallelo, non una
      // serie per alcuni: le colonne portano il nome.
      expect(righe.single, isA<ParallelaPdf>());
      final soli = sezioniPdf(
        [
          Serie(
            id: 's',
            allenamentoId: 'a',
            clubId: 'c',
            ordine: 1,
            blocco: 'principale',
            ripetute: 4,
            distanzaM: 50,
            stile: 'libero',
            esecuzione: 'nuoto',
            destinatari: Destinatari.solo(const ['x']),
          ),
        ],
        nomiAtleti: const {'x': 'Rossi'},
      );
      expect(riga(soli.single.elementi.single).note, 'Solo rossi');
    });

    test('senza serie non ci sono sezioni', () {
      expect(sezioniPdf(const []), isEmpty);
      expect(totaliPdf(const []), '');
    });

    test('i totali: metri e durata stimata', () {
      final totali = totaliPdf(serieDaTesto(testoCompleto));
      expect(totali, startsWith('3.150 m · circa '));
      expect(totali, endsWith("'"));
    });
  });

  group('generaPdf', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final allenamento = Allenamento(
      id: 'a',
      clubId: 'c',
      data: DateTime(2026, 10, 20, 18, 30),
      titolo: 'Martedì di soglia',
      gruppoId: 'g',
      note: 'Portare i palloni a bordo vasca.',
    );

    test('scrive un PDF per un allenamento completo', () async {
      final bytes = await generaPdf(
        [(allenamento, serieDaTesto(testoCompleto))],
        nomiGruppi: const {'g': 'Under 15'},
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('senza serie scrive comunque il PDF', () async {
      final bytes = await generaPdf([(allenamento, const [])]);
      expect(bytes, isNotEmpty);
    });
  });
}
