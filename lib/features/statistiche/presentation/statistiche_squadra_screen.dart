import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../pallanuoto/presentation/campo_tiro.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/statistiche_providers.dart';
import '../domain/statistiche_stagionali.dart';
import 'selettore_stagione.dart';

enum _FonteStatistiche { referti, eventi, confronto }

/// Due fonti separate, mai mescolate: "da referti" (risultato/parziali/
/// rose digitalizzate, non contano i tiri sbagliati) e "da eventi live"
/// (tracking in tempo reale durante la partita, piu' accurato ma solo per
/// le partite seguite dal vivo dall'app). "Confronto" le affianca per
/// atleta, senza sommarle (fonti diverse, numeri non sempre comparabili).
class StatisticheSquadraScreen extends ConsumerStatefulWidget {
  const StatisticheSquadraScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<StatisticheSquadraScreen> createState() =>
      _StatisticheSquadraScreenState();
}

class _StatisticheSquadraScreenState
    extends ConsumerState<StatisticheSquadraScreen> {
  Stagione? _stagione;
  _FonteStatistiche _fonte = _FonteStatistiche.referti;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Statistiche stagione')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelettoreStagione(
            clubId: widget.clubId,
            onCambiata: (s) => setState(() => _stagione = s),
          ),
          if (_stagione != null) ...[
            const SizedBox(height: AppSpacing.s16),
            LayoutBuilder(
              builder: (context, vincoli) {
                // Su telefono le etichette lunghe andavano a capo: sotto
                // ~480 px si usano le forme brevi.
                final breve = vincoli.maxWidth < 480;
                Widget etichetta(String testo) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(testo, maxLines: 1),
                );
                return SegmentedButton<_FonteStatistiche>(
                  // Senza spunta: la scelta e' gia' evidenziata dal
                  // colore, e la spunta toglieva spazio all'etichetta
                  // che su telefono andava a capo a meta' parola.
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _FonteStatistiche.referti,
                      label: etichetta(breve ? 'Referti' : 'Da referti'),
                      tooltip: 'Statistiche dai referti',
                    ),
                    ButtonSegment(
                      value: _FonteStatistiche.eventi,
                      label: etichetta(breve ? 'Live' : 'Da eventi live'),
                      tooltip: 'Statistiche dagli eventi live',
                    ),
                    ButtonSegment(
                      value: _FonteStatistiche.confronto,
                      label: etichetta('Confronto'),
                    ),
                  ],
                  selected: {_fonte},
                  onSelectionChanged: (s) => setState(() => _fonte = s.first),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s16),
            Expanded(
              child: switch (_fonte) {
                _FonteStatistiche.referti => _SezioneReferti(
                  clubId: widget.clubId,
                  stagione: _stagione!,
                ),
                _FonteStatistiche.eventi => _SezioneEventi(
                  clubId: widget.clubId,
                  stagione: _stagione!,
                ),
                _FonteStatistiche.confronto => _SezioneConfronto(
                  clubId: widget.clubId,
                  stagione: _stagione!,
                ),
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SezioneReferti extends ConsumerWidget {
  const _SezioneReferti({required this.clubId, required this.stagione});

  final String clubId;
  final Stagione stagione;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (
      clubId: clubId,
      dataInizio: stagione.dataInizio,
      dataFine: stagione.dataFine,
    );
    final riepilogoAsync = ref.watch(riepilogoRefertiProvider(chiave));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: true)),
    );
    final colori = context.colori;

    return riepilogoAsync.when(
      data: (r) => atletiAsync.when(
        data: (atleti) {
          final nomiPerId = {for (final a in atleti) a.id: a.nomeCompleto};
          final righe = [...r.perAtleta]
            ..sort((a, b) => b.reti.compareTo(a.reti));
          return ListView(
            children: [
              GrigliaNumeri(
                children: [
                  StatPanel(etichetta: 'Partite', valore: '${r.partite}'),
                  StatPanel(
                    etichetta: 'V-P-S',
                    valore: '${r.vittorie}-${r.pareggi}-${r.sconfitte}',
                  ),
                  StatPanel(
                    etichetta: 'Gol fatti-subiti',
                    valore: '${r.golFatti}-${r.golSubiti}',
                  ),
                  StatPanel(
                    etichetta: 'Gol/partita',
                    valore: r.mediaGolPartita.toStringAsFixed(2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Non include i tiri sbagliati (non registrati nel referto).',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const TitoloSezione('Per atleta'),
              const SizedBox(height: AppSpacing.s16),
              if (righe.isEmpty)
                const RiquadroVuoto(
                  'Nessun dato per atleta in questa stagione: collega i '
                  'giocatori agli atleti salvando i referti.',
                )
              else
                AppListPanel(
                  righe: [
                    for (final riga in righe)
                      _RigaConMetriche(
                        titolo: nomiPerId[riga.atletaId] ?? 'Atleta rimosso',
                        metriche: [
                          '${riga.reti} reti',
                          '${riga.espulsioni} espulsioni',
                          '${riga.partite} partite',
                          '${riga.mediaRetiPartita.toStringAsFixed(2)} reti/partita',
                        ],
                      ),
                  ],
                ),
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (e, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(e),
        ),
      ),
      loading: () => const LoadingSkeletonList(righe: 5),
      error: (e, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare i referti.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(e),
      ),
    );
  }
}

class _SezioneEventi extends ConsumerWidget {
  const _SezioneEventi({required this.clubId, required this.stagione});

  final String clubId;
  final Stagione stagione;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (
      clubId: clubId,
      dataInizio: stagione.dataInizio,
      dataFine: stagione.dataFine,
    );
    final riepilogoAsync = ref.watch(riepilogoEventiProvider(chiave));
    final tiriMappaAsync = ref.watch(tiriStagionePerMappaProvider(chiave));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: true)),
    );
    final colori = context.colori;

    return riepilogoAsync.when(
      data: (r) => atletiAsync.when(
        data: (atleti) {
          final nomiPerId = {for (final a in atleti) a.id: a.nomeCompleto};
          final righe = [...r.perAtleta]
            ..sort((a, b) => b.gol.compareTo(a.gol));
          final percentuale = r.tiri > 0
              ? '${(r.gol / r.tiri * 100).round()}%'
              : '—';
          return ListView(
            children: [
              GrigliaNumeri(
                children: [
                  StatPanel(
                    etichetta: 'Gol',
                    valore: '${r.gol}/${r.tiri}',
                    confronto: percentuale,
                  ),
                  StatPanel(etichetta: 'Espulsioni', valore: '${r.espulsioni}'),
                  StatPanel(
                    etichetta: 'Gol/partita',
                    valore: r.mediaGolPartita.toStringAsFixed(2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              GrigliaNumeri(
                children: [
                  StatPanel(etichetta: 'Gol azione', valore: '${r.golAzione}'),
                  StatPanel(
                    etichetta: 'Gol superiorità',
                    valore: '${r.golSuperiorita}',
                  ),
                  StatPanel(etichetta: 'Gol rigore', valore: '${r.golRigore}'),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              GrigliaNumeri(
                children: [
                  StatPanel(
                    etichetta: 'Gol subiti',
                    valore: '${r.golSubiti}/${r.tiriSubiti}',
                    confronto: r.tiriSubiti > 0
                        ? '${r.percentualeGolSubiti.round()}%'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${r.partite} partite seguite dal vivo con "Eventi partita".',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              const TitoloSezione('Per atleta'),
              const SizedBox(height: AppSpacing.s16),
              if (righe.isEmpty)
                const RiquadroVuoto('Nessun evento registrato in questa stagione.')
              else
                AppListPanel(
                  righe: [
                    for (final riga in righe)
                      _RigaConMetriche(
                        titolo: nomiPerId[riga.atletaId] ?? 'Atleta rimosso',
                        metriche: [
                          'Gol ${riga.gol}/${riga.tiri}'
                              '${riga.tiri > 0 ? ' (${(riga.gol / riga.tiri * 100).round()}%)' : ''}',
                          '${riga.espulsioni} espulsioni',
                          'azione ${riga.golAzione}',
                          'superiorità ${riga.golSuperiorita}',
                          'rigore ${riga.golRigore}',
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.s24),
              const TitoloSezione('Shot chart dei tiri'),
              const SizedBox(height: AppSpacing.s16),
              tiriMappaAsync.when(
                data: (tiri) => tiri.isEmpty
                    ? const RiquadroVuoto(
                        'Nessun tiro con posizione registrata in questa '
                        'stagione.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CampoTiro(
                            punti: [
                              for (final e in tiri)
                                (x: e.posX!, y: e.posY!, esito: e.esito),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          const LegendaCampoTiro(),
                        ],
                      ),
                loading: () => const LoadingSkeleton(height: 240),
                error: (err, _) => ErrorBanner(
                  messaggio: 'Non è stato possibile caricare la mappa.',
                  dettaglioTecnico: messaggioErrore(err),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (e, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(e),
        ),
      ),
      loading: () => const LoadingSkeletonList(righe: 5),
      error: (e, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare gli eventi.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(e),
      ),
    );
  }
}

/// Affianca, per ogni atleta, i dati "da referti" e "da eventi live" senza
/// sommarli: sono due misure diverse (una piu' completa nel campione di
/// partite, l'altra piu' precisa nel dettaglio) e mescolarle darebbe un
/// numero senza significato.
class _SezioneConfronto extends ConsumerWidget {
  const _SezioneConfronto({required this.clubId, required this.stagione});

  final String clubId;
  final Stagione stagione;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chiave = (
      clubId: clubId,
      dataInizio: stagione.dataInizio,
      dataFine: stagione.dataFine,
    );
    final refertiAsync = ref.watch(riepilogoRefertiProvider(chiave));
    final eventiAsync = ref.watch(riepilogoEventiProvider(chiave));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: true)),
    );
    final colori = context.colori;

    return refertiAsync.when(
      data: (r) => eventiAsync.when(
        data: (e) => atletiAsync.when(
          data: (atleti) {
            final nomiPerId = {for (final a in atleti) a.id: a.nomeCompleto};
            final refertiPerId = {
              for (final riga in r.perAtleta) riga.atletaId: riga,
            };
            final eventiPerId = {
              for (final riga in e.perAtleta) riga.atletaId: riga,
            };
            final tuttiGliId =
                {...refertiPerId.keys, ...eventiPerId.keys}.toList()..sort(
                  (a, b) => (nomiPerId[a] ?? '').compareTo(nomiPerId[b] ?? ''),
                );

            return ListView(
              children: [
                Text(
                  'Squadra — da referti: ${r.golFatti} gol in ${r.partite} '
                  'partite (${r.mediaGolPartita.toStringAsFixed(2)}/'
                  'partita) · da eventi live: ${e.gol} gol in ${e.partite} '
                  'partite tracciate (${e.mediaGolPartita.toStringAsFixed(2)}'
                  '/partita)',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                if (tuttiGliId.isEmpty)
                  const RiquadroVuoto(
                    'Nessun dato da nessuna delle due fonti in questa '
                    'stagione.',
                  )
                else
                  AppListPanel(
                    righe: [
                      for (final atletaId in tuttiGliId)
                        _RigaConfronto(
                          titolo: nomiPerId[atletaId] ?? 'Atleta rimosso',
                          referti: refertiPerId[atletaId],
                          eventi: eventiPerId[atletaId],
                        ),
                    ],
                  ),
              ],
            );
          },
          loading: () => const LoadingSkeletonList(righe: 5),
          error: (err, _) => ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli atleti.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(err),
          ),
        ),
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (err, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli eventi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(err),
        ),
      ),
      loading: () => const LoadingSkeletonList(righe: 5),
      error: (err, _) => ErrorBanner(
        messaggio: 'Non è stato possibile caricare i referti.',
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(err),
      ),
    );
  }
}

/// Riga di elenco con un titolo e più metriche affiancate (mai unite da
/// puntini, per non superare le due informazioni per riga di DESIGN.md
/// sezione 8) — usata dalle sezioni "Da referti" e "Da eventi live".
class _RigaConMetriche extends StatelessWidget {
  const _RigaConMetriche({required this.titolo, required this.metriche});

  final String titolo;
  final List<String> metriche;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo,
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: AppSpacing.s16,
            runSpacing: AppSpacing.s4,
            children: [
              for (final m in metriche)
                Text(
                  m,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RigaConfronto extends StatelessWidget {
  const _RigaConfronto({
    required this.titolo,
    required this.referti,
    required this.eventi,
  });

  final String titolo;
  final RigaAtletaReferti? referti;
  final RigaAtletaEventi? eventi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titolo,
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Da referti: ${referti != null ? '${referti!.reti} reti in ${referti!.partite} partite' : 'nessun dato'}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          Text(
            'Da eventi live: ${eventi != null ? '${eventi!.gol} gol su ${eventi!.tiri} tiri' : 'nessun dato'}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ),
    );
  }
}
