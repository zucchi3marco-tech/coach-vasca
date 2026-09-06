import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../allenamenti/application/allenamenti_per_microciclo_provider.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../export/csv_export.dart' show AllenamentoConSerie;
import '../../export/export_actions.dart';
import '../data/duplicazione_settimana_service.dart';
import '../domain/microciclo.dart';
import 'microciclo_form_screen.dart';

class MicrocicloDetailScreen extends ConsumerWidget {
  const MicrocicloDetailScreen({required this.microciclo, super.key});

  final Microciclo microciclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String get _titolo {
    if (microciclo.nome != null && microciclo.nome!.isNotEmpty) {
      return microciclo.nome!;
    }
    if (microciclo.numeroSettimana != null) {
      return 'Settimana ${microciclo.numeroSettimana}';
    }
    return 'Microciclo';
  }

  Future<void> _duplicaSettimana(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplica settimana'),
        content: const Text(
          'Verrà creata una nuova settimana subito dopo questa, con tutti '
          'gli allenamenti e le serie copiati. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Duplica'),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    try {
      final nuovoMicrociclo = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .duplica(microciclo);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MicrocicloDetailScreen(microciclo: nuovoMicrociclo),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Errore nella duplicazione: ${messaggioErrore(e)}'),
        ),
      );
    }
  }

  Future<void> _esportaSettimana(BuildContext context, WidgetRef ref) async {
    final filter = (clubId: microciclo.clubId, microcicloId: microciclo.id);
    await mostraMenuExport(
      context,
      titoloDocumento: _titolo,
      caricaDati: () async {
        final allenamenti =
            ref.read(allenamentiPerMicrocicloProvider(filter)).value ?? [];
        final serieRepository = ref.read(serieRepositoryProvider);
        final elenco = <AllenamentoConSerie>[];
        for (final a in allenamenti) {
          elenco.add((a, await serieRepository.fetchPerAllenamento(a.id)));
        }
        return elenco;
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (clubId: microciclo.clubId, microcicloId: microciclo.id);
    final allenamentiAsync = ref.watch(
      allenamentiPerMicrocicloProvider(filter),
    );

    return AppScaffold(
      appBar: AppBar(
        title: Text(_titolo),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) => azione(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => _duplicaSettimana(context, ref),
                child: const _VoceMenu(
                  icona: Icons.content_copy_outlined,
                  etichetta: 'Duplica settimana',
                ),
              ),
              PopupMenuItem(
                value: () => _esportaSettimana(context, ref),
                child: const _VoceMenu(
                  icona: Icons.ios_share,
                  etichetta: 'Esporta settimana',
                ),
              ),
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MicrocicloFormScreen(
                      mesocicloId: microciclo.mesocicloId,
                      ordineSuccessivo: microciclo.ordine,
                      microciclo: microciclo,
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
            child: Text(
              '${_formattaData(microciclo.dataInizio)} — '
              '${_formattaData(microciclo.dataFine)}'
              '${microciclo.tipo != null && microciclo.tipo!.isNotEmpty ? ' · ${microciclo.tipo}' : ''}',
              style: AppTypography.sezione,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: allenamentiAsync.when(
              data: (allenamenti) => allenamenti.isEmpty
                  ? EmptyState(
                      icona: Icons.calendar_month_outlined,
                      titolo: 'Nessun allenamento in questa settimana',
                      descrizione:
                          'Crea il primo allenamento a mano oppure genera '
                          'una proposta con l\'AI.',
                      azionePrincipale: 'Nuovo allenamento',
                      onAzionePrincipale: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllenamentoFormScreen(
                            clubId: microciclo.clubId,
                            microcicloId: microciclo.id,
                            dataPredefinita: microciclo.dataInizio,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: AppListPanel(
                        righe: [
                          for (final a in allenamenti)
                            AppListRow(
                              titolo: a.titolo != null && a.titolo!.isNotEmpty
                                  ? a.titolo!
                                  : 'Allenamento',
                              sottotitolo:
                                  '${_formattaData(a.data)}'
                                  '${a.gruppo != null && a.gruppo!.isNotEmpty ? ' · ${a.gruppo}' : ''}',
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AllenamentoDetailScreen(allenamento: a),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 4),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare gli '
                      'allenamenti.',
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab-genera-ai-microciclo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GeneraAllenamentoFormScreen(
                  clubId: microciclo.clubId,
                  microcicloId: microciclo.id,
                  dataPredefinita: microciclo.dataInizio,
                ),
              ),
            ),
            tooltip: 'Genera con AI',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: AppSpacing.s12),
          FloatingActionButton(
            heroTag: 'fab-allenamenti-microciclo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AllenamentoFormScreen(
                  clubId: microciclo.clubId,
                  microcicloId: microciclo.id,
                  dataPredefinita: microciclo.dataInizio,
                ),
              ),
            ),
            tooltip: 'Nuovo allenamento',
            child: const Icon(Icons.add),
          ),
        ],
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
