class Gruppo {
  const Gruppo({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.ordine,
    this.sport,
  });

  final String id;
  final String clubId;
  final String nome;
  final int ordine;

  /// Com'è nel database ('pallanuoto', 'nuoto' nelle righe vecchie, o
  /// null): l'app non decide niente da qui, vedi `sportApp`.
  final String? sport;
}
