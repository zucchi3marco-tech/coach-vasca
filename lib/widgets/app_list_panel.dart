import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/colori_app.dart';

/// Pannello che raggruppa più [AppListRow], separate da filetti da 1px —
/// vedi DESIGN.md sezione 13, "Elenchi".
class AppListPanel extends StatelessWidget {
  const AppListPanel({required this.righe, super.key});

  final List<Widget> righe;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < righe.length; i++) ...[
            righe[i],
            if (i != righe.length - 1) Divider(color: colori.linea, height: 1),
          ],
        ],
      ),
    );
  }
}
