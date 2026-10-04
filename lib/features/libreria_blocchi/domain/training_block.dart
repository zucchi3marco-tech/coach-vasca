/// Un blocco di allenamento approvato dal coach (es. "8x100 soglia"),
/// fatto di una o più [TrainingBlockParte] — stesso schema
/// allenamento -> serie, ma riusabile da un generatore (FASE 3) invece
/// di essere legato a una data.
class TrainingBlock {
  const TrainingBlock({
    required this.id,
    required this.clubId,
    required this.codice,
    required this.sport,
    required this.fase,
    required this.obiettivo,
    required this.zoneCoinvolte,
    required this.titolo,
    required this.descrizione,
    this.stilePrincipale,
    required this.livelli,
    this.attrezzi,
    required this.metriTotali,
    required this.durataStimataMin,
    this.note,
    required this.stato,
    required this.fonte,
    this.importatoIl,
    required this.modificatoInApp,
  });

  final String id;
  final String clubId;

  /// Chiave di business (es. "N-001"), unica per club — usata
  /// dall'importatore Excel per capire se un blocco esiste già.
  final String codice;

  /// 'nuoto' | 'pallanuoto' | 'entrambi'.
  final String sport;

  /// Vocabolario aperto (es. "Riscaldamento", "Tiro"), come la
  /// categoria degli schemi tattici.
  final String fase;
  final String obiettivo;

  /// Testo libero di sintesi (es. "A1 / A2 / RG / V"): solo
  /// visualizzazione, non usato in nessun calcolo.
  final String zoneCoinvolte;

  final String titolo;
  final String descrizione;
  final String? stilePrincipale;

  /// Elenco separato da virgole (es. "Ragazzi, Assoluti, Master").
  final String livelli;
  final String? attrezzi;
  final int metriTotali;
  final int durataStimataMin;
  final String? note;

  /// 'approvato' | 'bozza'.
  final String stato;
  final String fonte;

  /// Quando importato/seminato l'ultima volta dal file Excel — null se
  /// creato a mano nell'app.
  final DateTime? importatoIl;

  /// Vero se il coach l'ha modificato nell'app dopo l'ultimo import:
  /// l'importatore non lo sovrascrive più.
  final bool modificatoInApp;

  factory TrainingBlock.fromMap(Map<String, dynamic> map) {
    return TrainingBlock(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      codice: map['codice'] as String,
      sport: map['sport'] as String,
      fase: map['fase'] as String,
      obiettivo: map['obiettivo'] as String,
      zoneCoinvolte: map['zone_coinvolte'] as String,
      titolo: map['titolo'] as String,
      descrizione: map['descrizione'] as String,
      stilePrincipale: map['stile_principale'] as String?,
      livelli: map['livelli'] as String? ?? '',
      attrezzi: map['attrezzi'] as String?,
      metriTotali: map['metri_totali'] as int,
      durataStimataMin: map['durata_stimata_min'] as int,
      note: map['note'] as String?,
      stato: map['stato'] as String,
      fonte: map['fonte'] as String,
      importatoIl: map['importato_il'] == null
          ? null
          : DateTime.parse(map['importato_il'] as String),
      modificatoInApp: map['modificato_in_app'] as bool? ?? false,
    );
  }
}

/// Una serie di un [TrainingBlock]. Usa distanza o durata, mai entrambe
/// (stesso principio della serie vera, vedi `Serie.aTempo`). [zona] resta
/// nel vocabolario esteso dell'Excel (A1/A2/B1/B2/C1/C2/V/RG/T/TT/TEST):
/// la traduzione in `zona_intensita` avviene solo quando una parte
/// diventa una serie vera (FASE 3), non qui.
class TrainingBlockParte {
  const TrainingBlockParte({
    required this.id,
    required this.bloccoId,
    required this.clubId,
    required this.ordine,
    required this.giri,
    required this.ripetizioni,
    this.distanzaM,
    this.durataS,
    this.stile,
    this.esercizio,
    required this.zona,
    required this.esecuzione,
    this.recuperoS,
    this.attrezzi,
    this.note,
  });

  final String id;
  final String bloccoId;
  final String clubId;
  final int ordine;
  final int giri;
  final int ripetizioni;
  final int? distanzaM;
  final int? durataS;
  final String? stile;

  /// Testo libero (es. "sciolto", "respirazione ogni 3-5-7 bracciate").
  final String? esercizio;

  /// Vocabolario esteso dell'Excel: A1, A2, B1, B2, C1, C2, V, RG, T, TT,
  /// TEST.
  final String zona;

  /// nuoto | gambe | braccia | pull | tecnica | remate | pallanuoto
  /// tecnico-tattico | a secco — dedotta all'importazione.
  final String esecuzione;
  final int? recuperoS;
  final String? attrezzi;
  final String? note;

  bool get aTempo => durataS != null;

  factory TrainingBlockParte.fromMap(Map<String, dynamic> map) {
    return TrainingBlockParte(
      id: map['id'] as String,
      bloccoId: map['blocco_id'] as String,
      clubId: map['club_id'] as String,
      ordine: map['ordine'] as int,
      giri: map['giri'] as int,
      ripetizioni: map['ripetizioni'] as int,
      distanzaM: map['distanza_m'] as int?,
      durataS: map['durata_s'] as int?,
      stile: map['stile'] as String?,
      esercizio: map['esercizio'] as String?,
      zona: map['zona'] as String,
      esecuzione: map['esecuzione'] as String,
      recuperoS: map['recupero_s'] as int?,
      attrezzi: map['attrezzi'] as String?,
      note: map['note'] as String?,
    );
  }
}
