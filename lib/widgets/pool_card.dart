import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Il pannello di base: superficie bianca su sfondo grigio, bordo 1px
/// linea, raggio 12 — vedi DESIGN.md sezione 6. "Non tutto è una card":
/// usalo solo per un vero contenitore di gruppo, non per ogni riquadro.
class PoolCard extends StatelessWidget {
  const PoolCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.paddingPannello),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: AppColors.linea),
      ),
      child: child,
    );
  }
}
