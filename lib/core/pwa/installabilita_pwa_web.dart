import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// `true` quando Chrome ha segnalato (evento `beforeinstallprompt`) che
/// l'installazione e' disponibile in questo momento — un bottone "Installa
/// l'app" nell'interfaccia lo osserva per mostrarsi solo allora, invece di
/// affidarsi al popup automatico del browser (che compare secondo criteri
/// suoi, non richiamabili a comando).
final ValueNotifier<bool> installabilitaPwa = ValueNotifier<bool>(false);

/// L'evento differito: si puo' richiamare `prompt()` una sola volta, poi
/// va scartato (un nuovo `beforeinstallprompt` ne fornirebbe un altro).
JSObject? _eventoDifferito;

void avviaOsservazioneInstallabilitaPwa() {
  // Gia' installata e in esecuzione come app standalone: non c'e' nulla
  // da proporre (a differenza della pagina aperta nel browser normale).
  if (web.window.matchMedia('(display-mode: standalone)').matches) return;

  web.window.addEventListener(
    'beforeinstallprompt',
    ((web.Event evento) {
      evento.preventDefault();
      _eventoDifferito = evento as JSObject;
      installabilitaPwa.value = true;
    }).toJS,
  );

  web.window.addEventListener(
    'appinstalled',
    ((web.Event _) {
      _eventoDifferito = null;
      installabilitaPwa.value = false;
    }).toJS,
  );
}

Future<void> installaPwa() async {
  final evento = _eventoDifferito;
  if (evento == null) return;
  _eventoDifferito = null;
  installabilitaPwa.value = false;
  evento.callMethod('prompt'.toJS);
}
