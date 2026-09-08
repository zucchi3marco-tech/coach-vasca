class Stagione {
  const Stagione({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppo,
    this.campionato,
  });

  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppo;

  /// Campionato disputato in questa stagione: le partite create con una
  /// data compresa fra [dataInizio] e [dataFine] lo ereditano
  /// automaticamente, non si sceglie più partita per partita.
  final String? campionato;
}
