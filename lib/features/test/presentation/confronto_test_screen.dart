import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/test_club_providers.dart';
import '../domain/test_club.dart';

/// Il colore di ogni atleta nel confronto (fino a cinque): la tavolozza
/// dei dati dell'app, mai il rosso (DESIGN.md, sezione 7).
List<Color> coloriConfronto(BuildContext context) {
  final dominio = context.dominio;
  return [
    context.colori.azione,
    dominio.evidenzaAmbra,
    dominio.evidenzaVerde,
    dominio.evidenzaViola,
    dominio.evidenzaCiano,
  ];
}

/// Due-cinque atleti nello stesso test: come sono andati nel tempo (un
/// punto per ogni volta che l'hanno fatto) e, con più prove, le prove
/// dell'ultima volta una accanto all'altra — si vede chi cala.
class ConfrontoTestScreen extends ConsumerWidget {
  const ConfrontoTestScreen({
    required this.test,
    required this.atletiIds,
    super.key,
  });

  final TestClub test;
  final List<String> atletiIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final tinte = coloriConfronto(context);
    final risultati =
        ref.watch(risultatiTestClubProvider(test.clubId)).value ?? const [];
    final perId = {
      for (final a
          in ref
                  .watch(
                    atletiListProvider((
                      clubId: test.clubId,
                      includeInactive: true,
                    )),
                  )
                  .value ??
              const <Atleta>[])
        a.id: a,
    };
    final atleti = [for (final id in atletiIds) ?perId[id]];
    final storici = [
      for (final a in atleti) storicoAtleta(test, risultati, a.id),
    ];

