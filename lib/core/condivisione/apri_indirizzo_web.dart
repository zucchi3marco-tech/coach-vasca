import 'package:web/web.dart' as web;

/// Apre [indirizzo] in una scheda nuova del browser.
bool apriIndirizzo(String indirizzo) {
  web.window.open(indirizzo, '_blank', 'noopener');
  return true;
}
