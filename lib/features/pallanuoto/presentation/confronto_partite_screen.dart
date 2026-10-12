import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/titolo_due_righe.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/partita.dart';
import '../domain/statistiche_eventi.dart';
import 'voci_partita.dart';

/// Due partite affiancate, voce per voce, dagli eventi registrati dal
/// vivo: per capire cosa è cambiato fra una vittoria e una sconfitta, o
/// fra l'andata e il ritorno.
class ConfrontoPartiteScreen extends ConsumerWidget {
  const ConfrontoPartiteScreen({
    required this.prima,
    required this.seconda,
    super.key,
  });

  final Partita prima;
  final Partita seconda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaAsync = ref.watch(eventiPartitaListProvider(prima.id));
    final secondaAsync = ref.watch(eventiPartitaListProvider(seconda.id));
    final errore = primaAsync.error ?? secondaAsync.error;

    return AppScaffold(
      appBar: AppBar(
        toolbarHeight: TitoloDueRighe.altezzaBarraDueRighe,
        title: TitoloDueRighe(
          titolo: 'Confronto fra partite',
          sottotitolo: 'vs ${prima.avversario} e vs ${seconda.avversario}',
          righeSottotitolo: 2,
        ),
      ),
      body: errore != null
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli eventi.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(errore),
              ),
            )
          : primaAsync.value == null || secondaAsync.value == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: LoadingSkeletonList(righe: 6),
            )
          : _Tabella(
              prima: prima,
              seconda: seconda,
              statistichePrima: StatisticheEventi.da(primaAsync.value!),
              statisticheSeconda: StatisticheEventi.da(secondaAsync.value!),
            ),
    );
  }
}

class _Tabella extends StatelessWidget {
  const _Tabella({
    required this.prima,
    required this.seconda,
    required this.statistichePrima,
    required this.statisticheSeconda,
  });

  final Partita prima;
  final Partita seconda;
  final StatisticheEventi statistichePrima;
  final StatisticheEventi statisticheSeconda;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final a = statistichePrima.squadra;
    final b = statisticheSeconda.squadra;
    final completa =
        prima.eventiCompleti ||
        seconda.eventiCompleti ||
        a.haEventiCompleti ||
        b.haEventiCompleti;
    final senzaEventi = [
      if (statistichePrima.partite == 0) prima,
      if (statisticheSeconda.partite == 0) seconda,
    ];
    final stileValore = AppTypography.numerica(
      AppTypography.corpoForte.copyWith(color: colori.testo),
    );

    Widget riga(Widget etichetta, Widget valoreA, Widget valoreB) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: etichetta),
          const SizedBox(width: AppSpacing.s8),
          Expanded(flex: 2, child: valoreA),
          const SizedBox(width: AppSpacing.s8),
          Expanded(flex: 2, child: valoreB),
        ],
      ),
    );

    Widget testata(Partita p) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'vs ${p.avversario}',
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.corpoForte.copyWith(color: colori.testo),
        ),
        Text(
          dataCompatta(p.data),
          textAlign: TextAlign.end,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        for (final p in senzaEventi) ...[
          Text(
            'Per la partita vs ${p.avversario} non ci sono eventi registrati '
            'dal vivo.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        AppListPanel(
          righe: [
            riga(const SizedBox.shrink(), testata(prima), testata(seconda)),
            for (final voce in vociPartita)
              if (completa || !voce.completa)
                riga(
                  Text(
                    voce.etichetta,
                    style: AppTypography.corpo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  Text(
                    voce.valore(a),
                    textAlign: TextAlign.end,
                    style: stileValore,
                  ),
                  Text(
                    voce.valore(b),
                    textAlign: TextAlign.end,
                    style: stileValore,
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Superiorità e inferiorità si contano dalle espulsioni (non da '
          'rigore).',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}
