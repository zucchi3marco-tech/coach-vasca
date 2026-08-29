import 'dart:async';

/// Avvia un refresh dei dati remoti "in background": se fallisce (es.
/// perche' offline) l'errore viene ignorato silenziosamente — la UI nel
/// frattempo continua a mostrare la cache locale via i watcher Drift, che
/// si aggiornano da soli quando il refresh scrive righe piu' recenti.
void refreshInBackground(Future<void> Function() refresh) {
  unawaited(refresh().catchError((_) {}));
}
