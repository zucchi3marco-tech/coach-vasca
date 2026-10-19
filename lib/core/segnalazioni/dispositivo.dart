/// Telefono o computer e browser di chi scrive una segnalazione: sul web
/// l'identificativo del browser (`navigator.userAgent`), altrove la
/// piattaforma. Vedi [descrizioneDispositivo] nei due file condizionali.
library;

export 'dispositivo_stub.dart'
    if (dart.library.js_interop) 'dispositivo_web.dart';
