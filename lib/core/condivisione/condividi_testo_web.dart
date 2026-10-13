import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Apre il foglio "Condividi" del browser (Web Share API) con [testo]:
/// true se si è aperto (anche se poi chi lo usa l'ha chiuso senza
/// scegliere), false se il browser non lo sa fare — allora chi chiama
/// copia il testo negli appunti.
Future<bool> condividiTesto(String testo) async {
  final navigatore = web.window.navigator;
  if (!(navigatore as JSObject).has('share')) return false;
  final dati = web.ShareData(text: testo);
  try {
    if (navigatore.has('canShare') && !navigatore.canShare(dati)) {
      return false;
    }
    await navigatore.share(dati).toDart;
    return true;
  } catch (e) {
    // Chiuso senza scegliere un'app: non c'è altro da fare.
    return e.toString().contains('AbortError');
  }
}
