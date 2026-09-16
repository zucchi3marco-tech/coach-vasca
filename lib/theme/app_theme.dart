import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'colori_app.dart';
import 'domain_tokens.dart';
import 'superfici_tema.dart';
import 'tokens_dominio.dart';

/// ThemeData completo dell'app — [chiaro] e [scuro] sono la coppia della
/// versione 2 di DESIGN.md (sezioni 3-20): `colorScheme` mappato dai
/// token uno per uno (sezione 20), `extensions: [ColoriApp, TokenDominio]`
/// per tutto quello che Material non sa già gestire.
///
/// [scuroBordoVasca] resta invariato: è la variante che solo le tre
/// schermate da bordo vasca possono scegliere di applicare (era già così
/// prima della versione 2 del design system, vedi `partita_live_screen`),
/// e non fa parte di questa fase.
abstract final class AppTheme {
  static ThemeData _costruisci({
    required Brightness brightness,
    required ColoriApp colori,
    required TokenDominio dominio,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colori.azione,
      onPrimary: colori.azioneInk,
      primaryContainer: colori.azioneTenue,
      onPrimaryContainer: colori.testo,
      secondary: colori.azione,
      onSecondary: colori.azioneInk,
      surface: colori.superficie,
      onSurface: colori.testo,
      onSurfaceVariant: colori.testoSecondario,
      surfaceContainerLowest: colori.sfondo,
      surfaceContainerLow: colori.superficieAlt,
      surfaceContainerHigh: colori.superficieAlta,
      surfaceContainerHighest: colori.superficieMassima,
      outline: colori.lineaForte,
      outlineVariant: colori.linea,
      error: colori.rosso,
      onError: colori.azioneInk,
      errorContainer: colori.rossoTenue,
      onErrorContainer: colori.testo,
      scrim: colori.scrim,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colori.sfondo,
      colorScheme: colorScheme,
      fontFamily: AppTypography.corpo.fontFamily,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colori.testo,
        displayColor: colori.testo,
      ),
      extensions: [colori, dominio],
      focusColor: colori.azioneFuoco,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: colori.superficie,
        foregroundColor: colori.testo,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.titolo.copyWith(color: colori.testo),
        // A riposo piatta; lo scorrimento che guadagna il filetto (chiaro)
        // o passa a superficieAlt (scuro) è gestito dalla schermata con
        // uno SliverAppBar/NotificationListener — DESIGN.md sezione 10,
        // "Scorrimento". Il tema fissa solo lo stato a riposo.
      ),

