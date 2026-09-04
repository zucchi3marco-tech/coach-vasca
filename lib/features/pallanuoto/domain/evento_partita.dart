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
    required this.creatoIl,
  });

  final String id;
  final String partitaId;
  final String clubId;
  final String tipo; // tiro | espulsione | superiorita
  final String squadra; // nostra | avversaria
  final String? atletaId;
  final int? periodo;
  final String? esito; // gol | non_gol | parato | palo_fuori
  final String contestoTiro; // azione | superiorita | rigore (solo per tiro)
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
      creatoIl: DateTime.parse(map['created_at'] as String),
    );
  }
}
