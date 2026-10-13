/// Aprire un indirizzo web in una scheda nuova del browser: su web sì,
/// altrove e nei test no (chi chiama copia l'indirizzo negli appunti).
/// Vedi i due file condizionali.
library;

export 'apri_indirizzo_stub.dart'
    if (dart.library.js_interop) 'apri_indirizzo_web.dart';
