import '../../../core/utils/pace_format.dart';
export '../../atleti/domain/abbina_atleta.dart' show abbinaAtleta;

/// Una riga del foglio dei tempi letta dalla foto (Edge Function
/// `leggi-tempi`): il nome come è scritto, i tempi della riga in secondi
/// e, se c'è, la distanza.
class RigaTempiLetta {
  const RigaTempiLetta({
    required this.nome,
    required this.tempiS,
    this.distanzaM,
  });

  factory RigaTempiLetta.fromMap(Map<String, dynamic> m) => RigaTempiLetta(
    nome: m['nome'] as String,
    tempiS: [for (final t in m['tempiS'] as List) (t as num).toDouble()],
    distanzaM: (m['distanzaM'] as num?)?.round(),
  );

  final String nome;
  final List<double> tempiS;
  final int? distanzaM;

  /// Il tempo migliore della riga (il più basso), se ce n'è uno.
  double? get migliore =>
      tempiS.isEmpty ? null : tempiS.reduce((a, b) => a < b ? a : b);
}

/// Dove vanno i tempi del foglio.
enum DestinazioneTempi {
  /// Un tempo su una distanza e uno stile: va fra i tempi dell'atleta
  /// (personal best).
  tempi('Tempi'),

  /// Test BVS: distanza e tempo di ogni atleta.
  bvs('Test BVS'),

  /// Test T30: i metri nuotati in 30 minuti.
  t30('Test T30');

  const DestinazioneTempi(this.etichetta);

  final String etichetta;
}

/// Un tempo scritto a mano o a tastiera: "1'05\"20", "1'05.2", "1:05.2",
/// "65,2" o "32\"5". null se non è un tempo.
double? leggiTempo(String testo) {
  final t = testo
      .trim()
      .replaceAll(',', '.')
      .replaceAll('\'', ':')
      .replaceAll('"', '.')
      .replaceAll(RegExp(r'\.$'), '');
  final secondi = parsePaceMmSs(t);
  return secondi == null || secondi <= 0 ? null : secondi;
}
