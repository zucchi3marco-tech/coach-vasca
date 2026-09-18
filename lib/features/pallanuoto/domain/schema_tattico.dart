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

/// Un fotogramma dello schema: una disposizione di giocatori/frecce
/// indipendente dagli altri passi — es. passo 1 "posizioni di
/// partenza", passo 2 "frecce di movimento", passo 3 "posizioni
/// finali". Ogni schema ne ha almeno uno, al massimo 10 (vedi
/// [SchemaTattico.massimoPassi]).
typedef PassoSchema = ({
  List<GiocatoreSchema> giocatori,
  List<FrecciaSchema> frecce,
});

/// Uno schema tattico salvato dall'allenatore (pallanuoto): una
/// sequenza di passi (giocatori piazzati + frecce di movimento per
/// ciascuno), disegnati sulla lavagna (`WaterPoloTacticsBoard`) e
/// salvati per poterli risfogliare — a differenza della versione
/// precedente, puramente locale ed effimera.
class SchemaTattico {
  const SchemaTattico({
    required this.id,
    required this.clubId,
    required this.titolo,
    required this.categoria,
    required this.campo,
    required this.passi,
    required this.aggiornatoIl,
  });

  static const massimoPassi = 10;

  final String id;
  final String clubId;
  final String titolo;

  /// Gruppo libero scelto dall'allenatore (es. "Transizioni",
  /// "Superiorità", "Inferiorità", "Difesa", "Attacco"...): non un
  /// elenco chiuso, se ne possono creare quanti se ne vogliono. Stringa
  /// vuota per gli schemi senza categoria assegnata.
  final String categoria;

  /// 'intero' | 'meta' — vedi `CampoLavagna` in `WaterPoloTacticsBoard`.
  final String campo;

  /// Sempre almeno un passo, al più [massimoPassi].
  final List<PassoSchema> passi;

  final DateTime aggiornatoIl;
}
