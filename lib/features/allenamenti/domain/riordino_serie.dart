import 'serie.dart';

/// Sposta l'elemento in posizione [da] alla posizione [a] (indici
/// dell'elenco come mostrato a schermo). [a] fuori dai limiti viene
/// riportato al primo o all'ultimo posto; se non cambia nulla si
/// restituisce lo stesso ordine. Generico: usato sia per una `List<Serie>`
/// sia per una `List<List<Serie>>` (gruppi piramide), così spostare un
/// gruppo lo muove come un unico elemento.
List<T> spostaSerie<T>(List<T> serie, int da, int a) {
  if (da < 0 || da >= serie.length) return List.of(serie);
  final destinazione = a.clamp(0, serie.length - 1);
  final riordinate = List<T>.of(serie);
  final spostata = riordinate.removeAt(da);
  riordinate.insert(destinazione, spostata);
  return riordinate;
}

/// Accorpa righe **consecutive** con lo stesso [Serie.piramideId] non
/// nullo in un unico gruppo (una piramide, es. 50-100-200-100-50, o le
/// serie di un "2x" scritto a testo): una riga normale
/// (`piramideId == null`) è un gruppo da sola. [serie] deve essere già
/// nell'ordine mostrato a schermo (per `ordine`).
List<List<T>> raggruppaPerPiramide<T extends DatiSerie>(List<T> serie) {
  final gruppi = <List<T>>[];
  for (final s in serie) {
    final ultimo = gruppi.isNotEmpty ? gruppi.last : null;
    if (s.piramideId != null &&
        ultimo != null &&
        ultimo.first.piramideId == s.piramideId) {
      ultimo.add(s);
    } else {
      gruppi.add([s]);
    }
  }
  return gruppi;
}

/// Le serie che, nell'elenco [ordinate] (già nell'ordine voluto), non hanno
/// ancora il numero d'ordine giusto (posizione + 1): sono le uniche da
/// riscrivere, così un riordino tocca il minimo di righe.
List<({Serie serie, int ordine})> cambiDiOrdine(List<Serie> ordinate) => [
  for (var i = 0; i < ordinate.length; i++)
    if (ordinate[i].ordine != i + 1) (serie: ordinate[i], ordine: i + 1),
];
