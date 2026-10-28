import '../../../core/utils/date_format.dart';
import '../../../core/utils/giorni.dart';

class Stagione {
  const Stagione({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppoId,
    this.campionato,
    this.fasi = const [],
  });

  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppoId;

  /// Campionato disputato in questa stagione: le partite create con una
  /// data compresa fra [dataInizio] e [dataFine] lo ereditano
  /// automaticamente, non si sceglie più partita per partita.
  final String? campionato;

  /// Le fasi (preparazione, andata, ritorno...) con i loro obiettivi
  /// settimanali, in ordine di data.
  final List<FaseStagione> fasi;
}

/// Una fase della stagione con gli obiettivi di ogni sua settimana.
class FaseStagione {
  const FaseStagione({
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivoMetri,
    this.obiettivoCarico,
    this.scopo,
    this.righeSettimane = const {},
  });

  factory FaseStagione.fromMap(Map<String, dynamic> m) => FaseStagione(
    nome: m['nome'] as String,
    dataInizio: DateTime.parse(m['data_inizio'] as String),
    dataFine: DateTime.parse(m['data_fine'] as String),
    obiettivoMetri: (m['obiettivo_metri'] as num?)?.round(),
    obiettivoCarico: (m['obiettivo_carico'] as num?)?.round(),
    scopo: _testoPieno(m['scopo']),
    righeSettimane: {
      if (m['righe_settimane'] case final Map<dynamic, dynamic> righe)
        for (final MapEntry(:key, :value) in righe.entries)
          _lunedi(DateTime.parse(key as String)): ?_testoPieno(value),
    },
  );

  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;

  /// Metri a settimana che la squadra dovrebbe fare.
  final int? obiettivoMetri;

  /// Carico a settimana (RPE × minuti) di un atleta.
  final int? obiettivoCarico;

  /// «A cosa serve»: una o due righe per gli atleti, che le leggono nella
  /// home per tutte le settimane della fase.
  final String? scopo;

  /// Una riga diversa per una settimana precisa (chiave: il lunedì), al
  /// posto di [scopo].
  final Map<DateTime, String> righeSettimane;

  /// Le settimane della fase, dal lunedì della prima al lunedì
  /// dell'ultima.
  List<DateTime> get settimane {
    final ultima = _lunedi(dataFine);
    return [
      for (
        var l = _lunedi(dataInizio);
        !l.isAfter(ultima);
        l = aggiungiGiorni(l, 7)
      )
        l,
    ];
  }

  /// Cosa leggono gli atleti nella settimana del [lunedi]: la riga di
  /// quella settimana o, se non c'è, «A cosa serve».
  String? testoDellaSettimana(DateTime lunedi) =>
      righeSettimane[_lunedi(lunedi)] ?? scopo;

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'data_inizio': formatDateOnly(dataInizio),
    'data_fine': formatDateOnly(dataFine),
    'obiettivo_metri': ?obiettivoMetri,
    'obiettivo_carico': ?obiettivoCarico,
    'scopo': ?_testoPieno(scopo),
    if (righeSettimane.isNotEmpty)
      'righe_settimane': {
        for (final MapEntry(:key, :value) in righeSettimane.entries)
          formatDateOnly(key): value,
      },
  };

  /// La stessa fase spostata di [giorni] giorni di calendario (per
  /// duplicare la stagione su un altro anno).
  FaseStagione spostata(int giorni) => FaseStagione(
    nome: nome,
    dataInizio: aggiungiGiorni(dataInizio, giorni),
    dataFine: aggiungiGiorni(dataFine, giorni),
    obiettivoMetri: obiettivoMetri,
    obiettivoCarico: obiettivoCarico,
    scopo: scopo,
    righeSettimane: {
      for (final MapEntry(:key, :value) in righeSettimane.entries)
        _lunedi(aggiungiGiorni(key, giorni)): value,
    },
  );
}

/// Il lunedì (a mezzanotte) della settimana di [d].
DateTime _lunedi(DateTime d) => soloData(aggiungiGiorni(d, -(d.weekday - 1)));

