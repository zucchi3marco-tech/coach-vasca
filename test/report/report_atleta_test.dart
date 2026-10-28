import 'dart:typed_data';

import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/rpe_seduta.dart';
import 'package:coach_vasca/features/export/marchio_pdf.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/obiettivi/domain/scheda_obiettivi.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/report/data/lettore_report_atleta.dart';
import 'package:coach_vasca/features/report/domain/report_atleta.dart';
import 'package:coach_vasca/features/report/pdf/report_atleta_pdf.dart';
import 'package:coach_vasca/features/report/presentation/azioni_report.dart';
import 'package:coach_vasca/features/report/presentation/report_atleta_screen.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/test/domain/test_club.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 27, 12);

Atleta _atleta({String ruolo = 'centroboa', String sport = 'pallanuoto'}) =>
    Atleta(
      id: 'luca',
      clubId: 'c1',
      nome: 'Luca',
      cognome: 'Rossi',
      dataNascita: DateTime(2012, 3, 4),
      sport: sport,
      gruppoId: 'u16',
      ruolo: ruolo,
      consensoPrivacyFirmato: true,
      attivo: true,
    );

Allenamento _allenamento(String id, DateTime data, {String? gruppo = 'u16'}) =>
    Allenamento(id: id, clubId: 'c1', data: data, gruppoId: gruppo);

Presenza _presenza(String allenamento, String stato) => Presenza(
  id: 'p-$allenamento',
  allenamentoId: allenamento,
  atletaId: 'luca',
  clubId: 'c1',
  stato: stato,
);

Partita _partita(String id, DateTime data, {String avversario = 'PN Monza'}) =>
    Partita(
      id: id,
      clubId: 'c1',
      gruppoId: 'u16',
      data: data,
      squadraCasa: 'Canottieri Milano',
      squadraTrasferta: avversario,
      numeroMaxConvocati: 14,
      nostraSquadra: 'casa',
    );

RefertoPartita _referto(Partita p, int casa, int trasferta, {int reti = 0}) =>
    RefertoPartita(
      id: 'r-${p.id}',
      partitaId: p.id,
      clubId: 'c1',
      squadraCasa: p.squadraCasa,
      squadraTrasferta: p.squadraTrasferta,
      risultatoCasa: casa,
      risultatoTrasferta: trasferta,
      parziali: const [],
      giocatoriCasa: [
        GiocatoreReferto(
          numeroCalottina: 7,
          nome: 'Rossi Luca',
          reti: reti,
          espulsioni: 1,
          atletaId: 'luca',
        ),
      ],
      giocatoriTrasferta: const [],
    );

EventoPartita _tiro(String id, String partita, String esito) => EventoPartita(
  id: id,
  partitaId: partita,
  clubId: 'c1',
  tipo: 'tiro',
  squadra: 'nostra',
  atletaId: 'luca',
  esito: esito,
  creatoIl: DateTime(2026, 10, 1),
);

const _sprint = TestClub(
  id: 't1',
  clubId: 'c1',
  nome: 'Sprint 25 m',
  unita: UnitaTest.secondi,
  piuBassoMeglio: true,
);

RisultatoTest _risultato(String id, DateTime data, double valore) =>
    RisultatoTest(
      id: id,
      testId: 't1',
      atletaId: 'luca',
      clubId: 'c1',
      data: data,
      valori: [valore],
    );

final _periodo = PeriodoReport(
  dal: DateTime(2026, 9, 1),
  al: DateTime(2026, 10, 27),
  nome: 'Stagione 2026-27',
);

