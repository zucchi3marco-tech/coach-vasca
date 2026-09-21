import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/stagioni_providers.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';
import 'stagione_detail_screen.dart';
import 'stagione_form_screen.dart';

class StagioniListScreen extends ConsumerWidget {
  const StagioniListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (stagioni di tutti i gruppi).
  final String? filtroGruppoId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Una stagione con gruppo è visibile solo a quel gruppo; una senza
    // gruppo è una stagione di club, visibile a tutti.
    final stagioniAsync = ref
        .watch(stagioniListProvider(clubId))
        .whenData(
          (stagioni) => stagioni
              .where(
                (s) => visibileNelGruppo(
                  gruppoDelRecord: s.gruppoId,
                  gruppoSelezionato: filtroGruppoId,
                ),
              )
              .toList(),
        );
    final Map<String, String> nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(clubId)).value ?? [])
        g.id: g.nome,
    };

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId),
        child: stagioniAsync.when(
          data: (stagioni) => stagioni.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      icona: Icons.event_note_outlined,
                      titolo: 'Nessuna stagione',
                      descrizione:
                          'Crea la prima stagione per programmare '
                          'macrocicli, mesocicli e microcicli.',
                      azionePrincipale: 'Nuova stagione',
                      onAzionePrincipale: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StagioneFormScreen(clubId: clubId),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: AppListPanel(
                    righe: [
                      for (final s in stagioni)
                        AppListRow(
                          titolo: s.nome,
                          sottotitolo:
                              '${_formattaData(s.dataInizio)} — '
                              '${_formattaData(s.dataFine)}'
                              ' · ${s.gruppoId == null ? etichettaTuttiGliAtleti : (nomiGruppi[s.gruppoId] ?? '')}'
                              '${s.campionato != null && s.campionato!.isNotEmpty ? ' · ${s.campionato}' : ''}',
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StagioneDetailScreen(stagione: s),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: const [LoadingSkeletonList(righe: 6)],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              ErrorBanner(
                messaggio: 'Non è stato possibile caricare le stagioni.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-stagioni',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StagioneFormScreen(clubId: clubId)),
        ),
        tooltip: 'Nuova stagione',
        child: const Icon(Icons.add),
      ),
    );
  }
}
