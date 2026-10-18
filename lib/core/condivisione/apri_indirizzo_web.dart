import 'package:web/web.dart' as web;

/// Apre [indirizzo] in una scheda nuova del browser.
bool apriIndirizzo(String indirizzo) {
  web.window.open(indirizzo, '_blank', 'noopener');
  return true;
}

/// Porta la pagina a [indirizzo] (per `webcal://`: il telefono apre
/// l'iscrizione al calendario).
bool apriCollegamento(String indirizzo) {
  web.window.location.href = indirizzo;
  return true;
}
