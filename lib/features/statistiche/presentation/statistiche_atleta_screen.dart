import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/domain/atleta.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiche — ${widget.atleta.nomeCompleto}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelettoreStagione(
                clubId: widget.atleta.clubId,
                onCambiata: (s) => setState(() => _stagione = s),
              ),
              if (_stagione != null) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: _DatiAtleta(
                    atleta: widget.atleta,
                    stagione: _stagione!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

    return refertiAsync.when(
      data: (r) => eventiAsync.when(
        data: (e) {
          final rigaReferti = _trovaReferti(r.perAtleta);
          final rigaEventi = _trovaEventi(e.perAtleta);
          return ListView(
            children: [
              Text(
                'Da referti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Non include i tiri sbagliati (non registrati nel referto).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                rigaReferti == null
                    ? 'Nessun dato da referto in questa stagione.'
                    : '${rigaReferti.reti} reti · ${rigaReferti.espulsioni} '
                          'espulsioni · ${rigaReferti.partite} partite · '
                          '${rigaReferti.mediaRetiPartita.toStringAsFixed(2)} '
                          'reti/partita',
              ),
              const Divider(height: 32),
              Text(
                'Da eventi live',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Solo dalle partite seguite dal vivo con "Eventi partita".',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                rigaEventi == null
                    ? 'Nessun evento registrato in questa stagione.'
                    : 'Gol: ${rigaEventi.gol}/${rigaEventi.tiri}'
                          '${rigaEventi.tiri > 0 ? ' (${(rigaEventi.gol / rigaEventi.tiri * 100).round()}%)' : ''}'
                          ' · ${rigaEventi.espulsioni} espulsioni',
              ),
              if (rigaEventi != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Azione: ${rigaEventi.golAzione} · superiorità: '
                  '${rigaEventi.golSuperiorita} · rigore: '
                  '${rigaEventi.golRigore}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(messaggioErrore(err))),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(messaggioErrore(err))),
    );
  }
}
