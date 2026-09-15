import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../atleti/domain/atleta.dart';
import '../application/stagioni_providers.dart';
import '../domain/stagione.dart';

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}/'
    '${data.year}';

/// Stagione in corso del gruppo dell'atleta (FASE 13, punto 3): sola
/// lettura, nessuna delle azioni di gestione della schermata del coach
/// (nome/periodo/obiettivo/campionato).
class StagioneAtletaScreen extends ConsumerWidget {
  const StagioneAtletaScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(atleta.clubId));

    return AppScaffold(
      appBar: AppBar(title: const Text('La mia stagione')),
      body: stagioniAsync.when(
        data: (stagioni) {
          final corrente = stagioneCorrenteDiGruppo(stagioni, atleta.gruppoId);
          if (corrente == null) {
            return const EmptyState(
              icona: Icons.event_note_outlined,
              titolo: 'Nessuna stagione in corso',
              descrizione: 'Non risulta una stagione attiva oggi.',
              azionePrincipale: 'Torna indietro',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(corrente.nome, style: AppTypography.titoloXl),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '${_formattaData(corrente.dataInizio)} - '
                  '${_formattaData(corrente.dataFine)}',
                  style: AppTypography.piccolo,
                ),
                if (corrente.campionato != null) ...[
                  const SizedBox(height: AppSpacing.s24),
                  Text('Campionato', style: AppTypography.etichetta),
                  const SizedBox(height: AppSpacing.s4),
                  Text(corrente.campionato!, style: AppTypography.corpo),
                ],
                if (corrente.obiettivo != null) ...[
                  const SizedBox(height: AppSpacing.s24),
                  Text('Obiettivo', style: AppTypography.etichetta),
                  const SizedBox(height: AppSpacing.s4),
                  Text(corrente.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare la stagione.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}
