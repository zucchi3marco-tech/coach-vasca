import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../application/libreria_blocchi_providers.dart';
import '../domain/training_block.dart';
import 'blocco_form_screen.dart';

String _labelVolume(TrainingBlockParte p) {
  final durata = p.durataS;
  final testo = durata != null ? formatDurataS(durata) : '${p.distanzaM}m';
  return p.giri > 1
      ? '${p.giri}× ${p.ripetizioni}×$testo'
      : '${p.ripetizioni}×$testo';
}

class BloccoDetailScreen extends ConsumerWidget {
  const BloccoDetailScreen({required this.blocco, super.key});

  final TrainingBlock blocco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiAsync = ref.watch(trainingBlockPartiProvider(blocco.id));
    final colori = context.colori;

    return AppScaffold(
      appBar: AppBar(
        title: Text(blocco.titolo),
        actions: [
          IconButton(
            tooltip: 'Modifica',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    BloccoFormScreen(clubId: blocco.clubId, blocco: blocco),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s12,
            children: [
              Text(
                'Codice ${blocco.codice}',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              Text(
                blocco.fase,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              Text(
                blocco.obiettivo,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              if (blocco.metriTotali > 0)
                Text(
                  '${blocco.metriTotali} m',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              if (blocco.durataStimataMin > 0)
                Text(
                  '~${blocco.durataStimataMin} min',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
            ],
          ),
          if (blocco.note != null && blocco.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              blocco.note!,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: partiAsync.when(
              data: (parti) => parti.isEmpty
                  ? const EmptyState(
                      icona: Icons.list_alt_outlined,
                      titolo: 'Nessuna parte',
                      descrizione: 'Questo blocco non ha ancora serie: modificalo per aggiungerne, o re-importa il file Excel.',
                      azionePrincipale: 'Ho capito',
                    )
                  : SingleChildScrollView(
                      child: AppListPanel(
                        righe: [
                          for (final p in parti)
                            AppListRow(
                              titolo: _labelVolume(p),
                              sottotitolo: [
                                p.zona,
                                if (p.stile != null) p.stile!,
                                if (p.esercizio != null) p.esercizio!,
                                p.esecuzione,
                                if (p.recuperoS != null) "rec ${p.recuperoS}''",
                              ].join(' · '),
                            ),
                        ],
                      ),
                    ),
              loading: () => const LoadingSkeletonList(righe: 4),
              error: (error, _) => ErrorBanner(
                messaggio: 'Non è stato possibile caricare le parti.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
