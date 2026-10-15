import 'riordino_serie.dart';
import 'serie.dart';

/// I lavori in parallelo (richiesta del coach 2026-10-15): "se devo fare
/// un lavoro con i portieri, deve corrispondere al tempo di lavoro degli
/// altri, devono andare in parallelo".
///
/// Le serie con lo stesso `momentoId` sono un **momento**: si fanno nello
/// stesso tempo, ognuno nella sua **colonna** (le serie con gli stessi
/// destinatari). In un momento ognuno fa la colonna più precisa fra
/// quelle che lo comprendono ([Destinatari.precedenza]): i suoi nomi, il
/// suo ruolo, "movimento", tutti. Così "tutti" in un momento con i
/// portieri vale per chi non è portiere. La stessa regola nel database
/// (`serie_fatta_da`).

/// Le [serie] che fa l'atleta [atletaId] con il [ruolo] (null: non
/// indicato, conta come movimento), nell'ordine. Con [atletaId] null, un
/// atleta qualunque di quel ruolo.
List<T> serieDellAtleta<T extends DatiSerie>(
  Iterable<T> serie,
  String? atletaId,
  String? ruolo,
) {
  final fa = filtroDellAtleta(serie, atletaId, ruolo);
  return [
    for (final s in serie)
      if (fa(s)) s,
  ];
}

/// Come [serieDellAtleta], come domanda su una serie alla volta: le
/// colonne si scelgono guardando tutte le [serie] dell'allenamento, poi
/// vale anche per le serie delle righe del testo (copie con gli stessi
/// destinatari e lo stesso momento).
bool Function(DatiSerie) filtroDellAtleta(
  Iterable<DatiSerie> serie,
  String? atletaId,
  String? ruolo,
) {
  final colonna = <String, int>{};
  for (final s in serie) {
    final momento = s.momentoId;
    if (momento == null || !s.destinatari.perAtleta(atletaId, ruolo)) {
      continue;
    }
    final precedenza = s.destinatari.precedenza;
    if (precedenza > (colonna[momento] ?? -1)) colonna[momento] = precedenza;
  }
  return (s) =>
      s.destinatari.perAtleta(atletaId, ruolo) &&
      (s.momentoId == null || s.destinatari.precedenza == colonna[s.momentoId]);
}

/// Una colonna di un momento: per chi è e le sue serie, nell'ordine.
class ColonnaMomento<T extends DatiSerie> {
  ColonnaMomento(this.destinatari) : serie = [];

  final Destinatari destinatari;
  final List<T> serie;
}

/// Le colonne delle [serie] di un momento, nell'ordine in cui compaiono:
/// prima quella di tutti, se c'è.
List<ColonnaMomento<T>> colonneMomento<T extends DatiSerie>(Iterable<T> serie) {
  final colonne = <ColonnaMomento<T>>[];
  for (final s in serie) {
    final colonna = colonne
        .where((c) => c.destinatari == s.destinatari)
        .firstOrNull;
    if (colonna != null) {
      colonna.serie.add(s);
    } else {
      colonne.add(ColonnaMomento<T>(s.destinatari)..serie.add(s));
    }
  }
  final base = colonne.where((c) => c.destinatari.base).toList();
  return [...base, ...colonne.where((c) => !c.destinatari.base)];
}

/// Le [serie] (nell'ordine) a pezzi: un momento con più colonne è un
/// pezzo solo, le altre serie stanno con le loro vicine fuori dai
/// momenti. Serve a contare il tempo di una seduta.
List<({bool momento, List<T> serie})> pezziPerMomento<T extends DatiSerie>(
  List<T> serie,
) {
  final pezzi = <({bool momento, List<T> serie})>[];
  for (final s in serie) {
    final ultimo = pezzi.isEmpty ? null : pezzi.last;
    final momento = s.momentoId;
    final insieme =
        ultimo != null &&
        (momento == null
            ? !ultimo.momento
            : ultimo.momento && ultimo.serie.first.momentoId == momento);
    if (insieme) {
      ultimo.serie.add(s);
    } else {
      pezzi.add((momento: momento != null, serie: [s]));
    }
  }
  return pezzi;
}

/// Accorpa le serie consecutive dello stesso momento in un gruppo solo, e
/// le altre come `raggruppaPerPiramide` (una piramide, un "2x"): gli
/// elementi dell'elenco nel dettaglio e a bordo vasca. Un momento si
/// sposta, si duplica e si elimina tutto insieme.
List<List<T>> raggruppaPerMomento<T extends DatiSerie>(List<T> serie) {
  final gruppi = <List<T>>[];
  for (final s in serie) {
    final ultimo = gruppi.isNotEmpty ? gruppi.last : null;
    final momento = s.momentoId;
    final piramide = s.piramideId;
    final insieme =
        ultimo != null &&
        (momento != null
            ? ultimo.first.momentoId == momento
            : ultimo.first.momentoId == null &&
                  piramide != null &&
                  ultimo.first.piramideId == piramide);
    if (insieme) {
      ultimo.add(s);
    } else {
      gruppi.add([s]);
    }
  }
  // Un momento rimasto con una colonna sola (le altre eliminate) torna a
  // essere serie normali.
  return [
    for (final g in gruppi)
      if (g.first.momentoId != null && !eMomento(g))
        ...raggruppaPerPiramide(g)
      else
        g,
  ];
}

/// Il gruppo è un momento con almeno due colonne.
bool eMomento(List<DatiSerie> gruppo) =>
    gruppo.first.momentoId != null &&
    gruppo.any((s) => s.destinatari != gruppo.first.destinatari);
