import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Un valore statistico — vedi DESIGN.md sezione 13, "Pannelli
/// statistica": etichetta sopra, valore `numeroGrande` con cifre
/// tabulari, unità/confronto sotto. Per affiancarne più di uno, mettili
/// in una Row/Wrap (massimo quattro, poi vanno a capo).
class StatPanel extends StatelessWidget {
  const StatPanel({
    required this.etichetta,
    required this.valore,
    this.confronto,
    super.key,
  });

  final String etichetta;
  final String valore;
  final String? confronto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etichetta,
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          valore,
          style: AppTypography.numerica(
            AppTypography.numeroGrande.copyWith(color: colori.testo),
          ),
        ),
        if (confronto != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            confronto!,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ],
    );
  }
}

/// Più [StatPanel] in schede di pari larghezza, nello stile "Oggi": due
/// per riga su telefono, fino a quattro su schermo largo, righe alte
/// quanto la scheda più alta.
class GrigliaNumeri extends StatelessWidget {
  const GrigliaNumeri({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return LayoutBuilder(
      builder: (context, vincoli) {
        const spazio = AppSpacing.spazioPannelli;
        final massimo = children.length.clamp(1, 4);
        final colonne = vincoli.maxWidth < 480 ? massimo.clamp(1, 2) : massimo;
        Widget scheda(Widget figlio) => Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: figlio,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < children.length; r += colonne) ...[
              if (r > 0) const SizedBox(height: spazio),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < colonne; c++) ...[
                      if (c > 0) const SizedBox(width: spazio),
                      Expanded(
                        child: r + c < children.length
                            ? scheda(children[r + c])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
