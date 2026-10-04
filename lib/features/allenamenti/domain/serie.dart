class Serie {
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
  });

  final String id;
  final String allenamentoId;
  final String clubId;
  final int ordine;
  final String blocco; // riscaldamento | principale | defaticamento | altro
  final int ripetute;

  /// Una serie usa l'una o l'altra, mai entrambe — vedi [aTempo].
  final int? distanzaM;
  final int? durataS;
  final String stile; // libero | dorso | rana | delfino | misti
  final String esecuzione; // nuoto | gambe | braccia | pull | tecnica | remate
  final String? zona; // A1 | A2 | B1 | B2 | C1 | C2 | C3 | D (C: storico)
  final double? passoObiettivoS;
  final int? recuperoS;
  final double? ripartenzaS;
  final String? attrezzatura;
  final String? note;

  /// Righe della stessa piramide (es. 50-100-200-100-50) condividono
  /// questo id, per raggrupparle in un'unica riga visiva — null per una
  /// serie normale.
  final String? piramideId;

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
    );
  }
}
