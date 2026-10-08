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
  final String esecuzione; // nuoto | gambe | braccia | pull | tecnica | remate
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

  /// 'fatta' | 'saltata', segnato a bordo vasca durante la seduta; null
  /// finché non si segna. Le saltate non contano nel volume reale.
  final String? esito;

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
    );
  }
}
