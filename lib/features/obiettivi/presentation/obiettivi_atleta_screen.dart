import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/premibile.dart';
import '../../atleti/domain/atleta.dart';
import '../data/obiettivi_repository.dart';
import '../domain/scheda_obiettivi.dart';
import 'risposta_obiettivi_screen.dart';

/// Le schede dell'[atleta] con le sue risposte: da compilare, mandate,
/// con il ritorno dell'allenatore.
typedef SchedaDellAtleta = ({
  SchedaObiettivi scheda,
  RispostaObiettivi? risposta,
});

/// Le schede che arrivano all'atleta, le più recenti prima, con la sua
/// risposta se c'è. null finché non si sono lette.
List<SchedaDellAtleta>? schedeDellAtleta(WidgetRef ref, Atleta atleta) {
  final schede = ref.watch(schedeObiettiviProvider(atleta.clubId)).value;
  final risposte = ref.watch(risposteAtletaObiettiviProvider(atleta.id)).value;
  if (schede == null || risposte == null) return null;
  final perScheda = {for (final r in risposte) r.schedaId: r};
  return [
    for (final s in schede)
      if (s.perAtleta(atleta)) (scheda: s, risposta: perScheda[s.id]),
  ];
}

void apriSchedaAtleta(
  BuildContext context,
  Atleta atleta,
  SchedaDellAtleta voce, {
  bool vistaAllenatore = false,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => RispostaObiettiviScreen(
      scheda: voce.scheda,
      atleta: atleta,
      risposta: voce.risposta,
      // L'allenatore che apre la pagina dell'atleta scrive il ritorno
      // (se l'atleta ha risposto) o legge soltanto.
      perAllenatore: vistaAllenatore,
    ),
  ),
);

String statoScheda(SchedaDellAtleta voce, {bool vistaAllenatore = false}) {
  final r = voce.risposta;
  if (r == null) {
    if (voce.scheda.chiusa) return 'Chiusa senza risposta';
    return vistaAllenatore ? 'Non ha ancora risposto' : 'Da compilare';
  }
  if (r.ritorno != null) {
    return vistaAllenatore
        ? 'Ritorno scritto'
        : 'C\'è il ritorno dell\'allenatore';
  }
  return 'Mandata ${dataCompatta(r.inviataAt)}';
}

/// «I miei obiettivi»: tutte le schede dell'atleta.
class ObiettiviAtletaScreen extends ConsumerWidget {
  const ObiettiviAtletaScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;
  final bool vistaAllenatore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final errore =
        ref.watch(schedeObiettiviProvider(atleta.clubId)).error ??
        ref.watch(risposteAtletaObiettiviProvider(atleta.id)).error;
    final voci = schedeDellAtleta(ref, atleta);

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(vistaAllenatore ? 'Obiettivi' : 'I miei obiettivi'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errore != null)
            ErrorBanner(messaggio: messaggioErrore(errore))
          else if (voci == null)
            const LoadingSkeletonList()
          else if (voci.isEmpty)
            Text(
              vistaAllenatore
                  ? 'Nessuna scheda obiettivi per ${atleta.nome}: le mandi '
                        'dalla pagina della stagione.'
                  : 'Nessuna scheda per ora: quando l\'allenatore ne manda '
                        'una la trovi qui e nella home.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            )
          else
            AppListPanel(
              righe: [
                for (final v in voci)
                  AppListRow(
                    titolo: v.scheda.titolo,
                    sottotitolo: statoScheda(
                      v,
                      vistaAllenatore: vistaAllenatore,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colori.testoSecondario,
                    ),
                    // L'allenatore apre solo quelle con una risposta.
                    onTap: vistaAllenatore && v.risposta == null
                        ? null
                        : () => apriSchedaAtleta(
                            context,
                            atleta,
                            v,
                            vistaAllenatore: vistaAllenatore,
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Nella home dell'atleta, in «In programma»: le schede aperte a cui non
/// ha ancora risposto. Non compare se non ce ne sono (o senza rete); il
/// ritorno dell'allenatore arriva come avviso e si legge in «I miei
/// obiettivi».
class CardSchedeObiettivi extends ConsumerWidget {
  const CardSchedeObiettivi({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voci = schedeDellAtleta(ref, atleta);
    final daFare = [
      for (final v in voci ?? const <SchedaDellAtleta>[])
        if (v.risposta == null && !v.scheda.chiusa) v,
    ];
    if (daFare.isEmpty) return const SizedBox.shrink();
    final colori = context.colori;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Column(
        children: [
          for (final (i, v) in daFare.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s12),
            Premibile(
              etichetta:
                  'Scheda da compilare: ${v.scheda.titolo}. Apri per '
                  'rispondere',
              onTap: () => apriSchedaAtleta(context, atleta, v),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colori.superficie,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colori.linea),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colori.azioneTenue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.flag_outlined, color: colori.azione),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheda da compilare',
                            style: AppTypography.etichetta.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.scheda.titolo,
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.scheda.domande.length == 1
                                ? '1 domanda dall\'allenatore'
                                : '${v.scheda.domande.length} domande '
                                      'dall\'allenatore',
                            style: AppTypography.piccolo.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: colori.azione),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
