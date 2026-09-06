import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Campo di testo con etichetta fissa sopra (mai flottante) — vedi
/// DESIGN.md sezione 8, "Campi di testo". I campi opzionali lo dicono
/// nell'etichetta ("facoltativo"), non con un asterisco sugli obbligatori.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.etichetta,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.aiuto,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.obscureText = false,
    this.autofillHints,
    this.onFieldSubmitted,
    super.key,
  });

  final String etichetta;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? aiuto;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  /// Per i campi password. Vedi DESIGN.md sezione 8: nessun widget su
  /// misura dentro una schermata, quindi questi casi restano parametri
  /// opzionali del componente condiviso invece di un campo locale.
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etichetta, style: AppTypography.etichetta),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          style: AppTypography.corpo.copyWith(color: AppColors.testo),
          decoration: InputDecoration(
            helperText: aiuto,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
