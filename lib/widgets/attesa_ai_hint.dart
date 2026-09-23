import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Testo mostrato sotto il pulsante mentre si aspetta una risposta dal
/// servizio AI (genera allenamento/settimana, dettatura): può richiedere
/// fino a decine di secondi (osservato fino a ~40s con il modello
/// sovraccarico), così l'attesa non sembra un blocco dell'app.
class AttesaAiHint extends StatelessWidget {
  const AttesaAiHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Text(
        'Può richiedere fino a 30-40 secondi.',
        textAlign: TextAlign.center,
        style: AppTypography.piccolo.copyWith(
          color: context.colori.testoSecondario,
        ),
      ),
    );
  }
}
