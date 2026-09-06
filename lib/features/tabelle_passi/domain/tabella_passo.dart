class TabellaPasso {
  const TabellaPasso({
    required this.id,
    required this.testId,
    required this.atletaId,
    required this.clubId,
    required this.zona,
    required this.passo100S,
    this.percentualeRiferimento,
  });

  final String id;
  final String testId;
  final String atletaId;
  final String clubId;
  final String zona; // 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2' | 'C3' | 'D'
  // ('C' compare ancora solo su righe salvate prima dello split in C1/C2/C3)
  final double passo100S;
  final double? percentualeRiferimento;

  factory TabellaPasso.fromMap(Map<String, dynamic> map) {
    return TabellaPasso(
      id: map['id'] as String,
      testId: map['test_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      zona: map['zona'] as String,
      passo100S: (map['passo_100_s'] as num).toDouble(),
      percentualeRiferimento: (map['percentuale_riferimento'] as num?)
          ?.toDouble(),
    );
  }
}
