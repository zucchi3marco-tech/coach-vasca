/// Notifiche push (Web Push) — solo su web; su native le funzioni non
/// fanno nulla (stato `nonSupportato`). Vedi i due file condizionali.
library;

export 'push_notifiche_stub.dart'
    if (dart.library.js_interop) 'push_notifiche_web.dart';
export 'push_tipi.dart';
