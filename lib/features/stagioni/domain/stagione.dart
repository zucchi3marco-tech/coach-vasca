class Stagione {
  const Stagione({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppo,
  });

  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppo;
}
