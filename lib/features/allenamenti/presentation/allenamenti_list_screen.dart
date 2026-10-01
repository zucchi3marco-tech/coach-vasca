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
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../ai_genera/presentation/genera_settimana_form_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../ripartenze/presentation/ripartenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';
import 'allenamento_detail_screen.dart';
import 'calendario/calendario_mensile_view.dart';
import 'calendario/calendario_settimanale_view.dart';
import 'giorno_allenamenti_screen.dart';

enum _Vista { elenco, settimana, mese }

class AllenamentiListScreen extends ConsumerStatefulWidget {
  const AllenamentiListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra gli allenamenti di tutti i gruppi).
  final String? filtroGruppoId;

  @override
  ConsumerState<AllenamentiListScreen> createState() =>
      _AllenamentiListScreenState();
}

class _AllenamentiListScreenState extends ConsumerState<AllenamentiListScreen> {
  _Vista _vista = _Vista.elenco;

  @override
  Widget build(BuildContext context) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(widget.clubId));
    final Map<String, String> nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };

    return AppScaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: SegmentedButton<_Vista>(
              segments: const [
                ButtonSegment(value: _Vista.elenco, label: Text('Elenco')),
                ButtonSegment(
                  value: _Vista.settimana,
                  label: Text('Settimana'),
                ),
                ButtonSegment(value: _Vista.mese, label: Text('Mese')),
              ],
              selected: {_vista},
              onSelectionChanged: (selezione) =>
                  setState(() => _vista = selezione.first),
            ),
          ),
          Expanded(
            child: allenamentiAsync.when(
              data: (tuttiGliAllenamenti) {
                // Un allenamento con gruppo assegnato è visibile solo a chi
                // lavora con quel gruppo; uno senza gruppo resta visibile a
                // tutti (stessa regola di PresenzeScreen).
                final allenamenti = widget.filtroGruppoId == null
                    ? tuttiGliAllenamenti
                    : tuttiGliAllenamenti
                          .where(
                            (a) =>
                                a.gruppoId == widget.filtroGruppoId ||
                                a.gruppoId == null,
                          )
                          .toList();
                return switch (_vista) {
                  _Vista.elenco => _buildElenco(allenamenti, nomiGruppi),
                  _Vista.settimana => CalendarioSettimanaleView(
                    clubId: widget.clubId,
                    allenamenti: allenamenti,
                    onGiornoSelezionato: (data) => _apriGiorno(data),
                  ),
                  _Vista.mese => CalendarioMensileView(
                    allenamenti: allenamenti,
                    onGiornoSelezionato: (data) => _apriGiorno(data),
                  ),
                };
              },
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
                    messaggio:
                        'Non è stato possibile caricare gli '
                        'allenamenti.',
                    suggerimento:
                        'Riprova. Se l\'errore continua, chiudi e riapri '
                        'l\'app.',
                    dettaglioTecnico: messaggioErrore(error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FabAzioni(
        heroTag: 'fab-allenamenti',
        azioni: [
          AzioneFab(
            icona: Icons.auto_awesome,
            etichetta: 'Nuovo allenamento',
            onPressed: _apriGeneraAI,
          ),
          AzioneFab(
            icona: Icons.view_week_outlined,
            etichetta: 'Genera settimana con AI',
            onPressed: _apriGeneraSettimanaAI,
          ),
          AzioneFab(
            icona: Icons.speed,
            etichetta: 'Ripartenze',
            onPressed: _apriRipartenze,
          ),
        ],
      ),
    );
  }

  Widget _buildElenco(
    List<Allenamento> allenamenti,
    Map<String, String> nomiGruppi,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(allenamentiRepositoryProvider)
          .refreshFromRemote(widget.clubId),
      child: allenamenti.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icona: Icons.calendar_month_outlined,
                  titolo: 'Nessun allenamento',
                  descrizione:
                      'Descrivi il primo allenamento o impostane i '
                      'parametri: l\'AI ti propone la scheda.',
                  azionePrincipale: 'Nuovo allenamento',
                  onAzionePrincipale: _apriGeneraAI,
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: AppListPanel(
                righe: [
                  for (final a in allenamenti)
                    AppListRow(
                      titolo: a.titolo != null && a.titolo!.isNotEmpty
                          ? a.titolo!
                          : 'Allenamento',
                      sottotitolo:
                          '${a.data.day.toString().padLeft(2, '0')}/'
                          '${a.data.month.toString().padLeft(2, '0')}/'
                          '${a.data.year}'
                          '${nomiGruppi[a.gruppoId] != null ? ' · ${nomiGruppi[a.gruppoId]}' : ''}',
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
    );
  }

  void _apriGiorno(DateTime data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GiornoAllenamentiScreen(clubId: widget.clubId, data: data),
      ),
    );
  }

  Future<void> _apriGeneraAI() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneraAllenamentoFormScreen(clubId: widget.clubId),
      ),
    );
  }

  Future<void> _apriGeneraSettimanaAI() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneraSettimanaFormScreen(clubId: widget.clubId),
      ),
    );
  }

  Future<void> _apriRipartenze() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RipartenzeScreen(
          clubId: widget.clubId,
          gruppoIdIniziale: widget.filtroGruppoId,
        ),
      ),
    );
  }
}
