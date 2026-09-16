import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../application/gruppi_providers.dart';
import '../application/selezione_gruppo_provider.dart';
import 'gruppi_management_screen.dart';

/// Mostrata a ogni apertura dell'app (dopo il primo login, quando i gruppi
/// esistono già): un pulsante per gruppo più "Tutti gli atleti", per
/// scegliere con chi si lavora in questa sessione prima di entrare nelle
/// tab normali. Nessuna AppBar propria — vedi GruppiOnboardingScreen.
class GruppiChooserScreen extends ConsumerWidget {
  const GruppiChooserScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gruppi = ref.watch(gruppiListProvider(clubId)).value ?? [];

    void scegli(String? gruppoId) => ref
        .read(selezioneGruppoProvider.notifier)
        .scegli(SelezioneGruppo(gruppoId));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Con chi lavori oggi?',
                    style: AppTypography.titoloXl.copyWith(
                      color: context.colori.testo,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Gestisci gruppi',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GruppiManagementScreen(clubId: clubId),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            AppListPanel(
              righe: [
                for (final g in gruppi)
                  AppListRow(
                    leading: const Icon(Icons.groups_outlined),
                    titolo: g.nome,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => scegli(g.id),
                  ),
                AppListRow(
                  leading: const Icon(Icons.groups),
                  titolo: 'Tutti gli atleti',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => scegli(null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
