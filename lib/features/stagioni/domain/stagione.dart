class Stagione {
  const Stagione({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.dataInizio,
    required this.dataFine,
    this.obiettivo,
    this.gruppoId,
    this.campionato,
  });

  final String id;
  final String clubId;
  final String nome;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String? obiettivo;
  final String? gruppoId;

  /// Campionato disputato in questa stagione: le partite create con una
  /// data compresa fra [dataInizio] e [dataFine] lo ereditano
  /// automaticamente, non si sceglie più partita per partita.
  final String? campionato;
}

/// La stagione che contiene la data odierna, preferendo quelle del
/// gruppo indicato (fallback su tutte se nessuna stagione ha quel
/// gruppo) — usata per la "stagione in corso" nella home dell'atleta.
/// Torna null se nessuna stagione contiene oggi.
Stagione? stagioneCorrenteDiGruppo(List<Stagione> stagioni, String? gruppoId) {
  final delGruppo = gruppoId == null
      ? stagioni
      : stagioni.where((s) => s.gruppoId == gruppoId).toList();
  final candidate = delGruppo.isEmpty ? stagioni : delGruppo;
  final oggi = DateTime.now();
  for (final s in candidate) {
    if (!oggi.isBefore(s.dataInizio) && !oggi.isAfter(s.dataFine)) {
      return s;
    }
  }
  return null;
}
