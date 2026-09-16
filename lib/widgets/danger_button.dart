import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Pulsante distruttivo — vedi DESIGN.md sezione 13: bordo 1px rosso,
/// testo rosso, fondo trasparente. Un pulsante rosso pieno non esiste in
/// questa app. Va sempre chiamato dopo una conferma (dialog), non prima:
/// questo widget non la mostra da solo.
class DangerButton extends StatelessWidget {
  const DangerButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final rosso = context.colori.rosso;
    final style = OutlinedButton.styleFrom(
      foregroundColor: rosso,
      side: BorderSide(color: rosso),
      minimumSize: const Size.fromHeight(AppSpacing.altezzaMinimaBersaglio),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.controllo),
      ),
      textStyle: AppTypography.corpoForte,
    );

    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