DatiReportAtleta _dati() {
  final andata = _partita('m1', DateTime(2026, 10, 4));
  final dalVivo = _partita(
    'm2',
    DateTime(2026, 10, 11),
    avversario: 'SG Arese',
  );
  final nonConvocato = _partita('m3', DateTime(2026, 10, 18));
  final futura = _partita('m4', DateTime(2026, 11, 8));
  return DatiReportAtleta(
    allenamenti: [
      _allenamento('a1', DateTime(2026, 9, 2, 18)),
      _allenamento('a2', DateTime(2026, 9, 4, 18)),
      _allenamento('a3', DateTime(2026, 9, 9, 18)),
      _allenamento('a4', DateTime(2026, 9, 11, 18)),
      _allenamento('a5', DateTime(2026, 9, 16, 18), gruppo: 'u14'),
      _allenamento('a6', DateTime(2026, 10, 30, 18)),
    ],
    presenze: [
      _presenza('a1', statoPresente),
      _presenza('a2', statoRitardo),
      _presenza('a3', statoAssente),
      _presenza('a4', statoGiustificato),
    ],
    partite: [andata, dalVivo, nonConvocato, futura],
    convocato: {'m1', 'm2', 'm4'},
    referti: [_referto(andata, 11, 7, reti: 3)],
    eventi: [
      _tiro('e1', 'm2', 'gol'),
      _tiro('e2', 'm2', 'parato'),
      _tiro('e3', 'm2', 'palo_fuori'),
      _tiro('e4', 'm2', 'gol'),
    ],
    test: [_sprint],
    risultatiTest: [
      _risultato('x0', DateTime(2026, 6, 1), 15.0),
      _risultato('x1', DateTime(2026, 9, 10), 14.2),
      _risultato('x2', DateTime(2026, 10, 20), 13.9),
    ],
    schedeObiettivi: [
      SchedaObiettivi(
        id: 's1',
        clubId: 'c1',
        titolo: 'Obiettivi della stagione',
        domande: const ['Cosa vuoi migliorare?', 'Come?'],
        createdAt: DateTime(2026, 9, 5),
      ),
      SchedaObiettivi(
        id: 's2',
        clubId: 'c1',
        titolo: 'Dopo il girone',
        domande: const ['Com\'è andata?'],
        createdAt: DateTime(2026, 11, 1),
      ),
    ],
    risposteObiettivi: [
      RispostaObiettivi(
        id: 'q1',
        schedaId: 's1',
        atletaId: 'luca',
        clubId: 'c1',
        risposte: const ['Il tiro', ''],
        ritorno: 'Bene, lavoriamoci il giovedì',
        inviataAt: DateTime(2026, 9, 6),
      ),
      RispostaObiettivi(
        id: 'q2',
        schedaId: 's2',
        atletaId: 'luca',
        clubId: 'c1',
        risposte: const ['Bene'],
        inviataAt: DateTime(2026, 11, 2),
      ),
    ],
    benessere: [
      SchedaBenessere(
        id: 'b1',
        atletaId: 'luca',
        clubId: 'c1',
        data: DateTime(2026, 10, 1),
        dolori: true,
        intensitaDolore: 7,
        oreSonno: 8,
        compilataIl: DateTime(2026, 10, 1),
        qualitaSonno: 4,
        energia: 4,
        muscoli: 4,
        stress: 4,
        umore: 4,
      ),
      SchedaBenessere(
        id: 'b2',
        atletaId: 'luca',
        clubId: 'c1',
        data: DateTime(2026, 10, 2),
        dolori: false,
        oreSonno: 7,
        compilataIl: DateTime(2026, 10, 2),
        qualitaSonno: 3,
        energia: 3,
        muscoli: 3,
        stress: 3,
        umore: 3,
      ),
    ],
    rpe: [
      RpeSeduta(
        id: 'r1',
        atletaId: 'luca',
        clubId: 'c1',
        eventoTipo: 'allenamento',
        eventoId: 'a1',
        data: DateTime(2026, 9, 2),
        rpe: 6,
      ),
      RpeSeduta(
        id: 'r2',
        atletaId: 'luca',
        clubId: 'c1',
        eventoTipo: 'allenamento',
        eventoId: 'a2',
        data: DateTime(2026, 9, 4),
        rpe: 7,
      ),
    ],
  );
}

/// Il lettore finto: dà sempre gli stessi dati e annota cosa gli si chiede.
class _Lettore implements LettoreReportAtleta {
  final richieste = <(PeriodoReport, bool)>[];

