class CodiceGruppo {
  const CodiceGruppo({
    required this.id,
    required this.clubId,
    required this.gruppoId,
    required this.gruppoNome,
    required this.codice,
    required this.creatoIl,
    required this.scadeIl,
  });

  final String id;
  final String clubId;
  final String gruppoId;
  final String gruppoNome;
  final String codice;
  final DateTime creatoIl;
  final DateTime scadeIl;

  bool get scaduto => scadeIl.isBefore(DateTime.now());

  /// `gruppi(nome)` e' l'embed PostgREST della riga collegata (vedi
  /// `elencoPerGruppo`).
  factory CodiceGruppo.fromMap(Map<String, dynamic> map) {
    return CodiceGruppo(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      gruppoId: map['gruppo_id'] as String,
      gruppoNome: (map['gruppi'] as Map<String, dynamic>)['nome'] as String,
      codice: map['codice'] as String,
      creatoIl: DateTime.parse(map['creato_il'] as String),
      scadeIl: DateTime.parse(map['scade_il'] as String),
    );
  }
}
