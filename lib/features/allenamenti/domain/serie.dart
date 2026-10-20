import 'destinatari.dart';

export 'destinatari.dart';
export 'momenti.dart';

/// Le esecuzioni di una serie, nell'ordine dei menu: i valori dell'enum
/// `esecuzione_serie` del database. Dopo il nuoto, il lavoro di
/// pallanuoto (richiesta del coach 2026-10-08) e quello a secco.
const esecuzioniSerie = [
  'nuoto',
  'gambe',
  'braccia',
  'pull',
  'tecnica',
  'remate',
  'test',
  'pallanuoto tecnico-tattico',
  'palleggio',
  'tiri',
  'uomo in più',
  'uomo in meno',
  'gioco da schierati',
  'schemi',
  'partita',
  'a secco',
];

/// Esecuzioni in cui lo stile non conta: "libero" è solo il valore di
/// partenza, e non si scrive né si mostra.
const esecuzioniSenzaStile = {
  'pallanuoto tecnico-tattico',
  'palleggio',
  'tiri',
  'uomo in più',
  'uomo in meno',
  'gioco da schierati',
  'schemi',
  'partita',
  'a secco',
};

/// I dati di una serie, salvata ([Serie]) o appena scritta a testo e non
/// ancora salvata (`SerieScritta`): quello che serve per descriverla,
/// stimarne la durata e disegnarla, senza id né ordine.
abstract interface class DatiSerie {
  String get blocco;
  int get ripetute;
  int? get distanzaM;
  int? get durataS;
  String get stile;
  String get esecuzione;
  String? get zona;
  double? get passoObiettivoS;
  int? get recuperoS;
  double? get ripartenzaS;
  String? get attrezzatura;
  String? get note;

  /// Righe dello stesso gruppo (una piramide, un "2x") hanno lo stesso
  /// valore; null per una serie da sola.
  String? get piramideId;

  /// Il recupero dopo la serie, prima della successiva, in secondi
  /// ("rec 2'" su una riga da sola nel compilatore). Diverso da
  /// [recuperoS], che sta fra le ripetute della stessa serie.
  int? get recuperoDopoS;

  /// Per chi è la serie: tutto il gruppo, un ruolo, alcuni atleti.
  Destinatari get destinatari;

  /// Le serie con lo stesso valore si fanno in parallelo, ognuno nella
  /// sua colonna (vedi `serieDellAtleta`): mentre tutti nuotano, i
  /// portieri parano. null per una serie normale, una dopo l'altra.
  String? get momentoId;

  /// Com'è andata: 'fatta' | 'saltata' segnato a bordo vasca e, per una
  /// serie fatta in parte, quanto se n'è fatto (vedi `volumeFatto`). Solo
  /// le serie salvate lo hanno; null per quelle scritte o generate.
  String? get esito;
  int? get metriFatti;
  int? get secondiFatti;
}

class Serie implements DatiSerie {
  const Serie({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.ordine,
    required this.blocco,
    required this.ripetute,
    this.distanzaM,
    this.durataS,
    required this.stile,
    required this.esecuzione,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
    this.ripartenzaS,
    this.attrezzatura,
    this.note,
    this.piramideId,
    this.esito,
    this.recuperoDopoS,
    this.destinatari = Destinatari.tutti,
    this.momentoId,
    this.metriFatti,
    this.secondiFatti,
  });

  final String id;
  final String allenamentoId;
  final String clubId;
  final int ordine;
  @override
  final String blocco; // riscaldamento | principale | defaticamento | altro
  @override
  final int ripetute;

  /// Una serie usa l'una o l'altra, mai entrambe — vedi [aTempo].
  @override
  final int? distanzaM;
  @override
  final int? durataS;
  @override
  final String stile; // libero | dorso | rana | delfino | misti
  @override
  final String esecuzione; // uno di [esecuzioniSerie]
  @override
  final String? zona; // A1 | A2 | B1 | B2 | C1 | C2 | C3 | D (C: storico)
  @override
  final double? passoObiettivoS;
  @override
  final int? recuperoS;
  @override
  final double? ripartenzaS;
  @override
  final String? attrezzatura;
  @override
  final String? note;

  /// Righe della stessa piramide (es. 50-100-200-100-50) condividono
  /// questo id, per raggrupparle in un'unica riga visiva — null per una
  /// serie normale.
  @override
  final String? piramideId;

  @override
  final int? recuperoDopoS;

  @override
  final Destinatari destinatari;

  @override
  final String? momentoId;

  /// 'fatta' | 'saltata', segnato a bordo vasca durante la seduta; null
  /// finché non si segna. Le saltate non contano nel volume reale.
  @override
  final String? esito;

  /// Fatta in parte ("Com'è andata"): quanto si è fatto, in metri per una
  /// serie a distanza o in secondi per una a tempo. null se è fatta tutta,
  /// saltata o non ancora segnata. Vedi `volumeFatto`.
  @override
  final int? metriFatti;
  @override
  final int? secondiFatti;

  bool get fatta => esito == 'fatta';
  bool get saltata => esito == 'saltata';

  /// Metri totali di nuoto — 0 per una serie a tempo: non si stima una
  /// distanza, i riepiloghi la segnalano a parte (vedi [aTempo]).
  int get distanzaTotaleM => ripetute * (distanzaM ?? 0);

  bool get aTempo => durataS != null;

  factory Serie.fromMap(Map<String, dynamic> map) {
    return Serie(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      clubId: map['club_id'] as String,
      ordine: map['ordine'] as int,
      blocco: map['blocco'] as String,
      ripetute: map['ripetute'] as int,
      distanzaM: map['distanza_m'] as int?,
      durataS: map['durata_s'] as int?,
      stile: map['stile'] as String,
      esecuzione: map['esecuzione'] as String,
      zona: map['zona'] as String?,
      passoObiettivoS: (map['passo_obiettivo_s'] as num?)?.toDouble(),
      recuperoS: map['recupero_s'] as int?,
      ripartenzaS: (map['ripartenza_s'] as num?)?.toDouble(),
      attrezzatura: map['attrezzatura'] as String?,
      note: map['note'] as String?,
      piramideId: map['piramide_id'] as String?,
      esito: map['esito'] as String?,
      recuperoDopoS: map['recupero_dopo_s'] as int?,
      destinatari: Destinatari.fromMap(map),
      momentoId: map['momento_id'] as String?,
      metriFatti: map['metri_fatti'] as int?,
      secondiFatti: map['secondi_fatti'] as int?,
    );
  }
}
