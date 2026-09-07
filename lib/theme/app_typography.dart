import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Scala tipografica — vedi DESIGN.md sezione 4. Un solo carattere
/// (IBM Plex Sans), una condensata solo per colonne strette (distinta,
/// tabella passi, referto), e le cifre tabulari obbligatorie per ogni
/// numero in colonna o che rappresenta un tempo.
abstract final class AppTypography {
  static TextStyle _plex({
    required double dimensione,
    required double interlinea,
    required FontWeight peso,
    Color colore = AppColors.testo,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: dimensione,
      height: interlinea / dimensione,
      fontWeight: peso,
      color: colore,
    );
  }

  static TextStyle display = _plex(
    dimensione: 44,
    interlinea: 48,
    peso: FontWeight.w700,
  );
  static TextStyle titoloXl = _plex(
    dimensione: 28,
    interlinea: 34,
    peso: FontWeight.w600,
  );
  static TextStyle titolo = _plex(
    dimensione: 22,
    interlinea: 28,
    peso: FontWeight.w600,
  );
  static TextStyle sezione = _plex(
    dimensione: 17,
    interlinea: 24,
    peso: FontWeight.w600,
  );
  static TextStyle corpo = _plex(
    dimensione: 16,
    interlinea: 24,
    peso: FontWeight.w400,
  );
  static TextStyle corpoForte = _plex(
    dimensione: 16,
    interlinea: 24,
    peso: FontWeight.w600,
  );
  static TextStyle piccolo = _plex(
    dimensione: 14,
    interlinea: 20,
    peso: FontWeight.w400,
    colore: AppColors.testoSecondario,
  );
  static TextStyle etichetta = _plex(
    dimensione: 13,
    interlinea: 18,
    peso: FontWeight.w500,
    colore: AppColors.testoSecondario,
  );
  static TextStyle numeroGrande = _plex(
    dimensione: 34,
    interlinea: 38,
    peso: FontWeight.w700,
  );

  /// IBM Plex Sans Condensed: solo per colonne strette (distinta, tabella
  /// passi, referto), mai per il testo normale.
  ///
  /// "IBM Plex Sans Condensed" non è nel catalogo servito dal pacchetto
  /// `google_fonts` in uso: un font-asset locale (scaricato da
  /// github.com/IBM/plex) è stato provato e ha causato instabilità di
  /// rendering diffusa sul web (liste che smettevano di comparire,
  /// blocchi) — vedi ROADMAP.md. Finché non si trova un'alternativa
  /// sicura, si usa la IBM Plex Sans normale.
  static TextStyle condensata(TextStyle base) {
    return GoogleFonts.ibmPlexSans(textStyle: base);
  }

  /// Obbligatoria per ogni numero in colonna o che rappresenta un tempo:
  /// senza, le colonne di cifre ballano e diventano illeggibili.
  static TextStyle cifreTabulari(TextStyle base) {
    return base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }

  static TextTheme textTheme = TextTheme(
    displayMedium: display,
    headlineMedium: titoloXl,
    headlineSmall: titolo,
    titleMedium: sezione,
    bodyLarge: corpo,
    bodyMedium: corpo,
    bodySmall: piccolo,
    labelLarge: etichetta,
    labelMedium: etichetta,
  );
}
