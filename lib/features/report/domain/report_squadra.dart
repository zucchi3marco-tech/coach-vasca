import '../../../core/utils/giorni.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../core/utils/percentuale_presenze.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../campionati/domain/campionato_fin.dart';
import '../../carico/domain/rpe_seduta.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/domain/risultato_partita.dart';
import '../../pallanuoto/domain/statistiche_eventi.dart';
import '../../presenze/domain/presenza.dart';
import '../../referti/domain/referto_partita.dart';
import 'report_atleta.dart';

/// Un girone FIN della squadra con la sua classifica, come si è letta
/// (o null se non si è potuta leggere: serve la rete la prima volta).
class GironeLetto {
  const GironeLetto({
    required this.collegato,
    this.girone,
    this.lettoIl,
    this.daCopia = false,
  });

  final GironeCollegato collegato;
  final GironeFin? girone;
  final DateTime? lettoIl;

  /// Letta dalla copia sul telefono, non dal sito.
  final bool daCopia;
}

/// I dati grezzi da cui nasce il report della squadra, già letti.
class DatiReportSquadra {
  const DatiReportSquadra({
    this.atleti = const [],
    this.allenamenti = const [],
    this.presenze = const [],
    this.partite = const [],
    this.referti = const [],
    this.eventi = const [],
    this.gironi = const [],
    this.gironiLetti = true,
    this.benessere = const [],
    this.rpe = const [],
  });

  /// Tutti gli atleti del club, anche quelli non più attivi (per i nomi
  /// dei marcatori).
  final List<Atleta> atleti;

  /// Gli allenamenti del club nel periodo.
  final List<Allenamento> allenamenti;

  /// Le presenze del club.
  final List<Presenza> presenze;

  /// Le partite del club nel periodo.
  final List<Partita> partite;
  final List<RefertoPartita> referti;
  final List<EventoPartita> eventi;

  /// I gironi FIN della squadra.
  final List<GironeLetto> gironi;

  /// false se non si è potuto sapere quali gironi ha la squadra.
  final bool gironiLetti;

  /// Le schede del benessere e gli RPE del club: vuote se non si mettono.
  final List<SchedaBenessere> benessere;
  final List<RpeSeduta> rpe;
}

/// Una partita già giocata nel periodo.
class PartitaDellaSquadra {
  const PartitaDellaSquadra({
    required this.partita,
    this.nostri,
    this.loro,
    this.daReferto = false,
  });

  final Partita partita;
  final int? nostri;
  final int? loro;
  final bool daReferto;

  bool get haRisultato => nostri != null && loro != null;

  /// "11-7", prima i nostri gol; "—" senza risultato.
  String get risultato => haRisultato ? '$nostri-$loro' : '—';

  /// "Vinta", "Pari", "Persa"; "—" senza risultato.
  String get esito {
    if (!haRisultato) return '—';
    return nostri! > loro!
        ? 'Vinta'
        : nostri == loro
        ? 'Pari'
        : 'Persa';
  }
}

/// Gol ed espulsioni di un atleta nelle partite del periodo.
class MarcatoreDellaSquadra {
  const MarcatoreDellaSquadra({
    required this.atletaId,
    required this.nome,
    required this.partite,
    required this.gol,
    required this.espulsioni,
  });

  final String atletaId;
  final String nome;
  final int partite;
  final int gol;
  final int espulsioni;
}

/// Le presenze di un atleta della squadra.
class PresenzeDellAtleta {
  const PresenzeDellAtleta({
    required this.atleta,
    required this.presenti,
    required this.ritardi,
    required this.assenti,
    required this.giustificati,
    required this.allenamenti,
  });

  final Atleta atleta;

  /// Comprende i [ritardi].
  final int presenti;
  final int ritardi;
  final int assenti;
  final int giustificati;
  final int allenamenti;

  int? get percentuale =>
      allenamenti == 0 ? null : (presenti / allenamenti * 100).round();
}

/// Il report di una squadra in un periodo, pronto da impaginare.
class ReportSquadra {
  const ReportSquadra({
    required this.nome,
    required this.periodo,
    required this.creatoIl,
    required this.partite,
    required this.presenze,
    required this.marcatori,
    required this.dalVivo,
    required this.partiteDalVivo,
    required this.gironi,
    required this.gironiLetti,
    this.campionato,
    this.benessere,
    this.nota,
  });

  /// La squadra ("U16") o "Tutto il club".
  final String nome;
  final PeriodoReport periodo;
  final DateTime creatoIl;
  final String? campionato;

