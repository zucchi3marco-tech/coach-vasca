import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/percentuale_presenze.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/rpe_seduta.dart';
import '../../obiettivi/domain/scheda_obiettivi.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/numeri_portiere.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/domain/risultato_partita.dart';
import '../../presenze/domain/presenza.dart';
import '../../referti/domain/referto_partita.dart';
import '../../stagioni/domain/stagione.dart';
import '../../test/domain/test_club.dart';

/// Il periodo di un report: dal giorno [dal] al giorno [al], estremi
/// compresi, con il [nome] che si legge nel PDF ("Stagione 2026-27",
/// "Fase «Preparazione»", "Periodo scelto").
class PeriodoReport {
  PeriodoReport({
    required DateTime dal,
    required DateTime al,
    required this.nome,
  }) : dal = soloData(dal),
       al = soloData(al);

  final DateTime dal;
  final DateTime al;
  final String nome;

  bool contiene(DateTime giorno) {
    final g = soloData(giorno);
    return !g.isBefore(dal) && !g.isAfter(al);
  }

  /// "dal 1 settembre al 27 ottobre 2026", con l'anno anche all'inizio
  /// quando cambia.
  String get descrizione {
    final inizio = dal.year == al.year ? giornoMese(dal) : dataLunga(dal);
    return 'dal $inizio al ${dataLunga(al)}';
  }
}

/// I periodi fra cui scegliere: la stagione fino a oggi, poi ogni fase
/// già cominciata (fino a oggi se non è finita). Senza stagione, dal 1°
/// settembre a oggi.
List<PeriodoReport> periodiProposti({
  required Stagione? stagione,
  required DateTime oggi,
}) {
  final giorno = soloData(oggi);
  DateTime fino(DateTime fine) =>
      soloData(fine).isAfter(giorno) ? giorno : soloData(fine);
  if (stagione == null) {
    final inizio = DateTime(
      giorno.month >= 9 ? giorno.year : giorno.year - 1,
      9,
    );
    return [PeriodoReport(dal: inizio, al: giorno, nome: 'Da settembre')];
  }
  return [
    PeriodoReport(
      dal: stagione.dataInizio,
      al: fino(stagione.dataFine),
      nome: stagione.nome,
    ),
    for (final f in stagione.fasi)
      if (!soloData(f.dataInizio).isAfter(giorno))
        PeriodoReport(
          dal: f.dataInizio,
          al: fino(f.dataFine),
          nome: 'Fase «${f.nome}»',
        ),
  ];
}

/// I dati grezzi da cui nasce il report di un atleta, già letti.
class DatiReportAtleta {
  const DatiReportAtleta({
    this.allenamenti = const [],
    this.presenze = const [],
    this.partite = const [],
    this.convocato = const {},
    this.referti = const [],
    this.eventi = const [],
    this.portiere,
    this.test = const [],
    this.risultatiTest = const [],
    this.schedeObiettivi = const [],
    this.risposteObiettivi = const [],
    this.obiettiviLetti = true,
    this.benessere = const [],
    this.rpe = const [],
  });

  /// Gli allenamenti del club nel periodo.
  final List<Allenamento> allenamenti;

  /// Le presenze dell'atleta.
  final List<Presenza> presenze;

  /// Le partite del club nel periodo.
  final List<Partita> partite;

  /// Le partite in cui era nella distinta.
  final Set<String> convocato;

  /// I referti di [partite].
  final List<RefertoPartita> referti;

  /// Gli eventi dal vivo di [partite].
  final List<EventoPartita> eventi;

  /// Parate e gol subiti nel periodo, per un portiere.
  final NumeriPortiere? portiere;

  final List<TestClub> test;

  /// I risultati dei test dell'atleta.
  final List<RisultatoTest> risultatiTest;

  final List<SchedaObiettivi> schedeObiettivi;

  /// Le risposte dell'atleta alle schede degli obiettivi.
  final List<RispostaObiettivi> risposteObiettivi;

  /// false se le schede degli obiettivi non si sono lette (servono la
  /// rete): nel PDF lo si dice invece di non scrivere niente.
  final bool obiettiviLetti;

  /// Le schede del benessere e gli RPE: vuote se non si mettono.
  final List<SchedaBenessere> benessere;
  final List<RpeSeduta> rpe;
}

