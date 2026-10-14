import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/esercizio_secco.dart';
import 'video_esercizio.dart';

/// Il foglio "come si fa" di un esercizio per l'atleta: nome, quanto
/// farne, attrezzo, come si fa e, se c'è, il video. Senza le note
/// dell'allenatore. Con il [massimale] dell'atleta un carico «70%»
/// diventa i suoi chili.
Future<void> mostraComeSiFa(
  BuildContext context,
  EsercizioSedutaAtleta e, {
  double? massimale,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final colori = sheetContext.colori;
    final descrizione = e.esercizio.descrizione;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.esercizio.nome,
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              prescrizioneEsercizio(e.riga, massimale: massimale),
              style: AppTypography.numerica(AppTypography.corpoForte)
                  .copyWith(color: colori.testo),
            ),
            if (e.esercizio.attrezzo case final a?
                when a.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                a,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            Text(
              descrizione == null || descrizione.trim().isEmpty
                  ? e.esercizio.videoYoutube == null
                        ? 'Per come si fa, chiedi all\'allenatore.'
                        : 'Come si fa: guarda il video.'
                  : descrizione,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
            if (e.esercizio.videoYoutube case final video?) ...[
              const SizedBox(height: AppSpacing.s16),
              VideoEsercizio(videoId: video, inizio: e.esercizio.videoDaS),
            ],
          ],
        ),
      ),
    );
  },
);
