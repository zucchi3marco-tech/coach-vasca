/// Rileva quando è disponibile una nuova versione della PWA (un nuovo
/// service worker ha preso il controllo) — solo su web, stub no-op
/// altrove. Vedi [aggiornamentoDisponibile]/
/// [avviaOsservazioneAggiornamentoPwa]/[aggiornaPwa] nei due file
/// condizionali.
library;

export 'aggiornamento_pwa_stub.dart'
    if (dart.library.js_interop) 'aggiornamento_pwa_web.dart';
