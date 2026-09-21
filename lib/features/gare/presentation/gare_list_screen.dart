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
import '../application/gare_providers.dart';
import '../data/gare_repository.dart';
import '../domain/elenco_gare.dart';
import '../domain/gara.dart';
import 'gara_detail_screen.dart';

/// Elenco delle gare della stagione in corso del gruppo (tab «Gare» del
/// nuoto), una sotto l'altra dalla più vecchia alla più recente. Le gare
/// non si creano da qui: si creano dal calendario della stagione.
class GareListScreen extends ConsumerWidget {
  const GareListScreen({
    required this.clubId,
    this.filtroGruppoId,
    this.onVaiAStagioni,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (gare di tutti i gruppi).
  final String? filtroGruppoId;

  /// Porta alla tab Stagioni (da lì si crea la stagione e le sue gare).
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
            icona: Icons.emoji_events_outlined,
            titolo: titolo,
            descrizione: descrizione,
            azionePrincipale: 'Vai alle stagioni',
            onAzionePrincipale: onVaiAStagioni,
          ),
        ],
      );

  Widget _elenco(BuildContext context, Stagione stagione, List<Gara> gare) {
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
              for (final g in gare)
                AppListRow(
                  titolo: g.nome,
                  sottotitolo:
                      '${_formattaData(g.data)}'
                      '${g.ora != null && g.ora!.isNotEmpty ? ' · ${g.ora}' : ''}'
                      '${g.luogo != null && g.luogo!.isNotEmpty ? ' · ${g.luogo}' : ''}'
                      '${g.diClub ? ' · Tutto il club' : ''}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GaraDetailScreen(gara: g),
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
    final gareAsync = ref.watch(gareListProvider(clubId));

    final Widget corpo;
    final errore = stagioniAsync.error ?? gareAsync.error;
    if (errore != null) {
      corpo = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          ErrorBanner(
            messaggio: 'Non è stato possibile caricare le gare.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(errore),
          ),
        ],
      );
    } else if (!stagioniAsync.hasValue || !gareAsync.hasValue) {
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
              'Le gare si aggiungono dal calendario di una stagione: '
              'crea prima la stagione.',
        );
      } else {
        final gare = gareDellaStagione(
          stagione,
          gareAsync.requireValue,
          filtroGruppoId,
        );
        corpo = gare.isEmpty
            ? _vuoto(
                titolo: 'Nessuna gara in questa stagione',
                descrizione:
                    'Apri la stagione «${stagione.nome}» e tocca un giorno '
                    'del calendario per aggiungere una gara.',
              )
            : _elenco(context, stagione, gare);
      }
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(gareRepositoryProvider).refreshFromRemote(clubId);
          await ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId);
        },
        child: corpo,
      ),
    );
  }
}
