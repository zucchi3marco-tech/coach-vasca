/// Una gara di nuoto: evento di calendario di una stagione (come la
/// partita per la pallanuoto). [gruppoId] nullo = gara di tutto il club,
/// visibile a ogni gruppo e a ogni atleta.
class Gara {
  const Gara({
    required this.id,
    required this.clubId,
    required this.data,
    required this.nome,
    this.gruppoId,
    this.ora,
    this.luogo,
    this.note,
  });

  final String id;
  final String clubId;
  final String? gruppoId;
  final DateTime data;
  final String? ora;
  final String? luogo;

  /// Nome della manifestazione (es. "Trofeo Città di ...").
  final String nome;
  final String? note;

  bool get diClub => gruppoId == null;

  factory Gara.fromMap(Map<String, dynamic> map) {
    return Gara(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      gruppoId: map['gruppo_id'] as String?,
      data: DateTime.parse(map['data'] as String),
      ora: map['ora'] as String?,
      luogo: map['luogo'] as String?,
      nome: map['nome'] as String,
      note: map['note'] as String?,
    );
  }
}
