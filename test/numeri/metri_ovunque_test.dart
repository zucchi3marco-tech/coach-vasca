// Prove sui numeri (piano, punto 15): una seduta divisa in parallelo, con un
// "2x" e la variante di un atleta, deve dare gli stessi metri in ogni posto
// dell'app che li mostra o li usa. Un numero che sembra credibile ma è
// sbagliato (le colonne sommate, un "2x" moltiplicato due volte) è peggio di
// un errore che si vede.
//
// La seduta è in `seduta_divisa.dart`: gruppo 2000 m, portiere 1500 m,
// Rossi 2200 m.
import 'package:coach_vasca/features/ai_genera/application/storico_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/durata_serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/prossimo_allenamento.dart'
    show metriTotaliSerie;
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/riepilogo_volumi.dart'
    show RiepilogoVolumi;
import 'package:coach_vasca/features/allenamenti/presentation/riga_gruppo_piramide.dart';
import 'package:coach_vasca/features/assistente/domain/pseudonimi.dart';
import 'package:coach_vasca/features/assistente/domain/strumenti_assistente.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/domain/volumi_atleta.dart';
import 'package:coach_vasca/features/export/application/excel_dati_club.dart';
import 'package:coach_vasca/features/export/domain/dati_club.dart';
import 'package:coach_vasca/features/export/domain/periodo_dati.dart';
import 'package:coach_vasca/features/export/pdf_allenamento.dart'
    show sezioniPdf, totaliPdf;
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'seduta_divisa.dart';

/// I metri di [serie] per l'atleta [id] con il [ruolo].
int _metriDi(Iterable<DatiSerie> serie, String? id, String? ruolo) =>
    volumeDi(serieDellAtleta(serie, id, ruolo)).metri;

/// Riscritta a testo e riletta: le serie come le rimette l'editor.
AllenamentoScritto _riletta(Iterable<DatiSerie> serie) => interpretaAllenamento(
  testoDaSerie(serie.toList(), atleti: atletiSeduta),
  atleti: atletiSeduta,
);

