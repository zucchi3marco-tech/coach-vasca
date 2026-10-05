import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const scaricaFileDisponibile = true;

/// Fa scaricare [bytes] al browser come file [nomeFile] — stesso schema
/// di sempre per questo genere di cose: un link "a" temporaneo con un
/// URL blob, un clic simulato, poi lo si rimuove.
void scaricaFile(Uint8List bytes, String nomeFile, {String? mimeType}) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = nomeFile;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