/// Una partita giocata nel periodo, come si legge nel report.
class PartitaNelReport {
  const PartitaNelReport({
    required this.partita,
    this.nostri,
    this.loro,
    this.gol,
    this.espulsioni,
  });

  final Partita partita;
  final int? nostri;
  final int? loro;

  /// I suoi gol e le sue espulsioni: dal referto, se no dal vivo; null se
  /// della partita non c'è niente.
  final int? gol;
  final int? espulsioni;

  /// "11-7", o "—" senza risultato.
  String get risultato =>
      nostri == null || loro == null ? '—' : '$nostri-$loro';
}

/// Un test nel periodo: il primo risultato e l'ultimo.
class TestNelReport {
  const TestNelReport({
    required this.test,
    required this.primo,
    required this.ultimo,
    required this.volte,
  });

  final TestClub test;
  final RisultatoTest primo;
  final RisultatoTest ultimo;

  /// Quante volte l'ha fatto nel periodo.
  final int volte;

  double get valorePrimo => test.punteggioDi(primo.valori);
  double get valoreUltimo => test.punteggioDi(ultimo.valori);

  /// true se è migliorato, false se è peggiorato, null se uguale o fatto
  /// una volta sola.
  bool? get migliorato {
    if (volte < 2 || valorePrimo == valoreUltimo) return null;
    return test.meglio(valoreUltimo, valorePrimo);
  }
}

/// Una scheda degli obiettivi con le sue risposte.
class ObiettivoNelReport {
  const ObiettivoNelReport({required this.scheda, required this.risposta});

  final SchedaObiettivi scheda;
  final RispostaObiettivi risposta;

  /// Domanda e risposta, solo quelle a cui ha risposto.
  List<(String, String)> get righe => [
    for (var i = 0; i < scheda.domande.length; i++)
      if (i < risposta.risposte.length &&
          risposta.risposte[i].trim().isNotEmpty)
        (scheda.domande[i], risposta.risposte[i].trim()),
  ];
}

/// Le medie di benessere e RPE nel periodo. Niente dolori né sintomi:
/// sono dati sulla salute e il PDF gira per email e chat.
class BenessereNelReport {
  const BenessereNelReport({
    required this.schede,
    this.indice,
    this.sonno,
    required this.sedute,
    this.rpe,
  });

  final int schede;

  /// La media delle cinque voci (sonno, energia, muscoli, stress, umore)
  /// riportata su 100; null senza voci.
  final int? indice;

  /// Ore di sonno in media.
  final double? sonno;

  final int sedute;
  final double? rpe;
}

/// Il report di un atleta in un periodo, pronto da impaginare.
class ReportAtleta {
  const ReportAtleta({
    required this.atleta,
    required this.periodo,
    required this.creatoIl,
    required this.presenti,
    required this.ritardi,
    required this.assenti,
    required this.giustificati,
    required this.allenamenti,
    required this.partite,
    required this.gol,
    required this.espulsioni,
    required this.tiri,
    required this.golDalVivo,
    this.portiere,
    required this.test,
    required this.obiettivi,
    required this.obiettiviLetti,
    this.benessere,
    this.squadra,
    this.categoria,
    this.nota,
  });

  final Atleta atleta;
  final PeriodoReport periodo;
  final DateTime creatoIl;

  /// Le presenze sugli [allenamenti] che lo riguardavano, già passati:
  /// [presenti] comprende i [ritardi].
  final int presenti;
  final int ritardi;
  final int assenti;
  final int giustificati;
  final int allenamenti;

  final List<PartitaNelReport> partite;
  final int gol;
  final int espulsioni;

  /// Solo dal vivo: il referto non ha i tiri sbagliati.
  final int tiri;
  final int golDalVivo;
  final NumeriPortiere? portiere;

  final List<TestNelReport> test;
  final List<ObiettivoNelReport> obiettivi;
  final bool obiettiviLetti;

  /// Null se non si è messa la spunta.
  final BenessereNelReport? benessere;

  final String? squadra;
  final String? categoria;

  /// La nota dell'allenatore, scritta al momento.
  final String? nota;

