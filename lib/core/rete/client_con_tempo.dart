import 'dart:async';

import 'package:http/http.dart' as http;

import 'stato_rete.dart';

/// Quanto può aspettare una chiamata al server prima di valere come «senza
/// rete»: 8 secondi per i dati e l'accesso, 30 per i file, 90 per le
/// funzioni sul server (l'AI ha già i suoi tempi, più corti).
Duration tempoMassimoPer(Uri url) {
  final percorso = url.path;
  if (percorso.contains('/functions/v1/')) return const Duration(seconds: 90);
  if (percorso.contains('/storage/v1/')) return const Duration(seconds: 30);
  return const Duration(seconds: 8);
}

/// Il client HTTP di Supabase con un tempo massimo per ogni chiamata
/// (proposta 28): una rete che non risponde vale come rete assente, invece
/// di lasciare l'app in attesa. Passato il tempo la chiamata si interrompe
/// davvero e finisce con un errore di rete, così le modifiche vanno in coda
/// e le pagine mostrano la copia sul telefono, come senza linea.
///
/// Ogni errore di rete esce come [http.RequestAbortedException]: è l'unico
/// che il client di Supabase non ritenta da solo. Con un errore di rete
/// qualsiasi ogni lettura riprova tre volte (1 + 2 + 4 secondi di attesa,
/// più il tempo massimo di ogni tentativo) prima di arrendersi.
///
/// Tiene aggiornato [StatoRete]: senza rete quando una chiamata non
/// arriva, in rete alla prima risposta del server, qualunque sia.
class ClientConTempoMassimo extends http.BaseClient {
  ClientConTempoMassimo(
    this._interno, {
    StatoRete? stato,
    Duration Function(Uri url)? tempoPer,
  }) : _stato = stato ?? statoRete,
       _tempoPer = tempoPer ?? tempoMassimoPer;

  final http.Client _interno;
  final StatoRete _stato;
  final Duration Function(Uri url) _tempoPer;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final tempo = _tempoPer(request.url);
    final scaduto = Completer<void>();
    final timer = Timer(tempo, () {
      if (!scaduto.isCompleted) scaduto.complete();
    });
    final altroStop = request is http.Abortable ? request.abortTrigger : null;

    // Una copia della richiesta che si può interrompere allo scadere.
    final corpo = request.finalize();
    final copia =
        http.AbortableStreamedRequest(
            request.method,
            request.url,
            abortTrigger: altroStop == null
                ? scaduto.future
                : Future.any([scaduto.future, altroStop]),
          )
          ..headers.addAll(request.headers)
          ..contentLength = request.contentLength
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection;
    corpo.listen(
      copia.sink.add,
      onError: copia.sink.addError,
      onDone: copia.sink.close,
      cancelOnError: true,
    );

    final http.StreamedResponse risposta;
    try {
      risposta = await Future.any([
        _interno.send(copia),
        // Anche se il client sotto non sa interrompere una richiesta.
        scaduto.future.then<http.StreamedResponse>(
          (_) => throw http.RequestAbortedException(request.url),
        ),
      ]);
    } on http.ClientException catch (e) {
      timer.cancel();
      // Interrotta da chi chiama (non dal tempo massimo): non è la rete.
      if (e is http.RequestAbortedException && !scaduto.isCompleted) rethrow;
      _stato.chiamataFallita();
      throw http.RequestAbortedException(request.url);
    }
    _stato.rispostaArrivata();

    // Il tempo massimo vale fino all'ultimo byte della risposta.
    StreamSubscription<List<int>>? sorgente;
    late final StreamController<List<int>> uscita;
    void interrompi() {
      if (uscita.isClosed) return;
      sorgente?.cancel();
      _stato.chiamataFallita();
      uscita
        ..addError(http.RequestAbortedException(request.url))
        ..close();
    }

    uscita = StreamController<List<int>>(
      onListen: () {
        sorgente = risposta.stream.listen(
          uscita.add,
          onError: (Object e, StackTrace traccia) {
            if (uscita.isClosed) return;
            if (e is http.ClientException) {
              timer.cancel();
              interrompi();
            } else {
              uscita.addError(e, traccia);
            }
          },
          onDone: () {
            timer.cancel();
            if (!uscita.isClosed) uscita.close();
          },
        );
        if (scaduto.isCompleted) {
          interrompi();
        } else {
          scaduto.future.then((_) => interrompi());
        }
      },
      onPause: () => sorgente?.pause(),
      onResume: () => sorgente?.resume(),
      onCancel: () {
        timer.cancel();
        return sorgente?.cancel();
      },
    );

    return http.StreamedResponse(
      uscita.stream,
      risposta.statusCode,
      contentLength: risposta.contentLength,
      request: request,
      headers: risposta.headers,
      isRedirect: risposta.isRedirect,
      persistentConnection: risposta.persistentConnection,
      reasonPhrase: risposta.reasonPhrase,
    );
  }

  @override
  void close() => _interno.close();
}
