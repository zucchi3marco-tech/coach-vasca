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

  /// 'nuoto' | 'pallanuoto' (un solo sport per club). null per i club
  /// creati prima che venisse chiesto (FASE 11).
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
