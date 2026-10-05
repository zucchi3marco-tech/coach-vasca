import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../../widgets/titolo_due_righe.dart';
import '../../atleti/application/tempi_gara_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/pb_slots.dart';
import '../../atleti/domain/tempo_gara.dart';
import '../../atleti/presentation/tempo_gara_form_screen.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/presentation/campo_tiro.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/statistiche_providers.dart';
import '../domain/statistiche_stagionali.dart';
import 'selettore_stagione.dart';

class StatisticheAtletaScreen extends ConsumerStatefulWidget {
  const StatisticheAtletaScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  ConsumerState<StatisticheAtletaScreen> createState() =>
      _StatisticheAtletaScreenState();
}

class _StatisticheAtletaScreenState
    extends ConsumerState<StatisticheAtletaScreen> {
  Stagione? _stagione;

  @override
  Widget build(BuildContext context) {
    final isPallanuoto = widget.atleta.sport == 'pallanuoto';
    return AppScaffold(
      appBar: AppBar(
        title: TitoloDueRighe(
          titolo: 'Statistiche',
          sottotitolo: widget.atleta.nomeCompleto,
        ),
      ),
      body: isPallanuoto
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelettoreStagione(
                  clubId: widget.atleta.clubId,
                  onCambiata: (s) => setState(() => _stagione = s),
                ),
                if (_stagione != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Expanded(
                    child: _DatiAtleta(
                      atleta: widget.atleta,
                      stagione: _stagione!,
                    ),
                  ),
                ],
              ],
            )
          : _StoricoTempiNuoto(atleta: widget.atleta),
    );
  }
}

class _DatiAtleta extends ConsumerWidget {
  const _DatiAtleta({required this.atleta, required this.stagione});

  final Atleta atleta;
  final Stagione stagione;

  RigaAtletaReferti? _trovaReferti(List<RigaAtletaReferti> righe) {
    for (final r in righe) {
      if (r.atletaId == atleta.id) return r;
    }
    return null;
  }

