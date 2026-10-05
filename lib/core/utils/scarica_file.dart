/// Avvia il download di un file nel browser (es. l'esportazione della
/// libreria blocchi in Excel) — solo su web, stub no-op sulle altre
/// piattaforme (desktop/mobile non hanno un "salva nel browser" a cui
/// appoggiarsi: stesso schema condizionale di `dettatura_vocale.dart`).
library;

export 'scarica_file_stub.dart'
    if (dart.library.js_interop) 'scarica_file_web.dart';
