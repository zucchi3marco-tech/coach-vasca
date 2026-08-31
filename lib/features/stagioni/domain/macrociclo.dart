class Macrociclo {
  const Macrociclo({
    required this.id,
    required this.stagioneId,
    required this.clubId,
    required this.nome,
    required this.ordine,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
  });

  final String id;
  final String stagioneId;
  final String clubId;
  final String nome;
  final int ordine;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
}