void main() {
  group('la regola dei momenti sulla seduta di prova', () {
    test('il gruppo fa 2000 m: né i portieri né la variante di Rossi', () {
      expect(volumeDi(serieDelGruppo(serieSeduta)).metri, metriGruppo);
      expect(volumiPerAllenamento(serieSeduta)[idAllenamento]?.metri, 2000);
    });

    test(
      'un portiere fa 1500 m: la sua colonna al posto di quella di tutti',
      () {
        // Nel momento m1 il portiere non fa l'8×100 ma le sue gambe.
        expect(_metriDi(serieSeduta, idPortiere, 'portiere'), metriPortiere);
        expect(volumeDi(serieDeiPortieri(serieSeduta)).metri, metriPortiere);
        // Qualunque portiere, anche senza sapere chi.
        expect(_metriDi(serieSeduta, null, 'portiere'), metriPortiere);
      },
    );

    test('Rossi fa 2200 m: il gruppo più la sua variante', () {
      expect(_metriDi(serieSeduta, idRossi, 'movimento'), metriRossi);
      // Senza ruolo indicato conta come movimento.
      expect(_metriDi(serieSeduta, idRossi, null), metriRossi);
    });

    test('un altro giocatore di movimento fa 2000 m', () {
      expect(_metriDi(serieSeduta, idAltro, 'movimento'), 2000);
      expect(_metriDi(serieSeduta, idAltro, null), 2000);
    });

    test('la variante di Rossi non finisce ai portieri né al gruppo', () {
      final delPortiere = serieDellAtleta(serieSeduta, idPortiere, 'portiere');
      final delGruppo = serieDelGruppo(serieSeduta);
      expect(delPortiere.any((s) => s.ordine == 8), isFalse);
      expect(delGruppo.any((s) => s.ordine == 8), isFalse);
      // E l'8×100 di tutti non è del portiere, le gambe non sono del gruppo.
      expect(delPortiere.any((s) => s.ordine == 2), isFalse);
      expect(delGruppo.any((s) => s.ordine == 3), isFalse);
    });
  });

  group('testata del dettaglio, bordo vasca e PDF', () {
    test('la testata e il bordo vasca contano il gruppo', () {
      // Le due schermate calcolano volumeDi(serieDelGruppo(serie)).metri.
      expect(volumeDi(serieDelGruppo(serieSeduta)).metri, 2000);
    });

    test('l\'intestazione del PDF dice 2.000 m', () {
      expect(totaliPdf(serieSeduta), startsWith('2.000 m'));
    });

    test('le sezioni del PDF sommano a 2000, blocco per blocco', () {
      final sezioni = sezioniPdf(serieSeduta);
      expect(
        [for (final s in sezioni) s.blocco],
        ['riscaldamento', 'principale', 'defaticamento'],
      );
      // Il "2x" conta una volta (600) e l'8×100 una volta (800).
      expect([for (final s in sezioni) s.metri], [400, 1400, 200]);
      expect(sezioni.fold<int>(0, (t, s) => t + s.metri), 2000);
    });

    test('la scheda dell\'atleta somma le sue serie: 1500, 2200, 2000', () {
      // Il server dà a ogni atleta solo le serie che fa lui; la home le
      // somma tutte con metriTotaliSerie.
      expect(
        metriTotaliSerie(serieDellAtleta(serieSeduta, idPortiere, 'portiere')),
        1500,
      );
      expect(
        metriTotaliSerie(serieDellAtleta(serieSeduta, idRossi, 'movimento')),
        2200,
      );
      expect(
        metriTotaliSerie(serieDellAtleta(serieSeduta, idAltro, 'movimento')),
        2000,
      );
    });
  });

  group('dal testo al testo', () {
    test('la seduta scritta a mano è la stessa delle serie salvate', () {
      final scritto = interpretaAllenamento(testoSeduta, atleti: atletiSeduta);
      expect(scritto.righeNonCapite, 0);
      expect(scritto.serie, hasLength(serieSeduta.length));
      for (var i = 0; i < serieSeduta.length; i++) {
        expect(
          stessaSerie(scritto.serie[i], serieSeduta[i]),
          isTrue,
          reason: 'serie $i',
        );
      }
      expect(scritto.metri, 2000);
      expect(_metriDi(scritto.serie, idPortiere, 'portiere'), 1500);
      expect(_metriDi(scritto.serie, idRossi, 'movimento'), 2200);
      expect(_metriDi(scritto.serie, idAltro, 'movimento'), 2000);
    });

    test('serie → testo → serie: stessi metri per gruppo e portiere', () {
      final scritto = _riletta(serieSeduta);
      expect(scritto.righeNonCapite, 0);
      expect(scritto.metri, 2000);

      final blocchi = volumiPerBlocco(scritto).values.toList();
      // Un blocco per titolo: i metri del gruppo, una volta sola.
      expect([for (final b in blocchi) b.blocco.metri], [400, 1400, 200]);
      expect(blocchi.fold<int>(0, (t, b) => t + b.blocco.metri), 2000);
      // Il totale corre fino a quello di tutto l'allenamento.
      expect(blocchi.last.totale.metri, 2000);

      expect(_metriDi(scritto.serie, null, 'movimento'), 2000);
      expect(_metriDi(scritto.serie, idPortiere, 'portiere'), 1500);
      expect(_metriDi(scritto.serie, idAltro, 'movimento'), 2000);
    });

    // Senza la riga "Tutti" prima della variante, riletta diventava una
    // colonna in parallelo con il "2x" e Rossi faceva 1600 m (errore
    // trovato da queste prove il 2026-10-20).
    test('serie → testo → serie: Rossi fa ancora 2200 m', () {
      final scritto = _riletta(serieSeduta);
      expect(_metriDi(scritto.serie, idRossi, 'movimento'), 2200);
      // Il gruppo non se ne accorge: per questo l'errore non si vedeva.
      expect(scritto.metri, 2000);
    });

    test('il testo è stabile: riscritto una seconda volta non cambia', () {
      final primo = testoDaSerie(serieSeduta, atleti: atletiSeduta);
      final scritto = interpretaAllenamento(primo, atleti: atletiSeduta);
      final secondo = testoDaSerie(scritto.serie, atleti: atletiSeduta);
      expect(secondo, primo);

      final ancora = interpretaAllenamento(secondo, atleti: atletiSeduta);
      expect(ancora.metri, 2000);
      expect(_metriDi(ancora.serie, idPortiere, 'portiere'), 1500);
      expect(volumiPerBlocco(ancora).values.last.totale.metri, 2000);
    });

    test('le righe riscritte mantengono il momento dei portieri', () {
      final scritto = _riletta(serieSeduta);
      expect(scritto.serie[1].momentoId, isNotNull);
      expect(scritto.serie[1].momentoId, scritto.serie[2].momentoId);
      expect(scritto.serie[2].destinatari, Destinatari.portieri);
      // Il riscaldamento e il defaticamento non sono in nessun momento.
      expect(scritto.serie.first.momentoId, isNull);
      expect(scritto.serie.last.momentoId, isNull);
      expect(scritto.serie[7].destinatari, const Destinatari.solo([idRossi]));
    });

    test(
      'le righe riscritte non mettono il "2x" e la variante in parallelo',
      () {
        final scritto = _riletta(serieSeduta);
        for (final i in [3, 4, 5, 6, 7]) {
          expect(scritto.serie[i].momentoId, isNull, reason: 'serie $i');
        }
      },
    );

    test(
      'due lavori di alcuni, uno dopo l\'altro, restano uno dopo l\'altro',
      () {
        // Una variante per Rossi e poi il lavoro dei soli portieri, senza
        // nessun lavoro in parallelo: riscritti, non diventano un momento.
        final serie = [
          serieSeduta.first,
          for (final s in serieSeduta.where((s) => s.momentoId == null))
            if (!s.destinatari.base) s,
          Serie(
            id: 'p1',
            allenamentoId: idAllenamento,
            clubId: 'c1',
            ordine: 99,
            blocco: 'principale',
            ripetute: 4,
            distanzaM: 25,
            stile: 'libero',
            esecuzione: 'gambe',
            destinatari: Destinatari.portieri,
          ),
        ];
        final scritto = _riletta(serie);
        expect(scritto.righeNonCapite, 0);
        expect(scritto.serie.every((s) => s.momentoId == null), isTrue);
        expect(scritto.serie.map((s) => s.destinatari), [
          for (final s in serie) s.destinatari,
        ]);
      },
    );
  });

  group('settimane, Excel, assistente, storico per l\'AI', () {
    test('la settimana somma i volumi dei gruppi: 2000 + 1000 = 3000', () {
      final seconda = Allenamento(
        id: 'a2',
        clubId: 'c1',
        data: DateTime(2026, 10, 16),
        gruppoId: 'u14',
      );
      final prossimaSettimana = Allenamento(
        id: 'a3',
        clubId: 'c1',
        data: DateTime(2026, 10, 19),
        gruppoId: 'u14',
      );
      final serie = [
        ...serieSeduta,
        serieDi(1, 'principale', 1, 1000, allenamentoId: 'a2'),
        serieDi(1, 'principale', 5, 100, allenamentoId: 'a3'),
      ];
      final settimane = volumiPerSettimana([
        allenamentoSeduta,
        seconda,
        prossimaSettimana,
      ], volumiPerAllenamento(serie));
      final questa = settimane[lunediDi(DateTime(2026, 10, 14))]!;
      expect(questa.volume.metri, 3000);
      expect(questa.allenamenti, 2);
      final dopo = settimane[lunediDi(DateTime(2026, 10, 19))]!;
      expect(dopo.volume.metri, 500);
      expect(dopo.allenamenti, 1);
    });

    test('l\'Excel del club scrive 2000 nei metri della seduta', () {
      final bytes = fileExcelDatiClub(
        DatiClub(allenamenti: [allenamentoSeduta], serie: serieSeduta),
        nomeClub: 'Club',
        scaricatoDa: 'Coach',
        adesso: DateTime(2026, 10, 18, 14),
        periodo: const PeriodoDati.stagione(2026),
        conBenessere: false,
      );
      final foglio = Excel.decodeBytes(bytes).tables['Allenamenti']!;
      final titoli = [for (final c in foglio.rows.first) c?.value.toString()];
      final riga = foglio.rows[1];
      expect(riga[titoli.indexOf('Metri')]?.value, const IntCellValue(2000));
      expect(foglio.rows, hasLength(2));
    });

    test('l\'assistente risponde con 2000 m per la seduta', () async {
      final strumenti = StrumentiAssistente(
        fonte: _Fonte(),
        pseudonimi: Pseudonimi(atletiSeduta),
        oggi: DateTime(2026, 10, 16, 18),
      );
      final esito = await strumenti.esegui('allenamenti', const {
        'da': '2026-10-14',
        'a': '2026-10-14',
      });
      final sedute = esito.perModello['sedute']! as List;
      expect(sedute, hasLength(1));
      expect((sedute.single as Map)['metri'], 2000);
    });

    test('lo storico per l\'AI conta 2000 m per la seduta', () {
      final riassunto = calcolaRiassunto(
        [allenamentoSeduta],
        {idAllenamento: serieSeduta},
      );
      expect(riassunto.volumeMedioPerSedutaM, 2000);
      // Le quote sui 2000 m del gruppo: 400, 1400, 200.
      expect(riassunto.percentualeMetriPerBlocco, {
        'riscaldamento': closeTo(20, 1e-9),
        'principale': closeTo(70, 1e-9),
        'defaticamento': closeTo(10, 1e-9),
      });
    });
  });

  group('carico di ogni atleta', () {
    final righe = righeCarico(serieSeduta);

    test('i metri per atleta: portiere 1500, Rossi 2200, altri 2000', () {
      VolumiAtleta di(String id, String? ruolo) => VolumiAtleta.daSerie(
        righe,
        {idAllenamento},
        atletaId: id,
        ruolo: ruolo,
      );
      expect(di(idPortiere, 'portiere').volumeTotaleM, 1500);
      expect(di(idRossi, 'movimento').volumeTotaleM, 2200);
      expect(di(idRossi, null).volumeTotaleM, 2200);
      expect(di(idAltro, 'movimento').volumeTotaleM, 2000);
    });

    test('le righe del server tornano le stesse destinatari e momenti', () {
      final lette = [for (final r in righe) SerieCarico.fromMap(r)];
      expect(lette[2].destinatari, Destinatari.portieri);
      expect(lette[7].destinatari, const Destinatari.solo([idRossi]));
      expect(lette[1].momentoId, 'm1');
      expect(volumeDi(serieDelGruppo(lette)).metri, 2000);
    });

    test('per zona e per esecuzione si somma quanto il totale', () {
      final portiere = VolumiAtleta.daSerie(
        righe,
        {idAllenamento},
        atletaId: idPortiere,
        ruolo: 'portiere',
      );
      // Il portiere: 400 (A1) + 300 gambe + 600 + 200.
      expect(portiere.perZona, {'A1': 400});
      expect(portiere.perEsecuzione, {'nuoto': 1200, 'gambe': 300});
      final rossi = VolumiAtleta.daSerie(
        righe,
        {idAllenamento},
        atletaId: idRossi,
        ruolo: 'movimento',
      );
      expect(rossi.perEsecuzione, {'nuoto': 2000, 'gambe': 200});
      expect(rossi.perEsecuzione.values.fold<int>(0, (a, b) => a + b), 2200);
    });

    test('un allenamento in cui non c\'era non conta', () {
      final volumi = VolumiAtleta.daSerie(
        righe,
        {'altro'},
        atletaId: idRossi,
        ruolo: 'movimento',
      );
      expect(volumi.volumeTotaleM, 0);
    });
  });

  group('durata di una seduta divisa', () {
    // Riscaldamento 8', poi un momento: tutti 4×100 ripartenza 2' (8'),
    // i portieri 10' di tiri; defaticamento 4'.
    final serie = [
      serieDi(1, 'riscaldamento', 1, 400, ripartenzaS: 480),
      serieDi(2, 'principale', 4, 100, ripartenzaS: 120, momentoId: 'm1'),
      serieDi(
        3,
        'principale',
        1,
        0,
        esecuzione: 'tiri',
        durataS: 600,
        destinatari: Destinatari.portieri,
        momentoId: 'm1',
      ),
      serieDi(4, 'defaticamento', 1, 200, ripartenzaS: 240),
    ];

    test('un momento dura quanto la colonna più lunga, non la somma', () {
      // 8' + max(8', 10') + 4' = 22'; sommando le colonne sarebbero 30'.
      expect(minutiSeduta(serie), 22);
    });

    test('il giocatore di movimento e il portiere hanno i loro minuti', () {
      expect(minutiStimati(serieDellAtleta(serie, null, 'movimento')), 20);
      expect(minutiStimati(serieDellAtleta(serie, null, 'portiere')), 22);
    });

    test('la durata nell\'Excel del club è quella della seduta: 22', () {
      final bytes = fileExcelDatiClub(
        DatiClub(allenamenti: [allenamentoSeduta], serie: serie),
        nomeClub: 'Club',
        scaricatoDa: 'Coach',
        adesso: DateTime(2026, 10, 18, 14),
        periodo: const PeriodoDati.stagione(2026),
        conBenessere: false,
      );
      final foglio = Excel.decodeBytes(bytes).tables['Allenamenti']!;
      final titoli = [for (final c in foglio.rows.first) c?.value.toString()];
      expect(
        foglio.rows[1][titoli.indexOf('Durata (min)')]?.value,
        const IntCellValue(22),
      );
      // I metri: i 400 + 4×100 + 200 del gruppo, non i tiri a tempo.
      expect(
        foglio.rows[1][titoli.indexOf('Metri')]?.value,
        const IntCellValue(1000),
      );
    });

    test('il carico di ogni atleta usa i minuti della sua colonna', () {
      List<CaricoSeduta> carico(String id, String ruolo) => seduteDiAtleta(
        dataAllenamenti: {idAllenamento: DateTime(2026, 10, 14)},
        seriePerAllenamento: {idAllenamento: serie},
        statoPresenze: {idAllenamento: 'presente'},
        dataPartite: const {},
        partiteConvocato: const {},
        rpe: const {},
        atletaId: id,
        ruolo: ruolo,
        oggi: DateTime(2026, 10, 16),
      );
      expect(carico(idAltro, 'movimento').single.minuti, 20);
      expect(carico(idPortiere, 'portiere').single.minuti, 22);
    });
  });

  group('i widget', () {
    Widget app(Widget figlio) => MaterialApp(
      theme: AppTheme.chiaro,
      home: Scaffold(body: SingleChildScrollView(child: figlio)),
    );

    /// Tutto il testo visibile, una voce per riga.
    List<String> testi(WidgetTester tester) => [
      for (final t in tester.widgetList<RichText>(find.byType(RichText)))
        t.text.toPlainText(),
    ];

    testWidgets('la riga del "2x" dice 600 m e non 1.200 m', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final gruppo = serieSeduta.where((s) => s.piramideId == 'g1').toList();
      expect(gruppo, hasLength(4));
      await tester.pumpWidget(
        app(
          RigaGruppoPiramide(
            gruppo: gruppo,
            maniglia: const SizedBox(),
            primo: true,
            ultimo: true,
            onAzione: (_) {},
          ),
        ),
      );
      final tutto = testi(tester).join('\n');
      expect(tutto, matches(RegExp(r'(^|[^\d.])600 m')));
      expect(tutto, isNot(contains('1.200')));
    });

    testWidgets('il riepilogo dà 2.000 m e i metri per blocco del gruppo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Come il dettaglio: il riepilogo riceve le serie del gruppo.
      await tester.pumpWidget(
        app(RiepilogoVolumi(serie: serieDelGruppo(serieSeduta))),
      );
      final tutto = testi(tester).join('\n');
      expect(tutto, contains('2.000 m'));
      expect(tutto, contains('Risc. 400'));
      expect(tutto, contains('Princ. 1.400'));
      expect(tutto, contains('Defat. 200'));
    });
  });
}

/// I dati dell'assistente: una seduta, i volumi calcolati come l'app.
class _Fonte implements FonteDatiAssistente {
  @override
  String? get gruppoId => 'u14';

  @override
  Future<List<Atleta>> atleti() async => atletiSeduta;

  @override
  Future<List<Partita>> partite() async => const [];

  @override
  Future<List<EventoPartita>> eventi(String partitaId) async => const [];

  @override
  Future<List<DistintaGiocatore>> distinta(String partitaId) async => const [];

  @override
  Future<List<Presenza>> presenze() async => const [];

  @override
  Future<List<Allenamento>> allenamenti() async => [allenamentoSeduta];

  @override
  Future<Map<String, VolumeAllenamento>> volumi() async =>
      volumiPerAllenamento(serieSeduta);

  @override
  Future<List<SchedaBenessere>> schedeBenessere() async => const [];

  @override
  Future<Map<String, List<CaricoSeduta>>> sedutePerAtleta() async => const {};
}