  final List<PartitaDellaSquadra> partite;
  final List<PresenzeDellAtleta> presenze;

  /// Dal referto, se no dal vivo; prima chi ha segnato di più.
  final List<MarcatoreDellaSquadra> marcatori;

  /// I numeri delle partite seguite dal vivo.
  final NumeriEventi dalVivo;
  final int partiteDalVivo;

  final List<GironeLetto> gironi;
  final bool gironiLetti;

  /// Le medie della squadra; null se non si è messa la spunta.
  final BenessereNelReport? benessere;
  final String? nota;

  List<PartitaDellaSquadra> get conRisultato => [
    for (final p in partite)
      if (p.haRisultato) p,
  ];

  int get vinte => conRisultato.where((p) => p.nostri! > p.loro!).length;
  int get pari => conRisultato.where((p) => p.nostri == p.loro).length;
  int get perse => conRisultato.where((p) => p.nostri! < p.loro!).length;
  int get golFatti => conRisultato.fold(0, (s, p) => s + p.nostri!);
  int get golSubiti => conRisultato.fold(0, (s, p) => s + p.loro!);

  /// Le presenze di tutta la squadra in %: tutte le presenze su tutti gli
  /// allenamenti attesi. Null senza allenamenti.
  int? get percentualePresenze {
    final su = presenze.fold(0, (s, p) => s + p.allenamenti);
    if (su == 0) return null;
    final presenti = presenze.fold(0, (s, p) => s + p.presenti);
    return (presenti / su * 100).round();
  }
}

/// La stagione FIN "2026-2027" tocca il periodo? Va da agosto del primo
/// anno a luglio del secondo; una stagione che non si legge resta dentro.
bool stagioneFinNelPeriodo(String stagione, PeriodoReport periodo) {
  final anno = int.tryParse(RegExp(r'\d{4}').firstMatch(stagione)?[0] ?? '');
  if (anno == null) return true;
  final inizio = DateTime(anno, 8);
  final fine = DateTime(anno + 1, 7, 31);
  return !periodo.al.isBefore(inizio) && !periodo.dal.isAfter(fine);
}

