/// Supabase restituisce al massimo 1000 righe per richiesta (il `max_rows`
/// del progetto) e oltre tronca la risposta senza errore: le serie di
/// tutto un club superano quel limite in pochi mesi. Qui si leggono a
/// pagine, finché ne arrivano meno di [dimensione].
///
/// [pagina] legge le righe da [da] ad [a] comprese (`.range(da, a)`), con
/// un ordine stabile (`.order('id')`), altrimenti due pagine possono
/// sovrapporsi.
Future<List<Map<String, dynamic>>> leggiAPagine(
  Future<dynamic> Function(int da, int a) pagina, {
  int dimensione = 1000,
}) async {
  final righe = <Map<String, dynamic>>[];
  for (var da = 0; ; da += dimensione) {
    final parte = ((await pagina(da, da + dimensione - 1)) as List)
        .cast<Map<String, dynamic>>();
    righe.addAll(parte);
    if (parte.length < dimensione) return righe;
  }
}