    return AppScaffold(
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: test.nome,
            titolo: 'Confronto',
            sottotitolo: descrizioneMisuraBreve(test),
          ),
          const SizedBox(height: AppSpacing.s20),
          // La legenda sta sopra il grafico (DESIGN.md, sezione 7).
          Wrap(
            spacing: AppSpacing.s16,
            runSpacing: AppSpacing.s8,
            children: [
              for (final (i, a) in atleti.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tinte[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      a.nomeCompleto,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testo,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          PoolCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 240,
                  child: _GraficoAndamento(
                    test: test,
                    storici: storici,
                    tinte: tinte,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  test.piuBassoMeglio
                      ? 'Un punto per ogni volta. Più in basso è meglio.'
                      : 'Un punto per ogni volta. Più in alto è meglio.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s28),
          const TitoloSezione('Dal primo all\'ultimo'),
          AppListPanel(
            righe: [
              for (final (i, a) in atleti.indexed)
                _RigaAtleta(
                  test: test,
                  atleta: a,
                  storico: storici[i],
                  tinta: tinte[i],
                ),
            ],
          ),
          if (test.prove > 1) ...[
            const SizedBox(height: AppSpacing.s28),
            const TitoloSezione(
              "Le prove dell'ultima volta",
              spiegazione:
                  'Una barra per atleta a ogni prova: chi cala '
                  'di più si affatica di più.',
            ),
            PoolCard(
              child: SizedBox(
                height: 220,
                child: _GraficoProve(
                  test: test,
                  storici: storici,
                  tinte: tinte,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Tempo · media di 6 prove".
String descrizioneMisuraBreve(TestClub t) =>
    '${t.unita.etichetta} · ${t.comeSiLegge.toLowerCase()}';

class _RigaAtleta extends StatelessWidget {
  const _RigaAtleta({
    required this.test,
    required this.atleta,
    required this.storico,
    required this.tinta,
  });

  final TestClub test;
  final Atleta atleta;
  final List<RisultatoTest> storico;
  final Color tinta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final punteggi = [for (final r in storico) test.punteggioDi(r.valori)];
    final migliore = punteggi.isEmpty
        ? null
        : punteggi.reduce((a, b) => test.meglio(a, b) ? a : b);
    final differenza = punteggi.length < 2
        ? null
        : punteggi.last - punteggi.first;
    return AppListRow(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: tinta, shape: BoxShape.circle),
      ),
      titolo: atleta.nomeCompleto,
      sottotitolo: storico.isEmpty
          ? 'Nessun risultato'
          : [
              storico.length == 1 ? '1 volta' : '${storico.length} volte',
              if (migliore != null)
                'migliore ${formattaValore(test.unita, migliore)}',
            ].join(' · '),
      trailing: storico.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattaValore(test.unita, punteggi.last),
                  style: AppTypography.numerica(AppTypography.numeroMedio)
                      .copyWith(color: colori.testo),
                ),
                if (differenza != null && differenza != 0)
                  Text(
                    '${formattaValore(test.unita, differenza.abs())} '
                    '${test.meglio(punteggi.last, punteggi.first) ? 'meglio' : 'peggio'} '
                    'dal ${dataCompatta(storico.first.data)}',
                    style: AppTypography.numerica(AppTypography.piccolo)
                        .copyWith(color: colori.testoSecondario),
                  ),
              ],
            ),
    );
  }
}

/// L'andamento nel tempo: una linea per atleta, un punto per risultato.
/// I punti si vedono sempre: i test si fanno poche volte, e un atleta con
/// un risultato solo altrimenti non comparirebbe.
class _GraficoAndamento extends StatelessWidget {
  const _GraficoAndamento({
    required this.test,
    required this.storici,
    required this.tinte,
  });

  final TestClub test;
  final List<List<RisultatoTest>> storici;
  final List<Color> tinte;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final giorni = [
      for (final s in storici)
        for (final r in s) r.data,
    ];
    if (giorni.isEmpty) return const SizedBox.shrink();
    final primo = giorni.reduce((a, b) => a.isBefore(b) ? a : b);
    double x(DateTime d) => d.difference(primo).inDays.toDouble();
    final ultimoX = giorni.map(x).reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: ultimoX == 0 ? 1 : ultimoX,
        lineBarsData: [
          for (final (i, s) in storici.indexed)
            LineChartBarData(
              spots: [
                for (final r in s)
                  FlSpot(x(r.data), test.punteggioDi(r.valori)),
              ],
              color: tinte[i],
              barWidth: 2,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3,
                  color: tinte[i],
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattaValore(test.unita, v, sigla: false),
                    style: AppTypography.numerica(AppTypography.etichetta)
                        .copyWith(color: colori.testoTenue),
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: ultimoX <= 0 ? 1 : (ultimoX / 4).ceilToDouble(),
              getTitlesWidget: (v, meta) {
                final d = primo.add(Duration(days: v.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s4),
                  child: Text(
                    '${d.day.toString().padLeft(2, '0')}/'
                    '${d.month.toString().padLeft(2, '0')}',
                    style: AppTypography.numerica(AppTypography.etichetta)
                        .copyWith(color: colori.testoTenue),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (toccati) => [
              for (final s in toccati)
                LineTooltipItem(
                  formattaValore(test.unita, s.y),
                  AppTypography.numerica(AppTypography.piccolo)
                      .copyWith(color: s.bar.color ?? colori.testo),
                ),
            ],
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colori.linea, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Le prove dell'ultimo risultato di ogni atleta: un gruppo di barre per
/// prova, una barra per atleta.
class _GraficoProve extends StatelessWidget {
  const _GraficoProve({
    required this.test,
    required this.storici,
    required this.tinte,
  });

  final TestClub test;
  final List<List<RisultatoTest>> storici;
  final List<Color> tinte;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final ultimi = [for (final s in storici) s.isEmpty ? null : s.last];
    final valori = [
      for (final r in ultimi)
        if (r != null) ...r.valori,
    ];
    if (valori.isEmpty) return const SizedBox.shrink();
    final massimo = valori.reduce((a, b) => a > b ? a : b);
    final minimo = valori.reduce((a, b) => a < b ? a : b);
    // Le barre partono poco sotto il valore più basso: le differenze fra
    // una prova e l'altra sono di decimi.
    final base = (minimo - (massimo - minimo) * 0.5)
        .clamp(0, minimo)
        .toDouble();
    return BarChart(
      BarChartData(
        minY: base,
        maxY: massimo + (massimo - base) * 0.05,
        barGroups: [
          for (var p = 0; p < test.prove; p++)
            BarChartGroupData(
              x: p,
              barsSpace: 2,
              barRods: [
                for (final (i, r) in ultimi.indexed)
                  BarChartRodData(
                    fromY: base,
                    toY: r != null && p < r.valori.length ? r.valori[p] : base,
                    color: tinte[i],
                    width: 8,
                    borderRadius: BorderRadius.zero,
                  ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattaValore(test.unita, v, sigla: false),
                    style: AppTypography.numerica(AppTypography.etichetta)
                        .copyWith(color: colori.testoTenue),
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s4),
                child: Text(
                  '${v.round() + 1}ª',
                  style: AppTypography.numerica(AppTypography.etichetta)
                      .copyWith(color: colori.testoTenue),
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
                  formattaValore(test.unita, rod.toY),
                  AppTypography.numerica(AppTypography.piccolo)
                      .copyWith(color: rod.color ?? colori.testo),
                ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colori.linea, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
