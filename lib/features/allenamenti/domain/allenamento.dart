class Allenamento {
  const Allenamento({
    required this.id,
    required this.clubId,
    required this.data,
    this.titolo,
    this.gruppoId,
    this.note,
  });

  final String id;
  final String clubId;
  final DateTime data;
  final String? titolo;
  final String? gruppoId;
  final String? note;

  factory Allenamento.fromMap(Map<String, dynamic> map) {
    return Allenamento(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      data: DateTime.parse(map['data'] as String),
      titolo: map['titolo'] as String?,
      gruppoId: map['gruppo_id'] as String?,
      note: map['note'] as String?,
    );
  }
}
