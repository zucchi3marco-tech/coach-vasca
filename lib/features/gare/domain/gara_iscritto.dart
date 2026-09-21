/// Un atleta iscritto a una gara.
class GaraIscritto {
  const GaraIscritto({
    required this.id,
    required this.garaId,
    required this.atletaId,
    required this.clubId,
  });

  final String id;
  final String garaId;
  final String atletaId;
  final String clubId;
}
