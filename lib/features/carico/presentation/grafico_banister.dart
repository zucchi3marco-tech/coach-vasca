import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../domain/banister.dart';

/// Grafico a linee del modello Banister (fitness/fatica/forma) — DESIGN.md
/// sezione 7: Fitness `azione`, Fatica `attenzione`, Forma `ok` (via
/// [TokenDominio.curvaFitness] e affini), mai `rosso`, riservato
/// esclusivamente a "in corso" ed errori (sezione 3). Riusato da
/// `CaricoAtletaScreen` (dettaglio completo) e dalla card "Andamento"
/// della dashboard atleta (in forma compatta).
class GraficoBanister extends StatelessWidget {
  const GraficoBanister({required this.punti, super.key});

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
          leftTitles: const AxisTitles(
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

/// Legenda del [GraficoBanister] — stesso schema colore/etichetta.
class LegendaBanister extends StatelessWidget {
  const LegendaBanister({super.key});

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
