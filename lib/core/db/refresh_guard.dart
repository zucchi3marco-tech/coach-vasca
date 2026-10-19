import 'dart:async';

import '../sync/network_failure.dart';

/// Una pagina che legge dalla copia sul telefono e la aggiorna dal server.
///
/// Se la copia ha già qualcosa la mostra subito, e il server la aggiorna
/// appena risponde (lo stream locale segue in tempo reale): con la rete
/// lenta della piscina la pagina non resta in caricamento (scelta del
/// coach, proposta 28). Se la copia è vuota (primo avvio, o durante lo
/// sviluppo un'origine diversa ad ogni riavvio del server web) aspetta
/// prima il server, così la UI mostra "caricamento" invece di un falso
/// "vuoto".
///
/// Se l'aggiornamento fallisce per un problema di rete si resta con quel
/// che c'e' in locale (magari vuoto): e' il comportamento offline atteso.
/// Un errore diverso (bug, RLS, dati non validi) invece non viene
/// nascosto: risale come errore dello stream, cosi' compare nella UI
/// invece di sembrare silenziosamente "nessun dato".
Stream<T> streamConRefreshIniziale<T>({
  required Future<void> Function() refresh,
  required Stream<T> Function() watch,
}) async* {
  final copia = await watch().first;
  if (!_haDati(copia)) {
    try {
      await refresh();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
    }
    yield* watch();
    return;
  }

  Object? errore;
  StackTrace? traccia;
  final aggiornamento = refresh().then<void>(
    (_) {},
    onError: (Object e, StackTrace s) {
      if (isNetworkFailure(e)) return;
      errore = e;
      traccia = s;
    },
  );
  yield* _conErroreDi(watch(), aggiornamento, () => (errore, traccia));
}

bool _haDati(Object? copia) => switch (copia) {
  null => false,
  Iterable() => copia.isNotEmpty,
  Map() => copia.isNotEmpty,
  _ => true,
};

/// [dati], più l'errore di [lavoro] (se c'è) quando finisce.
Stream<T> _conErroreDi<T>(
  Stream<T> dati,
  Future<void> lavoro,
  (Object?, StackTrace?) Function() errore,
) {
  late final StreamController<T> uscita;
  StreamSubscription<T>? sorgente;
  uscita = StreamController<T>(
    onListen: () {
      sorgente = dati.listen(
        uscita.add,
        onError: uscita.addError,
        onDone: uscita.close,
      );
      lavoro.then((_) {
        final (e, s) = errore();
        if (e != null && !uscita.isClosed) uscita.addError(e, s);
      });
    },
    onPause: () => sorgente?.pause(),
    onResume: () => sorgente?.resume(),
    onCancel: () => sorgente?.cancel(),
  );
  return uscita.stream;
}
