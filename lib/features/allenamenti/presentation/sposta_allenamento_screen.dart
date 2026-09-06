import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../stagioni/application/microcicli_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';

class SpostaAllenamentoScreen extends ConsumerWidget {
  const SpostaAllenamentoScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(
      microcicliDelClubProvider(allenamento.clubId),
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('Sposta scheda')),
      body: microcicliAsync.when(
        data: (microcicli) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: AppListPanel(
            righe: [
              AppListRow(
                leading: Icon(
                  allenamento.microcicloId == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: allenamento.microcicloId == null
                      ? AppColors.blu
                      : AppColors.testoTenue,
                ),
                titolo: 'Nessun microciclo',
                sottotitolo: 'Scollega la scheda dalla settimana',
                onTap: () => _seleziona(context, ref, null),
              ),
              for (final m in microcicli)
                AppListRow(
                  leading: Icon(
                    allenamento.microcicloId == m.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: allenamento.microcicloId == m.id
                        ? AppColors.blu
                        : AppColors.testoTenue,
                  ),
                  titolo: m.nome != null && m.nome!.isNotEmpty
                      ? m.nome!
                      : (m.numeroSettimana != null
                            ? 'Settimana ${m.numeroSettimana}'
                            : 'Microciclo'),
                  sottotitolo:
                      '${_formattaData(m.dataInizio)} — '
                      '${_formattaData(m.dataFine)}',
                  onTap: () => _seleziona(context, ref, m.id),
                ),
            ],
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i microcicli.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }

  Future<void> _seleziona(
    BuildContext context,
    WidgetRef ref,
    String? microcicloId,
  ) async {
    await ref
        .read(allenamentiRepositoryProvider)
        .setMicrociclo(id: allenamento.id, microcicloId: microcicloId);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
