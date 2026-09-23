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

/// Parametri raccolti dal form "Genera con AI" (o costruiti seduta per
/// seduta da "Genera settimana con AI", che riusa la stessa Edge
/// Function — vedi `genera_settimana_form_screen.dart`).
///
/// [minutiMax] e [vascaM] sono **obbligatori nel form del generatore
/// singolo** (validazione lì, non qui): restano nullable a livello di
/// classe perché il generatore settimana, finché non li raccoglie anche
/// lui (redesign in corso), può ancora chiamare senza — l'Edge Function
/// tratta la loro assenza come "nessun vincolo", non come un errore.
class ParametriGenerazione {
  const ParametriGenerazione({
    required this.gruppo,
    required this.volumeMetri,
    this.volumeLavoroCentraleM,
    required this.focus,
    this.metriFocusSpecifico,
    this.attrezzaturaFocus = const [],
    this.stileFocus,
    this.attrezzaturaLavoroCentrale = const [],
    this.minutiMax,
    this.vascaM,
    required this.regimiAmmessi,
    this.vincoli,
    this.corsie = const [],
  });

  final String gruppo;
  final int volumeMetri;

  /// Metri del blocco "principale" (lavoro centrale): entro [volumeMetri].
  /// `null` = l'AI decide liberamente la ripartizione fra i blocchi.
  final int? volumeLavoroCentraleM;

  /// 'completo' | 'braccia' | 'gambe' | 'tecnica' — quale parte del
  /// corpo/nuotata enfatizzare (non più l'energia: quella vive in
  /// [regimiAmmessi]/"tipo di lavoro").
  final String focus;

  /// Solo quando [focus] è 'braccia' o 'gambe': metri dedicati a quel
  /// lavoro specifico, entro [volumeMetri].
  final int? metriFocusSpecifico;

  /// Attrezzatura per il lavoro di [focus] (braccia: pull, palette;
  /// gambe: pinne, tavola, boccaglio). Vuota se [focus] non è
  /// braccia/gambe o il coach non ne ha scelta nessuna.
  final List<String> attrezzaturaFocus;

  /// Stile per il lavoro di [focus] ('libero'|'dorso'|'rana'|'delfino'|
  /// 'misti'), solo quando [focus] è braccia/gambe. `null` = l'AI sceglie.
  final String? stileFocus;

  /// Attrezzatura per il blocco "principale" in generale (pull, palette,
  /// boccaglio, pinne), indipendente dal [focus].
  final List<String> attrezzaturaLavoroCentrale;

  /// Minuti massimi di lavoro: vincolo stretto lato Edge Function,
  /// calcolato sulla corsia più lenta. `null` = nessun vincolo di tempo.
  final int? minutiMax;

  /// 25 o 50: lunghezza della vasca, solo contesto per il prompt (evitare
  /// distanze scomode). `null` = non specificata.
  final int? vascaM;

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
      'volumeLavoroCentraleMetri': volumeLavoroCentraleM,
      'focus': focus,
      'metriFocusSpecifico': metriFocusSpecifico,
      'attrezzaturaFocus': attrezzaturaFocus,
      'stileFocus': stileFocus,
      'attrezzaturaLavoroCentrale': attrezzaturaLavoroCentrale,
      'minutiMax': minutiMax,
      'vascaM': vascaM,
      'regimiAmmessi': regimiAmmessi,
      'vincoli': vincoli,
      'corsie': corsie.map((c) => c.toMap()).toList(),
    };
  }
}
