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
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../application/libreria_blocchi_providers.dart';
import '../domain/training_block.dart';
import 'blocco_form_screen.dart';
import 'parte_form_screen.dart';

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
    final parti = partiAsync.value ?? const <TrainingBlockParte>[];

    void apriParte({TrainingBlockParte? parte}) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParteFormScreen(
          bloccoId: blocco.id,
          clubId: blocco.clubId,
          parte: parte,
          ordineSuccessivo: parti.length + 1,
        ),
      ),
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Blocco'),
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
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: [
              blocco.stato == 'approvato'
                  ? blocco.codice
                  : '${blocco.codice} (bozza)',
              if (blocco.fase.trim().isNotEmpty) blocco.fase.trim(),
            ].join(' · '),
            titolo: blocco.titolo,
            sottotitolo: blocco.obiettivo.trim().isEmpty
                ? null
                : blocco.obiettivo,
            numeri: [
              if (blocco.metriTotali > 0)
                NumeroTestata(
                  valore: '${blocco.metriTotali}',
                  etichetta: 'Metri',
                ),
              if (blocco.durataStimataMin > 0)
                NumeroTestata(
                  valore: '~${blocco.durataStimataMin}',
                  etichetta: 'Minuti',
                ),
              NumeroTestata(valore: '${parti.length}', etichetta: 'Parti'),
            ],
            azioni: [
              AzioneTestata(
                icona: Icons.add,
                etichetta: 'Aggiungi parte',
                principale: true,
                onTap: apriParte,
              ),
            ],
          ),
          if (blocco.note != null && blocco.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            PoolCard(
              child: Text(
                blocco.note!,
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          partiAsync.when(
            data: (parti) => parti.isEmpty
                ? EmptyState(
                    icona: Icons.list_alt_outlined,
                    titolo: 'Nessuna parte',
                    descrizione:
                        'Questo blocco non ha ancora serie: aggiungine una, '
                        'o re-importa il file Excel.',
                    azionePrincipale: 'Aggiungi parte',
                    onAzionePrincipale: apriParte,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TitoloSezione('Parti', conteggio: parti.length),
                      AppListPanel(
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
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => apriParte(parte: p),
                            ),
                        ],
                      ),
                    ],
                  ),
            loading: () => const LoadingSkeletonList(righe: 4),
            error: (error, _) => ErrorBanner(
              messaggio: 'Non è stato possibile caricare le parti.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ],
      ),
    );
  }
}
