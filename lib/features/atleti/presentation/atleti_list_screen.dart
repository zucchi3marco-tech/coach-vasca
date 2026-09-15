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
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../carico/presentation/carico_atleta_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../statistiche/presentation/statistiche_atleta_screen.dart';
import '../../stroke_rate/presentation/stroke_rate_screen.dart';
import '../application/atleti_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import 'atleta_form_screen.dart';
import 'gestisci_account_atleta_dialog.dart';
import 'pb_list_screen.dart';

enum _Ordinamento { cognome, dataNascita }

class AtletiListScreen extends ConsumerStatefulWidget {
  const AtletiListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra tutti gli atleti).
  final String? filtroGruppoId;

  @override
  ConsumerState<AtletiListScreen> createState() => _AtletiListScreenState();
}

class _AtletiListScreenState extends ConsumerState<AtletiListScreen> {
  bool _mostraInattivi = false;
  String _ricerca = '';
  _Ordinamento _ordinamento = _Ordinamento.cognome;

  @override
  Widget build(BuildContext context) {
    final filter = (clubId: widget.clubId, includeInactive: _mostraInattivi);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  etichetta: 'Cerca per cognome o nome',
                  suffixIcon: const Icon(Icons.search),
                  onChanged: (value) => setState(() => _ricerca = value),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              PopupMenuButton<_Ordinamento>(
                icon: const Icon(Icons.sort, color: AppColors.testoSecondario),
                tooltip: 'Ordina',
                onSelected: (valore) => setState(() => _ordinamento = valore),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _Ordinamento.cognome,
                    child: _VoceMenu(
                      icona: Icons.sort_by_alpha,
                      etichetta: 'Cognome (A-Z)',
                    ),
                  ),
                  PopupMenuItem(
                    value: _Ordinamento.dataNascita,
                    child: _VoceMenu(
                      icona: Icons.cake_outlined,
                      etichetta: 'Data di nascita',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(atletiRepositoryProvider)
                  .refreshFromRemote(widget.clubId),
              child: atletiAsync.when(
                data: (atleti) => _AtletiList(
                  atleti: atleti,
                  gruppi: gruppi,
                  filtroGruppoId: widget.filtroGruppoId,
                  ricerca: _ricerca,
                  ordinamento: _ordinamento,
                  onTap: (atleta) => _apriForm(context, atleta: atleta),
                  onTapNuovo: () => _apriForm(context),
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
                  onTapPb: (atleta) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PbListScreen(atleta: atleta),
                    ),
                  ),
                ),
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [LoadingSkeletonList(righe: 6)],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ErrorBanner(
                      messaggio: 'Non è stato possibile caricare gli atleti.',
                      suggerimento:
                          'Riprova. Se l\'errore continua, chiudi e riapri '
                          'l\'app.',
                      dettaglioTecnico: messaggioErrore(error),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        onPressed: () => _apriForm(context),
        tooltip: 'Nuovo atleta',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, {Atleta? atleta}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AtletaFormScreen(clubId: widget.clubId, atleta: atleta),
      ),
    );
  }
}

class _AtletiList extends StatelessWidget {
  const _AtletiList({
    required this.atleti,
    required this.gruppi,
    required this.filtroGruppoId,
    required this.ricerca,
    required this.ordinamento,
    required this.onTap,
    required this.onTapNuovo,
    required this.onTapCarico,
    required this.onTapStatistiche,
    required this.onTapBracciate,
    required this.onTapPb,
  });

  final List<Atleta> atleti;
  final List<Gruppo> gruppi;
  final String? filtroGruppoId;
  final String ricerca;
  final _Ordinamento ordinamento;
  final ValueChanged<Atleta> onTap;
  final VoidCallback onTapNuovo;
  final ValueChanged<Atleta> onTapCarico;
  final ValueChanged<Atleta> onTapStatistiche;
  final ValueChanged<Atleta> onTapBracciate;
  final ValueChanged<Atleta> onTapPb;

  /// Il rilevamento bracciate usa la fotocamera + Google ML Kit: disponibile
  /// solo nell'app nativa Android/iOS, non nella versione web.
  static bool get _bracciateDisponibili =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  List<Atleta> _filtrati() {
    final query = ricerca.trim().toLowerCase();
    var filtrati = filtroGruppoId == null
        ? [...atleti]
        : atleti.where((a) => a.gruppoId == filtroGruppoId).toList();
    if (query.isNotEmpty) {
      filtrati = filtrati
          .where((a) => a.nomeCompleto.toLowerCase().contains(query))
          .toList();
    }
    filtrati.sort((a, b) {
      if (ordinamento == _Ordinamento.dataNascita) {
        return a.dataNascita.compareTo(b.dataNascita);
      }
      final perCognome = a.cognome.compareTo(b.cognome);
      return perCognome != 0 ? perCognome : a.nome.compareTo(b.nome);
    });
    return filtrati;
  }

  @override
  Widget build(BuildContext context) {
    final nomeGruppo = {for (final g in gruppi) g.id: g.nome};
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

    final filtrati = _filtrati();
    if (filtrati.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icona: Icons.search_off,
            titolo: 'Nessun atleta trovato',
            descrizione: 'Prova a cercare con un altro nome o cognome.',
            azionePrincipale: 'Ho capito',
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: AppListPanel(
        righe: [
          for (final atleta in filtrati)
            AppListRow(
              leading: _AvatarAtleta(atleta: atleta),
              titolo: atleta.nomeCompleto,
              sottotitolo:
                  [
                    atleta.sport == 'nuoto' ? 'Nuoto' : 'Pallanuoto',
                    ?nomeGruppo[atleta.gruppoId],
                  ].join(' · ') +
                  (atleta.attivo ? '' : ' · inattivo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (atleta.visitaMedicaScaduta)
                    const Tooltip(
                      message: 'Visita medica scaduta',
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: AppColors.attenzione,
                      ),
                    )
                  else if (atleta.visitaMedicaInScadenza)
                    const Tooltip(
                      message: 'Visita medica in scadenza',
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: AppColors.attenzione,
                      ),
                    ),
                  PopupMenuButton<VoidCallback>(
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
                        value: () => onTapPb(atleta),
                        child: const _VoceMenu(
                          icona: Icons.emoji_events_outlined,
                          etichetta: 'Personal best',
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
                      PopupMenuItem(
                        value: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              GestisciAccountAtletaDialog(atleta: atleta),
                        ),
                        child: _VoceMenu(
                          icona: atleta.haAccountCollegato
                              ? Icons.verified_user_outlined
                              : Icons.person_add_alt_outlined,
                          etichetta: 'Account atleta',
                        ),
                      ),
                    ],
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
    final iniziale = atleta.cognome.isNotEmpty
        ? atleta.cognome[0].toUpperCase()
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
