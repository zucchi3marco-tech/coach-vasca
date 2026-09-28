import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// `true` quando un nuovo service worker ha preso il controllo della
/// pagina (evento `controllerchange`): il codice JS in esecuzione è
/// quello vecchio, un ricaricamento mostra la build appena distribuita.
/// Un bottone "Aggiorna" nell'interfaccia lo osserva per mostrarsi solo
/// allora — mai un ricaricamento automatico non richiesto, che
/// interromperebbe una dettatura o un salvataggio in corso.
final ValueNotifier<bool> aggiornamentoDisponibile = ValueNotifier<bool>(false);

bool _osservazioneAvviata = false;

void avviaOsservazioneAggiornamentoPwa() {
  if (_osservazioneAvviata) return;
  _osservazioneAvviata = true;

  final serviceWorker = web.window.navigator.serviceWorker;

  serviceWorker.addEventListener(
    'controllerchange',
    ((web.Event _) => aggiornamentoDisponibile.value = true).toJS,
  );

  // Il service worker scarica la nuova versione in background e la tiene
  // in attesa finché non c'è modo di attivarla: senza un controllo
  // esplicito, una PWA installata e tenuta sempre aperta potrebbe restare
  // su una build vecchia per giorni. Un controllo alla partenza e ogni
  // volta che l'app torna in primo piano è economico e non intrusivo.
  Future<void> controllaAggiornamento() async {
    try {
      final registrazione = await serviceWorker.getRegistration().toDart;
      await registrazione?.update().toDart;
    } catch (_) {
      // Nessun service worker attivo, o rete assente: non c'è nulla da
      // segnalare, non è un errore da mostrare al coach.
    }
  }

  controllaAggiornamento();
  web.document.addEventListener(
    'visibilitychange',
    ((web.Event _) {
      if (web.document.visibilityState == 'visible') controllaAggiornamento();
    }).toJS,
  );
}

void aggiornaPwa() {
  web.window.location.reload();
}
