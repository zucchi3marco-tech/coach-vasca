import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Riga di navigazione rapida per la gerarchia Stagione › Macrociclo ›
/// Mesociclo › Microciclo: mostra le tappe dalla radice al livello attuale
/// (l'ultima, in grassetto, non è cliccabile) e permette di risalire di più
/// livelli in un colpo, invece di tornare indietro schermata per schermata.
/// Non introduce route nuove: ogni tappa fa solo dei `pop` sullo stack già
/// esistente. Vedi DESIGN.md, "Widget riutilizzabili".
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({required this.tappe, this.trailing, super.key});

  /// Le etichette dalla radice (es. la stagione) al livello attuale.
  final List<String> tappe;

  /// Contenuto opzionale allineato a destra della riga (es. i pulsanti per
  /// passare al fratello precedente/successivo).
  final Widget? trailing;

  void _vaiA(BuildContext context, int indice) {
    var daSaltare = tappe.length - 1 - indice;
    if (daSaltare <= 0) return;
    Navigator.of(context).popUntil((route) {
      if (daSaltare <= 0) return true;
      daSaltare--;
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.superficie,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < tappe.length; i++) ...[
                    if (i != 0) ...[
                      const SizedBox(width: AppSpacing.s4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.testoSecondario,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                    ],
                    InkWell(
                      onTap: i == tappe.length - 1
                          ? null
                          : () => _vaiA(context, i),
                      child: Text(
                        tappe[i],
                        style: i == tappe.length - 1
                            ? AppTypography.piccolo.copyWith(
                                color: AppColors.testo,
                                fontWeight: FontWeight.w600,
                              )
                            : AppTypography.piccolo.copyWith(
                                color: AppColors.testoSecondario,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
