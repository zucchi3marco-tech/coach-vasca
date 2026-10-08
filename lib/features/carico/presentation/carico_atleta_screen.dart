import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/domain/serie.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/domain/atleta.dart';
import '../application/carico_providers.dart';
import 'grafico_banister.dart';

const _ordineZonePerVolume = [
  'A1',
  'A2',
  'B1',
  'B2',
  'C1',
  'C2',
  'C3',
  'C',
  'D',
];

String _formattaVolume(int metri) =>
    metri >= 1000 ? '${(metri / 1000).toStringAsFixed(1)} km' : '$metri m';

/// 2700 -> "45'", 9000 -> "2h30'", 7200 -> "2h".
String formattaTempoLavoro(int secondi) {
  if (secondi < 60) return formatDurataS(secondi);
  final minuti = (secondi / 60).round();
  if (minuti < 60) return "$minuti'";
  final resto = minuti % 60;
  return resto == 0
      ? '${minuti ~/ 60}h'
      : "${minuti ~/ 60}h${resto.toString().padLeft(2, '0')}'";
}

/// Un riquadro con i metri e/o il tempo di lavoro: i metri in grande e il
/// tempo sotto quando ci sono entrambi ("nuoto" a distanza e a tempo),
/// il solo tempo per il lavoro a tempo (palleggio, tattica).
StatPanel _pannelloVolume(String etichetta, int metri, int secondi) =>
    StatPanel(
      etichetta: etichetta,
      valore: metri == 0 && secondi > 0
          ? formattaTempoLavoro(secondi)
          : _formattaVolume(metri),
      confronto: metri > 0 && secondi > 0
          ? '+ ${formattaTempoLavoro(secondi)} a tempo'
          : null,
    );

/// Palette dei grafici a linee — DESIGN.md sezione 7: Fitness `azione`,
/// Fatica `attenzione`, Forma `ok` (via [TokenDominio.curvaFitness] e
/// affini), mai `rosso`, riservato esclusivamente a "in corso" ed
/// errori (sezione 3).
class CaricoAtletaScreen extends ConsumerWidget {
  const CaricoAtletaScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntiAsync = ref.watch(
      andamentoCaricoProvider((atletaId: atleta.id, clubId: atleta.clubId)),
    );

    return AppScaffold(
      appBar: AppBar(),
      body: puntiAsync.when(
        data: (punti) => punti.isEmpty
            ? EmptyState(
                icona: Icons.show_chart,
                titolo: 'Nessuna presenza registrata',
                descrizione:
                    'Il carico si calcola dagli allenamenti con presenza '
                    'segnata come "presente": non c\'è ancora niente da '
                    'mostrare per questo atleta.',
                azionePrincipale: 'Torna indietro',
                onAzionePrincipale: () => Navigator.of(context).pop(),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s32),
                children: [
                  // I tre valori di oggi in testata; la spiegazione del
                  // modello dietro la "i" del grafico.
                  TestataPagina(
                    occhiello: atleta.nomeCompleto,
                    titolo: 'Forma e carico',
                    numeri: [
                      NumeroTestata(
                        valore: punti.last.forma.round().toString(),
                        etichetta: 'Forma',
                      ),
                      NumeroTestata(
                        valore: punti.last.fitness.round().toString(),
                        etichetta: 'Fitness',
                      ),
                      NumeroTestata(
                        valore: punti.last.fatica.round().toString(),
                        etichetta: 'Fatica',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  const TitoloSezione(
                    'Andamento',
                    spiegazione:
                        'Modello Banister (fitness/fatica/forma) calcolato '
                        'dal volume di allenamento pesato per zona di '
                        'intensità, contato solo nei giorni in cui '
                        'l\'atleta era presente. Il lavoro a tempo '
                        '(palleggio, tattica, a secco) vale i metri che si '
                        'nuotano in quel tempo al passo medio (1\'50" ogni '
                        '100 m). È un indice relativo utile per valutare '
                        'l\'andamento nel tempo, non un valore fisiologico '
                        'assoluto.',
                  ),
                  PoolCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 280,
                          child: GraficoBanister(punti: punti),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        const LegendaBanister(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s28),
                  _SezioneVolumi(atletaId: atleta.id, clubId: atleta.clubId),
                ],
              ),

        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeleton(height: 280),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare il carico.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

/// Volume totale e scomposto per zona/tipo di lavoro (FASE 9): stesso
/// perimetro dati del grafico Banister sopra (solo presenze segnate
/// "presente"), ma come somma di metri — e di tempo, per il lavoro a
/// tempo — invece che curva pesata.
class _SezioneVolumi extends ConsumerWidget {
  const _SezioneVolumi({required this.atletaId, required this.clubId});

  final String atletaId;
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumiAsync = ref.watch(
      volumiAtletaProvider((atletaId: atletaId, clubId: clubId)),
    );

    return volumiAsync.when(
      data: (volumi) {
        final zoneOrdinate = [
          for (final z in _ordineZonePerVolume)
            if (volumi.perZona.containsKey(z) ||
                volumi.tempoPerZona.containsKey(z))
              z,
        ];
        final esecuzioniOrdinate = [
          for (final e in esecuzioniSerie)
            if (volumi.perEsecuzione.containsKey(e) ||
                volumi.tempoPerEsecuzione.containsKey(e))
              e,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TitoloSezione('Volume'),
            GrigliaNumeri(
              children: [
                StatPanel(
                  etichetta: 'Volume totale',
                  valore: _formattaVolume(volumi.volumeTotaleM),
                ),
                if (volumi.tempoTotaleS > 0)
                  StatPanel(
                    etichetta: 'Lavoro a tempo',
                    valore: formattaTempoLavoro(volumi.tempoTotaleS),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            const TitoloSezione('Per zona'),
            if (zoneOrdinate.isEmpty)
              const RiquadroVuoto('Nessuna serie con zona indicata.')
            else
              GrigliaNumeri(
                children: [
                  for (final z in zoneOrdinate)
                    _pannelloVolume(
                      z,
                      volumi.perZona[z] ?? 0,
                      volumi.tempoPerZona[z] ?? 0,
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.s24),
            const TitoloSezione('Per tipo di lavoro'),
            if (esecuzioniOrdinate.isEmpty)
              const RiquadroVuoto('Nessuna serie registrata.')
            else
              GrigliaNumeri(
                children: [
                  for (final e in esecuzioniOrdinate)
                    _pannelloVolume(
                      labelEsecuzione(e),
                      volumi.perEsecuzione[e] ?? 0,
                      volumi.tempoPerEsecuzione[e] ?? 0,
                    ),
                ],
              ),
          ],
        );
      },
      loading: () => const LoadingSkeleton(height: 120),
      error: (error, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare i volumi.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(error),
      ),
    );
  }
}