  RigaAtletaEventi? _trovaEventi(List<RigaAtletaEventi> righe) {
    for (final r in righe) {
      if (r.atletaId == atleta.id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (
      clubId: atleta.clubId,
      dataInizio: stagione.dataInizio,
      dataFine: stagione.dataFine,
    );
    final refertiAsync = ref.watch(riepilogoRefertiProvider(chiave));
    final eventiAsync = ref.watch(riepilogoEventiProvider(chiave));
    final colori = context.colori;

    return refertiAsync.when(
      data: (r) => eventiAsync.when(
        data: (e) {
          final rigaReferti = _trovaReferti(r.perAtleta);
          final rigaEventi = _trovaEventi(e.perAtleta);
          return ListView(
            children: [
              const SectionHeader('Da referti'),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Non include i tiri sbagliati (non registrati nel referto).',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (rigaReferti == null)
                Text(
                  'Nessun dato da referto in questa stagione.',
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                )
              else
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(etichetta: 'Reti', valore: '${rigaReferti.reti}'),
                    StatPanel(
                      etichetta: 'Espulsioni',
                      valore: '${rigaReferti.espulsioni}',
                    ),
                    StatPanel(
                      etichetta: 'Partite',
                      valore: '${rigaReferti.partite}',
                    ),
                    StatPanel(
                      etichetta: 'Reti/partita',
                      valore: rigaReferti.mediaRetiPartita.toStringAsFixed(2),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.s28),
              const SectionHeader('Da eventi live'),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Solo dalle partite seguite dal vivo con "Eventi partita".',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (rigaEventi == null)
                Text(
                  'Nessun evento registrato in questa stagione.',
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                )
              else ...[
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(
                      etichetta: 'Gol',
                      valore: '${rigaEventi.gol}/${rigaEventi.tiri}',
                      confronto: rigaEventi.tiri > 0
                          ? '${(rigaEventi.gol / rigaEventi.tiri * 100).round()}%'
                          : null,
                    ),
                    StatPanel(
                      etichetta: 'Espulsioni',
                      valore: '${rigaEventi.espulsioni}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Wrap(
                  spacing: AppSpacing.s24,
                  runSpacing: AppSpacing.s16,
                  children: [
                    StatPanel(
                      etichetta: 'Gol azione',
                      valore: '${rigaEventi.golAzione}',
                    ),
                    StatPanel(
                      etichetta: 'Gol superiorità',
                      valore: '${rigaEventi.golSuperiorita}',
                    ),
                    StatPanel(
                      etichetta: 'Gol rigore',
                      valore: '${rigaEventi.golRigore}',
                    ),
                  ],
                ),
              ],
              if (atleta.sport == 'pallanuoto') ...[
                const SizedBox(height: AppSpacing.s28),
                _SezioneMappaTiri(atletaId: atleta.id),
              ],
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 4),
        error: (err, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli eventi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(err),
        ),
      ),
      loading: () => const LoadingSkeletonList(righe: 4),
      error: (err, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare i referti.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(err),
      ),
    );
  }
}

/// Mappa di calore dei tiri dell'atleta (pallanuoto), da sempre — non
/// filtrata per stagione come il resto di questa schermata, perché un
/// tiro non ha un periodo "di stagione" più significativo del totale.
class _SezioneMappaTiri extends ConsumerWidget {
  const _SezioneMappaTiri({required this.atletaId});

  final String atletaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiriAsync = ref.watch(tiriAtletaProvider(atletaId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Shot chart dei tiri',
          spiegazione:
              'La mappa di tutti i tiri registrati, nella posizione da cui '
              'sono stati tirati: verde un gol, grigio un tiro parato, '
              'bianco palo o fuori.',
        ),
        const SizedBox(height: AppSpacing.s16),
        tiriAsync.when(
          data: (tiri) {
            final conPosizione = [
              for (final e in tiri)
                if (e.posX != null && e.posY != null) e,
            ];
            if (conPosizione.isEmpty) {
              return Text(
                'Nessun tiro con posizione registrato per questo atleta.',
                style: AppTypography.piccolo.copyWith(
                  color: context.colori.testoSecondario,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoTiro(
                  punti: [
                    for (final e in conPosizione)
                      (x: e.posX!, y: e.posY!, esito: e.esito),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                const LegendaCampoTiro(),
              ],
            );
          },
          loading: () => const LoadingSkeleton(height: 240),
          error: (error, _) => ErrorBanner(
            messaggio: 'Non è stato possibile caricare i tiri.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ],
    );
  }
}

/// Storico dei tempi nuoto per stile+distanza+vasca, con curva delle
/// prestazioni nel tempo — equivalente, per il nuoto, di [_DatiAtleta]
/// (pallanuoto). Non filtrato per stagione: una progressione ha senso
/// solo guardando tutta la storia disponibile, non solo l'ultima
/// stagione.
class _StoricoTempiNuoto extends ConsumerStatefulWidget {
  const _StoricoTempiNuoto({required this.atleta});

  final Atleta atleta;

  @override
  ConsumerState<_StoricoTempiNuoto> createState() => _StoricoTempiNuotoState();
}

class _StoricoTempiNuotoState extends ConsumerState<_StoricoTempiNuoto> {
  late String _stile;
  late int _distanzaM;
  int _vascaM = 25;

  @override
  void initState() {
    super.initState();
    _stile = stiliNuoto.first;
    _distanzaM = distanzePerStileNuoto[_stile]!.first;
  }

  void _cambiaStile(String? stile) {
    if (stile == null) return;
    setState(() {
      _stile = stile;
      final distanze = distanzePerStileNuoto[_stile]!;
      if (!distanze.contains(_distanzaM)) _distanzaM = distanze.first;
    });
  }

  void _apriForm({TempoGara? tempoGara}) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TempoGaraFormScreen(
        atleta: widget.atleta,
        tempoGara: tempoGara,
        stileIniziale: _stile,
        distanzaMIniziale: _distanzaM,
        vascaMIniziale: _vascaM,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tempiAsync = ref.watch(tempiGaraListProvider(widget.atleta.id));
    final colori = context.colori;
    final distanze = distanzePerStileNuoto[_stile]!;

    return tempiAsync.when(
      data: (tutti) {
        final filtrati = [
          for (final t in tutti)
            if (t.stile == _stile &&
                t.distanzaM == _distanzaM &&
                t.vascaM == _vascaM)
              t,
        ]..sort((a, b) => a.data.compareTo(b.data));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppSelect<String>(
                    etichetta: 'Stile',
                    value: _stile,
                    items: [
                      for (final s in stiliNuoto)
                        DropdownMenuItem(
                          value: s,
                          child: Text(capitalizzaParola(s)),
                        ),
                    ],
                    onChanged: _cambiaStile,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: AppSelect<int>(
                    etichetta: 'Distanza',
                    value: _distanzaM,
                    items: [
                      for (final d in distanze)
                        DropdownMenuItem(value: d, child: Text('${d}m')),
                    ],
                    onChanged: (d) => setState(() => _distanzaM = d!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Vasca',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            SegmentedButton<int>(
              // Senza spunta: la scelta e' gia' evidenziata dal
              // colore, e la spunta toglieva spazio all'etichetta
              // che su telefono andava a capo a meta' parola.
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 25, label: Text('25m')),
                ButtonSegment(value: 50, label: Text('50m')),
              ],
              selected: {_vascaM},
              onSelectionChanged: (s) => setState(() => _vascaM = s.first),
            ),
            const SizedBox(height: AppSpacing.s28),
            const SectionHeader(
              'Curva delle prestazioni',
              spiegazione:
                  'Tutti i tempi registrati per lo stile, la distanza e la '
                  'vasca scelti sopra, in ordine di data: una curva in '
                  'discesa significa che stai migliorando.',
            ),
            const SizedBox(height: AppSpacing.s16),
            if (filtrati.length < 2)
              Text(
                'Servono almeno due tempi in questa combinazione per '
                'disegnare la curva.',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              )
            else
              SizedBox(height: 220, child: _GraficoTempi(punti: filtrati)),
            const SizedBox(height: AppSpacing.s28),
            const SectionHeader('Storico'),
            const SizedBox(height: AppSpacing.s16),
            AppListPanel(
              righe: [
                AppListRow(
                  leading: Icon(Icons.add_circle_outline, color: colori.azione),
                  titolo: 'Aggiungi tempo',
                  onTap: _apriForm,
                ),
                for (final t in filtrati.reversed)
                  AppListRow(
                    titolo: formatPaceSeconds(t.tempoS),
                    sottotitolo:
                        '${t.data.day.toString().padLeft(2, '0')}/'
                        '${t.data.month.toString().padLeft(2, '0')}/'
                        '${t.data.year}'
                        '${t.note != null && t.note!.isNotEmpty ? ' · ${t.note}' : ''}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _apriForm(tempoGara: t),
                  ),
              ],
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: ErrorBanner(
          messaggio: 'Non è stato possibile caricare i tempi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }
}

/// Curva dei tempi (nuoto) nel tempo — stessa struttura di
/// [GraficoBanister], una sola serie in `azione`.
class _GraficoTempi extends StatelessWidget {
  const _GraficoTempi({required this.punti});

  final List<TempoGara> punti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final spot = [
      for (var i = 0; i < punti.length; i++)
        FlSpot(i.toDouble(), punti[i].tempoS),
    ];
    final intervalloEtichette = (punti.length / 5).ceil().clamp(
      1,
      punti.length,
    );

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spot,
            isCurved: false,
            color: colori.azione,
            barWidth: 2,
            dotData: const FlDotData(show: true),
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
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                formatPaceSeconds(value),
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
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
