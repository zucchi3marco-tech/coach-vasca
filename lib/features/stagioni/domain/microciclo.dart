class Microciclo {
  const Microciclo({
    required this.id,
    required this.mesocicloId,
    required this.clubId,
    this.nome,
    this.numeroSettimana,
    required this.ordine,
    required this.dataInizio,
    required this.dataFine,
    this.tipo,
  });

  final String id;
  final String mesocicloId;
  final String clubId;
  final String? nome;
  final int? numeroSettimana;
  final int ordine;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? tipo;
}
