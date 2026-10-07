import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/premibile.dart';

/// Una casella del "tabellone dei tempi" (personal best, record del
/// club): la distanza piccola sopra, il tempo grande, una riga sotto.
/// Senza tempo il valore e' un trattino tenue: si vede subito cosa manca.
class SchedaTempo extends StatelessWidget {
  const SchedaTempo({
    required this.distanza,
    required this.tempo,
    this.sotto,
    this.onTap,
    super.key,
  });

  final String distanza;

  /// null = nessun tempo registrato.
  final String? tempo;
  final String? sotto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Premibile(
      onTap: onTap,
      etichetta: '$distanza: ${tempo ?? 'nessun tempo'}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              distanza,
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                tempo ?? '—',
                maxLines: 1,
                style: AppTypography.numerica(
                  AppTypography.numeroMedio.copyWith(
                    color: tempo == null ? colori.testoTenue : colori.testo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (sotto != null) ...[
              const SizedBox(height: 2),
              Text(
                sotto!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.piccolo.copyWith(
                  color: tempo == null ? colori.azione : colori.testoSecondario,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