      dividerTheme: DividerThemeData(
        color: colori.linea,
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: colori.superficie,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          side: BorderSide(color: colori.linea),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colori.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s16,
        ),
        labelStyle: AppTypography.etichetta.copyWith(
          color: colori.testoSecondario,
        ),
        hintStyle: AppTypography.corpo.copyWith(color: colori.testoTenue),
        helperStyle: AppTypography.piccolo.copyWith(
          color: colori.testoSecondario,
        ),
        errorStyle: AppTypography.piccolo.copyWith(color: colori.rosso),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          borderSide: BorderSide(color: colori.lineaForte),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          borderSide: BorderSide(color: colori.lineaForte),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          borderSide: BorderSide(color: colori.azione, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          borderSide: BorderSide(color: colori.rosso),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          borderSide: BorderSide(color: colori.rosso, width: 2),
        ),
      ),

      // Pulsante principale — DESIGN.md sezione 13: fondo azione, testo
      // azioneInk, raggio 8, altezza 48 (52 da esteso — deciso schermata
      // per schermata, non nel tema globale).
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: colori.azione,
              foregroundColor: colori.azioneInk,
              disabledBackgroundColor: colori.testoTenue,
              disabledForegroundColor: colori.superficie,
              minimumSize: const Size.fromHeight(
                AppSpacing.altezzaMinimaBersaglio,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.controllo),
              ),
              textStyle: AppTypography.corpoForte,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? colori.azionePremuta
                    : null,
              ),
            ),
      ),

      // Pulsante secondario — bordo lineaForte, testo testo, fondo
      // superficie.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colori.testo,
          backgroundColor: colori.superficie,
          side: BorderSide(color: colori.lineaForte),
          minimumSize: const Size.fromHeight(AppSpacing.altezzaMinimaBersaglio),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.controllo),
          ),
          textStyle: AppTypography.corpoForte,
        ),
      ),

      // Pulsante testuale — solo testo azione, padding orizzontale 12.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colori.azione,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
          minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
          textStyle: AppTypography.corpoForte,
        ),
      ),

      // Variante neutra di sezione 13 — le varianti "selezionato" e "di
      // dominio" si compongono nel widget `TonalChip`, non nel tema
      // globale (dipendono dal token di dominio o dallo stato).
      chipTheme: ChipThemeData(
        backgroundColor: colori.superficieAlt,
        labelStyle: AppTypography.piccolo.copyWith(
          fontWeight: FontWeight.w500,
          color: colori.testoSecondario,
        ),
        side: BorderSide(color: colori.linea),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        shape: const StadiumBorder(),
      ),

      // Livello 3, filetto sinistro ok applicato dal widget che la
      // mostra (uno snackbar "neutro" qui non porta di per sé il
      // significato di conferma) — DESIGN.md sezione 13 "Conferme": "nel
      // tema scuro la snackbar è superficieAlta, non un rettangolo
      // chiaro invertito".
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colori.superficieAlta,
        contentTextStyle: AppTypography.corpo.copyWith(color: colori.testo),
        actionTextColor: colori.azione,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          side: BorderSide(color: colori.lineaForte),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colori.superficieMassima,
        elevation: 0,
        modalBackgroundColor: colori.superficieMassima,
        modalBarrierColor: colori.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colori.superficieMassima,
        elevation: 0,
        barrierColor: colori.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: AppTypography.titolo.copyWith(color: colori.testo),
        contentTextStyle: AppTypography.corpo.copyWith(color: colori.testo),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colori.azione,
        foregroundColor: colori.azioneInk,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colori.azione
              : colori.superficie,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colori.azioneTenue
              : colori.linea,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colori.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: colori.azioneTenue,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.etichetta.copyWith(
            color: states.contains(WidgetState.selected)
                ? colori.azione
                : colori.testoSecondario,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colori.azione
                : colori.testoSecondario,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colori.superficie,
        elevation: 0,
        indicatorColor: colori.azioneTenue,
        selectedLabelTextStyle: AppTypography.etichetta.copyWith(
          color: colori.azione,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTypography.etichetta.copyWith(
          color: colori.testoSecondario,
        ),
        selectedIconTheme: IconThemeData(color: colori.azione),
        unselectedIconTheme: IconThemeData(color: colori.testoSecondario),
      ),

      iconTheme: IconThemeData(color: colori.testoSecondario),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colori.superficieAlta,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          border: Border.all(color: colori.lineaForte),
        ),
        textStyle: AppTypography.piccolo.copyWith(color: colori.testo),
      ),
    );
  }

  static ThemeData chiaro = _costruisci(
    brightness: Brightness.light,
    colori: ColoriApp.chiaro,
    dominio: TokenDominio.chiaro,
  );

  static ThemeData scuro = _costruisci(
    brightness: Brightness.dark,
    colori: ColoriApp.scuro,
    dominio: TokenDominio.scuro,
  );

  /// Variante scura, solo per le tre schermate da bordo vasca — invariata
  /// rispetto a prima della versione 2 di DESIGN.md: non fa parte di
  /// questa fase (resta legata ad `AppColors`/`SuperficiTema`/
  /// `DomainTokens`, il sistema di token precedente), la userà ancora
  /// `partita_live_screen.dart` finché quella schermata non migra.
  static ThemeData scuroBordoVasca = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SuperficiTema.scuro.sfondo,
    colorScheme: ColorScheme.dark(
      primary: AppColors.blu,
      onPrimary: Colors.white,
      secondary: AppColors.blu,
      onSecondary: Colors.white,
      error: AppColors.rosso,
      onError: Colors.white,
      surface: SuperficiTema.scuro.superficie,
      onSurface: SuperficiTema.scuro.testo,
    ),
    fontFamily: AppTypography.corpo.fontFamily,
    extensions: [DomainTokens.standard, SuperficiTema.scuro],

    appBarTheme: AppBarTheme(
      backgroundColor: SuperficiTema.scuro.superficie,
      foregroundColor: SuperficiTema.scuro.testo,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.titolo.copyWith(
        color: SuperficiTema.scuro.testo,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: SuperficiTema.scuro.linea,
      thickness: 1,
      space: 1,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: AppColors.blu,
            foregroundColor: Colors.white,
            disabledBackgroundColor: SuperficiTema.scuro.testoTenue,
            minimumSize: const Size.fromHeight(
              AppSpacing.altezzaMinimaBersaglio,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
            ),
            textStyle: AppTypography.corpoForte,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? AppColors.bluPremuto
                  : null,
            ),
          ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SuperficiTema.scuro.testo,
        backgroundColor: SuperficiTema.scuro.superficie,
        side: BorderSide(color: SuperficiTema.scuro.linea),
        minimumSize: const Size.fromHeight(AppSpacing.altezzaMinimaBersaglio),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        ),
        textStyle: AppTypography.corpoForte,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ok,
      contentTextStyle: AppTypography.corpo.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: SuperficiTema.scuro.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.raggioSheet),
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: SuperficiTema.scuro.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioSheet),
      ),
      titleTextStyle: AppTypography.titolo.copyWith(
        color: SuperficiTema.scuro.testo,
      ),
      contentTextStyle: AppTypography.corpo.copyWith(
        color: SuperficiTema.scuro.testo,
      ),
    ),
  );
}
