import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/colori_app.dart';

/// Il pannello di base: superficie bianca su sfondo grigio, bordo 1px
/// linea, raggio 12 — vedi DESIGN.md sezione 6. "Non tutto è una card":
/// usalo solo per un vero contenitore di gruppo, non per ogni riquadro.
///
/// Legge [ColoriApp] dal tema ambiente — chiaro ovunque, tranne dentro
/// le tre schermate da bordo vasca se l'allenatore ha scelto lo scuro
/// (DESIGN.md sezione 15).
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
    final colori = context.colori;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: child,
    );
  }
}
