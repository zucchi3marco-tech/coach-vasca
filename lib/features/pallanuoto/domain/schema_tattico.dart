/// Un punto frazionario (0-1 su entrambi gli assi) sul campo della
/// lavagna tattica — vedi `WaterPoloTacticsBoard`, che usa `Offset`
/// (dipendenza da Flutter): qui, a livello di dominio, una semplice
/// coppia di double evita quella dipendenza.
typedef PuntoSchema = (double x, double y);

/// Colore: uno tra 'blu' | 'bianco' | 'nero' | 'rosso' | 'giallo' — vedi
/// `ColoreLavagna` in `WaterPoloTacticsBoard`, qui solo il nome (stessa
/// ragione di [PuntoSchema]: evitare la dipendenza da Flutter).
typedef GiocatoreSchema = ({PuntoSchema punto, String colore});
typedef FrecciaSchema = ({PuntoSchema inizio, PuntoSchema fine, String colore});

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
  final List<GiocatoreSchema> giocatori;
  final List<FrecciaSchema> frecce;
  final DateTime aggiornatoIl;
}
