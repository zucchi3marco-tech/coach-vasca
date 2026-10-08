/// Il bip dell'orologio di vasca. Su web suona con la Web Audio API del
/// browser; altrove (e nei test) non fa nulla.
library;

export 'bip_stub.dart' if (dart.library.js_interop) 'bip_web.dart';
