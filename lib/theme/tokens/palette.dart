import 'package:flutter/material.dart';

/// Primitivi di colore — DESIGN.md sezione 4. Nessun significato
/// semantico nei nomi: solo scale grezze. **Nessuna schermata importa
/// questo file**: lo leggono solo `tokens_chiaro.dart`/`tokens_scuro.dart`
/// (DESIGN.md sezione 3, livello 1 "Primitivi").
abstract final class Palette {
  // ---------------------------------------------------------------
  // Acqua — la scala d'azione. acqua600 è il blu della piastrella
  // (azione nel chiaro), acqua400 è l'acqua illuminata (azione nello
  // scuro).
  // ---------------------------------------------------------------
  static const acqua50 = Color(0xFFEDF6FB);
  static const acqua100 = Color(0xFFD3E8F4);
  static const acqua200 = Color(0xFFA9D2E8);
  static const acqua300 = Color(0xFF71B4D6);
  static const acqua400 = Color(0xFF4FC3E8);
  static const acqua500 = Color(0xFF1E76A4);
  static const acqua600 = Color(0xFF0D5C87);
  static const acqua700 = Color(0xFF094B6E);
  static const acqua800 = Color(0xFF073A55);
  static const acqua900 = Color(0xFF05293C);

  // ---------------------------------------------------------------
  // Neutri chiari — la piastrella. Solo questi otto esistono (niente
  // chiaro400/700/800).
  // ---------------------------------------------------------------
  static const chiaro0 = Color(0xFFFFFFFF);
  static const chiaro50 = Color(0xFFF7FAFC);
  static const chiaro100 = Color(0xFFEEF2F5);
  static const chiaro200 = Color(0xFFDCE3E9);
  static const chiaro300 = Color(0xFFC3CDD6);
  static const chiaro500 = Color(0xFF64798A);
  static const chiaro600 = Color(0xFF4A5F70);
  static const chiaro900 = Color(0xFF0C1B24);

  // ---------------------------------------------------------------
  // Neutri scuri — l'acqua di notte. Punta di blu (~205° di tinta,
  // saturazione 25-30%): un grigio neutro puro sembrerebbe sporco
  // accanto all'azzurro d'azione.
  // ---------------------------------------------------------------
  static const scuro900 = Color(0xFF0B141B);
  static const scuro800 = Color(0xFF121E27);
  static const scuro700 = Color(0xFF18262F);
  static const scuro600 = Color(0xFF1F2F3A);
  static const scuro500 = Color(0xFF253743);
  static const scuro400 = Color(0xFF263844);
  static const scuro300 = Color(0xFF38505F);
  static const scuro200 = Color(0xFF7A8E9D);
  static const scuro100 = Color(0xFFA3B5C2);
  static const scuro50 = Color(0xFFE8EFF4);

  // ---------------------------------------------------------------
  // Segnale — rosso/verde/ambra, una variante per tema.
  // ---------------------------------------------------------------
  static const rossoChiaro = Color(0xFFD42D1E);
  static const rossoScuro = Color(0xFFFF6B5A);
  static const verdeChiaro = Color(0xFF157F4C);
  static const verdeScuro = Color(0xFF45D391);
  static const ambraChiaro = Color(0xFF9E5A08);
  static const ambraScuro = Color(0xFFF0A93C);
}
