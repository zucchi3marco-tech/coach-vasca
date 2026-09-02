class DistintaGiocatore {
  const DistintaGiocatore({
    required this.id,
    required this.partitaId,
    required this.atletaId,
    required this.clubId,
    required this.numeroCalottina,
    required this.capitano,
    required this.viceCapitano,
    required this.portiere,
    required this.fuoriquota,
  });

  final String id;
  final String partitaId;
  final String atletaId;
  final String clubId;
  final int numeroCalottina;
  final bool capitano;
  final bool viceCapitano;
  final bool portiere;
  final bool fuoriquota;

  factory DistintaGiocatore.fromMap(Map<String, dynamic> map) {
    return DistintaGiocatore(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      numeroCalottina: map['numero_calottina'] as int,
      capitano: map['capitano'] as bool,
      viceCapitano: map['vice_capitano'] as bool,
      portiere: map['portiere'] as bool,
      fuoriquota: map['fuoriquota'] as bool,
    );
  }
}