/// Il testo senza spazi in più; null se vuoto.
String? _testoPieno(Object? v) {
  final t = (v as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Quanto può essere lungo «A cosa serve» (e la riga di una settimana).
const lunghezzaMassimaScopo = 200;

/// La settimana in corso vista dall'atleta: la fase, a che settimana
/// siamo e cosa c'è da leggere.
typedef SettimanaDiFase = ({
  FaseStagione fase,
  int numero,
  int totale,
  String? testo,
});

/// La settimana di [oggi] per un atleta del gruppo [gruppoId] (vedi
/// [faseDellaSettimana]); null se nessuna fase la tocca.
SettimanaDiFase? settimanaDellAtleta(
  List<Stagione> stagioni,
  String? gruppoId,
  DateTime oggi,
) {
  final lunedi = _lunedi(oggi);
  final fase = faseDellaSettimana(stagioni, gruppoId, lunedi);
  if (fase == null) return null;
  final settimane = fase.settimane;
  final indice = settimane.indexOf(lunedi);
  return (
    fase: fase,
    numero: indice < 0 ? 1 : indice + 1,
    totale: settimane.length,
    testo: fase.testoDellaSettimana(lunedi),
  );
}

/// I nomi proposti per una fase nuova.
const nomiFasiProposti = [
  'Preparazione',
  'Andata',
  'Ritorno',
  'Playoff',
  'Scarico',
];

/// La fase della settimana del [lunedi] per il gruppo [gruppoId]: fra le
/// stagioni del gruppo e poi quelle di club (mai di un altro gruppo),
/// quella che copre più giorni di quella settimana. null se nessuna fase
/// la tocca.
FaseStagione? faseDellaSettimana(
  List<Stagione> stagioni,
  String? gruppoId,
  DateTime lunedi,
) {
  final inizio = soloData(lunedi);
  final fine = aggiungiGiorni(inizio, 6);
  int giorniCoperti(FaseStagione f) {
    final da = f.dataInizio.isAfter(inizio) ? soloData(f.dataInizio) : inizio;
    final a = f.dataFine.isBefore(fine) ? soloData(f.dataFine) : fine;
    return a.isBefore(da) ? 0 : giorniTra(da, a) + 1;
  }

  FaseStagione? migliore(Iterable<Stagione> candidate) {
    FaseStagione? scelta;
    var giorni = 0;
    for (final s in candidate) {
      for (final f in s.fasi) {
        final g = giorniCoperti(f);
        if (g > giorni) {
          scelta = f;
          giorni = g;
        }
      }
    }
    return scelta;
  }

  return (gruppoId == null
          ? null
          : migliore(stagioni.where((s) => s.gruppoId == gruppoId))) ??
      migliore(stagioni.where((s) => s.gruppoId == null));
}

/// Etichetta della "categoria" di una stagione di club (senza gruppo).
const etichettaTuttiGliAtleti = 'Tutti gli atleti';

String _giornoMeseAnno(DateTime d) =>
    '${d.day}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Titolo automatico di una stagione, es. "Campionato U14 -
/// 1/09/2026-30/06/2027": parola fissa "Campionato", la categoria (il
/// nome del gruppo, oppure [etichettaTuttiGliAtleti]) e le date.
String titoloStagione({
  required String? categoria,
  required DateTime dataInizio,
  required DateTime dataFine,
}) {
  final cat = (categoria == null || categoria.trim().isEmpty)
      ? ''
      : ' ${categoria.trim()}';
  return 'Campionato$cat - ${_giornoMeseAnno(dataInizio)}-'
      '${_giornoMeseAnno(dataFine)}';
}

/// La stagione che contiene la data odierna: preferisce quelle del gruppo
/// indicato, altrimenti quelle di club (senza gruppo) — mai quelle di un
/// altro gruppo. [gruppoId] null = nessun gruppo: solo le stagioni di
/// club. Usata per la "stagione in corso" (home dell'atleta, tab Partite).
/// Torna null se nessuna stagione visibile contiene oggi.
Stagione? stagioneCorrenteDiGruppo(
  List<Stagione> stagioni,
  String? gruppoId, {
  DateTime? oggi,
}) {
  final data = oggi ?? DateTime.now();
  bool inCorso(Stagione s) =>
      !data.isBefore(s.dataInizio) && !data.isAfter(s.dataFine);
  final delGruppo = gruppoId == null
      ? const <Stagione>[]
      : stagioni.where((s) => s.gruppoId == gruppoId && inCorso(s));
  if (delGruppo.isNotEmpty) return delGruppo.first;
  for (final s in stagioni) {
    if (s.gruppoId == null && inCorso(s)) return s;
  }
  return null;
}

/// Le stagioni che riguardano un atleta del gruppo [gruppoId]: quelle del
/// suo gruppo e quelle di club (senza gruppo), mai quelle di un altro
/// gruppo. [gruppoId] null = atleta senza gruppo: solo quelle di club.
List<Stagione> stagioniDiAtleta(List<Stagione> stagioni, String? gruppoId) => [
  for (final s in stagioni)
    if (s.gruppoId == null || s.gruppoId == gruppoId) s,
];

/// Il campionato che una partita eredita dalla stagione che ne comprende la
/// data: preferisce una stagione del suo gruppo, poi una di club (senza
/// gruppo). Una partita di club (senza gruppo) usa una stagione di club e,
/// solo se non c'è, la prima che copre la data (compatibilità con le
/// partite create prima della divisione per gruppo). Mai la stagione di
/// un altro gruppo per una partita che ha un gruppo.
String? campionatoPerData(
  List<Stagione> stagioni,
  DateTime data,
  String? gruppoId,
) {
  final giorno = DateTime(data.year, data.month, data.day);
  final coprono = [
    for (final s in stagioni)
      if (!giorno.isBefore(
            DateTime(s.dataInizio.year, s.dataInizio.month, s.dataInizio.day),
          ) &&
          !giorno.isAfter(
            DateTime(s.dataFine.year, s.dataFine.month, s.dataFine.day),
          ))
        s,
  ];
  if (gruppoId != null) {
    for (final s in coprono) {
      if (s.gruppoId == gruppoId) return s.campionato;
    }
  }
  for (final s in coprono) {
    if (s.gruppoId == null) return s.campionato;
  }
  if (gruppoId == null && coprono.isNotEmpty) return coprono.first.campionato;
  return null;
}

/// La stagione di cui mostrare le partite in elenco: quella in corso del
/// gruppo (o di club); se oggi nessuna è in corso, la più recente fra
/// quelle visibili al gruppo. Torna null se non esiste nessuna stagione
/// visibile. [gruppoId] null = "Tutti gli atleti": tutte le stagioni sono
/// visibili.
Stagione? stagionePerElenco(
  List<Stagione> stagioni,
  String? gruppoId, {
  DateTime? oggi,
}) {
  final corrente = stagioneCorrenteDiGruppo(stagioni, gruppoId, oggi: oggi);
  if (corrente != null) return corrente;
  final visibili = [
    for (final s in stagioni)
      if (gruppoId == null || s.gruppoId == null || s.gruppoId == gruppoId) s,
  ];
  if (visibili.isEmpty) return null;
  visibili.sort((a, b) => b.dataFine.compareTo(a.dataFine));
  return visibili.first;
}
