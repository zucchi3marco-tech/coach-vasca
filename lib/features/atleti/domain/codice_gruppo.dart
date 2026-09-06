class CodiceGruppo {
  const CodiceGruppo({
    required this.id,
    required this.clubId,
    required this.gruppo,
    required this.codice,
    required this.creatoIl,
    required this.scadeIl,
  });

  final String id;
  final String clubId;
  final String gruppo;
  final String codice;
  final DateTime creatoIl;
  final DateTime scadeIl;

  bool get scaduto => scadeIl.isBefore(DateTime.now());

  factory CodiceGruppo.fromMap(Map<String, dynamic> map) {
    return CodiceGruppo(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      gruppo: map['gruppo'] as String,
      codice: map['codice'] as String,
      creatoIl: DateTime.parse(map['creato_il'] as String),
      scadeIl: DateTime.parse(map['scade_il'] as String),
    );
  }
}
