import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';
import 'premibile.dart';
import 'riquadri.dart';

/// Un riquadro della griglia "Cosa vuoi fare?".
class AzioneRapida {
  const AzioneRapida({
    required this.icona,
    required this.titolo,
    required this.sottotitolo,
    required this.colore,
    required this.onTap,
    this.evidenziata = false,
  });

  final IconData icona;
  final String titolo;
  final String sottotitolo;
  final Color colore;
  final VoidCallback onTap;

  /// Le azioni del momento (presenze, partita dal vivo): piu' in vista.
  final bool evidenziata;
}

/// La griglia di azioni della schermata "Oggi": 2 colonne su telefono,
/// 3 su tablet, 4 su schermo largo.
class GrigliaAzioni extends StatelessWidget {
  const GrigliaAzioni({required this.azioni, super.key});

  final List<AzioneRapida> azioni;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final colonne = w < 520 ? 2 : (w < 900 ? 3 : 4);
        const spazio = AppSpacing.spazioPannelli;
        final larghezza = (w - spazio * (colonne - 1)) / colonne;
        return Wrap(
          spacing: spazio,
          runSpacing: spazio,
          children: [
            for (final a in azioni)
              SizedBox(
                width: larghezza,
                child: Premibile(
                  onTap: a.onTap,
                  etichetta: '${a.titolo}. ${a.sottotitolo}',
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 112),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pannello),
                      color: a.evidenziata ? null : colori.superficie,
                      gradient: a.evidenziata
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                a.colore.withValues(alpha: 0.32),
                                a.colore.withValues(alpha: 0.1),
                              ],
                            )
                          : null,
                      border: Border.all(
                        color: a.evidenziata
                            ? a.colore.withValues(alpha: 0.6)
                            : colori.linea,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconaRiquadro(a.icona, colore: a.colore),
                        const SizedBox(height: 10),
                        Text(
                          a.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.sottotitolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.etichetta.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
