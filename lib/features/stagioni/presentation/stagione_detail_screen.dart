import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../atleti/presentation/record_club_screen.dart';
import '../../club/application/current_club_provider.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../statistiche/presentation/statistiche_squadra_screen.dart';
import '../data/duplicazione_stagione_service.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';
import 'elimina_dialogs.dart';
import 'stagione_form_screen.dart';

enum _AzioneStagione { duplica, modifica, elimina }

/// Scheda di una stagione: solo intestazione (periodo, gruppo, campionato,
/// obiettivo) e, al posto della programmazione a settimane eliminata in
/// FASE 11, un collegamento alle statistiche di stagione (pallanuoto) o ai
/// record di club (nuoto), secondo lo sport del club.
class StagioneDetailScreen extends ConsumerWidget {
  const StagioneDetailScreen({required this.stagione, super.key});

  final Stagione stagione;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Future<void> _elimina(BuildContext context, WidgetRef ref) async {
    final conferma = await confermaEliminaStagione(context);
    if (conferma && context.mounted) {
      await ref.read(stagioniRepositoryProvider).deleteStagione(stagione.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _duplicaStagione(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final nuovaDataInizio = await showDatePicker(
      context: context,
      initialDate: stagione.dataInizio,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Data di inizio della nuova stagione',
    );
    if (nuovaDataInizio == null) return;
    try {
      final nuovaStagione = await ref
          .read(duplicazioneStagioneServiceProvider)
          .duplica(stagione, nuovaDataInizio);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StagioneDetailScreen(stagione: nuovaStagione),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nomeGruppo = {
      for (final g
          in ref.watch(gruppiListProvider(stagione.clubId)).value ?? [])
        g.id: g.nome,
    }[stagione.gruppoId];
    // null finche' il club non ha ancora compilato lo sport (o durante il
    // caricamento): in quel caso si mostrano entrambe le sezioni, non si
    // nasconde contenuto per un dato mancante.
    final sport = ref.watch(currentClubProvider).value?.sport;
    final mostraPallanuoto =
        sport == null || sport == 'pallanuoto' || sport == 'nuoto_pallanuoto';
    final mostraNuoto =
        sport == null || sport == 'nuoto' || sport == 'nuoto_pallanuoto';

    return AppScaffold(
      appBar: AppBar(
        title: Text(stagione.nome),
        actions: [
          PopupMenuButton<_AzioneStagione>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) {
              switch (azione) {
                case _AzioneStagione.duplica:
                  _duplicaStagione(context, ref);
                case _AzioneStagione.modifica:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StagioneFormScreen(
                        clubId: stagione.clubId,
                        stagione: stagione,
                      ),
                    ),
                  );
                case _AzioneStagione.elimina:
                  _elimina(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AzioneStagione.duplica,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Duplica stagione'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneStagione.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneStagione.elimina,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.rosso,
                    ),
                    SizedBox(width: AppSpacing.s12),
                    Text('Elimina', style: TextStyle(color: AppColors.rosso)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formattaData(stagione.dataInizio)} — '
                  '${_formattaData(stagione.dataFine)}'
                  '${nomeGruppo != null ? ' · $nomeGruppo' : ''}'
                  '${stagione.campionato != null && stagione.campionato!.isNotEmpty ? ' · ${stagione.campionato}' : ''}',
                  style: AppTypography.sezione,
                ),
                if (stagione.obiettivo != null &&
                    stagione.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(stagione.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: AppListPanel(
              righe: [
                if (mostraPallanuoto)
                  AppListRow(
                    leading: const Icon(Icons.query_stats),
                    titolo: 'Statistiche di stagione',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            StatisticheSquadraScreen(clubId: stagione.clubId),
                      ),
                    ),
                  ),
                if (mostraNuoto)
                  AppListRow(
                    leading: const Icon(Icons.emoji_events_outlined),
                    titolo: 'Record',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecordClubScreen(clubId: stagione.clubId),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
