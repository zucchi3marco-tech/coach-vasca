/// Aprire un indirizzo web in una scheda nuova del browser: su web sì,
/// altrove e nei test no (chi chiama copia l'indirizzo negli appunti).
/// Vedi i due file condizionali.
///
/// `apriCollegamento` invece porta la pagina stessa all'indirizzo: serve
/// per gli indirizzi `webcal://`, che su iPhone aprono la richiesta di
/// iscrizione al calendario solo se la pagina ci naviga.
library;

export 'apri_indirizzo_stub.dart'
    if (dart.library.js_interop) 'apri_indirizzo_web.dart';
