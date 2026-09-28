/// Implementazione no-op per le piattaforme native (Android/iOS/desktop)
/// e per i test (`flutter test` gira sulla VM, non sul web): lì il
/// riconoscimento vocale del browser non esiste, quindi [disponibile]
/// resta sempre `false` e [avvia]/[ferma] non fanno nulla — la schermata
/// che lo usa deve già gestire "non disponibile" (campo di testo dettato
/// a mano) come percorso normale, non come errore.
class DettatoreVocale {
  DettatoreVocale({
    required void Function(String testoSessione) onTrascrizione,
    required void Function(String messaggio) onErrore,
    required void Function() onFine,
  });

  static bool get disponibile => false;

  bool get inAscolto => false;

  void avvia() {}

  void ferma() {}

  void dispose() {}
}
