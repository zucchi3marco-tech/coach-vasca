import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Una riga di elenco — vedi DESIGN.md sezione 8, "Elenchi": titolo
/// `corpoForte`, riga di metadati sotto in `piccolo`/`testoSecondario`.
/// Va dentro un [AppListPanel], mai appoggiata direttamente sul fondo.
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.titolo,
    this.sottotitolo,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String titolo;
  final String? sottotitolo;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titolo,
                      style: AppTypography.corpoForte.copyWith(
                        color: AppColors.testo,
                      ),
                    ),
                    if (sottotitolo != null) ...[
                      const SizedBox(height: 2),
                      Text(sottotitolo!, style: AppTypography.piccolo),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
