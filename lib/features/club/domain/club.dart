class Club {
  const Club({
    required this.id,
    required this.nome,
    this.citta,
    this.sport,
    this.categorie = const [],
  });

  final String id;
  final String nome;
  final String? citta;

  /// Com'è nel database ('pallanuoto', 'nuoto' nelle righe vecchie, o
  /// null): l'app non decide niente da qui, vedi `sportApp`.
  final String? sport;

  /// Categorie allenate (es. "U14", "Assoluti"): libere nel contenuto, ma
  /// scelte da un elenco chiuso in fase di creazione del club.
  final List<String> categorie;

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as String,
      nome: map['nome'] as String,
      citta: map['citta'] as String?,
      sport: map['sport'] as String?,
      categorie: (map['categorie'] as List? ?? const [])
          .map((c) => c as String)
          .toList(),
    );
  }
}
