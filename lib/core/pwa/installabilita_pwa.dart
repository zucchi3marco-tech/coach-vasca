/// Osserva/attiva il prompt di installazione PWA di Chrome
/// (`beforeinstallprompt`) — solo su web (stub no-op altrove, vedi
/// [installabilitaPwa]/[avviaOsservazioneInstallabilitaPwa]/[installaPwa]
/// nei due file condizionali).
library;

export 'installabilita_pwa_stub.dart'
    if (dart.library.js_interop) 'installabilita_pwa_web.dart';
