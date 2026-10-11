import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../carico/presentation/carico_settimane.dart' show formattaCarico;
import '../application/stagioni_providers.dart';
import '../domain/stagione.dart';
import 'fase_form_screen.dart';

/// "Fasi e obiettivi" nel dettaglio della stagione: le fasi in ordine,
/// con le date e gli obiettivi di ogni settimana; un tocco apre la fase.
/// Legge la stagione aggiornata dalla cache, così una fase appena salvata
/// compare subito.
class SezioneFasi extends ConsumerWidget {
  const SezioneFasi({required this.stagione, super.key});

  final Stagione stagione;

  String _obiettivi(FaseStagione f) {
    final parti = [
      if (f.obiettivoMetri case final m?) '${kmDaMetri(m)} km',
      if (f.obiettivoCarico case final c?) 'carico ${formattaCarico(c * 1.0)}',
    ];
    return parti.isEmpty
        ? 'Nessun obiettivo'
        : '${parti.join(' · ')} a settimana';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final aggiornata =
        ref
            .watch(stagioniListProvider(stagione.clubId))
            .value
            ?.where((s) => s.id == stagione.id)
            .firstOrNull ??
        stagione;
    final oggi = soloData(DateTime.now());

    void apri([int? indice]) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FaseFormScreen(stagione: aggiornata, indice: indice),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione(
          'Fasi e obiettivi',
          spiegazione:
              'Dividi la stagione in fasi (preparazione, andata, '
              'ritorno...) e scrivi quanto volume e quanto carico vuoi '
              'ogni settimana. Il grafico "Volume per settimana" degli '
              'allenamenti e quello del carico di ogni atleta mostrano '
              'l\'obiettivo accanto a quanto si è fatto.',
        ),
        if (aggiornata.fasi.isEmpty)
          Text(
            'Nessuna fase: aggiungine una per vedere gli obiettivi sui '
            'grafici.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          )
        else
          AppListPanel(
            righe: [
              for (final (i, f) in aggiornata.fasi.indexed)
                AppListRow(
                  titolo: f.nome,
                  extraTitolo:
                      !oggi.isBefore(f.dataInizio) && !oggi.isAfter(f.dataFine)
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.s8),
                          child: Pastiglia('In corso', colore: colori.ok),
                        )
                      : null,
                  sottotitolo:
                      '${dataCompatta(f.dataInizio)} – '
                      '${dataCompatta(f.dataFine)} · ${_obiettivi(f)}',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colori.testoSecondario,
                  ),
                  onTap: () => apri(i),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: SecondaryButton(
            label: 'Aggiungi fase',
            icon: Icons.add,
            expanded: false,
            onPressed: apri,
          ),
        ),
      ],
    );
  }
}
