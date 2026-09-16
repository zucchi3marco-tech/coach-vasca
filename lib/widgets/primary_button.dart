import 'package:flutter/material.dart';

import '../theme/colori_app.dart';

/// Pulsante principale — vedi DESIGN.md sezione 13. Uno solo per
/// schermata. L'etichetta dice cosa succede ("Salva atleta"), non
/// "Invia".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    // L'inchiostro sopra `azione` si inverte fra i due temi (DESIGN.md
    // sezione 5): bianco nel chiaro (fondo blu scuro), scuro nello
    // scuro (fondo azzurro chiaro) — un colore fisso sarebbe illeggibile
    // in uno dei due.
    final azioneInk = context.colori.azioneInk;
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: azioneInk),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
