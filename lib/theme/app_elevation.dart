import 'package:flutter/material.dart';

/// I cinque livelli di profondità — DESIGN.md sezione 11. Il chiaro usa
/// l'ombra, lo scuro usa la luminosità della superficie (vedi
/// `tokens_chiaro.dart`/`tokens_scuro.dart` per come le superfici salgono
/// di luminosità con il livello): **il tema scuro non ha ombre** sotto
/// il livello 3, e anche lì servono solo a staccare dal velo, non a
/// creare profondità.
///
/// Il livello 0 (fondo pagina) e il livello 1 (pannello/riga/campo) non
/// hanno mai ombra in nessuno dei due temi — il livello 1 si distingue
/// con `superficie` + bordo `linea`, non con `AppElevation`.
abstract final class AppElevation {
  /// AppBar su scorrimento, barra di azione fissa.
  static const List<BoxShadow> livello2Chiaro = [
    BoxShadow(
      color: Color.fromRGBO(12, 27, 36, 0.06),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Menu, dropdown, snackbar, tooltip.
  static const List<BoxShadow> livello3Chiaro = [
    BoxShadow(
      color: Color.fromRGBO(12, 27, 36, 0.12),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
    BoxShadow(
      color: Color.fromRGBO(12, 27, 36, 0.08),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// Dialog, bottom sheet.
  static const List<BoxShadow> livello4Chiaro = [
    BoxShadow(
      color: Color.fromRGBO(12, 27, 36, 0.18),
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
  ];

  /// Livelli 0-2: nessuna ombra nello scuro, la profondità è solo
  /// luminosità di superficie + bordo.
  static const List<BoxShadow> livello0Scuro = [];
  static const List<BoxShadow> livello1Scuro = [];
  static const List<BoxShadow> livello2Scuro = [];

  /// Menu, dropdown, snackbar, tooltip — nello scuro il lavoro lo fa
  /// `superficieAlta` + bordo `lineaForte` (DESIGN.md sezione 11); questa
  /// ombra leggerissima serve solo a staccare dal velo dietro, non a
  /// dare profondità. Valore non specificato in DESIGN.md, scelta
  /// autonoma (vedi riepilogo finale).
  static const List<BoxShadow> livello3Scuro = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.24),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Dialog, bottom sheet — stesso discorso di [livello3Scuro], un filo
  /// più marcata perché il livello è più "sopra" lo scrim.
  static const List<BoxShadow> livello4Scuro = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.32),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];
}
