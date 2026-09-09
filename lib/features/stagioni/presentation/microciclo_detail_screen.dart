import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/breadcrumb_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../ai_genera/presentation/genera_settimana_form_screen.dart';
import '../../allenamenti/application/allenamenti_per_microciclo_provider.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../export/csv_export.dart' show AllenamentoConSerie;
import '../../export/export_actions.dart';
import '../application/microcicli_providers.dart';
import '../data/duplicazione_settimana_service.dart';
import '../data/microcicli_repository.dart';
import '../domain/microciclo.dart';
import 'elimina_dialogs.dart';
import 'microciclo_form_screen.dart';

class MicrocicloDetailScreen extends ConsumerWidget {
  const MicrocicloDetailScreen({
    required this.microciclo,
    required this.nomeStagione,
    required this.nomeMacrociclo,
    required this.nomeMesociclo,
    super.key,
  });

  final Microciclo microciclo;

  /// Solo per la breadcrumb — vedi `MacrocicloDetailScreen.nomeStagione`.
  final String nomeStagione;
  final String nomeMacrociclo;
  final String nomeMesociclo;

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
          builder: (_) => MicrocicloDetailScreen(
            microciclo: nuovoMicrociclo,
            nomeStagione: nomeStagione,
            nomeMacrociclo: nomeMacrociclo,
            nomeMesociclo: nomeMesociclo,
          ),
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

  Future<void> _elimina(BuildContext context, WidgetRef ref) async {
    final allenamenti =
        ref.read(
          allenamentiPerMicrocicloProvider((
            clubId: microciclo.clubId,
            microcicloId: microciclo.id,
          )),
        ).value ??
        const [];
    final conferma = await confermaEliminaMicrociclo(
      context,
      allenamenti.length,
    );
    if (conferma) {
      await ref
          .read(microcicliRepositoryProvider)
          .deleteMicrociclo(microciclo.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (clubId: microciclo.clubId, microcicloId: microciclo.id);
    final allenamentiAsync = ref.watch(
      allenamentiPerMicrocicloProvider(filter),
    );
    final fratelli =
        ref.watch(microcicliListProvider(microciclo.mesocicloId)).value ?? [];
    final indiceAttuale = fratelli.indexWhere((m) => m.id == microciclo.id);
    final precedente = indiceAttuale > 0
        ? fratelli[indiceAttuale - 1]
        : null;
    final successivo =
        indiceAttuale >= 0 && indiceAttuale < fratelli.length - 1
        ? fratelli[indiceAttuale + 1]
        : null;

    void vaiAlFratello(Microciclo m) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MicrocicloDetailScreen(
            microciclo: m,
            nomeStagione: nomeStagione,
            nomeMacrociclo: nomeMacrociclo,
            nomeMesociclo: nomeMesociclo,
          ),
        ),
      );
    }

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
              PopupMenuItem(
                value: () => _elimina(context, ref),
                child: const _VoceMenu(
                  icona: Icons.delete_outline,
                  etichetta: 'Elimina',
                  colore: AppColors.rosso,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbBar(
            tappe: [nomeStagione, nomeMacrociclo, nomeMesociclo, _titolo],
            trailing: Row(
              children: [
                IconButton(
                  onPressed: precedente == null
                      ? null
                      : () => vaiAlFratello(precedente),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Settimana precedente',
                ),
                IconButton(
                  onPressed: successivo == null
                      ? null
                      : () => vaiAlFratello(successivo),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Settimana successiva',
                ),
              ],
            ),
          ),
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
                  messaggio:
                      'Non è stato possibile caricare gli '
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
            heroTag: 'fab-genera-settimana-microciclo',
            mini: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    GeneraSettimanaFormScreen(microciclo: microciclo),
              ),
            ),
            tooltip: 'Genera settimana con AI',
            child: const Icon(Icons.view_week_outlined),
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
  const _VoceMenu({required this.icona, required this.etichetta, this.colore});

  final IconData icona;
  final String etichetta;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final effettivo = colore ?? AppColors.testoSecondario;
    return Row(
      children: [
        Icon(icona, size: 20, color: effettivo),
        const SizedBox(width: AppSpacing.s12),
        Text(etichetta, style: AppTypography.corpo.copyWith(color: colore)),
      ],
    );
  }
}
