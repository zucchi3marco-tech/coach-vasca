/// Riconoscimento vocale del browser (Web Speech API), solo su web e solo
/// dove il browser lo supporta (Chrome/Edge; non Safari/Firefox — vedi
/// [DettatoreVocale.disponibile]). Stub no-op sulle altre piattaforme,
/// vedi i due file condizionali.
library;

export 'dettatura_vocale_stub.dart'
    if (dart.library.js_interop) 'dettatura_vocale_web.dart';
