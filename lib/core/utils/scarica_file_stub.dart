import 'dart:typed_data';

/// Implementazione no-op per le piattaforme native (Android/iOS/desktop)
/// e per i test: lì non esiste un "salva nel browser" a cui appoggiarsi.
/// La UI che chiama [scaricaFile] deve controllare prima
/// [scaricaFileDisponibile] e mostrare un messaggio alternativo.
const scaricaFileDisponibile = false;

void scaricaFile(Uint8List bytes, String nomeFile, {String? mimeType}) {}
