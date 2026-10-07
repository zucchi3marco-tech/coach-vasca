import 'package:flutter/material.dart';

import '../features/home/atleta/grafica_pallanuoto.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'premibile.dart';

/// Un'azione della testata: un pulsante a pillola sempre in vista (al
/// posto delle azioni nascoste dietro il "+").
class AzioneTestata {
  const AzioneTestata({
    required this.icona,
    required this.etichetta,
    required this.onTap,
    this.principale = false,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback onTap;

  /// La prima cosa da fare in questa pagina: pulsante pieno.
  final bool principale;
}

/// Un numero della fascia in basso della testata (come in "Oggi").
class NumeroTestata {
  const NumeroTestata({
    required this.valore,
    required this.etichetta,
    this.onTap,
  });

  final String valore;
  final String etichetta;
  final VoidCallback? onTap;
}

/// Testata delle schermate principali, nello stesso linguaggio della
/// testata di "Oggi" ma piu' bassa: acqua animata, titolo bianco, una
/// riga di contesto, i numeri che contano e le azioni della pagina.
class TestataPagina extends StatelessWidget {
  const TestataPagina({
    required this.titolo,
    this.occhiello,
    this.sottotitolo,
    this.numeri = const [],
    this.azioni = const [],
    super.key,
  });

  final String titolo;

  /// Riga piccola sopra il titolo (es. il nome della squadra).
  final String? occhiello;
  final String? sottotitolo;
  final List<NumeroTestata> numeri;
  final List<AzioneTestata> azioni;

  @override
  Widget build(BuildContext context) {
    final stretto = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sheet),
      child: Stack(
        children: [
          const Positioned.fill(
            child: AcquaAnimata(conCorsia: false, conPorta: false),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AcquaPalette.profonda.withValues(alpha: 0.92),
                    AcquaPalette.profonda.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(stretto ? 18 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (occhiello != null) ...[
                  Text(
                    occhiello!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.piccolo.copyWith(
                      color: AcquaPalette.schiuma.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  titolo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titoloXl.copyWith(
                    color: AcquaPalette.bianco,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (sottotitolo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sottotitolo!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.corpo.copyWith(
                      color: AcquaPalette.schiuma.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (numeri.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _FasciaNumeri(numeri: numeri),
                ],
                if (azioni.isNotEmpty) ...[
                  SizedBox(height: numeri.isEmpty ? 16 : 12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [for (final a in azioni) _PillolaAzione(a)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FasciaNumeri extends StatelessWidget {
  const _FasciaNumeri({required this.numeri});

  final List<NumeroTestata> numeri;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AcquaPalette.bianco.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AcquaPalette.bianco.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          for (final n in numeri)
            Expanded(
              child: Premibile(
                raggio: 16,
                onTap: n.onTap,
                etichetta: '${n.etichetta}: ${n.valore}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          n.valore,
                          maxLines: 1,
                          style: AppTypography.numerica(
                            AppTypography.numeroMedio.copyWith(
                              color: AcquaPalette.bianco,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          n.etichetta,
                          maxLines: 1,
                          style: AppTypography.etichetta.copyWith(
                            color: AcquaPalette.schiuma.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillolaAzione extends StatelessWidget {
  const _PillolaAzione(this.azione);

  final AzioneTestata azione;

  @override
  Widget build(BuildContext context) {
    final principale = azione.principale;
    final testo = principale ? AcquaPalette.profonda : AcquaPalette.bianco;
    return Premibile(
      onTap: azione.onTap,
      raggio: 99,
      etichetta: azione.etichetta,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: principale
              ? AcquaPalette.turchese
              : AcquaPalette.bianco.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: principale
              ? null
              : Border.all(color: AcquaPalette.bianco.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(azione.icona, size: 18, color: testo),
            const SizedBox(width: 8),
            Text(
              azione.etichetta,
              style: AppTypography.etichetta.copyWith(
                color: testo,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
