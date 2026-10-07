/// Proposta di scheda restituita dalla generazione AI, già validata lato
/// server (Edge Function) contro i valori noti di blocco/stile/esecuzione/
/// zona. Non è ancora un `Allenamento` salvato: la conferma manuale del
/// coach (prossimo punto della roadmap) la trasforma in righe reali.
class SchedaGenerata {
  const SchedaGenerata({
    required this.titolo,
    this.note,
    required this.serie,
    this.minutiStimati,
  });

  final String titolo;
  final String? note;
  final List<SerieGenerata> serie;

  /// Minuti stimati dalla Edge Function, gli stessi usati per rispettare
  /// i minuti massimi richiesti: `null` per le schede che non passano dal
  /// generatore (es. dettatura), dove si ricade su `stimaMinutiSessione`.
  final int? minutiStimati;

  int get volumeTotaleM =>
      serie.fold(0, (totale, s) => totale + s.distanzaTotaleM);

  /// Metri del solo blocco "principale" (lavoro centrale).
  int get volumeLavoroCentraleM => serie
      .where((s) => s.blocco == 'principale')
      .fold(0, (totale, s) => totale + s.distanzaTotaleM);

  factory SchedaGenerata.fromMap(Map<String, dynamic> map) {
    return SchedaGenerata(
      titolo: map['titolo'] as String,
      note: map['note'] as String?,
      serie: (map['serie'] as List)
          .map((voce) => SerieGenerata.fromMap(voce as Map<String, dynamic>))
          .toList(),
      minutiStimati: (map['minutiStimati'] as num?)?.round(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titolo': titolo,
      'note': note,
      'serie': serie.map((s) => s.toMap()).toList(),
      'minutiStimati': minutiStimati,
    };
  }
}

/// Ripartenza proposta per una singola corsia (vedi [CorsiaGenerazione]),
/// per una serie della scheda generata.
class RipartenzaCorsia {
  const RipartenzaCorsia({required this.nome, required this.ripartenzaS});

  final String nome;
  final double ripartenzaS;

  factory RipartenzaCorsia.fromMap(Map<String, dynamic> map) {
    return RipartenzaCorsia(
      nome: map['nome'] as String,
      ripartenzaS: (map['ripartenzaS'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nome': nome, 'ripartenzaS': ripartenzaS};
  }
}

class SerieGenerata {
  const SerieGenerata({
    required this.ordine,
    required this.blocco,
    required this.ripetute,
    required this.distanzaM,
    required this.stile,
    required this.esecuzione,
    this.zona,
    this.recuperoS,
    this.attrezzatura,
    this.note,
    this.ripartenzePerCorsia = const [],
    this.bloccoLibreriaId,
    this.nuovo = false,
  });

  final int ordine;
  final String blocco;
  final int ripetute;
  final int distanzaM;
  final String stile;
  final String esecuzione;
  final String? zona;
  final int? recuperoS;
  final String? attrezzatura;
  final String? note;

  /// Una voce per corsia richiesta (vedi [CorsiaGenerazione]); vuota se
  /// la generazione non aveva passi di riferimento da usare, o se questo
  /// tipo di serie (es. riscaldamento) non ha una ripartenza sensata.
  final List<RipartenzaCorsia> ripartenzePerCorsia;

  /// Id del blocco di libreria scelto e adattato dall'AI per questa
  /// serie (FASE 3) — `null` se la generazione non usava una libreria
  /// (club senza blocchi approvati) o se questa serie è [nuovo].
  final String? bloccoLibreriaId;

  /// Vero se l'AI non ha trovato nessun blocco adatto e ne ha inventata
  /// una: al salvataggio finisce anche in libreria come bozza da
  /// approvare (vedi `TrainingBlocksRepository.salvaSerieComeBlocco`).
  final bool nuovo;

  int get distanzaTotaleM => ripetute * distanzaM;

  factory SerieGenerata.fromMap(Map<String, dynamic> map) {
    return SerieGenerata(
      ordine: map['ordine'] as int,
      blocco: map['blocco'] as String,
      ripetute: map['ripetute'] as int,
      distanzaM: map['distanzaM'] as int,
      stile: map['stile'] as String,
      esecuzione: map['esecuzione'] as String,
      zona: map['zona'] as String?,
      recuperoS: map['recuperoS'] as int?,
      attrezzatura: map['attrezzatura'] as String?,
      note: map['note'] as String?,
      ripartenzePerCorsia:
          (map['ripartenzePerCorsia'] as List<dynamic>?)
              ?.map((v) => RipartenzaCorsia.fromMap(v as Map<String, dynamic>))
              .toList() ??
          const [],
      bloccoLibreriaId: map['bloccoLibreriaId'] as String?,
      nuovo: map['nuovo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ordine': ordine,
      'blocco': blocco,
      'ripetute': ripetute,
      'distanzaM': distanzaM,
      'stile': stile,
      'esecuzione': esecuzione,
      'zona': zona,
      'recuperoS': recuperoS,
      'attrezzatura': attrezzatura,
      'note': note,
      'ripartenzePerCorsia': ripartenzePerCorsia.map((r) => r.toMap()).toList(),
      'bloccoLibreriaId': bloccoLibreriaId,
      'nuovo': nuovo,
    };
  }
}
