import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/superfici_tema.dart';
import '../../../theme/tema_bordo_vasca_provider.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/presenze_providers.dart';
import '../data/presenze_repository.dart';

/// Schermata da bordo vasca (DESIGN.md sezione 9): bersagli grandi, niente
/// form, e — a scelta dell'allenatore — sfondo scuro (vedi
/// [temaBordoVascaScuroProvider]).
class PresenzeScreen extends ConsumerWidget {
  const PresenzeScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (clubId: allenamento.clubId, includeInactive: false);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final presenzeAsync = ref.watch(presenzeListProvider(allenamento.id));
    final scuro = ref.watch(temaBordoVascaScuroProvider);

    return Theme(
      data: scuro ? AppTheme.scuroBordoVasca : AppTheme.chiaro,
      child: AppScaffold(
        scrollabile: true,
        appBar: AppBar(
          title: Text(
            'Presenze — ${allenamento.data.day.toString().padLeft(2, '0')}/'
            '${allenamento.data.month.toString().padLeft(2, '0')}/'
            '${allenamento.data.year}',
          ),
          actions: const [BottoneTemaBordoVasca()],
        ),
        body: atletiAsync.when(
          data: (atleti) {
            // Nessun filtro per gruppo: si segnano le presenze di tutto il
            // club in un colpo, un atleta senza gruppo assegnato non deve
            // sparire dall'elenco.
            return presenzeAsync.when(
              data: (presenze) {
                if (atleti.isEmpty) {
                  return EmptyState(
                    icona: Icons.groups_outlined,
                    titolo: 'Nessun atleta attivo in questo club',
                    descrizione:
                        'Aggiungi gli atleti dalla schermata Atleti per poter '
                        'segnare le presenze.',
                    azionePrincipale: 'Torna indietro',
                    onAzionePrincipale: () => Navigator.of(context).pop(),
                  );
                }

                final statoPerAtleta = {
                  for (final p in presenze) p.atletaId: p.stato,
                };

                return AppListPanel(
                  righe: [
                    for (final atleta in atleti)
                      _RigaPresenza(
                        atleta: atleta,
                        statoAttuale: statoPerAtleta[atleta.id],
                        onSelect: (nuovoStato) => ref
                            .read(presenzeRepositoryProvider)
                            .segnaPresenza(
                              allenamentoId: allenamento.id,
                              atletaId: atleta.id,
                              stato: nuovoStato,
                            ),
                      ),
                  ],
                );
              },
              loading: () => const LoadingSkeletonList(righe: 6),
              error: (error, _) => ErrorBanner(
                messaggio: 'Non è stato possibile caricare le presenze.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            );
          },
          loading: () => const LoadingSkeletonList(righe: 6),
          error: (error, _) => ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli atleti.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

/// Riga di un atleta con i tre stati possibili come bersagli grandi — vedi
/// DESIGN.md sezione 9: a bordo vasca i dati si inseriscono con "bottoni
/// grandi", altezza minima 64, mai un form o un menu a tendina.
class _RigaPresenza extends StatelessWidget {
  const _RigaPresenza({
    required this.atleta,
    required this.statoAttuale,
    required this.onSelect,
  });

  final Atleta atleta;
  final String? statoAttuale;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tema = SuperficiTema.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            atleta.nomeCompleto,
            style: AppTypography.corpoForte.copyWith(color: tema.testo),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Presente',
                  icona: Icons.check,
                  colore: AppColors.ok,
                  selezionato: statoAttuale == 'presente',
                  onTap: () => onSelect('presente'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Assente',
                  icona: Icons.close,
                  colore: AppColors.testoSecondario,
                  selezionato: statoAttuale == 'assente',
                  onTap: () => onSelect('assente'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Giustificato',
                  icona: Icons.event_note_outlined,
                  colore: AppColors.attenzione,
                  selezionato: statoAttuale == 'giustificato',
                  onTap: () => onSelect('giustificato'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottoneStato extends StatelessWidget {
  const _BottoneStato({
    required this.etichetta,
    required this.icona,
    required this.colore,
    required this.selezionato,
    required this.onTap,
  });

  final String etichetta;
  final IconData icona;
  final Color colore;
  final bool selezionato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = SuperficiTema.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaBersaglioVasca,
        ),
        decoration: BoxDecoration(
          color: selezionato ? colore : tema.superficie,
          borderRadius: BorderRadius.circular(AppSpacing.raggioControllo),
          border: Border.all(color: selezionato ? colore : tema.linea),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icona,
              size: 24,
              color: selezionato ? Colors.white : tema.testoSecondario,
            ),
            const SizedBox(height: 4),
            Text(
              etichetta,
              style: AppTypography.piccolo.copyWith(
                color: selezionato ? Colors.white : tema.testoSecondario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
