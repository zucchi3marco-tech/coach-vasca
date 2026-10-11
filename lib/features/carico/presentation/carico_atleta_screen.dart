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
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/carico_providers.dart';
import '../domain/carico_rpe.dart';
import 'carico_settimane.dart';
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
                titolo: 'Nessuna seduta registrata',
                descrizione:
                    'Il carico si calcola dagli allenamenti con presenza '
                    'segnata come "presente", dalle partite con l\'atleta '
                    'in distinta e dalle sedute a cui ha dato l\'RPE: non '
                    'c\'è ancora niente da mostrare per questo atleta.',
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
                        'dal carico di ogni seduta: quanto è stata dura '
                        '(RPE da 0 a 10, detto dall\'atleta a fine seduta) '
                        'per quanti minuti è durata. Contano gli '
                        'allenamenti in cui era presente, il lavoro a secco '
                        'e le partite in cui era convocato (60 minuti). '
                        'Senza la sua risposta l\'RPE si stima dalle zone '
                        'delle serie. È un indice relativo utile per '
                        'valutare l\'andamento nel tempo, non un valore '
                        'fisiologico assoluto.',
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
                  _SezioneCarico(atleta: atleta),
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

/// Il carico settimana per settimana (acqua, secco, partita) e il
/// confronto della settimana con il solito (ACWR).
class _SezioneCarico extends ConsumerWidget {
  const _SezioneCarico({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seduteAsync = ref.watch(
      seduteCaricoProvider((atletaId: atleta.id, clubId: atleta.clubId)),
    );
    // Gli obiettivi di carico delle fasi della sua stagione.
    final stagioni =
        ref.watch(stagioniListProvider(atleta.clubId)).value ??
        const <Stagione>[];
    return seduteAsync.when(
      data: (sedute) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TitoloSezione(
            'Carico per settimana',
            spiegazione:
                'Il carico di una seduta è l\'RPE (quanto è stata dura, '
                'da 0 a 10) per i minuti: il metodo di Foster. L\'acqua '
                'e il secco vengono dagli allenamenti (i minuti delle '
                'serie a secco vanno nel secco), la partita dalle partite '
                'in cui era convocato. Le sedute senza la risposta '
                'dell\'atleta hanno un carico stimato dalle serie.',
          ),
          PoolCard(
            child: CaricoSettimane(
              sedute: sedute,
              obiettivoDi: (lunedi) => faseDellaSettimana(
                stagioni,
                atleta.gruppoId,
                lunedi,
              )?.obiettivoCarico,
            ),
          ),
          const SizedBox(height: AppSpacing.s28),
          const TitoloSezione(
            'Questa settimana e il solito',
            spiegazione:
                'Il rapporto fra il carico degli ultimi 7 giorni e la '
                'media settimanale delle ultime 4 settimane (ACWR). Fra '
                '0,8 e 1,3 la settimana è in linea con il solito; sopra '
                '1,5 il carico è salito molto in fretta. È un riferimento '
                'per programmare, non una diagnosi.',
          ),
          PoolCard(child: PannelloAcwr(acwr: calcolaAcwr(sedute))),
        ],
      ),
      loading: () => const LoadingSkeleton(height: 160),
      error: (error, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare il carico.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(error),
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
