import 'package:flutter/foundation.dart';
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
import '../../carico/presentation/carico_atleta_screen.dart';
import '../../statistiche/presentation/statistiche_atleta_screen.dart';
import '../../stroke_rate/presentation/stroke_rate_screen.dart';
import '../../test/presentation/test_list_screen.dart';
import '../application/atleti_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import 'atleta_form_screen.dart';

class AtletiListScreen extends ConsumerStatefulWidget {
  const AtletiListScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<AtletiListScreen> createState() => _AtletiListScreenState();
}

class _AtletiListScreenState extends ConsumerState<AtletiListScreen> {
  bool _mostraInattivi = false;

  @override
  Widget build(BuildContext context) {
    final filter = (clubId: widget.clubId, includeInactive: _mostraInattivi);
    final atletiAsync = ref.watch(atletiListProvider(filter));

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(atletiRepositoryProvider).refreshFromRemote(widget.clubId),
        child: atletiAsync.when(
          data: (atleti) => _AtletiList(
            atleti: atleti,
            onTap: (atleta) => _apriForm(context, atleta: atleta),
            onTapNuovo: () => _apriForm(context),
            onTapTest: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TestListScreen(atleta: atleta),
              ),
            ),
            onTapCarico: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaricoAtletaScreen(atleta: atleta),
              ),
            ),
            onTapStatistiche: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatisticheAtletaScreen(atleta: atleta),
              ),
            ),
            onTapBracciate: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StrokeRateScreen(atleta: atleta),
              ),
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
                messaggio: 'Non è stato possibile caricare gli atleti.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostra atleti inattivi'),
          value: _mostraInattivi,
          onChanged: (value) => setState(() => _mostraInattivi = value),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-atleti',
        onPressed: () => _apriForm(context),
        tooltip: 'Nuovo atleta',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, {Atleta? atleta}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AtletaFormScreen(clubId: widget.clubId, atleta: atleta),
      ),
    );
  }
}

class _AtletiList extends StatelessWidget {
  const _AtletiList({
    required this.atleti,
    required this.onTap,
    required this.onTapNuovo,
    required this.onTapTest,
    required this.onTapCarico,
    required this.onTapStatistiche,
    required this.onTapBracciate,
  });

  final List<Atleta> atleti;
  final ValueChanged<Atleta> onTap;
  final VoidCallback onTapNuovo;
  final ValueChanged<Atleta> onTapTest;
  final ValueChanged<Atleta> onTapCarico;
  final ValueChanged<Atleta> onTapStatistiche;
  final ValueChanged<Atleta> onTapBracciate;

  /// Il rilevamento bracciate usa la fotocamera + Google ML Kit: disponibile
  /// solo nell'app nativa Android/iOS, non nella versione web.
  static bool get _bracciateDisponibili =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Widget build(BuildContext context) {
    if (atleti.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icona: Icons.groups_outlined,
            titolo: 'Nessun atleta',
            descrizione:
                'Aggiungi il primo atleta per iniziare a programmare '
                'allenamenti e tenere le presenze.',
            azionePrincipale: 'Nuovo atleta',
            onAzionePrincipale: onTapNuovo,
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: AppListPanel(
        righe: [
          for (final atleta in atleti)
            AppListRow(
              leading: _AvatarAtleta(atleta: atleta),
              titolo: atleta.nomeCompleto,
              sottotitolo: [
                atleta.sport == 'nuoto' ? 'Nuoto' : 'Pallanuoto',
                if (atleta.gruppo != null && atleta.gruppo!.isNotEmpty)
                  atleta.gruppo!,
              ].join(' · ') + (atleta.attivo ? '' : ' · inattivo'),
              trailing: PopupMenuButton<VoidCallback>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.testoSecondario,
                ),
                onSelected: (azione) => azione(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: () => onTapCarico(atleta),
                    child: const _VoceMenu(
                      icona: Icons.show_chart,
                      etichetta: 'Carico',
                    ),
                  ),
                  PopupMenuItem(
                    value: () => onTapStatistiche(atleta),
                    child: const _VoceMenu(
                      icona: Icons.query_stats,
                      etichetta: 'Statistiche',
                    ),
                  ),
                  PopupMenuItem(
                    value: () => onTapTest(atleta),
                    child: const _VoceMenu(
                      icona: Icons.speed_outlined,
                      etichetta: 'Test',
                    ),
                  ),
                  if (_bracciateDisponibili)
                    PopupMenuItem(
                      value: () => onTapBracciate(atleta),
                      child: const _VoceMenu(
                        icona: Icons.camera_alt_outlined,
                        etichetta: 'Bracciate',
                      ),
                    ),
                ],
              ),
              onTap: () => onTap(atleta),
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

class _AvatarAtleta extends StatelessWidget {
  const _AvatarAtleta({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    final iniziale = atleta.nome.isNotEmpty
        ? atleta.nome[0].toUpperCase()
        : '?';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atleta.attivo ? AppColors.bluTenue : AppColors.superficieTenue,
        shape: BoxShape.circle,
      ),
      child: Text(
        iniziale,
        style: AppTypography.corpoForte.copyWith(
          color: atleta.attivo ? AppColors.blu : AppColors.testoTenue,
        ),
      ),
    );
  }
}
