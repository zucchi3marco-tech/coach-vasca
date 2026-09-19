import 'package:flutter/material.dart';

import '../theme/colori_app.dart';

/// Cerchio con un'icona su sfondo tenue dello stesso colore — badge
/// d'identità per una card/sezione (dashboard atleta, riepilogo club).
/// Colore di default [ColoriApp.azione] se non specificato.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icona, {this.colore, this.dimensione = 48, super.key});

  final IconData icona;
  final Color? colore;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final colore = this.colore ?? context.colori.azione;
    return Container(
      width: dimensione,
      height: dimensione,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icona, color: colore),
    );
  }
}
