import '../sync/network_failure.dart';

/// Aspetta un primo tentativo di refresh dal server prima di iniziare a
/// emettere, cosi' la UI mostra "caricamento" invece di un falso "vuoto"
/// quando la cache locale non ha ancora nulla (primo avvio, o durante lo
/// sviluppo un'origine diversa ad ogni riavvio del server web) — poi segue
/// lo stream locale in tempo reale come sempre.
///
/// Se il refresh fallisce per un problema di rete si procede comunque con
/// quel che c'e' in locale (magari vuoto): e' il comportamento offline
/// atteso. Un errore diverso (bug, RLS, dati non validi) invece non viene
/// nascosto: risale come errore dello stream, cosi' compare nella UI
/// invece di sembrare silenziosamente "nessun dato".
Stream<T> streamConRefreshIniziale<T>({
  required Future<void> Function() refresh,
  required Stream<T> Function() watch,
}) async* {
  try {
    await refresh();
  } catch (e) {
    if (!isNetworkFailure(e)) rethrow;
  }
  yield* watch();
}
