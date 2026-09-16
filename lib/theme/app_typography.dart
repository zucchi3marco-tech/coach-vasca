import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Scala tipografica — vedi DESIGN.md sezione 8. Un solo carattere
/// (IBM Plex Sans), una condensata solo per colonne strette (distinta,
/// tabella passi, referto), e le cifre tabulari + zero barrato
/// obbligatori per ogni numero in colonna o che rappresenta un tempo.
///
/// Questi stili non portano un colore fisso: chi li usa applica sempre
/// `.copyWith(color: context.colori.X)` (DESIGN.md sezione 20) — senza
/// override, il colore resta `null` ed eredita dal `DefaultTextStyle`
/// ambiente (a sua volta guidato da `AppTheme` tramite
/// `textTheme.apply(bodyColor: ..., displayColor: ...)`), che segue già
/// il tema chiaro/scuro invece di restare fisso.
abstract final class AppTypography {
  static TextStyle _plex({
    required double dimensione,
    required double interlinea,
    required FontWeight peso,
    double spaziatura = 0,
    Color? colore,
  }) {
    return GoogleFonts.ibmPlexSans(
      fontSize: dimensione,
      height: interlinea / dimensione,
      fontWeight: peso,
      letterSpacing: spaziatura,
      color: colore,
    );
  }

  /// Solo per le schermate da bordo vasca, variante telefono (DESIGN.md
  /// sezione 8: "44/46 · 64/66 su tablet"). È il valore storico di
  /// `display` prima che esistesse una variante tablet distinta.
  static TextStyle display = _plex(
    dimensione: 44,
    interlinea: 46,
    peso: FontWeight.w700,
    spaziatura: -1.0,
  );

  /// Variante tablet di [display] — DESIGN.md sezione 8. Non ancora
  /// scelta automaticamente da nessuna schermata: la scelta fra le due
  /// varianti spetta a chi migra la schermata (di solito con
  /// `Breakpoint.of(context)`, vedi app_layout.dart).
  static TextStyle displayTablet = _plex(
    dimensione: 64,
    interlinea: 66,
    peso: FontWeight.w700,
    spaziatura: -1.0,
  );

  static TextStyle titoloXl = _plex(
    dimensione: 28,
    interlinea: 34,
    peso: FontWeight.w600,
    spaziatura: -0.4,
  );
  static TextStyle titolo = _plex(
    dimensione: 22,
    interlinea: 28,
    peso: FontWeight.w600,
    spaziatura: -0.2,
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
  );
  static TextStyle etichetta = _plex(
    dimensione: 13,
    interlinea: 18,
    peso: FontWeight.w500,
    spaziatura: 0.1,
  );
  static TextStyle numeroGrande = _plex(
    dimensione: 34,
    interlinea: 38,
    peso: FontWeight.w700,
    spaziatura: -0.5,
  );

  /// Numeri dentro una riga di tabella o di elenco — DESIGN.md sezione 8
  /// (nuovo in questa scala, prima non esisteva un ruolo dedicato: chi
  /// serviva un numero medio usava `corpoForte` a mano).
  static TextStyle numeroMedio = _plex(
    dimensione: 22,
    interlinea: 26,
    peso: FontWeight.w600,
    spaziatura: -0.2,
  );

  /// IBM Plex Sans Condensed: solo per colonne strette (distinta, tabella
  /// passi, referto), mai per il testo normale.
  ///
  /// "IBM Plex Sans Condensed" non è nel catalogo servito dal pacchetto
  /// `google_fonts` in uso: un font-asset locale (scaricato da
  /// github.com/IBM/plex) è stato provato e ha causato instabilità di
  /// rendering diffusa sul web (liste che smettevano di comparire,
  /// blocchi) — vedi ROADMAP.md. Finché non si trova un'alternativa
  /// sicura, si usa la IBM Plex Sans normale: `condensata()` è un alias
  /// del rendering "regolare" (`GoogleFonts.ibmPlexSans`), non una vera
  /// condensata.
  static TextStyle condensata(TextStyle base) {
    return GoogleFonts.ibmPlexSans(textStyle: base);
  }

  /// Obbligatoria per ogni numero in colonna o che rappresenta un tempo:
  /// senza, le colonne di cifre ballano e diventano illeggibili.
  ///
  /// Alias dello storico `cifreTabulari()`, che resta per compatibilità
  /// con le schermate già scritte: `numerica()` aggiunge anche
  /// `FontFeature.slashedZero()` (DESIGN.md sezione 8 — "a mezzo metro
  /// di distanza uno zero e una O si confondono"), da preferire in ogni
  /// codice nuovo.
  static TextStyle numerica(TextStyle base) {
    return base.copyWith(
      fontFeatures: const [
        FontFeature.tabularFigures(),
        FontFeature.slashedZero(),
      ],
    );
  }

  /// Storico: solo cifre tabulari, senza zero barrato. Vedi [numerica].
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
