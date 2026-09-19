import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/fab_azioni.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../referti/presentation/leggi_referto_screen.dart';
import '../../statistiche/presentation/statistiche_squadra_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import 'distinta_screen.dart';
import 'partita_form_screen.dart';
import 'schemi_tattici_list_screen.dart';

class PartiteListScreen extends ConsumerWidget {
  const PartiteListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra le partite di tutti i gruppi).
  final String? filtroGruppoId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuttePartite = ref.watch(partiteListProvider(clubId));
    // Una partita con gruppo assegnato è visibile solo a chi lavora con
    // quel gruppo; una senza gruppo resta visibile a tutti (stessa
    // regola di PresenzeScreen/AllenamentiListScreen).
    final partiteAsync = filtroGruppoId == null
        ? tuttePartite
        : tuttePartite.whenData(
            (partite) => partite
                .where(
                  (p) => p.gruppoId == filtroGruppoId || p.gruppoId == null,
                )
                .toList(),
          );

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(partiteRepositoryProvider).refreshFromRemote(clubId),
        child: partiteAsync.when(
          data: (partite) => partite.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      icona: Icons.sports_handball_outlined,
                      titolo: 'Nessuna partita',
                      descrizione:
                          'Crea la prima partita per gestire distinta, '
                          'eventi e referto.',
                      azionePrincipale: 'Nuova partita',
                      onAzionePrincipale: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PartitaFormScreen(clubId: clubId),
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
                      for (final p in partite)
                        AppListRow(
                          titolo: '${p.squadraCasa} - ${p.squadraTrasferta}',
                          sottotitolo:
                              '${_formattaData(p.data)}'
                              '${p.ora != null && p.ora!.isNotEmpty ? ' · ${p.ora}' : ''}'
                              '${p.campionato != null && p.campionato!.isNotEmpty ? ' · ${p.campionato}' : ''}',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Modifica partita',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PartitaFormScreen(
                                      clubId: clubId,
                                      partita: p,
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DistintaScreen(partita: p),
                            ),
                          ),
                          onLongPress: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PartitaFormScreen(clubId: clubId, partita: p),
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
                messaggio: 'Non è stato possibile caricare le partite.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FabAzioni(
        heroTag: 'fab-partite',
        azioni: [
          AzioneFab(
            icona: Icons.add,
            etichetta: 'Nuova partita',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartitaFormScreen(clubId: clubId),
              ),
            ),
          ),
          AzioneFab(
            icona: Icons.document_scanner_outlined,
            etichetta: 'Leggi referto',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeggiRefertoScreen(clubId: clubId),
              ),
            ),
          ),
          AzioneFab(
            icona: Icons.bar_chart,
            etichetta: 'Statistiche stagione',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatisticheSquadraScreen(clubId: clubId),
              ),
            ),
          ),
          AzioneFab(
            icona: Icons.sports_outlined,
            etichetta: 'Schemi tattici',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemiTatticiListScreen(
                  clubId: clubId,
                  filtroGruppoId: filtroGruppoId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
