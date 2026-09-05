import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Un valore statistico — vedi DESIGN.md sezione 8, "Pannelli
/// statistica": etichetta sopra, valore `numeroGrande` con cifre
/// tabulari, unità/confronto sotto. Per affiancarne più di uno, mettili
/// in una Row/Wrap (massimo quattro, poi vanno a capo).
class StatPanel extends StatelessWidget {
  const StatPanel({
    required this.etichetta,
    required this.valore,
    this.confronto,
    super.key,
  });

  final String etichetta;
  final String valore;
  final String? confronto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etichetta, style: AppTypography.etichetta),
        const SizedBox(height: AppSpacing.s4),
        Text(
          valore,
          style: AppTypography.cifreTabulari(
            AppTypography.numeroGrande.copyWith(color: AppColors.testo),
          ),
        ),
        if (confronto != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(confronto!, style: AppTypography.piccolo),
        ],
      ],
    );
  }
}
