import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/superfici_tema.dart';

/// Fascia di errore — vedi DESIGN.md sezione 8, "Errori". Non deve mai
/// comparire un errore tecnico grezzo nell'interfaccia: [messaggio] è il
/// testo in linguaggio umano (da `messaggioErrore`), [dettaglioTecnico]
/// resta chiuso dietro "Mostra dettagli", solo per segnalare un problema.
class ErrorBanner extends StatefulWidget {
  const ErrorBanner({
    required this.messaggio,
    this.suggerimento,
    this.dettaglioTecnico,
    super.key,
  });

  final String messaggio;
  final String? suggerimento;
  final String? dettaglioTecnico;

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner> {
  bool _mostraDettagli = false;

  @override
  Widget build(BuildContext context) {
    final tema = SuperficiTema.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.rossoTenue,
        borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
        border: const Border(
          left: BorderSide(color: AppColors.rosso, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.rosso, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.messaggio,
                      style: AppTypography.corpoForte.copyWith(
                        color: tema.testo,
                      ),
                    ),
                    if (widget.suggerimento != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.suggerimento!,
                        style: AppTypography.piccolo.copyWith(
                          color: tema.testoSecondario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (widget.dettaglioTecnico != null) ...[
            const SizedBox(height: AppSpacing.s8),
            InkWell(
              onTap: () => setState(() => _mostraDettagli = !_mostraDettagli),
              child: Text(
                _mostraDettagli ? 'Nascondi dettagli' : 'Mostra dettagli',
                style: AppTypography.piccolo.copyWith(
                  color: AppColors.blu,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_mostraDettagli) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.dettaglioTecnico!,
                style: AppTypography.piccolo.copyWith(
                  color: tema.testoSecondario,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
