import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Campo di testo con etichetta fissa sopra (mai flottante) — vedi
/// DESIGN.md sezione 13, "Campi di testo". I campi opzionali lo dicono
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
    this.onChanged,
    this.focusNode,
    this.valoreIniziale,
    this.abilitato = true,
    super.key,
  });

  final String etichetta;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? aiuto;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  /// Per i campi password. Vedi DESIGN.md sezione 13: nessun widget su
  /// misura dentro una schermata, quindi questi casi restano parametri
  /// opzionali del componente condiviso invece di un campo locale.
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  /// Testo di un campo di sola visualizzazione (senza controller): per un
  /// valore che cambia, dare al widget una `key` che cambi con esso.
  final String? valoreIniziale;
  final bool abilitato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etichetta,
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? valoreIniziale : null,
          enabled: abilitato,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          style: AppTypography.corpo.copyWith(color: colori.testo),
          decoration: InputDecoration(
            helperText: aiuto,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
