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
import '../application/microcicli_providers.dart';
import '../domain/mesociclo.dart';
import 'mesociclo_form_screen.dart';
import 'microciclo_detail_screen.dart';
import 'microciclo_form_screen.dart';

class MesocicloDetailScreen extends ConsumerWidget {
  const MesocicloDetailScreen({required this.mesociclo, super.key});

  final Mesociclo mesociclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(microcicliListProvider(mesociclo.id));

    void apriNuovo() {
      final microcicliAttuali =
          ref.read(microcicliListProvider(mesociclo.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MicrocicloFormScreen(
            mesocicloId: mesociclo.id,
            ordineSuccessivo: microcicliAttuali.length + 1,
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(mesociclo.nome),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MesocicloFormScreen(
                  macrocicloId: mesociclo.macrocicloId,
                  ordineSuccessivo: mesociclo.ordine,
                  mesociclo: mesociclo,
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
                  '${_formattaData(mesociclo.dataInizio)} — '
                  '${_formattaData(mesociclo.dataFine)}',
                  style: AppTypography.sezione,
                ),
                if (mesociclo.obiettivo != null &&
                    mesociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(mesociclo.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: microcicliAsync.when(
              data: (microcicli) => microcicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun microciclo',
                      descrizione:
                          'Aggiungi il primo microciclo per suddividere '
                          'questo mesociclo in settimane.',
                      azionePrincipale: 'Nuovo microciclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: AppListPanel(
                        righe: [
                          for (final m in microcicli)
                            AppListRow(
                              leading: OrdineBadge(numero: m.ordine),
                              titolo: m.nome != null && m.nome!.isNotEmpty
                                  ? m.nome!
                                  : (m.numeroSettimana != null
                                        ? 'Settimana ${m.numeroSettimana}'
                                        : 'Microciclo'),
                              sottotitolo:
                                  '${_formattaData(m.dataInizio)} — '
                                  '${_formattaData(m.dataFine)}'
                                  '${m.tipo != null && m.tipo!.isNotEmpty ? ' · ${m.tipo}' : ''}',
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MicrocicloDetailScreen(microciclo: m),
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
                  messaggio: 'Non è stato possibile caricare i microcicli.',
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
        heroTag: 'fab-microcicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo microciclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
