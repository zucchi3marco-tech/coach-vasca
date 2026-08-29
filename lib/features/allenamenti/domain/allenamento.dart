class Allenamento {
  const Allenamento({
    required this.id,
    required this.clubId,
    this.microcicloId,
    required this.data,
    this.titolo,
    this.gruppo,
    this.note,
  });

  final String id;
  final String clubId;
  final String? microcicloId;
  final DateTime data;
  final String? titolo;
  final String? gruppo;
  final String? note;

  factory Allenamento.fromMap(Map<String, dynamic> map) {
    return Allenamento(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      microcicloId: map['microciclo_id'] as String?,
      data: DateTime.parse(map['data'] as String),
      titolo: map['titolo'] as String?,
      gruppo: map['gruppo'] as String?,
      note: map['note'] as String?,
    );
  }
}
