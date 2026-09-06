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
import '../application/allenamenti_providers.dart';
import 'allenamento_detail_screen.dart';
import 'allenamento_form_screen.dart';
import 'calendario/allenamenti_per_giorno.dart';

class GiornoAllenamentiScreen extends ConsumerWidget {
  const GiornoAllenamentiScreen({
    required this.clubId,
    required this.data,
    super.key,
  });

  final String clubId;
  final DateTime data;

  String get _titolo =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(clubId));

    void apriNuovo() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AllenamentoFormScreen(clubId: clubId, dataPredefinita: data),
      ),
    );

    return AppScaffold(
      appBar: AppBar(title: Text(_titolo)),
      body: allenamentiAsync.when(
        data: (tutti) {
          final delGiorno = tutti
              .where((a) => isStessoGiorno(a.data, data))
              .toList();
          if (delGiorno.isEmpty) {
            return EmptyState(
              icona: Icons.calendar_month_outlined,
              titolo: 'Nessun allenamento in questo giorno',
              descrizione: 'Crea il primo allenamento per questa data.',
              azionePrincipale: 'Nuovo allenamento',
              onAzionePrincipale: apriNuovo,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: AppListPanel(
              righe: [
                for (final a in delGiorno)
                  AppListRow(
                    titolo: a.titolo != null && a.titolo!.isNotEmpty
                        ? a.titolo!
                        : 'Allenamento',
                    sottotitolo: a.gruppo != null && a.gruppo!.isNotEmpty
                        ? a.gruppo!
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AllenamentoDetailScreen(allenamento: a),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-giorno-allenamenti',
        onPressed: apriNuovo,
        tooltip: 'Nuovo allenamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
