class PersonalBest {
  const PersonalBest({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.stile,
    required this.distanzaM,
    required this.tempoS,
    this.data,
    this.note,
  });

  final String id;
  final String atletaId;
  final String clubId;
  final String stile;
  final int distanzaM;
  final double tempoS;
  final DateTime? data;
  final String? note;
}
