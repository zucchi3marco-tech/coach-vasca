import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../theme/palette_acqua.dart';
import 'controllore_video.dart';

/// L'IFrame Player API di YouTube, caricata una volta sola (e di nuovo
/// solo se la prima volta non è arrivata).
Future<void>? _apiYoutube;

Future<void> _caricaApi() => _apiYoutube ??= _caricaApiOra();

JSObject? _oggetto(JSObject o, String proprieta) {
  final v = o.getProperty<JSAny?>(proprieta.toJS);
  return v != null && v.isA<JSObject>() ? v as JSObject : null;
}

bool get _apiPronta {
  final yt = _oggetto(globalContext, 'YT');
  if (yt == null || !yt.has('Player')) return false;
  final caricata = yt.getProperty<JSAny?>('loaded'.toJS);
  return caricata != null &&
      caricata.isA<JSNumber>() &&
      (caricata as JSNumber).toDartInt == 1;
}

Future<void> _caricaApiOra() async {
  if (_apiPronta) return;
  final pronta = Completer<void>();
  final precedente = globalContext.getProperty<JSAny?>(
    'onYouTubeIframeAPIReady'.toJS,
  );
  globalContext.setProperty(
    'onYouTubeIframeAPIReady'.toJS,
    (() {
      if (precedente != null && precedente.isA<JSFunction>()) {
        (precedente as JSFunction).callAsFunction();
      }
      if (!pronta.isCompleted) pronta.complete();
    }).toJS,
  );
  final script = web.HTMLScriptElement()
    ..src = 'https://www.youtube.com/iframe_api'
    ..async = true;
  script.onerror = ((web.Event _) {
    if (!pronta.isCompleted) {
      pronta.completeError(StateError('YouTube non raggiungibile'));
    }
  }).toJS;
  web.document.head!.append(script);
  try {
    await pronta.future.timeout(const Duration(seconds: 20));
  } catch (_) {
    _apiYoutube = null;
    rethrow;
  }
}

/// I codici d'errore del lettore — vedi
/// https://developers.google.com/youtube/iframe_api_reference#onError
String _messaggioErrore(int codice) => switch (codice) {
  2 => 'Il link del video non è valido: ricopialo da YouTube.',
  5 => 'Questo browser non riesce a riprodurre il video.',
  100 =>
    'Il video non c\'è più su YouTube o è privato: deve essere pubblico '
        'o "non in elenco".',
  101 || 150 =>
    'Chi ha caricato il video non permette di guardarlo dentro altre app: '
        'su YouTube Studio, nei dettagli del video, attiva "Consenti '
        'incorporamento".',
  _ => 'Il video non si riesce a guardare (errore $codice).',
};

/// Il lettore YouTube dentro l'app (IFrame Player API, dominio
/// youtube-nocookie.com): [controllore] lo comanda e ne riceve lo stato
/// (secondo, durata, in riproduzione) quattro volte al secondo.
class LettoreYoutube extends StatefulWidget {
  const LettoreYoutube({
    required this.videoId,
    required this.controllore,
    super.key,
  });

  final String videoId;
  final ControlloreVideo controllore;

  @override
  State<LettoreYoutube> createState() => _LettoreYoutubeState();
}

