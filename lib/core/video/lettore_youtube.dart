/// Il lettore dei video YouTube (IFrame Player API), solo su web; fuori
/// dal web e nei test un riquadro finto con gli stessi comandi. Vedi i due
/// file condizionali e [ControlloreVideo].
library;

export 'controllore_video.dart';
export 'lettore_youtube_stub.dart'
    if (dart.library.js_interop) 'lettore_youtube_web.dart';
