import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../data/notifiche_repository.dart';
import '../domain/notifica.dart';

class NotificheScreen extends ConsumerWidget {
  const NotificheScreen({required this.clubId, super.key});

  final String clubId;

  IconData _icona(String tipo) => switch (tipo) {
    'convocazione_gara' => Icons.pool_outlined,
    'convocazione_partita' => Icons.sports_handball_outlined,
    'visita_medica' => Icons.medical_services_outlined,
    _ => Icons.person_add_alt_outlined,
  };

  Color _colore(BuildContext context, String tipo) => switch (tipo) {
    'convocazione_gara' => context.dominio.evidenzaAmbra,
    'convocazione_partita' => context.dominio.evidenzaAmbra,
    'visita_medica' => context.colori.rosso,
    _ => context.colori.azione,
  };

  /// "Oggi 14:30", "Ieri 09:05", "lunedì 5 ott 18:00".
  String _quando(DateTime data) {
    final d = data.toLocal();
    final giorno = traQuanto(d);
    final ora =
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return '${giorno == 'Oggi' || giorno == 'Ieri' ? giorno : dataEstesa(d)} '
        '$ora';
  }

  Future<void> _segnaLette(
    BuildContext context,
    WidgetRef ref,
    List<Notifica> notifiche,
  ) async {
    try {
      final repository = ref.read(notificheRepositoryProvider);
      for (final n in notifiche) {
        await repository.segnaLetta(n.id);
      }
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
    } finally {
      ref.invalidate(notificheNonLetteProvider(clubId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificheAsync = ref.watch(notificheNonLetteProvider(clubId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Notifiche')),
      body: notificheAsync.when(
        data: (notifiche) => notifiche.isEmpty
            ? EmptyState(
                icona: Icons.notifications_none_outlined,
                titolo: 'Nessuna notifica',
                descrizione: 'Le notifiche non lette compariranno qui.',
                azionePrincipale: 'Torna indietro',
                onAzionePrincipale: () => Navigator.of(context).maybePop(),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s32),
                children: [
                  TitoloSezione(
                    'Da leggere',
                    conteggio: notifiche.length,
                    // Con tante notifiche, una per una era lungo.
                    azione: notifiche.length > 1
                        ? 'Segna tutte come lette'
                        : null,
                    onAzione: () => _segnaLette(context, ref, notifiche),
                  ),
                  GrigliaSchede(
                    colonneMassime: 1,
                    figli: [
                      for (final n in notifiche)
                        SchedaElenco(
                          leading: IconaRiquadro(
                            _icona(n.tipo),
                            colore: _colore(context, n.tipo),
                            dimensione: 44,
                          ),
                          titolo: n.messaggio,
                          sottotitolo: _quando(n.creataIl),
                          mostraFreccia: false,
                          trailing: IconButton(
                            icon: const Icon(Icons.check_outlined),
                            tooltip: 'Segna come letta',
                            onPressed: () => _segnaLette(context, ref, [n]),
                          ),
                        ),
                    ],
                  ),
                ],
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
