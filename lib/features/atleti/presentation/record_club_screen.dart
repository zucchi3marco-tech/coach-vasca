import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../application/atleti_providers.dart';
import '../application/personal_best_providers.dart';
import '../domain/pb_slots.dart';
import 'scheda_tempo.dart';

/// Record del club, per stile+distanza (FASE 11): al posto della
/// programmazione a settimane, la scheda di una stagione "nuoto" mostra
/// qui il tempo migliore mai registrato dal club in ogni gara, con
/// l'atleta che lo detiene — non filtrati per data della stagione, dato
/// che [PersonalBest.data] è facoltativo e spesso assente.
class RecordClubScreen extends ConsumerWidget {
  const RecordClubScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: false)),
    );
    final pbAsync = ref.watch(personalBestClubProvider(clubId));

    return AppScaffold(
      // Il titolo sta in grande nella testata.
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: atletiAsync.when(
        data: (atleti) => pbAsync.when(
          data: (pb) {
            final nomiNuotatori = {
              for (final a in atleti)
                if (a.sport == 'nuoto') a.id: a.nomeCompleto,
            };
            if (nomiNuotatori.isEmpty) {
              return EmptyState(
                icona: Icons.emoji_events_outlined,
                titolo: 'Nessun nuotatore nel club',
                descrizione:
                    'I record compaiono qui appena ci sono atleti di '
                    'nuoto con un personal best registrato.',
                azionePrincipale: 'Torna indietro',
                onAzionePrincipale: () => Navigator.of(context).pop(),
              );
            }

            ({String nome, double tempo})? migliorePerSlot(
              String stile,
              int distanzaM,
            ) {
              ({String nome, double tempo})? migliore;
              for (final p in pb) {
                if (p.stile != stile || p.distanzaM != distanzaM) continue;
                final nome = nomiNuotatori[p.atletaId];
                if (nome == null) continue;
                if (migliore == null || p.tempoS < migliore.tempo) {
                  migliore = (nome: nome, tempo: p.tempoS);
                }
              }
              return migliore;
            }

            final slots = slotsPerSport('nuoto');
            final registrati = slots
                .where((s) => migliorePerSlot(s.stile, s.distanzaM) != null)
                .length;

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s32),
              children: [
                TestataPagina(
                  titolo: 'Record del club',
                  sottotitolo:
                      'Il tempo migliore mai registrato dal club in ogni '
                      'gara, con chi lo detiene.',
                  numeri: [
                    NumeroTestata(
                      valore: '$registrati/${slots.length}',
                      etichetta: 'Gare con un record',
                    ),
                    NumeroTestata(
                      valore: '${nomiNuotatori.length}',
                      etichetta: 'Nuotatori',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                for (final stile in stiliNuoto) ...[
                  TitoloSezione(capitalizzaParola(stile)),
                  GrigliaSchede(
                    larghezzaMinimaColonna: 150,
                    colonneMassime: 4,
                    cascata: false,
                    figli: [
                      for (final slot in slots.where((s) => s.stile == stile))
                        Builder(
                          builder: (context) {
                            final r = migliorePerSlot(
                              slot.stile,
                              slot.distanzaM,
                            );
                            return SchedaTempo(
                              distanza: '${slot.distanzaM} m',
                              tempo: r == null
                                  ? null
                                  : formatPaceSeconds(r.tempo),
                              sotto: r?.nome,
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: LoadingSkeletonList(righe: 5),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: ErrorBanner(
              messaggio: 'Non è stato possibile caricare i record.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
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
