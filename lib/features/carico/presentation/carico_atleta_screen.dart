import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../../atleti/domain/atleta.dart';
import '../application/carico_providers.dart';
import '../domain/banister.dart';

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
const _ordineEsecuzionePerVolume = [
  'nuoto',
  'gambe',
  'braccia',
  'pull',
  'tecnica',
  'remate',
];

String _formattaVolume(int metri) =>
    metri >= 1000 ? '${(metri / 1000).toStringAsFixed(1)} km' : '$metri m';

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
    final colori = context.colori;

    return AppScaffold(
      appBar: AppBar(title: Text('Carico — ${atleta.nomeCompleto}')),
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Modello Banister (fitness/fatica/forma) calcolato '
                      'dal volume di allenamento pesato per zona di '
                      'intensità, contato solo nei giorni in cui l\'atleta '
                      'era presente. È un indice relativo utile per '
                      'valutare l\'andamento nel tempo, non un valore '
                      'fisiologico assoluto.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatPanel(
                          etichetta: 'Fitness',
                          valore: punti.last.fitness.round().toString(),
                        ),
                        StatPanel(
                          etichetta: 'Fatica',
                          valore: punti.last.fatica.round().toString(),
                        ),
                        StatPanel(
                          etichetta: 'Forma',
                          valore: punti.last.forma.round().toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SizedBox(
                      height: 280,
                      child: _GraficoBanister(punti: punti),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const _Legenda(),
                    const SizedBox(height: AppSpacing.s28),
                    _SezioneVolumi(atletaId: atleta.id, clubId: atleta.clubId),
                  ],
                ),
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

class _GraficoBanister extends StatelessWidget {
  const _GraficoBanister({required this.punti});

  final List<PuntoBanister> punti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final dominio = context.dominio;
    List<FlSpot> spot(double Function(PuntoBanister) valore) => [
      for (var i = 0; i < punti.length; i++)
        FlSpot(i.toDouble(), valore(punti[i])),
    ];

    LineChartBarData linea(List<FlSpot> dati, Color colore) => LineChartBarData(
      spots: dati,
      isCurved: false,
      color: colore,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    final intervalloEtichette = (punti.length / 5).ceil().clamp(
      1,
      punti.length,
    );

    return LineChart(
      LineChartData(
        lineBarsData: [
          linea(spot((p) => p.fitness), dominio.curvaFitness(colori)),
          linea(spot((p) => p.fatica), dominio.curvaFatica(colori)),
          linea(spot((p) => p.forma), dominio.curvaForma(colori)),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: intervalloEtichette.toDouble(),
              getTitlesWidget: (value, meta) {
                final indice = value.round();
                if (indice < 0 || indice >= punti.length) {
                  return const SizedBox.shrink();
                }
                final data = punti[indice].data;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Text(
                    '${data.day.toString().padLeft(2, '0')}/'
                    '${data.month.toString().padLeft(2, '0')}',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final dominio = context.dominio;
    Widget voce(Color colore, String etichetta) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: AppSpacing.s12, height: AppSpacing.s12, color: colore),
        const SizedBox(width: AppSpacing.s4),
        Text(
          etichetta,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpacing.s16,
      children: [
        voce(dominio.curvaFitness(colori), 'Fitness'),
        voce(dominio.curvaFatica(colori), 'Fatica'),
        voce(dominio.curvaForma(colori), 'Forma'),
      ],
    );
  }
}

/// Volume totale e scomposto per zona/tipo di lavoro (FASE 9): stesso
/// perimetro dati del grafico Banister sopra (solo presenze segnate
/// "presente"), ma come somma di metri invece che curva pesata.
class _SezioneVolumi extends ConsumerWidget {
  const _SezioneVolumi({required this.atletaId, required this.clubId});

  final String atletaId;
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumiAsync = ref.watch(
      volumiAtletaProvider((atletaId: atletaId, clubId: clubId)),
    );
    final colori = context.colori;

    return volumiAsync.when(
      data: (volumi) {
        final zoneOrdinate = [
          for (final z in _ordineZonePerVolume)
            if (volumi.perZona.containsKey(z)) z,
        ];
        final esecuzioniOrdinate = [
          for (final e in _ordineEsecuzionePerVolume)
            if (volumi.perEsecuzione.containsKey(e)) e,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader('Volume'),
            const SizedBox(height: AppSpacing.s16),
            StatPanel(
              etichetta: 'Volume totale',
              valore: _formattaVolume(volumi.volumeTotaleM),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Per zona',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (zoneOrdinate.isEmpty)
              Text(
                'Nessuna serie con zona indicata.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.s24,
                runSpacing: AppSpacing.s16,
                children: [
                  for (final z in zoneOrdinate)
                    StatPanel(
                      etichetta: z,
                      valore: _formattaVolume(volumi.perZona[z]!),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Per tipo di lavoro',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (esecuzioniOrdinate.isEmpty)
              Text(
                'Nessuna serie registrata.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.s24,
                runSpacing: AppSpacing.s16,
                children: [
                  for (final e in esecuzioniOrdinate)
                    StatPanel(
                      etichetta: labelEsecuzione(e),
                      valore: _formattaVolume(volumi.perEsecuzione[e]!),
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
