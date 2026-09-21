import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
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
import '../../../widgets/nascondi_barra_club.dart';

/// Schermata da bordo vasca (DESIGN.md sezione 9): bersagli grandi, niente
/// form, e — a scelta dell'allenatore — sfondo scuro (vedi
/// [temaBordoVascaOverrideProvider]).
class PresenzeScreen extends ConsumerWidget {
  const PresenzeScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      NascondiBarraClub(child: _costruisci(context, ref));

  Widget _costruisci(BuildContext context, WidgetRef ref) {
    final filter = (clubId: allenamento.clubId, includeInactive: false);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final presenzeAsync = ref.watch(presenzeListProvider(allenamento.id));
    final overrideVasca = ref.watch(temaBordoVascaOverrideProvider);
    final temaVasca = temaBordoVascaDa(overrideVasca);

    final scaffold = AppScaffold(
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
        data: (tuttiGliAtleti) {
          // Un allenamento con gruppo assegnato mostra solo gli atleti di
          // quel gruppo (bug: prima si vedevano — e si potevano segnare —
          // le presenze di tutto il club); un atleta senza gruppo
          // assegnato resta comunque visibile, non deve sparire
          // dall'elenco.
          final atleti = allenamento.gruppoId == null
              ? tuttiGliAtleti
              : tuttiGliAtleti
                    .where(
                      (a) =>
                          a.gruppoId == allenamento.gruppoId ||
                          a.gruppoId == null,
                    )
                    .toList();
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
    );

    if (temaVasca == null) return scaffold;
    return Theme(data: temaVasca, child: scaffold);
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
    final colori = context.colori;
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
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Presente',
                  icona: Icons.check,
                  colore: colori.ok,
                  selezionato: statoAttuale == 'presente',
                  onTap: () => onSelect('presente'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Assente',
                  icona: Icons.close,
                  colore: colori.testoSecondario,
                  selezionato: statoAttuale == 'assente',
                  onTap: () => onSelect('assente'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _BottoneStato(
                  etichetta: 'Giustificato',
                  icona: Icons.event_note_outlined,
                  colore: colori.attenzione,
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
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.controllo),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaBersaglioVasca,
        ),
        decoration: BoxDecoration(
          color: selezionato ? colore : colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          border: Border.all(color: selezionato ? colore : colori.linea),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icona,
              size: 24,
              color: selezionato ? colori.azioneInk : colori.testoSecondario,
            ),
            const SizedBox(height: 4),
            Text(
              etichetta,
              style: AppTypography.piccolo.copyWith(
                color: selezionato ? colori.azioneInk : colori.testoSecondario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
