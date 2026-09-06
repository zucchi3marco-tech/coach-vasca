import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';
import 'allenamento_detail_screen.dart';
import 'allenamento_form_screen.dart';
import 'calendario/calendario_mensile_view.dart';
import 'calendario/calendario_settimanale_view.dart';
import 'giorno_allenamenti_screen.dart';

enum _Vista { elenco, settimana, mese }

class AllenamentiListScreen extends ConsumerStatefulWidget {
  const AllenamentiListScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<AllenamentiListScreen> createState() =>
      _AllenamentiListScreenState();
}

class _AllenamentiListScreenState
    extends ConsumerState<AllenamentiListScreen> {
  _Vista _vista = _Vista.elenco;

  @override
  Widget build(BuildContext context) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(widget.clubId));

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
              data: (allenamenti) => switch (_vista) {
                _Vista.elenco => _buildElenco(allenamenti),
                _Vista.settimana => CalendarioSettimanaleView(
                  allenamenti: allenamenti,
                  onGiornoSelezionato: (data) => _apriGiorno(data),
                ),
                _Vista.mese => CalendarioMensileView(
                  allenamenti: allenamenti,
                  onGiornoSelezionato: (data) => _apriGiorno(data),
                ),
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
                    messaggio: 'Non è stato possibile caricare gli '
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab-genera-ai',
            onPressed: _apriGeneraAI,
            tooltip: 'Genera con AI',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: AppSpacing.s12),
          FloatingActionButton(
            heroTag: 'fab-allenamenti',
            onPressed: _apriForm,
            tooltip: 'Nuovo allenamento',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildElenco(List<Allenamento> allenamenti) {
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
                      'Crea il primo allenamento a mano oppure genera una '
                      'proposta con l\'AI.',
                  azionePrincipale: 'Nuovo allenamento',
                  onAzionePrincipale: _apriForm,
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

  Future<void> _apriForm() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllenamentoFormScreen(clubId: widget.clubId),
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
}
