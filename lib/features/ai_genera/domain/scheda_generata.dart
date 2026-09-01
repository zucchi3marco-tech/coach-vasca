/// Proposta di scheda restituita dalla generazione AI, già validata lato
/// server (Edge Function) contro i valori noti di blocco/stile/esecuzione/
/// zona. Non è ancora un `Allenamento` salvato: la conferma manuale del
/// coach (prossimo punto della roadmap) la trasforma in righe reali.
class SchedaGenerata {
  const SchedaGenerata({required this.titolo, this.note, required this.serie});

  final String titolo;
  final String? note;
  final List<SerieGenerata> serie;

  int get volumeTotaleM =>
      serie.fold(0, (totale, s) => totale + s.distanzaTotaleM);

  factory SchedaGenerata.fromMap(Map<String, dynamic> map) {
    return SchedaGenerata(
      titolo: map['titolo'] as String,
      note: map['note'] as String?,
      serie: (map['serie'] as List)
          .map((voce) => SerieGenerata.fromMap(voce as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titolo': titolo,
      'note': note,
      'serie': serie.map((s) => s.toMap()).toList(),
    };
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
    };
  }
}
