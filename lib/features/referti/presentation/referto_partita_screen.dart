import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/referti_providers.dart';
import '../domain/referto_letto.dart';
import '../domain/referto_partita.dart';
import 'leggi_referto_screen.dart';

/// Mostra il referto gia' salvato per questa partita (risultato finale,
/// parziali, rose complete di reti/espulsioni), se esiste. Da qui si legge
/// anche un nuovo referto da una foto ("Leggi referto"), gia' assegnato a
/// questa partita; se ne esiste uno, "Rileggi referto" lo sostituisce.
class RefertoPartitaScreen extends ConsumerWidget {
  const RefertoPartitaScreen({required this.partita, super.key});

  final Partita partita;

  void _leggiReferto(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LeggiRefertoScreen(partita: partita)),
  );

  Future<void> _rileggiReferto(BuildContext context) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sostituire il referto salvato?'),
        content: const Text(
          'Leggendo una nuova foto, il referto attuale di questa partita '
          'viene sostituito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Sostituisci',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma == true && context.mounted) _leggiReferto(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refertoAsync = ref.watch(refertoPerPartitaProvider(partita.id));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Referto'),
        actions: [
          if (refertoAsync.value != null)
            IconButton(
              tooltip: 'Rileggi referto',
              onPressed: () => _rileggiReferto(context),
              icon: const Icon(Icons.document_scanner_outlined),
            ),
        ],
      ),
      body: refertoAsync.when(
        data: (referto) => referto == null
            ? EmptyState(
                icona: Icons.description_outlined,
                titolo: 'Nessun referto salvato',
                descrizione:
                    'Scatta o carica la foto del referto: i dati letti '
                    'vengono assegnati a questa partita.',
                azionePrincipale: 'Leggi referto',
                onAzionePrincipale: () => _leggiReferto(context),
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
    final colori = context.colori;
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
                  style: AppTypography.condensata(
                    AppTypography.numerica(
                      AppTypography.titoloXl.copyWith(color: colori.testo),
                    ),
                  ),
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
                    style: AppTypography.condensata(
                      AppTypography.numerica(
                        AppTypography.corpo.copyWith(color: colori.testo),
                      ),
                    ),
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
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titolo,
          style: AppTypography.sezione.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppListPanel(
          righe: [
            for (final g in giocatori)
              AppListRow(
                leading: CapBadge(numero: g.numeroCalottina),
                titolo: g.nome,
                trailing: Text(
                  '${g.reti} reti · ${g.espulsioni} esp.',
                  style: AppTypography.condensata(
                    AppTypography.numerica(
                      AppTypography.piccolo.copyWith(color: colori.testo),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
