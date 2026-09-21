/// Un tempo nuotato in una gara/allenamento, con la sua data — a
/// differenza di [PersonalBest] (un solo tempo, il migliore, per
/// stile+distanza), qui ogni tempo inserito resta come voce a sé nello
/// storico: serve per la curva delle prestazioni nel tempo, non solo il
/// primato attuale.
class TempoGara {
  const TempoGara({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.stile,
    required this.distanzaM,
    required this.vascaM,
    required this.tempoS,
    required this.data,
    this.note,
    this.garaId,
  });

  final String id;
  final String atletaId;
  final String clubId;
  final String stile;
  final int distanzaM;

  /// Lunghezza della vasca in cui è stato nuotato: 25 (vasca corta) o 50
  /// (vasca lunga) — i tempi non sono comparabili fra le due.
  final int vascaM;

  final double tempoS;
  final DateTime data;
  final String? note;

  /// La gara in cui e' stato nuotato, se collegato a una.
  final String? garaId;
}