  @override
  Future<DatiReportAtleta> leggi(
    Atleta atleta,
    PeriodoReport periodo, {
    bool conBenessere = false,
  }) async {
    richieste.add((periodo, conBenessere));
    return _dati();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Azioni extends AzioniReport {
  final report = <ReportAtleta>[];
  final consegnati = <String>[];

  @override
  Future<Uint8List> creaPdf(ReportAtleta report, MarchioPdf? marchio) async {
    this.report.add(report);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> consegna(Uint8List bytes, String nomeFile) async =>
      consegnati.add(nomeFile);
}

void main() {
  group('il report dell\'atleta', () {
    final report = reportAtleta(
      atleta: _atleta(),
      periodo: _periodo,
      dati: _dati(),
      adesso: _oggi,
      squadra: 'U16',
      categoria: 'U16',
      nota: '  Ottimo inizio di stagione.  ',
    );

    test('presenze: gli allenamenti già fatti della sua squadra', () {
      // a5 è degli U14, a6 deve ancora venire.
      expect(report.allenamenti, 4);
      expect(report.presenti, 2, reason: 'chi è in ritardo c\'era');
      expect(report.ritardi, 1);
      expect(report.assenti, 1);
      expect(report.giustificati, 1);
      expect(report.percentualePresenze, 50);
    });

    test('partite: convocato e già giocate, gol dal referto o dal vivo', () {
      expect(
        [for (final p in report.partite) p.partita.id],
        ['m1', 'm2'],
        reason: 'm3 senza di lui, m4 deve ancora venire',
      );
      expect(report.partite[0].risultato, '11-7');
      expect(report.partite[0].gol, 3);
      expect(report.partite[0].espulsioni, 1);
      // m2 senza referto: i suoi due gol dal vivo, il risultato dagli
      // eventi (solo i nostri gol, 2-0).
      expect(report.partite[1].gol, 2);
      expect(report.partite[1].risultato, '2-0');
      expect(report.gol, 5);
      expect(report.espulsioni, 1);
      expect(report.tiri, 4);
      expect(report.precisione, 50);
    });

    test('test: il primo e l\'ultimo del periodo', () {
      expect(report.test, hasLength(1));
      final t = report.test.single;
      expect(t.valorePrimo, 14.2, reason: 'quello di giugno è fuori');
      expect(t.valoreUltimo, 13.9);
      expect(t.migliorato, isTrue, reason: 'nel tempo più basso è meglio');
    });

    test('obiettivi: quelli scritti entro la fine del periodo', () {
      expect(report.obiettivi, hasLength(1));
      final o = report.obiettivi.single;
      expect(o.scheda.titolo, 'Obiettivi della stagione');
      expect(o.righe, [('Cosa vuoi migliorare?', 'Il tiro')]);
    });

    test('benessere solo con la spunta, e solo le medie', () {
      expect(report.benessere, isNull);
      final con = reportAtleta(
        atleta: _atleta(),
        periodo: _periodo,
        dati: _dati(),
        adesso: _oggi,
        conBenessere: true,
      );
      final b = con.benessere!;
      expect(b.schede, 2);
      expect(b.indice, 70, reason: '(80 + 60) / 2, senza togliere il dolore');
      expect(b.sonno, 7.5);
      expect(b.sedute, 2);
      expect(b.rpe, 6.5);
    });

    test('la nota senza spazi, vuota non c\'è', () {
      expect(report.nota, 'Ottimo inizio di stagione.');
      final senza = reportAtleta(
        atleta: _atleta(),
        periodo: _periodo,
        dati: _dati(),
        adesso: _oggi,
        nota: '   ',
      );
      expect(senza.nota, isNull);
    });

    test('un atleta ancora segnato «nuoto» nel database ha le partite come '
        'gli altri', () {
      final segnatoNuoto = reportAtleta(
        atleta: _atleta(sport: 'nuoto'),
        periodo: _periodo,
        dati: _dati(),
        adesso: _oggi,
      );
      final normale = reportAtleta(
        atleta: _atleta(),
        periodo: _periodo,
        dati: _dati(),
        adesso: _oggi,
      );
      expect(segnatoNuoto.partite, isNotEmpty);
      expect(segnatoNuoto.partite.length, normale.partite.length);
      expect(segnatoNuoto.gol, normale.gol);
    });

    test(
      'il PDF si crea, anche con benessere e senza obiettivi letti',
      () async {
        final pdf = await generaReportAtletaPdf(
          report,
          marchio: const MarchioPdf(nomeClub: 'Canottieri Milano'),
        );
        expect(pdf, isNotEmpty);
        final senzaRete = reportAtleta(
          atleta: _atleta(ruolo: 'portiere'),
          periodo: _periodo,
          dati: const DatiReportAtleta(obiettiviLetti: false),
          adesso: _oggi,
          conBenessere: true,
        );
        expect(senzaRete.obiettiviLetti, isFalse);
        expect(await generaReportAtletaPdf(senzaRete), isNotEmpty);
      },
    );
  });

  group('i periodi', () {
    final stagione = Stagione(
      id: 'st',
      clubId: 'c1',
      nome: 'Stagione 2026-27',
      dataInizio: DateTime(2026, 9, 1),
      dataFine: DateTime(2027, 6, 30),
      gruppoId: 'u16',
      fasi: [
        FaseStagione(
          nome: 'Preparazione',
          dataInizio: DateTime(2026, 9, 1),
          dataFine: DateTime(2026, 10, 11),
        ),
        FaseStagione(
          nome: 'Girone d\'andata',
          dataInizio: DateTime(2026, 10, 12),
          dataFine: DateTime(2026, 12, 20),
        ),
        FaseStagione(
          nome: 'Ritorno',
          dataInizio: DateTime(2027, 1, 10),
          dataFine: DateTime(2027, 4, 30),
        ),
      ],
    );

    test('la stagione fino a oggi e le fasi già cominciate', () {
      final p = periodiProposti(stagione: stagione, oggi: _oggi);
      expect(
        [for (final x in p) x.nome],
        ['Stagione 2026-27', 'Fase «Preparazione»', 'Fase «Girone d\'andata»'],
      );
      expect(p[0].al, DateTime(2026, 10, 27));
      expect(p[1].al, DateTime(2026, 10, 11));
      expect(p[2].al, DateTime(2026, 10, 27));
      expect(p[0].descrizione, 'dal 1 settembre al 27 ottobre 2026');
    });

    test('senza stagione, da settembre', () {
      final p = periodiProposti(stagione: null, oggi: DateTime(2027, 2, 3));
      expect(p.single.dal, DateTime(2026, 9, 1));
      expect(p.single.al, DateTime(2027, 2, 3));
      expect(p.single.descrizione, 'dal 1 settembre 2026 al 3 febbraio 2027');
    });

    test('la stagione della sua squadra prima di quella del club', () {
      final club = Stagione(
        id: 'club',
        clubId: 'c1',
        nome: 'Tutti',
        dataInizio: DateTime(2026, 9, 1),
        dataFine: DateTime(2027, 6, 30),
      );
      final altra = Stagione(
        id: 'u14',
        clubId: 'c1',
        nome: 'U14',
        dataInizio: DateTime(2026, 9, 1),
        dataFine: DateTime(2027, 6, 30),
        gruppoId: 'u14',
      );
      expect(
        stagioneDellAtleta([club, altra, stagione], _atleta(), _oggi)?.id,
        'st',
      );
      expect(stagioneDellAtleta([club, altra], _atleta(), _oggi)?.id, 'club');
    });

    test('il nome del file', () {
      expect(
        nomeFileReport('Rossi Niccolò', _oggi),
        'report-rossi-niccolo-2026-10-27.pdf',
      );
    });
  });

  group('«Report PDF»', () {
    Future<(_Lettore, _Azioni)> apri(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final lettore = _Lettore();
      final azioni = _Azioni();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lettoreReportAtletaProvider.overrideWithValue(lettore),
            azioniReportProvider.overrideWithValue(azioni),
            stagioniListProvider.overrideWith(
              (ref, clubId) => Stream.value([
                Stagione(
                  id: 'st',
                  clubId: 'c1',
                  nome: 'Stagione 2026-27',
                  dataInizio: DateTime(2026, 9, 1),
                  dataFine: DateTime(2027, 6, 30),
                  gruppoId: 'u16',
                  fasi: [
                    FaseStagione(
                      nome: 'Preparazione',
                      dataInizio: DateTime(2026, 9, 1),
                      dataFine: DateTime(2026, 10, 11),
                    ),
                  ],
                ),
              ]),
            ),
            gruppiListProvider.overrideWith(
              (ref, clubId) => Stream.value(const [
                Gruppo(id: 'u16', clubId: 'c1', nome: 'U16', ordine: 1),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ReportAtletaScreen(atleta: _atleta(), oggi: _oggi),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return (lettore, azioni);
    }

    testWidgets('di base la stagione, senza benessere; con la nota', (
      tester,
    ) async {
      final (lettore, azioni) = await apri(tester);
      expect(find.text('Report PDF'), findsOneWidget);
      expect(find.text('Stagione 2026-27'), findsOneWidget);
      expect(find.text('Fase «Preparazione»'), findsOneWidget);
      expect(
        find.text('Dentro: dal 1 settembre al 27 ottobre 2026.'),
        findsOneWidget,
      );

      // La nota è l'unico campo della pagina.
      await tester.enterText(find.byType(TextFormField), 'Bravo Luca');
      await tester.tap(find.text('Crea il PDF'));
      await tester.pump();
      await tester.pump();

      expect(lettore.richieste.single.$2, isFalse);
      expect(lettore.richieste.single.$1.nome, 'Stagione 2026-27');
      final r = azioni.report.single;
      expect(r.nota, 'Bravo Luca');
      expect(r.squadra, 'U16');
      expect(r.categoria, 'classe 2012 (U16)');
      expect(r.benessere, isNull);
      expect(azioni.consegnati, ['report-rossi-luca-2026-10-27.pdf']);
      expect(
        find.text('Report pronto: report-rossi-luca-2026-10-27.pdf'),
        findsOneWidget,
      );
    });

    testWidgets('una fase e la spunta del benessere', (tester) async {
      final (lettore, azioni) = await apri(tester);
      await tester.tap(find.text('Fase «Preparazione»'));
      await tester.pump();
      expect(
        find.text('Dentro: dal 1 settembre al 11 ottobre 2026.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Aggiungi benessere e RPE'));
      await tester.pump();
      await tester.tap(find.text('Crea il PDF'));
      await tester.pump();
      await tester.pump();

      expect(lettore.richieste.single.$1.nome, 'Fase «Preparazione»');
      expect(lettore.richieste.single.$2, isTrue);
      expect(azioni.report.single.benessere, isNotNull);
    });
  });
}
