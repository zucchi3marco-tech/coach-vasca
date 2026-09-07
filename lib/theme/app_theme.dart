import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'domain_tokens.dart';
import 'superfici_tema.dart';

/// ThemeData completo dell'app — vedi DESIGN.md sezione 14. Un solo tema
/// chiaro per le schermate da scrivania; [scuroBordoVasca] è una variante
/// che solo le tre schermate da bordo vasca possono scegliere di
/// applicare (DESIGN.md sezione 9, "Chiaro o scuro?").
abstract final class AppTheme {
  static ThemeData chiaro = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.sfondo,
    colorScheme: const ColorScheme.light(
      primary: AppColors.blu,
      onPrimary: Colors.white,
      secondary: AppColors.blu,
      onSecondary: Colors.white,
      error: AppColors.rosso,
      onError: Colors.white,
      surface: AppColors.superficie,
      onSurface: AppColors.testo,
    ),
    fontFamily: AppTypography.corpo.fontFamily,
    textTheme: AppTypography.textTheme,
    extensions: const [DomainTokens.standard],

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.superficie,
      foregroundColor: AppColors.testo,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.titolo,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.linea,
      thickness: 1,
      space: 1,
    ),

    cardTheme: CardThemeData(
      color: AppColors.superficie,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        side: const BorderSide(color: AppColors.linea),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.superficie,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s16,
      ),
      labelStyle: AppTypography.etichetta,
      hintStyle: AppTypography.corpo.copyWith(color: AppColors.testoTenue),
      helperStyle: AppTypography.piccolo,
      errorStyle: AppTypography.piccolo.copyWith(color: AppColors.rosso),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        borderSide: const BorderSide(color: AppColors.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        borderSide: const BorderSide(color: AppColors.linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        borderSide: const BorderSide(color: AppColors.blu, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        borderSide: const BorderSide(color: AppColors.rosso),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        borderSide: const BorderSide(color: AppColors.rosso, width: 2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: AppColors.blu,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.testoTenue,
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
        foregroundColor: AppColors.testo,
        backgroundColor: AppColors.superficie,
        side: const BorderSide(color: AppColors.linea),
        minimumSize: const Size.fromHeight(AppSpacing.altezzaMinimaBersaglio),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        ),
        textStyle: AppTypography.corpoForte,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blu,
        minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
        textStyle: AppTypography.corpoForte,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.superficieTenue,
      labelStyle: AppTypography.piccolo.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.testo,
      ),
      side: const BorderSide(color: AppColors.linea),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      shape: const StadiumBorder(),
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
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.raggioSheet),
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.raggioSheet),
      ),
      titleTextStyle: AppTypography.titolo,
      contentTextStyle: AppTypography.corpo,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.blu,
      foregroundColor: Colors.white,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.blu
            : AppColors.superficie,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.bluTenue
            : AppColors.linea,
      ),
    ),
  );

  /// Variante scura, solo per le tre schermate da bordo vasca. Stessa
  /// struttura di [chiaro]: cambiano i neutri (via [SuperficiTema.scuro]),
  /// restano invariati i colori d'azione/segnale (blu, rosso, ok,
  /// attenzione) perché quelli portano un significato, non solo contrasto.
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
