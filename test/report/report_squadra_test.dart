import 'dart:typed_data';

import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/campionati/domain/campionato_fin.dart';
import 'package:coach_vasca/features/carico/domain/rpe_seduta.dart';
import 'package:coach_vasca/features/export/marchio_pdf.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/referti/domain/referto_letto.dart';
import 'package:coach_vasca/features/referti/domain/referto_partita.dart';
import 'package:coach_vasca/features/report/data/lettore_report_squadra.dart';
import 'package:coach_vasca/features/report/domain/report_atleta.dart';
import 'package:coach_vasca/features/report/domain/report_squadra.dart';
import 'package:coach_vasca/features/report/pdf/report_squadra_pdf.dart';
import 'package:coach_vasca/features/report/presentation/azioni_report.dart';
import 'package:coach_vasca/features/report/presentation/report_squadra_screen.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 27, 12);

Atleta _atleta(
  String id,
  String cognome, {
  String gruppo = 'u16',
  bool attivo = true,
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Nome',
  cognome: cognome,
  dataNascita: DateTime(2012, 3, 4),
  sport: 'pallanuoto',
  gruppoId: gruppo,
  consensoPrivacyFirmato: true,
  attivo: attivo,
);

Allenamento _allenamento(String id, DateTime data, {String gruppo = 'u16'}) =>
    Allenamento(id: id, clubId: 'c1', data: data, gruppoId: gruppo);

Presenza _presenza(String atleta, String allenamento, String stato) => Presenza(
  id: 'p-$atleta-$allenamento',
  allenamentoId: allenamento,
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

Partita _partita(
  String id,
  DateTime data, {
  String? gruppo = 'u16',
  String avversario = 'PN Monza',
  bool inCasa = true,
}) => Partita(
  id: id,
  clubId: 'c1',
  gruppoId: gruppo,
  data: data,
  squadraCasa: inCasa ? 'Canottieri Milano' : avversario,
  squadraTrasferta: inCasa ? avversario : 'Canottieri Milano',
  numeroMaxConvocati: 14,
  nostraSquadra: inCasa ? 'casa' : 'trasferta',
);

EventoPartita _evento(
  String id,
  String partita,
  String tipo, {
  String squadra = 'nostra',
  String? atleta,
  String? esito,
}) => EventoPartita(
  id: id,
  partitaId: partita,
  clubId: 'c1',
  tipo: tipo,
  squadra: squadra,
  atletaId: atleta,
  esito: esito,
  creatoIl: DateTime(2026, 10, 11),
);

SchedaBenessere _scheda(String id, String atleta, int voto, double sonno) =>
    SchedaBenessere(
      id: id,
      atletaId: atleta,
      clubId: 'c1',
      data: DateTime(2026, 10, 1),
      dolori: true,
      intensitaDolore: 8,
      oreSonno: sonno,
      compilataIl: DateTime(2026, 10, 1),
      qualitaSonno: voto,
      energia: voto,
      muscoli: voto,
      stress: voto,
      umore: voto,
    );

RigaClassificaFin _riga(int pos, String squadra, int punti) =>
    RigaClassificaFin(
      posizione: pos,
      squadra: squadra,
      punti: punti,
      giocate: 2,
      vinte: punti ~/ 3,
      pareggiate: 0,
      perse: 2 - punti ~/ 3,
      golFatti: 20,
      golSubiti: 18,
      differenza: 2,
    );

GironeCollegato _collegato(String id, String stagione) => GironeCollegato(
  id: id,
  clubId: 'c1',
  gruppoId: 'u16',
  cmpId: id.hashCode,
  stagione: stagione,
  campionato: 'Under 16 Maschile',
  fase: 'Fase 1',
  girone: 'Girone 2',
  squadra: 'CANOTTIERI MILANO',
);

final _periodo = PeriodoReport(
  dal: DateTime(2026, 9, 1),
  al: DateTime(2026, 10, 27),
  nome: 'Stagione 2026-27',
);

DatiReportSquadra _dati() {
  final andata = _partita('m1', DateTime(2026, 10, 4));
  final dalVivo = _partita(
    'm2',
    DateTime(2026, 10, 11),
    avversario: 'SG Arese',
    inCasa: false,
  );
  final u14 = _partita('m3', DateTime(2026, 10, 18), gruppo: 'u14');
  final futura = _partita('m4', DateTime(2026, 11, 8));
  final delClub = _partita('m5', DateTime(2026, 10, 20), gruppo: null);
  return DatiReportSquadra(
    atleti: [
      _atleta('luca', 'Rossi'),
      _atleta('marco', 'Verdi'),
      _atleta('anna', 'Neri', gruppo: 'u14'),
      _atleta('paolo', 'Bianchi', attivo: false),
    ],
    allenamenti: [
      _allenamento('a1', DateTime(2026, 9, 2, 18)),
      _allenamento('a2', DateTime(2026, 9, 4, 18)),
      _allenamento('a3', DateTime(2026, 9, 9, 18), gruppo: 'u14'),
      _allenamento('a4', DateTime(2026, 10, 30, 18)),
    ],
    presenze: [
      _presenza('luca', 'a1', statoPresente),
      _presenza('luca', 'a2', statoRitardo),
      _presenza('marco', 'a1', statoAssente),
      _presenza('marco', 'a2', statoGiustificato),
      _presenza('anna', 'a3', statoPresente),
    ],
    partite: [andata, dalVivo, u14, futura, delClub],
    referti: [
      RefertoPartita(
        id: 'r1',
        partitaId: 'm1',
        clubId: 'c1',
        squadraCasa: andata.squadraCasa,
        squadraTrasferta: andata.squadraTrasferta,
        risultatoCasa: 11,
        risultatoTrasferta: 7,
        parziali: const [],
        giocatoriCasa: const [
          GiocatoreReferto(
            numeroCalottina: 7,
            nome: 'Rossi',
            reti: 3,
            espulsioni: 1,
            atletaId: 'luca',
          ),
          GiocatoreReferto(
            numeroCalottina: 9,
            nome: 'Bianchi',
            reti: 2,
            espulsioni: 0,
            atletaId: 'paolo',
          ),
          GiocatoreReferto(
            numeroCalottina: 10,
            nome: 'Ospite',
            reti: 1,
            espulsioni: 0,
          ),
        ],
        giocatoriTrasferta: const [
          GiocatoreReferto(
            numeroCalottina: 3,
            nome: 'Avversario',
            reti: 4,
            espulsioni: 0,
            atletaId: 'marco',
          ),
        ],
      ),
    ],
    eventi: [
      _evento('e1', 'm2', 'tiro', atleta: 'luca', esito: 'gol'),
      _evento('e2', 'm2', 'tiro', squadra: 'avversaria', esito: 'gol'),
      _evento('e3', 'm2', 'tiro', squadra: 'avversaria', esito: 'gol'),
      _evento('e4', 'm2', 'espulsione', atleta: 'marco'),
      _evento('e5', 'm3', 'tiro', atleta: 'anna', esito: 'gol'),
    ],
    gironi: [
      GironeLetto(
        collegato: _collegato('g1', '2026-2027'),
        girone: GironeFin(
          cmpId: 1,
          stagione: '2026-2027',
          titolo: 'Under 16',
          classifica: [
            _riga(1, 'SG ARESE', 6),
            _riga(2, 'CANOTTIERI MILANO', 3),
          ],
          giornate: const [],
        ),
        lettoIl: DateTime(2026, 10, 27, 9),
      ),
      GironeLetto(collegato: _collegato('g2', '2026-2027')),
      GironeLetto(collegato: _collegato('g3', '2024-2025')),
    ],
    benessere: [
      _scheda('b1', 'luca', 4, 8),
      _scheda('b2', 'marco', 3, 7),
      _scheda('b3', 'anna', 1, 5),
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
        atletaId: 'anna',
        clubId: 'c1',
        eventoTipo: 'allenamento',
        eventoId: 'a3',
        data: DateTime(2026, 9, 9),
        rpe: 10,
      ),
    ],
  );
}

ReportSquadra _report({bool conBenessere = false}) => reportSquadra(
  nome: 'U16',
  gruppoId: 'u16',
  periodo: _periodo,
  dati: _dati(),
  adesso: _oggi,
  conBenessere: conBenessere,
  campionato: 'Under 16',
  nota: '  Bel girone.  ',
);

class _Lettore implements LettoreReportSquadra {
  final richieste = <({String? gruppoId, PeriodoReport periodo, bool b})>[];

  @override
  Future<DatiReportSquadra> leggi({
    required String clubId,
    required String? gruppoId,
    required PeriodoReport periodo,
    bool conBenessere = false,
  }) async {
    richieste.add((gruppoId: gruppoId, periodo: periodo, b: conBenessere));
    return _dati();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Azioni extends AzioniReport {
  final report = <ReportSquadra>[];
  final consegnati = <String>[];

  @override
  Future<Uint8List> creaPdfSquadra(
    ReportSquadra report,
    MarchioPdf? marchio,
  ) async {
    this.report.add(report);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> consegna(Uint8List bytes, String nomeFile) async =>
      consegnati.add(nomeFile);
}

void main() {
  group('il report della squadra', () {
    final report = _report();

    test('partite: quelle già giocate della squadra e di tutto il club', () {
      expect(
        [for (final p in report.partite) p.partita.id],
        ['m1', 'm2', 'm5'],
      );
      expect(report.partite[0].risultato, '11-7');
      expect(report.partite[0].esito, 'Vinta');
      expect(report.partite[0].daReferto, isTrue);
      // In trasferta, dal vivo: prima i nostri gol.
      expect(report.partite[1].risultato, '1-2');
      expect(report.partite[1].esito, 'Persa');
      expect(report.partite[2].risultato, '—');
      expect(report.partite[2].esito, '—');
    });

    test('il bilancio conta solo le partite con il risultato', () {
      expect((report.vinte, report.pari, report.perse), (1, 0, 1));
      expect((report.golFatti, report.golSubiti), (12, 9));
    });

    test('marcatori: dal referto (solo i nostri), se no dal vivo', () {
      expect(
        [
          for (final m in report.marcatori)
            (m.nome, m.partite, m.gol, m.espulsioni),
        ],
        [
          ('Rossi Nome', 2, 4, 1),
          ('Bianchi Nome', 1, 2, 0),
          ('Verdi Nome', 1, 0, 1),
        ],
      );
    });

    test('presenze: gli atleti attivi della squadra, già fatti', () {
      expect([for (final p in report.presenze) p.atleta.id], ['luca', 'marco']);
      final luca = report.presenze.first;
      expect((luca.presenti, luca.ritardi, luca.allenamenti), (2, 1, 2));
      expect(luca.percentuale, 100);
      final marco = report.presenze.last;
      expect((marco.assenti, marco.giustificati), (1, 1));
      expect(marco.percentuale, 0);
      expect(report.percentualePresenze, 50);
    });

    test('numeri dal vivo: solo le partite della squadra', () {
      expect(report.partiteDalVivo, 1);
      expect((report.dalVivo.gol, report.dalVivo.tiri), (1, 1));
      expect(report.dalVivo.golSubiti, 2);
    });

    test('i gironi FIN della stagione, anche quelli non letti', () {
      expect([for (final g in report.gironi) g.collegato.id], ['g1', 'g2']);
      expect(report.gironiLetti, isTrue);
    });

    test('nota e benessere', () {
      expect(report.nota, 'Bel girone.');
      expect(report.benessere, isNull);
      final b = _report(conBenessere: true).benessere!;
      // Solo Luca e Marco: Anna è degli U14.
      expect(b.schede, 2);
      expect(b.indice, 70);
      expect(b.sonno, 7.5);
      expect((b.sedute, b.rpe), (1, 6.0));
    });

    test('la stagione FIN tocca il periodo', () {
      expect(stagioneFinNelPeriodo('2026-2027', _periodo), isTrue);
      expect(stagioneFinNelPeriodo('2025-2026', _periodo), isFalse);
      expect(stagioneFinNelPeriodo('2024/25', _periodo), isFalse);
      expect(stagioneFinNelPeriodo('?', _periodo), isTrue);
    });

    test('tutto il club: tutte le partite e tutti gli atleti attivi', () {
      final club = reportSquadra(
        nome: 'Tutto il club',
        gruppoId: null,
        periodo: _periodo,
        dati: _dati(),
        adesso: _oggi,
      );
      expect(club.partite, hasLength(4));
      expect(club.presenze, hasLength(3));
    });
  });

  group('il PDF', () {
    test('con tutto', () async {
      final bytes = await generaReportSquadraPdf(
        _report(conBenessere: true),
        marchio: const MarchioPdf(nomeClub: 'Canottieri Milano'),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('vuoto, e senza i campionati', () async {
      final bytes = await generaReportSquadraPdf(
        reportSquadra(
          nome: 'U16',
          gruppoId: 'u16',
          periodo: _periodo,
          dati: const DatiReportSquadra(gironiLetti: false),
          adesso: _oggi,
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('«Report PDF» della squadra', () {
    Stagione stagione({String? gruppo = 'u16', DateTime? inizio}) => Stagione(
      id: 'st',
      clubId: 'c1',
      nome: 'Stagione 2026-27',
      dataInizio: inizio ?? DateTime(2026, 9, 1),
      dataFine: DateTime(2027, 6, 30),
      gruppoId: gruppo,
      fasi: [
        FaseStagione(
          nome: 'Preparazione',
          dataInizio: DateTime(2026, 9, 1),
          dataFine: DateTime(2026, 10, 11),
        ),
      ],
    );

    Future<(_Lettore, _Azioni)> apri(WidgetTester tester, Stagione s) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final lettore = _Lettore();
      final azioni = _Azioni();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lettoreReportSquadraProvider.overrideWithValue(lettore),
            azioniReportProvider.overrideWithValue(azioni),
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
            home: ReportSquadraScreen(stagione: s, oggi: _oggi),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return (lettore, azioni);
    }

    testWidgets('di base la stagione; la squadra e la nota', (tester) async {
      final (lettore, azioni) = await apri(tester, stagione());
      expect(find.text('U16 · Stagione 2026-27'), findsOneWidget);
      expect(
        find.text('Dentro: dal 1 settembre al 27 ottobre 2026.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'Avanti così');
      await tester.tap(find.text('Crea il PDF'));
      await tester.pump();
      await tester.pump();

      final richiesta = lettore.richieste.single;
      expect(richiesta.gruppoId, 'u16');
      expect(richiesta.periodo.nome, 'Stagione 2026-27');
      expect(richiesta.b, isFalse);
      final r = azioni.report.single;
      expect(r.nome, 'U16');
      expect(r.nota, 'Avanti così');
      expect(azioni.consegnati, ['report-u16-2026-10-27.pdf']);
      expect(
        find.text('Report pronto: report-u16-2026-10-27.pdf'),
        findsOneWidget,
      );
    });

    testWidgets('una fase e la spunta del benessere', (tester) async {
      final (lettore, azioni) = await apri(tester, stagione());
      await tester.tap(find.text('Fase «Preparazione»'));
      await tester.pump();
      await tester.tap(find.text('Aggiungi benessere e RPE'));
      await tester.pump();
      await tester.tap(find.text('Crea il PDF'));
      await tester.pump();
      await tester.pump();
      expect(lettore.richieste.single.periodo.nome, 'Fase «Preparazione»');
      expect(lettore.richieste.single.b, isTrue);
      expect(azioni.report.single.benessere, isNotNull);
    });

    testWidgets('stagione di tutto il club', (tester) async {
      final (_, azioni) = await apri(tester, stagione(gruppo: null));
      await tester.tap(find.text('Crea il PDF'));
      await tester.pump();
      await tester.pump();
      expect(azioni.report.single.nome, 'Tutto il club');
      expect(azioni.consegnati, ['report-tutto-il-club-2026-10-27.pdf']);
    });

    testWidgets('una stagione non ancora cominciata', (tester) async {
      await apri(tester, stagione(inizio: DateTime(2026, 11, 1)));
      expect(find.textContaining('non è ancora cominciata'), findsOneWidget);
      expect(find.text('Crea il PDF'), findsNothing);
    });
  });
}

