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
import '../../../widgets/ordine_badge.dart';
import '../application/macrocicli_providers.dart';
import '../domain/stagione.dart';
import 'macrociclo_detail_screen.dart';
import 'macrociclo_form_screen.dart';
import 'stagione_form_screen.dart';

class StagioneDetailScreen extends ConsumerWidget {
  const StagioneDetailScreen({required this.stagione, super.key});

  final Stagione stagione;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrocicliAsync = ref.watch(macrocicliListProvider(stagione.id));

    void apriNuovo() {
      final macrocicliAttuali =
          ref.read(macrocicliListProvider(stagione.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MacrocicloFormScreen(
            stagioneId: stagione.id,
            ordineSuccessivo: macrocicliAttuali.length + 1,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(stagione.nome),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StagioneFormScreen(
                  clubId: stagione.clubId,
                  stagione: stagione,
                ),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Modifica'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formattaData(stagione.dataInizio)} — '
                  '${_formattaData(stagione.dataFine)}'
                  '${stagione.gruppo != null && stagione.gruppo!.isNotEmpty ? ' · ${stagione.gruppo}' : ''}',
                  style: AppTypography.sezione,
                ),
                if (stagione.obiettivo != null &&
                    stagione.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(stagione.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: macrocicliAsync.when(
              data: (macrocicli) => macrocicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun macrociclo',
                      descrizione:
                          'Aggiungi il primo macrociclo per suddividere la '
                          'stagione.',
                      azionePrincipale: 'Nuovo macrociclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: AppListPanel(
                        righe: [
                          for (final m in macrocicli)
                            AppListRow(
                              leading: OrdineBadge(numero: m.ordine),
                              titolo: m.nome,
                              sottotitolo:
                                  '${_formattaData(m.dataInizio)} — '
                                  '${_formattaData(m.dataFine)}',
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MacrocicloDetailScreen(macrociclo: m),
                                ),
                              ),
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
                  messaggio: 'Non è stato possibile caricare i macrocicli.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-macrocicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo macrociclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
