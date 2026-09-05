import 'package:flutter/material.dart';

/// Tutti i colori dell'app vivono qui — vedi DESIGN.md sezione 3.
/// Nessun colore va scritto a mano dentro una schermata.
abstract final class AppColors {
  // Neutri
  static const sfondo = Color(0xFFEFF2F4);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieTenue = Color(0xFFF7F9FA);
  static const linea = Color(0xFFD5DBE0);
  static const testo = Color(0xFF10222E);
  static const testoSecondario = Color(0xFF55697A);
  static const testoTenue = Color(0xFF8A9AA8);

  // Colori d'azione
  static const blu = Color(0xFF0D5C87);
  static const bluPremuto = Color(0xFF094866);
  static const bluTenue = Color(0xFFE3EEF5);

  // Segnale
  static const rosso = Color(0xFFD42D1E);
  static const rossoTenue = Color(0xFFFCEAE8);
  static const ok = Color(0xFF157F4C);
  static const attenzione = Color(0xFFB4690E);

  // Zone di intensita'
  static const zonaA1 = Color(0xFF4FA3D1);
  static const zonaA2 = Color(0xFF2E8B8B);
  static const zonaB1 = Color(0xFF5A9E3F);
  static const zonaB2 = Color(0xFFC79A18);
  static const zonaC = Color(0xFFD9741F);
  static const zonaD = Color(0xFF8E3B8F);

  // Calottine (pallanuoto)
  static const calottinaBianca = Color(0xFFFFFFFF);
  static const calottinaBlu = Color(0xFF14477D);
  static const calottinaRossaPortiere = Color(0xFFD42D1E);
}
