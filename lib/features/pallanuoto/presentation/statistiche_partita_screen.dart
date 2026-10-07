import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/stat_panel.dart';
import '../../../widgets/titolo_due_righe.dart';
import '../application/pallanuoto_providers.dart';
import '../data/nomi_squadra_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import 'campo_tiro.dart';

typedef _StatisticaGiocatore = ({
  DistintaGiocatore giocatore,
  String nome,
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
    Map<String, String> nomiPerId,
  ) {
    final righe = <_StatisticaGiocatore>[];
    for (final g in convocati) {
      final nome = nomiPerId[g.atletaId];
      if (nome == null) continue;
      final tiriGiocatore = eventi.where(
        (e) => e.tipo == 'tiro' && e.atletaId == g.atletaId,
      );
      final espulsioni = eventi.where(
        (e) => e.tipo == 'espulsione' && e.atletaId == g.atletaId,
      );
      righe.add((
        giocatore: g,
        nome: nome,
        tiri: tiriGiocatore.length,
        gol: tiriGiocatore.where((e) => e.esito == 'gol').length,
        espulsioni: espulsioni.length,
      ));
    }
    righe.sort(
      (a, b) =>
          a.giocatore.numeroCalottina.compareTo(b.giocatore.numeroCalottina),
    );
    return righe;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(partita.id));
    final nomiAsync = ref.watch(nomiSquadraProvider(partita.clubId));

    return AppScaffold(
      appBar: AppBar(
        toolbarHeight: TitoloDueRighe.altezzaBarraDueRighe,
        title: TitoloDueRighe(
          titolo: 'Statistiche',
          sottotitolo: '${partita.squadraCasa} - ${partita.squadraTrasferta}',
          righeSottotitolo: 2,
        ),
      ),
      body: eventiAsync.when(
        data: (eventi) => convocatiAsync.when(
          data: (convocati) => nomiAsync.when(
            data: (nomiPerId) {
              final righe = _calcola(convocati, eventi, nomiPerId);
              if (righe.isEmpty) {
                return const EmptyState(
                  icona: Icons.bar_chart_outlined,
                  titolo: 'Nessun convocato in distinta',
                  descrizione:
                      'Le statistiche si calcolano dai convocati e dagli '
                      'eventi registrati per questa partita.',
                  azionePrincipale: 'Torna indietro',
                );
              }
              final tiriTotali = righe.fold<int>(0, (s, r) => s + r.tiri);
              final golTotali = righe.fold<int>(0, (s, r) => s + r.gol);
              final espulsioniTotali = righe.fold<int>(
                0,
                (s, r) => s + r.espulsioni,
              );
              final tiriSubiti = eventi
                  .where((e) => e.tipo == 'tiro' && e.squadra == 'avversaria')
                  .toList();
              final golSubiti = tiriSubiti
                  .where((e) => e.esito == 'gol')
                  .length;
              final haPortiere = convocati.any((g) => g.portiere);
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  GrigliaNumeri(
                    children: [
                      StatPanel(
                        etichetta: 'Gol',
                        valore: '$golTotali/$tiriTotali',
                        confronto: tiriTotali > 0
                            ? '${(golTotali / tiriTotali * 100).round()}%'
                            : null,
                      ),
                      StatPanel(
                        etichetta: 'Espulsioni',
                        valore: '$espulsioniTotali',
                      ),
                      if (haPortiere)
                        StatPanel(
                          etichetta: 'Gol subiti',
                          valore: '$golSubiti/${tiriSubiti.length}',
                          confronto: tiriSubiti.isNotEmpty
                              ? '${(golSubiti / tiriSubiti.length * 100).round()}%'
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  AppListPanel(
                    righe: [
                      for (final r in righe)
                        AppListRow(
                          leading: CapBadge(
                            numero: r.giocatore.numeroCalottina,
                          ),
                          titolo: r.nome,
                          sottotitolo:
                              'Gol: ${r.gol}/${r.tiri} '
                              '(${r.tiri > 0 ? '${(r.gol / r.tiri * 100).round()}%' : '—'}) · '
                              'Espulsioni: ${r.espulsioni}',
                        ),
                    ],
                  ),
                  if (eventi.any(
                    (e) => e.tipo == 'tiro' && e.posX != null && e.posY != null,
                  )) ...[
                    const SizedBox(height: AppSpacing.s24),
                    const SectionHeader('Shot chart dei tiri'),
                    const SizedBox(height: AppSpacing.s16),
                    CampoTiro(
                      punti: [
                        for (final e in eventi)
                          if (e.tipo == 'tiro' &&
                              e.posX != null &&
                              e.posY != null)
                            (x: e.posX!, y: e.posY!, esito: e.esito),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const LegendaCampoTiro(),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: LoadingSkeletonList(righe: 5),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: ErrorBanner(
                messaggio: 'Non è stato possibile caricare i nomi.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri '
                    'l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: LoadingSkeletonList(righe: 5),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: ErrorBanner(
              messaggio: 'Non è stato possibile caricare la distinta.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare gli eventi.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}
