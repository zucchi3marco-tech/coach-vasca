import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Quante schermate da bordo vasca lo stanno chiedendo adesso: si lascia
/// spegnere solo quando l'ultima si chiude.
var _richieste = 0;
JSObject? _sentinella;
var _osservaVisibilita = false;

/// Chiede al browser di non spegnere lo schermo. Il browser toglie il
/// blocco quando la pagina va in secondo piano: al ritorno si richiede.
Future<void> tieniSchermoAcceso() async {
  _richieste++;
  if (!_osservaVisibilita) {
    _osservaVisibilita = true;
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event _) {
        if (_richieste > 0 && web.document.visibilityState == 'visible') {
          _richiedi();
        }
      }).toJS,
    );
  }
  await _richiedi();
}

Future<void> lasciaSpegnereSchermo() async {
  if (_richieste > 0) _richieste--;
  if (_richieste > 0) return;
  final sentinella = _sentinella;
  _sentinella = null;
  if (sentinella == null) return;
  try {
    await sentinella.callMethod<JSPromise>('release'.toJS).toDart;
  } catch (_) {
    // Gia' rilasciato dal browser: niente da fare.
  }
}

Future<void> _richiedi() async {
  try {
    final navigator = web.window.navigator as JSObject;
    // Browser senza Screen Wake Lock (o pagina non sicura): si va avanti
    // senza, lo schermo seguira' le impostazioni del dispositivo.
    if (!navigator.has('wakeLock')) return;
    final wakeLock = navigator['wakeLock'] as JSObject;
    _sentinella = await wakeLock
        .callMethod<JSPromise<JSObject>>('request'.toJS, 'screen'.toJS)
        .toDart;
  } catch (_) {
    // Rifiutato (es. batteria scarica): non e' un errore da mostrare.
  }
}
