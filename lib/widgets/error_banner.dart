import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Fascia di errore — vedi DESIGN.md sezione 13, "Errori". Non deve mai
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
    final colori = context.colori;
    return Container(
      decoration: BoxDecoration(
        color: colori.rossoTenue,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border(left: BorderSide(color: colori.rosso, width: 3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colori.rosso, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.messaggio,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    if (widget.suggerimento != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.suggerimento!,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
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
                  color: colori.azione,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_mostraDettagli) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.dettaglioTecnico!,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
