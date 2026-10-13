class Allenamento {
  const Allenamento({
    required this.id,
    required this.clubId,
    required this.data,
    this.titolo,
    this.gruppoId,
    this.note,
    this.tipo = 'acqua',
    this.durataMin,
  });

  final String id;
  final String clubId;
  final DateTime data;
  final String? titolo;
  final String? gruppoId;
  final String? note;

  /// acqua | secco — una seduta a secco ha esercizi invece delle serie,
  /// e il suo carico va nella colonna del secco.
  final String tipo;

  /// Quanto dura una seduta a secco, in minuti (i minuti del carico): per
  /// l'acqua la durata si stima dalle serie.
  final int? durataMin;

  bool get secco => tipo == 'secco';

  /// Il titolo da mostrare: quello scritto o, senza, il tipo di seduta.
  String get titoloMostrato => titolo != null && titolo!.trim().isNotEmpty
      ? titolo!
      : secco
      ? 'Seduta a secco'
      : 'Allenamento';

  factory Allenamento.fromMap(Map<String, dynamic> map) {
    return Allenamento(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      data: DateTime.parse(map['data'] as String),
      titolo: map['titolo'] as String?,
      gruppoId: map['gruppo_id'] as String?,
      note: map['note'] as String?,
      tipo: map['tipo'] as String? ?? 'acqua',
      durataMin: (map['durata_min'] as num?)?.toInt(),
    );
  }
}
