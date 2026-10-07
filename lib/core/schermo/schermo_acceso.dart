/// Tiene lo schermo acceso mentre una sessione a bordo vasca è aperta —
/// DESIGN.md sezione 14: "Lo schermo non si spegne mentre una sessione è
/// attiva". Su web usa la Screen Wake Lock API del browser; altrove non
/// fa nulla (stub).
library;

export 'schermo_acceso_stub.dart'
    if (dart.library.js_interop) 'schermo_acceso_web.dart';
