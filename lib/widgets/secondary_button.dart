import 'package:flutter/material.dart';

/// Pulsante secondario — vedi DESIGN.md sezione 8: bordo 1px linea,
/// testo `testo`, fondo `superficie`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
