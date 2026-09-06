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
import '../application/mesocicli_providers.dart';
import '../domain/macrociclo.dart';
import 'macrociclo_form_screen.dart';
import 'mesociclo_detail_screen.dart';
import 'mesociclo_form_screen.dart';

class MacrocicloDetailScreen extends ConsumerWidget {
  const MacrocicloDetailScreen({required this.macrociclo, super.key});

  final Macrociclo macrociclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesocicliAsync = ref.watch(mesocicliListProvider(macrociclo.id));

    void apriNuovo() {
      final mesocicliAttuali =
          ref.read(mesocicliListProvider(macrociclo.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MesocicloFormScreen(
            macrocicloId: macrociclo.id,
            ordineSuccessivo: mesocicliAttuali.length + 1,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(macrociclo.nome),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MacrocicloFormScreen(
                  stagioneId: macrociclo.stagioneId,
                  ordineSuccessivo: macrociclo.ordine,
                  macrociclo: macrociclo,
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
                  '${_formattaData(macrociclo.dataInizio)} — '
                  '${_formattaData(macrociclo.dataFine)}',
                  style: AppTypography.sezione,
                ),
                if (macrociclo.obiettivo != null &&
                    macrociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(macrociclo.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: mesocicliAsync.when(
              data: (mesocicli) => mesocicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun mesociclo',
                      descrizione:
                          'Aggiungi il primo mesociclo per suddividere '
                          'questo macrociclo.',
                      azionePrincipale: 'Nuovo mesociclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: AppListPanel(
                        righe: [
                          for (final m in mesocicli)
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
                                      MesocicloDetailScreen(mesociclo: m),
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
                  messaggio: 'Non è stato possibile caricare i mesocicli.',
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
        heroTag: 'fab-mesocicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo mesociclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
