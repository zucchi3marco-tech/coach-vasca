/// Passo di riferimento di una corsia (FASE 10, punto 4): calcolato dai
/// personal best degli atleti del gruppo (100 stile libero) e dal
/// differenziale di gara T200-T100, quando disponibile. Se i PB del
/// gruppo sono molto eterogenei se ne generano due (veloce/lenta) invece
/// di una sola, ciascuna con la propria media.
class CorsiaGenerazione {
  const CorsiaGenerazione({
    required this.nome,
    required this.passo100S,
    this.differenzialeS,
  });

  final String nome;
  final double passo100S;
  final double? differenzialeS;

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'passo100S': passo100S,
      'differenzialeS': differenzialeS,
    };
  }
}

/// Parametri raccolti dal form "Genera con AI", da passare alla chiamata
/// API di generazione (Fase 5, punto successivo).
class ParametriGenerazione {
  const ParametriGenerazione({
    required this.gruppo,
    required this.volumeMetri,
    required this.focus,
    required this.regimiAmmessi,
    this.vincoli,
    this.corsie = const [],
  });

  final String gruppo;
  final int volumeMetri;
  final String focus;
  final List<String> regimiAmmessi;
  final String? vincoli;

  /// Vuoto se nessun atleta del gruppo ha i PB necessari (100/200 stile
  /// libero): la generazione procede comunque, solo senza ripartenze
  /// calcolate sui passi reali.
  final List<CorsiaGenerazione> corsie;

  Map<String, dynamic> toMap() {
    return {
      'gruppo': gruppo,
      'volumeMetri': volumeMetri,
      'focus': focus,
      'regimiAmmessi': regimiAmmessi,
      'vincoli': vincoli,
      'corsie': corsie.map((c) => c.toMap()).toList(),
    };
  }
}
