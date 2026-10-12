class EventoPartita {
  const EventoPartita({
    required this.id,
    required this.partitaId,
    required this.clubId,
    required this.tipo,
    required this.squadra,
    this.atletaId,
    this.periodo,
    this.esito,
    this.contestoTiro = 'azione',
    this.posX,
    this.posY,
    this.numeroCalottinaAvversario,
    this.espulsioneDaRigore = false,
    this.assistDi,
    this.guadagnataDa,
    required this.creatoIl,
  });

  final String id;
  final String partitaId;
  final String clubId;

  /// tiro | espulsione | superiorita | palla_persa | palla_recuperata
  final String tipo;
  final String squadra; // nostra | avversaria
  final String? atletaId;
  final int? periodo;
  final String? esito; // gol | non_gol | parato | palo_fuori
  /// azione | superiorita | rigore | controfuga (solo per tiro)
  final String contestoTiro;

  /// Posizione del tiro sul campo disegnato (percentuale 0-100 su
  /// entrambi gli assi), solo per tipo 'tiro'. Null per gli eventi
  /// registrati prima di questa funzione o senza posizione.
  final double? posX;
  final double? posY;

  /// Solo per un'espulsione di un giocatore avversario, del quale non
  /// abbiamo un Atleta in rubrica: alternativo ad [atletaId], mai
  /// entrambi valorizzati.
  final int? numeroCalottinaAvversario;

  /// Solo per tipo 'espulsione': fallo da rigore (nega un'occasione da
  /// gol netta). Tre di queste nella stessa partita per lo stesso
  /// giocatore lo escludono dal resto della gara (calcolato in UI, non
  /// salvato come stato a parte).
  final bool espulsioneDaRigore;

  /// Solo per un nostro tiro: chi ha passato la palla del gol (modalità
  /// completa). Conta come assist solo se il tiro è gol.
  final String? assistDi;

  /// Solo per l'espulsione di un avversario: chi dei nostri l'ha
  /// guadagnata (con [espulsioneDaRigore], il rigore guadagnato).
  final String? guadagnataDa;

  final DateTime creatoIl;

  factory EventoPartita.fromMap(Map<String, dynamic> map) {
    return EventoPartita(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      squadra: map['squadra'] as String? ?? 'nostra',
      atletaId: map['atleta_id'] as String?,
      periodo: map['periodo'] as int?,
      esito: map['esito'] as String?,
      contestoTiro: map['contesto_tiro'] as String? ?? 'azione',
      posX: (map['pos_x'] as num?)?.toDouble(),
      posY: (map['pos_y'] as num?)?.toDouble(),
      numeroCalottinaAvversario: map['numero_calottina_avversario'] as int?,
      espulsioneDaRigore: map['espulsione_da_rigore'] as bool? ?? false,
      assistDi: map['assist_di'] as String?,
      guadagnataDa: map['guadagnata_da'] as String?,
      creatoIl: DateTime.parse(map['created_at'] as String),
    );
  }
}
