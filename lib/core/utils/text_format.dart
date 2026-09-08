/// Capitalizza la prima lettera di ogni parola (spazio o trattino come
/// separatore, es. "de rossi" → "De Rossi", "jean-paul" → "Jean-Paul"), il
/// resto minuscolo — per correggere nome/cognome digitati tutto minuscolo,
/// tutto maiuscolo o con maiuscole/minuscole miste.
String capitalizzaNome(String testo) {
  final pulito = testo.trim();
  if (pulito.isEmpty) return pulito;
  return pulito
      .split(RegExp(r'\s+'))
      .map((parola) => parola.split('-').map(_capitalizzaParola).join('-'))
      .join(' ');
}

String _capitalizzaParola(String parola) {
  if (parola.isEmpty) return parola;
  return parola[0].toUpperCase() + parola.substring(1).toLowerCase();
}
