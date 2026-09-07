import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/superfici_tema.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Schermata/sezione vuota — vedi DESIGN.md sezione 8, "Schermate
/// vuote". Regola non negoziabile: mai una riga di testo grigio da sola.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    required this.azionePrincipale,
    this.onAzionePrincipale,
    this.azioneSecondaria,
    this.onAzioneSecondaria,
    super.key,
  });

  final IconData icona;
  final String titolo;
  final String descrizione;
  final String azionePrincipale;
  final VoidCallback? onAzionePrincipale;
  final String? azioneSecondaria;
  final VoidCallback? onAzioneSecondaria;

  @override
  Widget build(BuildContext context) {
    final tema = SuperficiTema.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icona, size: 48, color: tema.testoTenue),
            const SizedBox(height: AppSpacing.s16),
            Text(
              titolo,
              style: AppTypography.sezione.copyWith(color: tema.testo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              descrizione,
              style: AppTypography.piccolo.copyWith(
                color: tema.testoSecondario,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s20),
            PrimaryButton(
              label: azionePrincipale,
              onPressed: onAzionePrincipale,
              expanded: false,
            ),
            if (azioneSecondaria != null) ...[
              const SizedBox(height: AppSpacing.s12),
              SecondaryButton(
                label: azioneSecondaria!,
                onPressed: onAzioneSecondaria,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