class _LettoreYoutubeState extends State<LettoreYoutube>
    implements MotoreVideo {
  web.HTMLElement? _contenitore;
  JSObject? _lettore;
  bool _pronto = false;
  Timer? _ascolto;

  @override
  void initState() {
    super.initState();
    widget.controllore.collega(this);
  }

  @override
  void didUpdateWidget(LettoreYoutube vecchio) {
    super.didUpdateWidget(vecchio);
    if (vecchio.controllore != widget.controllore) {
      vecchio.controllore.collega(null);
      widget.controllore.collega(this);
    }
    if (vecchio.videoId != widget.videoId && _pronto) {
      _lettore?.callMethod('cueVideoById'.toJS, widget.videoId.toJS);
    }
  }

  @override
  void dispose() {
    _ascolto?.cancel();
    widget.controllore.collega(null);
    try {
      _lettore?.callMethod('destroy'.toJS);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _crea(web.HTMLElement contenitore) async {
    _contenitore = contenitore;
    contenitore.style
      ..width = '100%'
      ..height = '100%';
    // Il lettore sostituisce questo segnaposto con il suo iframe: deve
    // avere un genitore anche prima che Flutter lo metta nella pagina.
    final segnaposto = web.HTMLDivElement();
    contenitore.append(segnaposto);
    try {
      await _caricaApi();
    } catch (_) {
      widget.controllore.aggiorna(
        errore:
            'YouTube non risponde: controlla la connessione e riapri la '
            'pagina.',
      );
      return;
    }
    if (!mounted) return;

    final variabili = JSObject()
      ..['playsinline'] = 1.toJS
      ..['rel'] = 0.toJS
      ..['modestbranding'] = 1.toJS
      ..['origin'] = web.window.location.origin.toJS;
    final eventi = JSObject()
      ..['onReady'] = ((JSObject _) {
        _pronto = true;
        widget.controllore.aggiorna(pronto: true);
        // Un "vai a" chiesto mentre il lettore si preparava.
        final attesa = widget.controllore.secondo;
        if (attesa > 0) vaiA(attesa);
        _ascolto = Timer.periodic(
          const Duration(milliseconds: 250),
          (_) => _leggiStato(),
        );
      }).toJS
      ..['onError'] = ((JSObject evento) {
        final codice = evento.getProperty<JSAny?>('data'.toJS);
        widget.controllore.aggiorna(
          errore: _messaggioErrore(
            codice != null && codice.isA<JSNumber>()
                ? (codice as JSNumber).toDartInt
                : 0,
          ),
        );
      }).toJS;
    final opzioni = JSObject()
      ..['videoId'] = widget.videoId.toJS
      ..['width'] = '100%'.toJS
      ..['height'] = '100%'.toJS
      ..['host'] = 'https://www.youtube-nocookie.com'.toJS
      ..['playerVars'] = variabili
      ..['events'] = eventi;
    final costruttore = _oggetto(
      globalContext,
      'YT',
    )!.getProperty<JSFunction>('Player'.toJS);
    _lettore = costruttore.callAsConstructor<JSObject>(segnaposto, opzioni);
  }

  void _leggiStato() {
    final lettore = _lettore;
    if (lettore == null || !_pronto || !mounted) return;
    try {
      final secondo = lettore
          .callMethod<JSNumber>('getCurrentTime'.toJS)
          .toDartDouble;
      final durata = lettore
          .callMethod<JSNumber>('getDuration'.toJS)
          .toDartDouble;
      final stato = lettore
          .callMethod<JSNumber>('getPlayerState'.toJS)
          .toDartInt;
      widget.controllore.aggiorna(
        secondo: secondo,
        durata: durata,
        // 1 in riproduzione, 3 sta caricando per riprodurre.
        inRiproduzione: stato == 1 || stato == 3,
      );
    } catch (_) {
      // Il lettore si sta ricreando (cambio di video): al giro dopo.
    }
  }

  @override
  void vaiA(double secondi) {
    if (!_pronto) return;
    _lettore?.callMethod('seekTo'.toJS, secondi.toJS, true.toJS);
  }

  @override
  void riproduci() {
    if (_pronto) _lettore?.callMethod('playVideo'.toJS);
  }

  @override
  void pausa() {
    if (_pronto) _lettore?.callMethod('pauseVideo'.toJS);
  }

  @override
  void impostaVelocita(double velocita) {
    if (_pronto) {
      _lettore?.callMethod('setPlaybackRate'.toJS, velocita.toJS);
    }
  }

  @override
  void accettaTocchi(bool accetta) {
    _contenitore?.style.pointerEvents = accetta ? 'auto' : 'none';
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AcquaPalette.nero,
    child: HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (elemento) {
        final contenitore = elemento as web.HTMLElement;
        _crea(contenitore);
        widget.controllore.collega(this);
      },
    ),
  );
}
