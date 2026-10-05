import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Pulsante secondario — vedi DESIGN.md sezione 8: bordo 1px linea,
/// testo `testo`, fondo `superficie`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.unaRiga = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  /// Etichetta sempre su una riga: padding ridotto e testo che si
  /// rimpicciolisce (mai spezzato a meta' parola) se lo spazio non basta.
  /// Per pulsanti affiancati in righe strette.
  final bool unaRiga;

  @override
  Widget build(BuildContext context) {
    final Widget testo = unaRiga
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, softWrap: false),
          )
        : Text(label);
    final style = unaRiga
        ? OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          )
        : null;
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: testo)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: testo,
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
