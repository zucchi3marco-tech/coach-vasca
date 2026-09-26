import 'serie.dart';

/// Sposta la serie in posizione [da] alla posizione [a] (indici dell'elenco
/// come mostrato a schermo). [a] fuori dai limiti viene riportato al primo
/// o all'ultimo posto; se non cambia nulla si restituisce lo stesso ordine.
List<Serie> spostaSerie(List<Serie> serie, int da, int a) {
  if (da < 0 || da >= serie.length) return List.of(serie);
  final destinazione = a.clamp(0, serie.length - 1);
  final riordinate = List<Serie>.of(serie);
  final spostata = riordinate.removeAt(da);
  riordinate.insert(destinazione, spostata);
  return riordinate;
}

/// Le serie che, nell'elenco [ordinate] (già nell'ordine voluto), non hanno
/// ancora il numero d'ordine giusto (posizione + 1): sono le uniche da
/// riscrivere, così un riordino tocca il minimo di righe.
List<({Serie serie, int ordine})> cambiDiOrdine(List<Serie> ordinate) => [
  for (var i = 0; i < ordinate.length; i++)
    if (ordinate[i].ordine != i + 1) (serie: ordinate[i], ordine: i + 1),
];
