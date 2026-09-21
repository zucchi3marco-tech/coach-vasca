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

/// Il personal best registrato per lo slot stile+distanza, se c'è.
PersonalBest? pbDelloSlot(
  Iterable<PersonalBest> personalBest,
  String stile,
  int distanzaM,
) {
  for (final pb in personalBest) {
    if (pb.stile == stile && pb.distanzaM == distanzaM) return pb;
  }
  return null;
}

/// Un tempo è un nuovo personal best se lo slot non ne ha ancora uno o se
/// è più veloce di quello attuale.
bool superaPersonalBest(PersonalBest? attuale, double tempoS) =>
    attuale == null || tempoS < attuale.tempoS;
