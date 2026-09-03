import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';

typedef _StatisticaGiocatore = ({
  DistintaGiocatore giocatore,
  Atleta atleta,
  int tiri,
  int gol,
  int espulsioni,
});

class StatistichePartitaScreen extends ConsumerWidget {
  const StatistichePartitaScreen({required this.partita, super.key});

  final Partita partita;

  List<_StatisticaGiocatore> _calcola(
    List<DistintaGiocatore> convocati,
    List<EventoPartita> eventi,
    Map<String, Atleta> atletiPerId,
  ) {
    final righe = <_StatisticaGiocatore>[];
    for (final g in convocati) {
      final atleta = atletiPerId[g.atletaId];
      if (atleta == null) continue;
      final tiriGiocatore = eventi.where(
        (e) => e.tipo == 'tiro' && e.atletaId == g.atletaId,
      );
      final espulsioni = eventi.where(
        (e) => e.tipo == 'espulsione' && e.atletaId == g.atletaId,
      );
      righe.add((
        giocatore: g,
        atleta: atleta,
        tiri: tiriGiocatore.length,
        gol: tiriGiocatore.where((e) => e.esito == 'gol').length,
        espulsioni: espulsioni.length,
      ));
    }
    righe.sort(
      (a, b) => a.giocatore.numeroCalottina.compareTo(b.giocatore.numeroCalottina),
    );
    return righe;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistiche — ${partita.squadraCasa} - ${partita.squadraTrasferta}',
        ),
      ),
      body: eventiAsync.when(
        data: (eventi) => convocatiAsync.when(
          data: (convocati) => atletiAsync.when(
            data: (atleti) {
              final atletiPerId = {for (final a in atleti) a.id: a};
              final righe = _calcola(convocati, eventi, atletiPerId);
              if (righe.isEmpty) {
                return const Center(
                  child: Text('Nessun convocato in distinta.'),
                );
              }
              final tiriTotali = righe.fold<int>(0, (s, r) => s + r.tiri);
              final golTotali = righe.fold<int>(0, (s, r) => s + r.gol);
              final espulsioniTotali = righe.fold<int>(
                0,
                (s, r) => s + r.espulsioni,
              );
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Squadra: $golTotali gol su $tiriTotali tiri'
                      '${tiriTotali > 0 ? ' (${(golTotali / tiriTotali * 100).round()}%)' : ''}'
                      ' · $espulsioniTotali espulsioni',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: righe.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = righe[index];
                        final percentuale = r.tiri > 0
                            ? '${(r.gol / r.tiri * 100).round()}%'
                            : '—';
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${r.giocatore.numeroCalottina}'),
                          ),
                          title: Text(r.atleta.nomeCompleto),
                          subtitle: Text(
                            'Gol: ${r.gol}/${r.tiri} ($percentuale) · '
                            'Espulsioni: ${r.espulsioni}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(messaggioErrore(error))),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(messaggioErrore(error))),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(messaggioErrore(error))),
      ),
    );
  }
}
