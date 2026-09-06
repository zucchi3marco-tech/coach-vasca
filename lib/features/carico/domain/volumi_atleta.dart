/// Volume di allenamento (metri) di un atleta, contato solo nei giorni
/// in cui risulta "presente" — stesso perimetro dati del modello
/// Banister (vedi [PuntoBanister]), scomposto per zona di intensità e
/// per tipo di lavoro invece che aggregato giorno per giorno.
class VolumiAtleta {
  const VolumiAtleta({
    required this.volumeTotaleM,
    required this.perZona,
    required this.perEsecuzione,
  });

  final int volumeTotaleM;

  /// Chiave = sigla zona ('A1'...'D', anche 'C' storica); solo le zone
  /// effettivamente presenti nelle serie nuotate.
  final Map<String, int> perZona;

  /// Chiave = esecuzione ('nuoto', 'gambe', ...); tutte le serie ne
  /// hanno una (non nullable a differenza della zona).
  final Map<String, int> perEsecuzione;
}
