class Presenza {
  const Presenza({
    required this.id,
    required this.allenamentoId,
    required this.atletaId,
    required this.clubId,
    required this.stato,
    this.note,
  });

  final String id;
  final String allenamentoId;
  final String atletaId;
  final String clubId;
  final String stato; // presente | assente | giustificato
  final String? note;

  factory Presenza.fromMap(Map<String, dynamic> map) {
    return Presenza(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: map['note'] as String?,
    );
  }
}
