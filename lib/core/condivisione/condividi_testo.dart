/// Condividere un testo con le app del telefono (WhatsApp compresa): il
/// foglio "Condividi" del browser su web, niente altrove e nei test. Vedi
/// i due file condizionali.
library;

export 'condividi_testo_stub.dart'
    if (dart.library.js_interop) 'condividi_testo_web.dart';
