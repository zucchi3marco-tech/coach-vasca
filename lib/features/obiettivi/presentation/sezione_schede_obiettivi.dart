import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../stagioni/domain/stagione.dart';
import '../data/obiettivi_repository.dart';
import '../domain/scheda_obiettivi.dart';
import 'nuova_scheda_screen.dart';
import 'scheda_obiettivi_screen.dart';

/// «Schede obiettivi» nel dettaglio della stagione: quelle mandate agli
/// atleti, la più recente in cima, e «Nuova scheda».
class SezioneSchedeObiettivi extends ConsumerWidget {
  const SezioneSchedeObiettivi({required this.stagione, super.key});

  final Stagione stagione;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final async = ref.watch(schedeObiettiviProvider(stagione.clubId));
    final schede = [
      for (final s in async.value ?? const <SchedaObiettivi>[])
        if (s.stagioneId == stagione.id) s,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione(
          'Schede obiettivi',
          spiegazione:
              'Scegli le domande e mandale agli atleti della stagione: '
              'ognuno risponde dalla sua home e tu scrivi due righe di '
              'ritorno. Puoi farne quante vuoi, per esempio una a inizio '
              'stagione e una a metà.',
        ),
        if (async.hasError)
          Text(
            'Le schede non si leggono: ${messaggioErrore(async.error!)}',
            style: AppTypography.piccolo.copyWith(color: colori.rosso),
          )
        else if (schede.isEmpty && !async.isLoading)
          Text(
            'Nessuna scheda per questa stagione.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          )
        else if (schede.isNotEmpty)
          AppListPanel(
            righe: [
              for (final s in schede)
                AppListRow(
                  titolo: s.titolo,
                  extraTitolo: s.chiusa
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s8),
                          child: Pastiglia(
                            'Chiusa',
                            colore: colori.testoSecondario,
                          ),
                        )
                      : null,
                  sottotitolo:
                      '${s.domande.length == 1 ? '1 domanda' : '${s.domande.length} domande'}'
                      ' · mandata ${dataCompatta(s.createdAt)}',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colori.testoSecondario,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SchedaObiettiviScreen(scheda: s),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: SecondaryButton(
            label: 'Nuova scheda',
            icon: Icons.add,
            expanded: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NuovaSchedaScreen(
                  stagione: stagione,
                  giaFatte: schede.length,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
