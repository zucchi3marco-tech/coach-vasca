import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/referti_providers.dart';
import '../domain/referto_letto.dart';
import '../domain/referto_partita.dart';

/// Mostra il referto gia' salvato per questa partita (risultato finale,
/// parziali, rose complete di reti/espulsioni), se esiste. Il salvataggio
/// vero e proprio avviene da "Leggi referto" (tab Partite): questa
/// schermata e' solo di consultazione.
class RefertoPartitaScreen extends ConsumerWidget {
  const RefertoPartitaScreen({required this.partita, super.key});

  final Partita partita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refertoAsync = ref.watch(refertoPerPartitaProvider(partita.id));

    return AppScaffold(
      appBar: AppBar(title: const Text('Referto')),
      body: refertoAsync.when(
        data: (referto) => referto == null
            ? EmptyState(
                icona: Icons.description_outlined,
                titolo: 'Nessun referto salvato',
                descrizione:
                    'Usa "Leggi referto" dalla lista partite per '
                    'digitalizzarne uno da una foto.',
                azionePrincipale: 'Torna indietro',
                onAzionePrincipale: () => Navigator.of(context).pop(),
              )
            : _RefertoSalvatoView(referto: referto),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 6),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare il referto.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

class _RefertoSalvatoView extends StatelessWidget {
  const _RefertoSalvatoView({required this.referto});

  final RefertoPartita referto;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  '${referto.squadraCasa}   '
                  '${referto.risultatoCasa} - ${referto.risultatoTrasferta}'
                  '   ${referto.squadraTrasferta}',
                  style: AppTypography.cifreTabulari(AppTypography.titoloXl),
                  textAlign: TextAlign.center,
                ),
                if (referto.parziali.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    [
                      for (var i = 0; i < referto.parziali.length; i++)
                        'T${i + 1}: ${referto.parziali[i].casa}-'
                            '${referto.parziali[i].trasferta}',
                    ].join('   '),
                    style: AppTypography.cifreTabulari(AppTypography.corpo),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _TabellaGiocatoriSalvata(
            titolo: referto.squadraCasa,
            giocatori: referto.giocatoriCasa,
          ),
          const SizedBox(height: AppSpacing.s24),
          _TabellaGiocatoriSalvata(
            titolo: referto.squadraTrasferta,
            giocatori: referto.giocatoriTrasferta,
          ),
        ],
      ),
    );
  }
}

class _TabellaGiocatoriSalvata extends StatelessWidget {
  const _TabellaGiocatoriSalvata({
    required this.titolo,
    required this.giocatori,
  });

  final String titolo;
  final List<GiocatoreReferto> giocatori;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: AppTypography.sezione),
        const SizedBox(height: AppSpacing.s8),
        AppListPanel(
          righe: [
            for (final g in giocatori)
              AppListRow(
                leading: CapBadge(numero: g.numeroCalottina),
                titolo: g.nome,
                trailing: Text(
                  '${g.reti} reti · ${g.espulsioni} esp.',
                  style: AppTypography.cifreTabulari(
                    AppTypography.piccolo.copyWith(color: AppColors.testo),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
