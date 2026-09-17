/// Un punto frazionario (0-1 su entrambi gli assi) sul campo della
/// lavagna tattica — vedi `WaterPoloTacticsBoard`, che usa `Offset`
/// (dipendenza da Flutter): qui, a livello di dominio, una semplice
/// coppia di double evita quella dipendenza.
typedef PuntoSchema = (double x, double y);

/// Uno schema tattico salvato dall'allenatore (pallanuoto): giocatori
/// piazzati + frecce di movimento, disegnati sulla lavagna
/// (`WaterPoloTacticsBoard`) e salvati per poterli risfogliare — a
/// differenza della versione precedente, puramente locale ed effimera.
class SchemaTattico {
  const SchemaTattico({
    required this.id,
    required this.clubId,
    required this.titolo,
    required this.giocatori,
    required this.frecce,
    required this.aggiornatoIl,
  });

  final String id;
  final String clubId;
  final String titolo;
  final List<PuntoSchema> giocatori;
  final List<(PuntoSchema, PuntoSchema)> frecce;
  final DateTime aggiornatoIl;
}
