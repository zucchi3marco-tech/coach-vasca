import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/superfici_tema.dart';

/// Scheletro di caricamento — vedi DESIGN.md sezione 8, "Caricamento".
/// Un rettangolo `superficieTenue` della forma del contenuto in arrivo;
/// mai una rotellina sola in mezzo allo schermo.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.width = double.infinity,
    this.height = AppSpacing.s16,
    super.key,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SuperficiTema.of(context).superficieTenue,
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
      ),
    );
  }
}

/// Un gruppo di righe scheletro, per un elenco che sta caricando.
class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({this.righe = 4, super.key});

  final int righe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < righe; i++) ...[
          const LoadingSkeleton(height: AppSpacing.altezzaMinimaRiga),
          if (i != righe - 1) const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}
