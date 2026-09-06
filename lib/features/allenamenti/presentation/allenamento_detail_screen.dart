import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/domain_tokens.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/zone_chip.dart';
import '../../export/export_actions.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import 'allenamento_form_screen.dart';
import 'scheda_bordo_vasca_screen.dart';
import 'serie_form_screen.dart';
import 'serie_labels.dart';
import 'sposta_allenamento_screen.dart';

class AllenamentoDetailScreen extends ConsumerWidget {
  const AllenamentoDetailScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serieAsync = ref.watch(serieListProvider(allenamento.id));

    void apriNuovaSerie() {
      final serieAttuale =
          ref.read(serieListProvider(allenamento.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SerieFormScreen(
            allenamentoId: allenamento.id,
            ordineSuccessivo: serieAttuale.length + 1,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          allenamento.titolo != null && allenamento.titolo!.isNotEmpty
              ? allenamento.titolo!
              : 'Allenamento',
        ),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) => azione(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SchedaBordoVascaScreen(allenamento: allenamento),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.pool,
                  etichetta: 'Vista bordo vasca',
                ),
              ),
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PresenzeScreen(allenamento: allenamento),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.how_to_reg_outlined,
                  etichetta: 'Presenze',
                ),
              ),
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SpostaAllenamentoScreen(allenamento: allenamento),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.drive_file_move_outline,
                  etichetta: 'Sposta',
                ),
              ),
              PopupMenuItem(
                value: () => mostraMenuExport(
                  context,
                  titoloDocumento:
                      allenamento.titolo != null &&
                          allenamento.titolo!.isNotEmpty
                      ? allenamento.titolo!
                      : 'Allenamento',
                  caricaDati: () async => [
                    (
                      allenamento,
                      await ref
                          .read(serieRepositoryProvider)
                          .fetchPerAllenamento(allenamento.id),
                    ),
                  ],
                ),
                child: const _VoceMenu(
                  icona: Icons.ios_share,
                  etichetta: 'Esporta',
                ),
              ),
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllenamentoFormScreen(
                      clubId: allenamento.clubId,
                      allenamento: allenamento,
                    ),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.edit_outlined,
                  etichetta: 'Modifica',
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${allenamento.data.day.toString().padLeft(2, '0')}/'
                  '${allenamento.data.month.toString().padLeft(2, '0')}/'
                  '${allenamento.data.year}'
                  '${allenamento.gruppo != null && allenamento.gruppo!.isNotEmpty ? ' · ${allenamento.gruppo}' : ''}',
                  style: AppTypography.sezione,
                ),
                if (allenamento.note != null &&
                    allenamento.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(allenamento.note!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: serieAsync.when(
              data: (serie) {
                if (serie.isEmpty) {
                  return EmptyState(
                    icona: Icons.pool_outlined,
                    titolo: 'Nessuna serie',
                    descrizione:
                        'Aggiungi la prima serie per costruire questo '
                        'allenamento.',
                    azionePrincipale: 'Nuova serie',
                    onAzionePrincipale: apriNuovaSerie,
                  );
                }
                // Riepilogo, non un campo a se': l'attrezzatura resta
                // scritta sulla singola serie (vedi SerieFormScreen), qui
                // si mostra solo l'elenco senza doppioni di quanto già
                // compilato, per prepararsi prima di andare in vasca.
                final materiale =
                    {
                      for (final s in serie)
                        if (s.attrezzatura != null &&
                            s.attrezzatura!.trim().isNotEmpty)
                          s.attrezzatura!.trim(),
                    }.toList()
                      ..sort();
                return Column(
                  children: [
                    if (materiale.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          AppSpacing.s16,
                          AppSpacing.s16,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Materiale utilizzato',
                              style: AppTypography.etichetta,
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: [
                                for (final m in materiale)
                                  Chip(label: Text(m)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        itemCount: serie.length,
                        itemBuilder: (context, index) {
                        final s = serie[index];
                        final tokens =
                            Theme.of(context).extension<DomainTokens>() ??
                            DomainTokens.standard;
                        final coloreZona = s.zona != null
                            ? tokens.colorePerZona(s.zona)
                            : AppColors.linea;
                        final meta = <String>[];
                        if (s.passoObiettivoS != null) {
                          meta.add(
                            '${formatPaceSeconds(s.passoObiettivoS!)}/100m',
                          );
                        }
                        if (s.recuperoS != null) {
                          meta.add("rec ${s.recuperoS}''");
                        }
                        if (s.ripartenzaS != null) {
                          meta.add(
                            'rip ${formatPaceSeconds(s.ripartenzaS!)}',
                          );
                        }
                        if (s.attrezzatura != null &&
                            s.attrezzatura!.isNotEmpty) {
                          meta.add(s.attrezzatura!);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s12,
                          ),
                          child: LaneRule(
                            colore: coloreZona,
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SerieFormScreen(
                                    allenamentoId: allenamento.id,
                                    ordineSuccessivo: serie.length + 1,
                                    serie: s,
                                  ),
                                ),
                              ),
                              child: PoolCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: AppColors.bluTenue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${s.ordine}',
                                            style: AppTypography.piccolo
                                                .copyWith(
                                                  color: AppColors.blu,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.s12,
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${s.ripetute}×${s.distanzaM}m '
                                            '${labelStile(s.stile)} '
                                            '${labelEsecuzione(s.esecuzione)}',
                                            style: AppTypography.corpoForte
                                                .copyWith(
                                                  color: AppColors.testo,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.s8),
                                    Row(
                                      children: [
                                        Text(
                                          labelBlocco(s.blocco),
                                          style: AppTypography.etichetta,
                                        ),
                                        if (s.zona != null) ...[
                                          const SizedBox(
                                            width: AppSpacing.s8,
                                          ),
                                          ZoneChip(sigla: s.zona!),
                                        ],
                                      ],
                                    ),
                                    if (meta.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.s8),
                                      Wrap(
                                        spacing: AppSpacing.s16,
                                        runSpacing: AppSpacing.s4,
                                        children: [
                                          for (final m in meta)
                                            Text(
                                              m,
                                              style: AppTypography.piccolo,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 5),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare le serie.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-serie',
        onPressed: apriNuovaSerie,
        tooltip: 'Nuova serie',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VoceMenu extends StatelessWidget {
  const _VoceMenu({required this.icona, required this.etichetta});

  final IconData icona;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icona, size: 20, color: AppColors.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(etichetta, style: AppTypography.corpo),
      ],
    );
  }
}