  /// Presenze in %, null senza allenamenti.
  int? get percentualePresenze =>
      allenamenti == 0 ? null : (presenti / allenamenti * 100).round();

  /// Precisione al tiro dal vivo in %, null senza tiri.
  int? get precisione => tiri == 0 ? null : (golDalVivo / tiri * 100).round();
}

/// Mette insieme il report di [atleta] nel [periodo] da [dati].
/// [conBenessere]: le medie di benessere e RPE (la spunta, tolta di base).
ReportAtleta reportAtleta({
  required Atleta atleta,
  required PeriodoReport periodo,
  required DatiReportAtleta dati,
  required DateTime adesso,
  bool conBenessere = false,
  String? squadra,
  String? categoria,
  String? nota,
}) {
  // Presenze: gli allenamenti già passati del periodo in cui era atteso
  // (o in cui è stato segnato), con la stessa regola dell'app.
  final nelPeriodo = [
    for (final a in dati.allenamenti)
      if (periodo.contiene(a.data)) a,
  ];
  final rilevanti = allenamentiRilevanti(
    allenamenti: nelPeriodo,
    presenze: dati.presenze,
    atletaId: atleta.id,
    gruppoAtleta: atleta.gruppoId,
    atteso: (a) => atleta.attesoA(a.gruppoId, a.data),
    adesso: adesso,
  );
  final idRilevanti = {for (final a in rilevanti) a.id};
  final suoi = [
    for (final p in dati.presenze)
      if (p.atletaId == atleta.id && idRilevanti.contains(p.allenamentoId)) p,
  ];
  int conta(String stato) => suoi.where((p) => p.stato == stato).length;
  final presenti = suoi.where((p) => contaComePresente(p.stato)).length;

  // Partite: quelle già giocate del periodo in cui era convocato, era nel
  // referto o ha fatto qualcosa dal vivo.
  final refertoPer = {for (final r in dati.referti) r.partitaId: r};
  final eventiPer = <String, List<EventoPartita>>{};
  for (final e in dati.eventi) {
    eventiPer.putIfAbsent(e.partitaId, () => []).add(e);
  }
  final giorno = soloData(adesso);
  final partite = <PartitaNelReport>[];
  var gol = 0;
  var espulsioni = 0;
  var tiri = 0;
  var golDalVivo = 0;
  final ordinate = [
    for (final p in dati.partite)
      if (periodo.contiene(p.data) && !soloData(p.data).isAfter(giorno)) p,
  ]..sort((a, b) => a.data.compareTo(b.data));
  for (final p in ordinate) {
    final referto = refertoPer[p.id];
    final eventi = eventiPer[p.id] ?? const <EventoPartita>[];
    final suoiEventi = [
      for (final e in eventi)
        if (e.atletaId == atleta.id && e.squadra == 'nostra') e,
    ];
    final nelReferto = [
      if (referto != null)
        for (final g in [
          ...referto.giocatoriCasa,
          ...referto.giocatoriTrasferta,
        ])
          if (g.atletaId == atleta.id) g,
    ];
    final giocata =
        dati.convocato.contains(p.id) ||
        nelReferto.isNotEmpty ||
        suoiEventi.isNotEmpty;
    if (!giocata) continue;

    int? nostri;
    int? loro;
    if (referto != null) {
      nostri = p.inCasa ? referto.risultatoCasa : referto.risultatoTrasferta;
      loro = p.inCasa ? referto.risultatoTrasferta : referto.risultatoCasa;
    } else {
      final r = risultatoPartita(eventi, p);
      if (r != null) {
        nostri = p.inCasa ? r.golCasa : r.golTrasferta;
        loro = p.inCasa ? r.golTrasferta : r.golCasa;
      }
    }

    final suoiTiri = [
      for (final e in suoiEventi)
        if (e.tipo == 'tiro') e,
    ];
    final golVivo = suoiTiri.where((e) => e.esito == 'gol').length;
    final espulsioniVivo = suoiEventi
        .where((e) => e.tipo == 'espulsione')
        .length;
    tiri += suoiTiri.length;
    golDalVivo += golVivo;

    int? golPartita;
    int? espulsioniPartita;
    if (nelReferto.isNotEmpty) {
      golPartita = nelReferto.fold<int>(0, (s, g) => s + g.reti);
      espulsioniPartita = nelReferto.fold<int>(0, (s, g) => s + g.espulsioni);
    } else if (eventi.isNotEmpty) {
      golPartita = golVivo;
      espulsioniPartita = espulsioniVivo;
    }
    gol += golPartita ?? 0;
    espulsioni += espulsioniPartita ?? 0;
    partite.add(
      PartitaNelReport(
        partita: p,
        nostri: nostri,
        loro: loro,
        gol: golPartita,
        espulsioni: espulsioniPartita,
      ),
    );
  }

  // Test: per ognuno il primo e l'ultimo risultato del periodo.
  final testNelReport = <TestNelReport>[];
  for (final t in dati.test) {
    final storico = [
      for (final r in storicoAtleta(t, dati.risultatiTest, atleta.id))
        if (periodo.contiene(r.data)) r,
    ];
    if (storico.isEmpty) continue;
    testNelReport.add(
      TestNelReport(
        test: t,
        primo: storico.first,
        ultimo: storico.last,
        volte: storico.length,
      ),
    );
  }
  testNelReport.sort(
    (a, b) => a.test.nome.toLowerCase().compareTo(b.test.nome.toLowerCase()),
  );

  // Obiettivi: le schede a cui ha risposto entro la fine del periodo
  // (gli obiettivi di settembre valgono anche per un report di febbraio).
  final schedaPer = {for (final s in dati.schedeObiettivi) s.id: s};
  final fine = aggiungiGiorni(periodo.al, 1);
  final obiettivi = [
    for (final r in dati.risposteObiettivi)
      if (r.atletaId == atleta.id &&
          r.inviataAt.isBefore(fine) &&
          schedaPer[r.schedaId] != null)
        ObiettivoNelReport(scheda: schedaPer[r.schedaId]!, risposta: r),
  ]..sort((a, b) => a.scheda.createdAt.compareTo(b.scheda.createdAt));

  BenessereNelReport? benessere;
  if (conBenessere) {
    final schede = [
      for (final s in dati.benessere)
        if (s.atletaId == atleta.id && periodo.contiene(s.data)) s,
    ];
    final indici = [for (final s in schede) ?indiceVociBenessere(s)];
    final rpe = [
      for (final r in dati.rpe)
        if (r.atletaId == atleta.id && periodo.contiene(r.data)) r.rpe,
    ];
    benessere = BenessereNelReport(
      schede: schede.length,
      indice: indici.isEmpty
          ? null
          : (indici.reduce((a, b) => a + b) / indici.length).round(),
      sonno: schede.isEmpty
          ? null
          : schede.map((s) => s.oreSonno).reduce((a, b) => a + b) /
                schede.length,
      sedute: rpe.length,
      rpe: rpe.isEmpty ? null : rpe.reduce((a, b) => a + b) / rpe.length,
    );
  }

  final testoNota = nota?.trim();
  return ReportAtleta(
    atleta: atleta,
    periodo: periodo,
    creatoIl: adesso,
    presenti: presenti,
    ritardi: conta(statoRitardo),
    assenti: conta(statoAssente),
    giustificati: conta(statoGiustificato),
    allenamenti: rilevanti.length,
    partite: partite,
    gol: gol,
    espulsioni: espulsioni,
    tiri: tiri,
    golDalVivo: golDalVivo,
    portiere: atleta.portiere ? dati.portiere : null,
    test: testNelReport,
    obiettivi: obiettivi,
    obiettiviLetti: dati.obiettiviLetti,
    benessere: benessere,
    squadra: squadra,
    categoria: categoria,
    nota: (testoNota == null || testoNota.isEmpty) ? null : testoNota,
  );
}

/// Le cinque voci della scheda su 100, come la base della Prontezza
/// (`calcolaPunteggio`), senza le penalità di sonno, dolori e sintomi.
int? indiceVociBenessere(SchedaBenessere s) {
  final voci = [
    s.qualitaSonno,
    s.energia,
    s.muscoli,
    s.stress,
    s.umore,
  ].whereType<int>().toList();
  if (voci.isEmpty) return null;
  return (voci.map((v) => v * 20).reduce((a, b) => a + b) / voci.length)
      .round();
}
