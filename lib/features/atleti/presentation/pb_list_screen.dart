import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../application/personal_best_providers.dart';
import '../domain/atleta.dart';
import '../domain/pb_slots.dart';
import '../domain/personal_best.dart';
import 'pb_form_screen.dart';

/// Tabella di tutti i personal best possibili per lo sport dell'atleta
/// (FASE 10, punto 3): ogni combinazione stile+distanza è sempre
/// visibile, registrata o no, così si vede a colpo d'occhio cosa manca.
class PbListScreen extends ConsumerWidget {
  const PbListScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync = ref.watch(personalBestListProvider(atleta.id));

    void apriForm({
      required String stile,
      required int distanzaM,
      PersonalBest? personalBest,
    }) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PbFormScreen(
          atleta: atleta,
          stile: stile,
          distanzaM: distanzaM,
          personalBest: personalBest,
        ),
      ),
    );

    return AppScaffold(
      appBar: AppBar(title: Text('Personal best — ${atleta.nomeCompleto}')),
      body: pbAsync.when(
        data: (righe) {
          // Il piu' veloce, se per qualche motivo ci fosse piu' di un
          // tempo salvato per la stessa combinazione stile+distanza.
          final migliorePerSlot = <String, PersonalBest>{};
          for (final pb in righe) {
            final chiave = '${pb.stile}_${pb.distanzaM}';
            final attuale = migliorePerSlot[chiave];
            if (attuale == null || pb.tempoS < attuale.tempoS) {
              migliorePerSlot[chiave] = pb;
            }
          }

          final slots = slotsPerSport(atleta.sport);
          final stiliOrdinati = <String>[];
          for (final s in slots) {
            if (!stiliOrdinati.contains(s.stile)) stiliOrdinati.add(s.stile);
          }
          final mostraIntestazioni = stiliOrdinati.length > 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final stile in stiliOrdinati) ...[
                  if (mostraIntestazioni) ...[
                    SectionHeader(capitalizzaParola(stile)),
                    const SizedBox(height: AppSpacing.s8),
                  ],
                  AppListPanel(
                    righe: [
                      for (final slot in slots.where((s) => s.stile == stile))
                        _rigaSlot(
                          slot: slot,
                          pb: migliorePerSlot['${slot.stile}_${slot.distanzaM}'],
                          onTap: () => apriForm(
                            stile: slot.stile,
                            distanzaM: slot.distanzaM,
                            personalBest:
                                migliorePerSlot['${slot.stile}_${slot.distanzaM}'],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                ],
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i personal best.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }

  AppListRow _rigaSlot({
    required SlotPersonalBest slot,
    required PersonalBest? pb,
    required VoidCallback onTap,
  }) {
    return AppListRow(
      titolo: '${slot.distanzaM}m ${capitalizzaParola(slot.stile)}',
      sottotitolo: pb != null ? formatPaceSeconds(pb.tempoS) : 'Non registrato',
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
