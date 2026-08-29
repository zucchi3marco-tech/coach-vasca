class TestIngresso {
  const TestIngresso({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.tipo,
    required this.dataTest,
    required this.distanzaTotaleM,
    required this.tempoTotaleS,
    required this.passoMedio100S,
    this.note,
  });

  final String id;
  final String atletaId;
  final String clubId;
  final String tipo; // 'BVS' | 'T30'
  final DateTime dataTest;
  final int distanzaTotaleM;
  final double tempoTotaleS;
  final double passoMedio100S;
  final String? note;

  factory TestIngresso.fromMap(Map<String, dynamic> map) {
    return TestIngresso(
      id: map['id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      dataTest: DateTime.parse(map['data_test'] as String),
      distanzaTotaleM: map['distanza_totale_m'] as int,
      tempoTotaleS: (map['tempo_totale_s'] as num).toDouble(),
      passoMedio100S: (map['passo_medio_100_s'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }
}
