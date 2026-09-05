import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Pannello che raggruppa più [AppListRow], separate da filetti da 1px —
/// vedi DESIGN.md sezione 8, "Elenchi".
class AppListPanel extends StatelessWidget {
  const AppListPanel({required this.righe, super.key});

  final List<Widget> righe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: AppColors.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < righe.length; i++) ...[
            righe[i],
            if (i != righe.length - 1)
              const Divider(color: AppColors.linea, height: 1),
          ],
        ],
      ),
    );
  }
}
