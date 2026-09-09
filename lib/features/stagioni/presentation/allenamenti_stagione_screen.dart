import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/allenamenti_stagione_provider.dart';
import '../domain/microciclo.dart';
import '../domain/stagione.dart';

/// Tutti gli allenamenti della stagione in un unico elenco, raggruppati per
/// settimana — invece di doverli guardare un microciclo alla volta.
class AllenamentiStagioneScreen extends ConsumerWidget {
  const AllenamentiStagioneScreen({required this.stagione, super.key});

  final Stagione stagione;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String _titoloSettimana(Microciclo m) {
    if (m.nome != null && m.nome!.isNotEmpty) return m.nome!;
    if (m.numeroSettimana != null) return 'Settimana ${m.numeroSettimana}';
    return 'Settimana ${_formattaData(m.dataInizio)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allenamentiStagioneProvider(stagione.id));
    final Map<String, String> nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(stagione.clubId)).value ?? [])
        g.id: g.nome,
    };

    return AppScaffold(
      appBar: AppBar(title: const Text('Tutti gli allenamenti')),
      body: async.when(
        data: (voci) {
          if (voci.isEmpty) {
            return EmptyState(
              icona: Icons.calendar_month_outlined,
              titolo: 'Nessun allenamento',
              descrizione:
                  'Non ci sono ancora allenamenti collegati a questa '
                  'stagione.',
              azionePrincipale: 'Torna alla stagione',
              onAzionePrincipale: () => Navigator.of(context).pop(),
            );
          }
          final gruppi = <String, (Microciclo, List<Allenamento>)>{};
          for (final (allenamento, microciclo) in voci) {
            final voce = gruppi.putIfAbsent(
              microciclo.id,
              () => (microciclo, []),
            );
            voce.$2.add(allenamento);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in gruppi.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                    child: Text(
                      _titoloSettimana(entry.$1),
                      style: AppTypography.sezione,
                    ),
                  ),
                  AppListPanel(
                    righe: [
                      for (final a in entry.$2)
                        AppListRow(
                          titolo: a.titolo != null && a.titolo!.isNotEmpty
                              ? a.titolo!
                              : 'Allenamento',
                          sottotitolo:
                              '${_formattaData(a.data)}'
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
                  const SizedBox(height: AppSpacing.s24),
                ],
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 6),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli allenamenti.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}
