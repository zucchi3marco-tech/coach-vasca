class Club {
  const Club({required this.id, required this.nome, this.citta});

  final String id;
  final String nome;
  final String? citta;

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as String,
      nome: map['nome'] as String,
      citta: map['citta'] as String?,
    );
  }
}
