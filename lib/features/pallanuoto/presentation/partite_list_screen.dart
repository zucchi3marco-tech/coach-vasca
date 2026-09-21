import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/data/stagioni_repository.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import '../domain/elenco_partite.dart';
import '../domain/partita.dart';
import 'distinta_screen.dart';
import 'partita_form_screen.dart';

/// Elenco delle partite della stagione in corso del gruppo, una sotto
/// l'altra dalla più vecchia alla più recente. Le partite non si creano
/// da qui: si creano dal calendario della stagione (tocco su un giorno).
class PartiteListScreen extends ConsumerWidget {
  const PartiteListScreen({
    required this.clubId,
    this.filtroGruppoId,
    this.onVaiAStagioni,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra le partite di tutti i gruppi).
  final String? filtroGruppoId;

  /// Porta alla tab Stagioni (da lì si crea la stagione e le sue partite).
  final VoidCallback? onVaiAStagioni;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  Widget _vuoto({required String titolo, required String descrizione}) =>
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icona: Icons.sports_handball_outlined,
            titolo: titolo,
            descrizione: descrizione,
            azionePrincipale: 'Vai alle stagioni',
            onAzionePrincipale: onVaiAStagioni,
          ),
        ],
      );

  Widget _elenco(
    BuildContext context,
    Stagione stagione,
    List<Partita> partite,
  ) {
    final colori = context.colori;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stagione.nome,
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppListPanel(
            righe: [
              for (final p in partite)
                AppListRow(
                  titolo: '${p.squadraCasa} - ${p.squadraTrasferta}',
                  sottotitolo:
                      '${_formattaData(p.data)}'
                      '${p.ora != null && p.ora!.isNotEmpty ? ' · ${p.ora}' : ''}'
                      '${p.gruppoId == null ? ' · Tutto il club' : ''}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Modifica partita',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PartitaFormScreen(clubId: clubId, partita: p),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(clubId));
    final partiteAsync = ref.watch(partiteListProvider(clubId));

    final Widget corpo;
    final errore = stagioniAsync.error ?? partiteAsync.error;
    if (errore != null) {
      corpo = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          ErrorBanner(
            messaggio: 'Non è stato possibile caricare le partite.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(errore),
          ),
        ],
      );
    } else if (!stagioniAsync.hasValue || !partiteAsync.hasValue) {
      corpo = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: const [LoadingSkeletonList(righe: 6)],
      );
    } else {
      final stagione = stagionePerElenco(
        stagioniAsync.requireValue,
        filtroGruppoId,
      );
      if (stagione == null) {
        corpo = _vuoto(
          titolo: 'Nessuna stagione',
          descrizione:
              'Le partite si aggiungono dal calendario di una stagione: '
              'crea prima la stagione.',
        );
      } else {
        final partite = partiteDellaStagione(
          stagione,
          partiteAsync.requireValue,
          filtroGruppoId,
        );
        corpo = partite.isEmpty
            ? _vuoto(
                titolo: 'Nessuna partita in questa stagione',
                descrizione:
                    'Apri la stagione «${stagione.nome}» e tocca un giorno '
                    'del calendario per aggiungere una partita.',
              )
            : _elenco(context, stagione, partite);
      }
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(partiteRepositoryProvider).refreshFromRemote(clubId);
          await ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId);
        },
        child: corpo,
      ),
    );
  }
}
