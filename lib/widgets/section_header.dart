import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Intestazione di un gruppo (form, elenco): stile `sezione` con un
/// filetto sotto — vedi DESIGN.md sezione 8, "Form".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.titolo, {super.key});

  final String titolo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: AppTypography.sezione),
        const SizedBox(height: AppSpacing.s8),
        const Divider(color: AppColors.linea, height: 1),
      ],
    );
  }
}