/// Mette insieme il report della squadra [gruppoId] (null: tutto il club)
/// nel [periodo] da [dati].
ReportSquadra reportSquadra({
  required String nome,
  required String? gruppoId,
  required PeriodoReport periodo,
  required DatiReportSquadra dati,
  required DateTime adesso,
  bool conBenessere = false,
  String? campionato,
  String? nota,
}) {
  final giorno = soloData(adesso);
  final nomePer = {for (final a in dati.atleti) a.id: a.nomeCompleto};

  // Gli atleti della squadra: quelli attivi del gruppo (di tutto il club
  // se la stagione è di tutto il club).
  final squadra =
      [
        for (final a in dati.atleti)
          if (a.attivo && (gruppoId == null || a.gruppoId == gruppoId)) a,
      ]..sort(
        (a, b) => a.nomeCompleto.toLowerCase().compareTo(
          b.nomeCompleto.toLowerCase(),
        ),
      );

  // Presenze: per ognuno gli allenamenti già passati in cui era atteso,
  // con la stessa regola dell'app.
  final allenamenti = [
    for (final a in dati.allenamenti)
      if (periodo.contiene(a.data)) a,
  ];
  final presenze = <PresenzeDellAtleta>[];
  for (final atleta in squadra) {
    final rilevanti = allenamentiRilevanti(
      allenamenti: allenamenti,
      presenze: dati.presenze,
      atletaId: atleta.id,
      gruppoAtleta: atleta.gruppoId,
      atteso: (a) => atleta.attesoA(a.gruppoId, a.data),
      adesso: adesso,
    );
    final ids = {for (final a in rilevanti) a.id};
    final suoi = [
      for (final p in dati.presenze)
        if (p.atletaId == atleta.id && ids.contains(p.allenamentoId)) p,
    ];
    int conta(String stato) => suoi.where((p) => p.stato == stato).length;
    presenze.add(
      PresenzeDellAtleta(
        atleta: atleta,
        presenti: suoi.where((p) => contaComePresente(p.stato)).length,
        ritardi: conta(statoRitardo),
        assenti: conta(statoAssente),
        giustificati: conta(statoGiustificato),
        allenamenti: rilevanti.length,
      ),
    );
  }

  // Partite: quelle già giocate del periodo, della squadra o di tutto il
  // club, come nell'elenco delle partite.
  final refertoPer = {for (final r in dati.referti) r.partitaId: r};
  final eventiPer = <String, List<EventoPartita>>{};
  for (final e in dati.eventi) {
    eventiPer.putIfAbsent(e.partitaId, () => []).add(e);
  }
  final giocate = [
    for (final p in dati.partite)
      if (periodo.contiene(p.data) &&
          !soloData(p.data).isAfter(giorno) &&
          visibileNelGruppo(
            gruppoDelRecord: p.gruppoId,
            gruppoSelezionato: gruppoId,
          ))
        p,
  ]..sort((a, b) => a.data.compareTo(b.data));

  final partite = <PartitaDellaSquadra>[];
  final marcatori = <String, ({int partite, int gol, int espulsioni})>{};
  void segna(String atletaId, int gol, int espulsioni) {
    final c = marcatori[atletaId] ?? (partite: 0, gol: 0, espulsioni: 0);
    marcatori[atletaId] = (
      partite: c.partite + 1,
      gol: c.gol + gol,
      espulsioni: c.espulsioni + espulsioni,
    );
  }

  final eventiDalVivo = <EventoPartita>[];
  for (final p in giocate) {
    final referto = refertoPer[p.id];
    final eventi = eventiPer[p.id] ?? const <EventoPartita>[];
    eventiDalVivo.addAll(eventi);
    if (referto != null) {
      partite.add(
        PartitaDellaSquadra(
          partita: p,
          nostri: p.inCasa ? referto.risultatoCasa : referto.risultatoTrasferta,
          loro: p.inCasa ? referto.risultatoTrasferta : referto.risultatoCasa,
          daReferto: true,
        ),
      );
      // Una riga per atleta anche se nel referto compare due volte.
      final perAtleta = <String, (int, int)>{};
      for (final g
          in p.inCasa ? referto.giocatoriCasa : referto.giocatoriTrasferta) {
        final id = g.atletaId;
        if (id == null) continue;
        final c = perAtleta[id] ?? (0, 0);
        perAtleta[id] = (c.$1 + g.reti, c.$2 + g.espulsioni);
      }
      perAtleta.forEach((id, c) => segna(id, c.$1, c.$2));
    } else {
      final r = risultatoPartita(eventi, p);
      partite.add(
        PartitaDellaSquadra(
          partita: p,
          nostri: r == null ? null : (p.inCasa ? r.golCasa : r.golTrasferta),
          loro: r == null ? null : (p.inCasa ? r.golTrasferta : r.golCasa),
        ),
      );
      final perAtleta = <String, (int, int)>{};
      for (final e in eventi) {
        final id = e.atletaId;
        if (id == null || e.squadra != 'nostra') continue;
        final c = perAtleta[id] ?? (0, 0);
        perAtleta[id] = (
          c.$1 + (e.tipo == 'tiro' && e.esito == 'gol' ? 1 : 0),
          c.$2 + (e.tipo == 'espulsione' ? 1 : 0),
        );
      }
      perAtleta.forEach((id, c) => segna(id, c.$1, c.$2));
    }
  }

  final classificaMarcatori =
      [
        for (final MapEntry(:key, :value) in marcatori.entries)
          MarcatoreDellaSquadra(
            atletaId: key,
            nome: nomePer[key] ?? 'Atleta rimosso',
            partite: value.partite,
            gol: value.gol,
            espulsioni: value.espulsioni,
          ),
      ]..sort((a, b) {
        final gol = b.gol.compareTo(a.gol);
        return gol != 0
            ? gol
            : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });

  final statistiche = StatisticheEventi.da(eventiDalVivo);

  BenessereNelReport? benessere;
  if (conBenessere) {
    final ids = {for (final a in squadra) a.id};
    final schede = [
      for (final s in dati.benessere)
        if (ids.contains(s.atletaId) && periodo.contiene(s.data)) s,
    ];
    final indici = [for (final s in schede) ?indiceVociBenessere(s)];
    final rpe = [
      for (final r in dati.rpe)
        if (ids.contains(r.atletaId) && periodo.contiene(r.data)) r.rpe,
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
  return ReportSquadra(
    nome: nome,
    periodo: periodo,
    creatoIl: adesso,
    campionato: campionato,
    partite: partite,
    presenze: presenze,
    marcatori: classificaMarcatori,
    dalVivo: statistiche.squadra,
    partiteDalVivo: statistiche.partite,
    gironi: [
      for (final g in dati.gironi)
        if (stagioneFinNelPeriodo(g.collegato.stagione, periodo)) g,
    ],
    gironiLetti: dati.gironiLetti,
    benessere: benessere,
    nota: (testoNota == null || testoNota.isEmpty) ? null : testoNota,
  );
}
