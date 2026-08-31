class Mesociclo {
  const Mesociclo({
    required this.id,
    required this.macrocicloId,
    required this.clubId,
    required this.nome,
    required this.ordine,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
  });

  final String id;
  final String macrocicloId;
  final String clubId;
  final String nome;
  final int ordine;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
}
