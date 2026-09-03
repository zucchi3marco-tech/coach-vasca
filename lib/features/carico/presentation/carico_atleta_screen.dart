import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/domain/atleta.dart';
import '../application/carico_providers.dart';
import '../domain/banister.dart';

class CaricoAtletaScreen extends ConsumerWidget {
  const CaricoAtletaScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntiAsync = ref.watch(
      andamentoCaricoProvider((atletaId: atleta.id, clubId: atleta.clubId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Carico — ${atleta.nomeCompleto}')),
      body: SafeArea(
        child: puntiAsync.when(
          data: (punti) => punti.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nessuna presenza registrata per questo atleta: '
                      'niente da mostrare finché non ci sono allenamenti '
                      'con presenza segnata come "presente".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _RiepilogoAttuale(punto: punti.last),
                      const SizedBox(height: 16),
                      SizedBox(height: 280, child: _GraficoBanister(punti: punti)),
                      const SizedBox(height: 12),
                      _Legenda(),
                    ],
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(messaggioErrore(error))),
        ),
      ),
    );
  }
}

class _RiepilogoAttuale extends StatelessWidget {
  const _RiepilogoAttuale({required this.punto});

  final PuntoBanister punto;

  @override
  Widget build(BuildContext context) {
    String arrotonda(double v) => v.round().toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ValoreOggi(etichetta: 'Fitness', valore: arrotonda(punto.fitness)),
        _ValoreOggi(etichetta: 'Fatica', valore: arrotonda(punto.fatica)),
        _ValoreOggi(etichetta: 'Forma', valore: arrotonda(punto.forma)),
      ],
    );
  }
}

class _ValoreOggi extends StatelessWidget {
  const _ValoreOggi({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valore, style: Theme.of(context).textTheme.headlineSmall),
        Text(etichetta, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _GraficoBanister extends StatelessWidget {
  const _GraficoBanister({required this.punti});

  final List<PuntoBanister> punti;

  @override
  Widget build(BuildContext context) {
    final colori = Theme.of(context).colorScheme;
    final coloreFitness = colori.primary;
    final coloreFatica = colori.error;
    const coloreForma = Colors.green;

    List<FlSpot> spot(double Function(PuntoBanister) valore) => [
      for (var i = 0; i < punti.length; i++) FlSpot(i.toDouble(), valore(punti[i])),
    ];

    LineChartBarData linea(List<FlSpot> dati, Color colore) => LineChartBarData(
      spots: dati,
      isCurved: false,
      color: colore,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    final intervalloEtichette = (punti.length / 5).ceil().clamp(1, punti.length);

    return LineChart(
      LineChartData(
        lineBarsData: [
          linea(spot((p) => p.fitness), coloreFitness),
          linea(spot((p) => p.fatica), coloreFatica),
          linea(spot((p) => p.forma), coloreForma),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${data.day.toString().padLeft(2, '0')}/'
                    '${data.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10),
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
  @override
  Widget build(BuildContext context) {
    final colori = Theme.of(context).colorScheme;
    Widget voce(Color colore, String etichetta) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: colore),
        const SizedBox(width: 4),
        Text(etichetta, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: 16,
      children: [
        voce(colori.primary, 'Fitness'),
        voce(colori.error, 'Fatica'),
        voce(Colors.green, 'Forma'),
      ],
    );
  }
}
