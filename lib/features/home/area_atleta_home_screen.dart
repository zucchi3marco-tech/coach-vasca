import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_list_panel.dart';
import '../../widgets/app_list_row.dart';
import '../atleti/domain/atleta.dart';
import '../atleti/presentation/pb_list_screen.dart';
import '../carico/presentation/carico_atleta_screen.dart';
import '../club/application/current_club_provider.dart';
import '../presenze/presentation/mie_presenze_screen.dart';

/// Home dell'atleta collegato (FASE 9): mostrata da HomeScreen al posto
/// delle tab da coach quando l'account autenticato non e' membro di
/// nessun club ma e' collegato a un record atleti. Nessun Scaffold
/// proprio: e' incorporata nel body di HomeScreen, che ha gia' AppBar e
/// pulsante "Esci".
class AreaAtletaHomeScreen extends ConsumerWidget {
  const AreaAtletaHomeScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubAsync = ref.watch(currentClubProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(atleta.nomeCompleto, style: AppTypography.titoloXl),
            const SizedBox(height: AppSpacing.s4),
            clubAsync.when(
              data: (club) => Text(
                club?.nome ?? '',
                style: AppTypography.piccolo,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.s28),
            AppListPanel(
              righe: [
                AppListRow(
                  leading: const Icon(Icons.emoji_events_outlined),
                  titolo: 'I miei personal best',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PbListScreen(atleta: atleta),
                    ),
                  ),
                ),
                AppListRow(
                  leading: const Icon(Icons.show_chart),
                  titolo: 'Il mio carico',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CaricoAtletaScreen(atleta: atleta),
                    ),
                  ),
                ),
                AppListRow(
                  leading: const Icon(Icons.how_to_reg_outlined),
                  titolo: 'Le mie presenze',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MiePresenzeScreen(atleta: atleta),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
