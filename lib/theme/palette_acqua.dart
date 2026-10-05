import 'package:flutter/painting.dart';

/// Colori dell'Area atleta di pallanuoto (testata, calottine, disegni dei
/// riquadri): stanno qui in lib/theme come ogni colore letterale.
///
/// Tavolozza fissa "acqua di piscina coperta", uguale nei due temi: la
/// testata e' una finestra sulla vasca, non una superficie dell'app.
abstract final class AcquaPalette {
  static const profonda = Color(0xFF031B2E);
  static const media = Color(0xFF07406A);
  static const chiara = Color(0xFF0E7FB0);
  static const turchese = Color(0xFF3FD0E0);
  static const schiuma = Color(0xFFE6FAFF);
  static const galleggianteRosso = Color(0xFFE5484D);
  static const galleggianteBianco = Color(0xFFF4F7FA);
  static const palla = Color(0xFFF2C230);
  static const pallaRighe = Color(0xFF1B4F8A);

  /// Bianco e nero puri per luci, riflessi e ombre dei disegni.
  static const bianco = Color(0xFFFFFFFF);
  static const nero = Color(0xFF000000);
}

/// Colori della calottina: bianca o blu come da regolamento, piu' la
/// rossa del portiere.
enum ColoreCalottina {
  bianca(Color(0xFFF5F7FA), Color(0xFF0C2A44), Color(0xFFD6DEE6)),
  blu(Color(0xFF123A8C), Color(0xFFFFFFFF), Color(0xFF0B2766)),
  rossa(Color(0xFFD7263D), Color(0xFFFFFFFF), Color(0xFFA51A2D));

  const ColoreCalottina(this.tessuto, this.numero, this.ombra);
  final Color tessuto;
  final Color numero;
  final Color ombra;

  static ColoreCalottina da(String? valore, {bool portiere = false}) {
    if (portiere) return ColoreCalottina.rossa;
    return valore == 'blu' ? ColoreCalottina.blu : ColoreCalottina.bianca;
  }
}
