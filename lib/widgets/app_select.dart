import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Menu a tendina con la stessa etichetta fissa sopra dei campi di testo
/// (mai flottante) — vedi DESIGN.md sezione 8.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    required this.etichetta,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String etichetta;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etichetta, style: AppTypography.etichetta),
        const SizedBox(height: AppSpacing.s8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: AppTypography.corpo.copyWith(color: AppColors.testo),
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  style: AppTypography.corpo.copyWith(
                    color: AppColors.testoTenue,
                  ),
                ),
        ),
      ],
    );
  }
}
