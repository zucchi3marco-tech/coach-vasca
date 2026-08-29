class Serie {
  const Serie({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.ordine,
    required this.blocco,
    required this.ripetute,
    required this.distanzaM,
    required this.stile,
    required this.esecuzione,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
    this.ripartenzaS,
    this.attrezzatura,
    this.note,
  });

  final String id;
  final String allenamentoId;
  final String clubId;
  final int ordine;
  final String blocco; // riscaldamento | principale | defaticamento | altro
  final int ripetute;
  final int distanzaM;
  final String stile; // libero | dorso | rana | delfino | misti
  final String esecuzione; // nuoto | gambe | braccia | pull | tecnica
  final String? zona; // A1 | A2 | B1 | B2 | C | D
  final double? passoObiettivoS;
  final int? recuperoS;
  final double? ripartenzaS;
  final String? attrezzatura;
  final String? note;

  int get distanzaTotaleM => ripetute * distanzaM;

  factory Serie.fromMap(Map<String, dynamic> map) {
    return Serie(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      clubId: map['club_id'] as String,
      ordine: map['ordine'] as int,
      blocco: map['blocco'] as String,
      ripetute: map['ripetute'] as int,
      distanzaM: map['distanza_m'] as int,
      stile: map['stile'] as String,
      esecuzione: map['esecuzione'] as String,
      zona: map['zona'] as String?,
      passoObiettivoS: (map['passo_obiettivo_s'] as num?)?.toDouble(),
      recuperoS: map['recupero_s'] as int?,
      ripartenzaS: (map['ripartenza_s'] as num?)?.toDouble(),
      attrezzatura: map['attrezzatura'] as String?,
      note: map['note'] as String?,
    );
  }
}
