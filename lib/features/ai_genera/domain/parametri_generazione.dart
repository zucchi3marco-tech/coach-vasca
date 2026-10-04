import '../../libreria_blocchi/application/selezione_blocchi_service.dart';

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
    this.atletiIds = const [],
  });

  final String nome;
  final double passo100S;
  final double? differenzialeS;

  /// Gli atleti che stanno in questa corsia: serve solo all'app per
  /// mostrarli all'allenatore, non viene inviato alla generazione.
  final List<String> atletiIds;

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'passo100S': passo100S,
      'differenzialeS': differenzialeS,
    };
  }
}

/// Dettaglio del lavoro di braccia o di gambe scelto fra i focus: metri
/// dedicati, attrezzatura e stile — ognuno indipendente dall'altro, così
/// una seduta può avere sia un blocco braccia sia uno gambe.
class DettaglioFocus {
  const DettaglioFocus({this.metri, this.attrezzatura = const [], this.stile});

  /// Metri dedicati a questo lavoro, entro il volume totale. `null` =
  /// l'AI decide quanto.
  final int? metri;

  /// Braccia: pull, palette. Gambe: pinne, tavola, boccaglio.
  final List<String> attrezzatura;

  /// 'libero'|'dorso'|'rana'|'delfino'|'misti'. `null` = l'AI sceglie.
  final String? stile;

  Map<String, dynamic> toMap() => {
    'metri': metri,
    'attrezzatura': attrezzatura,
    'stile': stile,
  };
}

/// Parametri raccolti dal form "Genera con AI" (o costruiti seduta per
/// seduta da "Genera settimana con AI", che riusa la stessa Edge
/// Function — vedi `genera_settimana_form_screen.dart`).
///
/// [minutiMax] e [vascaM] sono **obbligatori nel form del generatore
/// singolo** (validazione lì, non qui): restano nullable a livello di
/// classe perché l'Edge Function tratta la loro assenza come "nessun
/// vincolo", non come un errore.
class ParametriGenerazione {
  const ParametriGenerazione({
    required this.gruppo,
    required this.volumeMetri,
    this.volumeLavoroCentraleM,
    required this.focus,
    this.dettaglioBraccia,
    this.dettaglioGambe,
    this.stileTecnica,
    this.attrezzaturaLavoroCentrale = const [],
    this.minutiMax,
    this.vascaM,
    required this.regimiAmmessi,
    this.vincoli,
    this.corsie = const [],
    this.blocchiDisponibili = const [],
  });

  final String gruppo;
  final int volumeMetri;

  /// Metri del blocco "principale" (lavoro centrale): entro [volumeMetri].
  /// `null` = l'AI decide liberamente la ripartizione fra i blocchi.
  final int? volumeLavoroCentraleM;

  /// Uno o più fra 'completo' | 'braccia' | 'gambe' | 'tecnica' — quali
  /// parti del corpo/nuotata enfatizzare (non l'energia: quella vive in
  /// [regimiAmmessi]/"tipo di lavoro"). 'completo' sta da solo.
  final List<String> focus;

  /// Presenti solo se [focus] contiene 'braccia' / 'gambe'.
  final DettaglioFocus? dettaglioBraccia;
  final DettaglioFocus? dettaglioGambe;

  /// Stile del lavoro tecnico, solo se [focus] contiene 'tecnica'.
  /// `null` = l'AI sceglie.
  final String? stileTecnica;

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

  /// Fino a ~40 blocchi approvati compatibili per sport/livello (FASE 3):
  /// l'AI può solo scegliere e adattare questi, non inventare liberamente
  /// come prima — vuoto se il club non ha ancora una libreria, la
  /// generazione resta quella "libera" di sempre.
  final List<BloccoDisponibile> blocchiDisponibili;

  Map<String, dynamic> toMap() {
    return {
      'gruppo': gruppo,
      'volumeMetri': volumeMetri,
      'volumeLavoroCentraleMetri': volumeLavoroCentraleM,
      'focus': focus,
      'dettaglioBraccia': dettaglioBraccia?.toMap(),
      'dettaglioGambe': dettaglioGambe?.toMap(),
      'stileTecnica': stileTecnica,
      'attrezzaturaLavoroCentrale': attrezzaturaLavoroCentrale,
      'minutiMax': minutiMax,
      'vascaM': vascaM,
      'regimiAmmessi': regimiAmmessi,
      'vincoli': vincoli,
      'corsie': corsie.map((c) => c.toMap()).toList(),
      'blocchiDisponibili': blocchiDisponibili.map((b) => b.toMap()).toList(),
    };
  }
}
