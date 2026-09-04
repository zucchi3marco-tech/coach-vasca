import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/statistiche_providers.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche stagione')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelettoreStagione(
                clubId: widget.clubId,
                onCambiata: (s) => setState(() => _stagione = s),
              ),
              if (_stagione != null) ...[
                const SizedBox(height: 16),
                SegmentedButton<_FonteStatistiche>(
                  segments: const [
                    ButtonSegment(
                      value: _FonteStatistiche.referti,
                      label: Text('Da referti'),
                    ),
                    ButtonSegment(
                      value: _FonteStatistiche.eventi,
                      label: Text('Da eventi live'),
                    ),
                    ButtonSegment(
                      value: _FonteStatistiche.confronto,
                      label: Text('Confronto'),
                    ),
                  ],
                  selected: {_fonte},
                  onSelectionChanged: (s) => setState(() => _fonte = s.first),
                ),
                const SizedBox(height: 16),
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
        ),
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

    return riepilogoAsync.when(
      data: (r) => atletiAsync.when(
        data: (atleti) {
          final nomiPerId = {for (final a in atleti) a.id: a.nomeCompleto};
          final righe = [...r.perAtleta]
            ..sort((a, b) => b.reti.compareTo(a.reti));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.partite} partite · ${r.vittorie}V ${r.pareggi}P '
                '${r.sconfitte}S · ${r.golFatti}-${r.golSubiti} gol · '
                '${r.mediaGolPartita.toStringAsFixed(2)} gol/partita',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Non include i tiri sbagliati (non registrati nel referto).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              Expanded(
                child: righe.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun dato per atleta in questa stagione: '
                          'collega i giocatori agli atleti salvando i '
                          'referti.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: righe.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final riga = righe[index];
                          return ListTile(
                            title: Text(
                              nomiPerId[riga.atletaId] ?? 'Atleta rimosso',
                            ),
                            subtitle: Text(
                              '${riga.reti} reti · ${riga.espulsioni} '
                              'espulsioni · ${riga.partite} partite · '
                              '${riga.mediaRetiPartita.toStringAsFixed(2)} '
                              'reti/partita',
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(messaggioErrore(e))),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(messaggioErrore(e))),
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
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: true)),
    );

    return riepilogoAsync.when(
      data: (r) => atletiAsync.when(
        data: (atleti) {
          final nomiPerId = {for (final a in atleti) a.id: a.nomeCompleto};
          final righe = [...r.perAtleta]
            ..sort((a, b) => b.gol.compareTo(a.gol));
          final percentuale = r.tiri > 0
              ? '${(r.gol / r.tiri * 100).round()}%'
              : '—';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.gol} gol su ${r.tiri} tiri ($percentuale) · '
                '${r.espulsioni} espulsioni · '
                '${r.mediaGolPartita.toStringAsFixed(2)} gol/partita',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Di cui su azione: ${r.golAzione} · su superiorità: '
                '${r.golSuperiorita} · su rigore: ${r.golRigore}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${r.partite} partite seguite dal vivo con "Eventi partita".',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              Expanded(
                child: righe.isEmpty
                    ? const Center(
                        child: Text(
                          'Nessun evento registrato in questa stagione.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: righe.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final riga = righe[index];
                          final perc = riga.tiri > 0
                              ? '${(riga.gol / riga.tiri * 100).round()}%'
                              : '—';
                          return ListTile(
                            title: Text(
                              nomiPerId[riga.atletaId] ?? 'Atleta rimosso',
                            ),
                            subtitle: Text(
                              'Gol: ${riga.gol}/${riga.tiri} ($perc) · '
                              '${riga.espulsioni} espulsioni\n'
                              'Azione: ${riga.golAzione} · superiorità: '
                              '${riga.golSuperiorita} · rigore: '
                              '${riga.golRigore}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(messaggioErrore(e))),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(messaggioErrore(e))),
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
                  (a, b) =>
                      (nomiPerId[a] ?? '').compareTo(nomiPerId[b] ?? ''),
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Squadra — da referti: ${r.golFatti} gol in ${r.partite} '
                  'partite (${r.mediaGolPartita.toStringAsFixed(2)}/'
                  'partita) · da eventi live: ${e.gol} gol in ${e.partite} '
                  'partite tracciate (${e.mediaGolPartita.toStringAsFixed(2)}'
                  '/partita)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(height: 24),
                Expanded(
                  child: tuttiGliId.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun dato da nessuna delle due fonti in '
                            'questa stagione.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: tuttiGliId.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final atletaId = tuttiGliId[index];
                            final rigaReferti = refertiPerId[atletaId];
                            final rigaEventi = eventiPerId[atletaId];
                            return ListTile(
                              title: Text(
                                nomiPerId[atletaId] ?? 'Atleta rimosso',
                              ),
                              subtitle: Text(
                                'Da referti: ${rigaReferti != null ? '${rigaReferti.reti} reti in ${rigaReferti.partite} partite' : 'nessun dato'}\n'
                                'Da eventi live: ${rigaEventi != null ? '${rigaEventi.gol} gol su ${rigaEventi.tiri} tiri' : 'nessun dato'}',
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(messaggioErrore(err))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(messaggioErrore(err))),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(messaggioErrore(err))),
    );
  }
}
