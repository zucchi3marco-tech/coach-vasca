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
import '../data/notifiche_repository.dart';
import '../domain/notifica.dart';

class NotificheScreen extends ConsumerWidget {
  const NotificheScreen({required this.clubId, super.key});

  final String clubId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year} ${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}';

  Future<void> _segnaLetta(
    BuildContext context,
    WidgetRef ref,
    Notifica notifica,
  ) async {
    try {
      await ref.read(notificheRepositoryProvider).segnaLetta(notifica.id);
      ref.invalidate(notificheNonLetteProvider(clubId));
    } catch (e) {
      // Senza rete (o con un errore del server) la notifica resta non
      // letta: meglio dirlo che far credere che sia andata a buon fine.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Non è stato possibile segnarla come letta: '
              '${messaggioErrore(e)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificheAsync = ref.watch(notificheNonLetteProvider(clubId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: notificheAsync.when(
        data: (notifiche) => notifiche.isEmpty
            ? const EmptyState(
                icona: Icons.notifications_none_outlined,
                titolo: 'Nessuna notifica',
                descrizione: 'Le notifiche non lette compariranno qui.',
                azionePrincipale: 'Torna indietro',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: AppListPanel(
                  righe: [
                    for (final n in notifiche)
                      AppListRow(
                        leading: const Icon(Icons.person_add_alt_outlined),
                        titolo: n.messaggio,
                        sottotitolo: _formattaData(n.creataIl),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_outlined),
                          tooltip: 'Segna come letta',
                          onPressed: () => _segnaLetta(context, ref, n),
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
            messaggio: 'Non è stato possibile caricare le notifiche.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}
