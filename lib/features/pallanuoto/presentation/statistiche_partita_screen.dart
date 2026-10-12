import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
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
import '../../stagioni/domain/evento_calendario.dart';
import '../application/pallanuoto_providers.dart';
import '../data/nomi_squadra_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import '../domain/statistiche_eventi.dart';
import 'campo_tiro.dart';
import 'chip_risultato.dart';
import 'confronto_partite_screen.dart';
import 'voci_partita.dart';

class StatistichePartitaScreen extends ConsumerWidget {
  const StatistichePartitaScreen({required this.partita, super.key});

  final Partita partita;

  Future<void> _confronta(BuildContext context) async {
    final altra = await showModalBottomSheet<Partita>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FoglioAltraPartita(partita: partita),
    );
    if (altra == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConfrontoPartiteScreen(prima: partita, seconda: altra),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(partita.id));
    final nomiAsync = ref.watch(nomiSquadraProvider(partita.clubId));

    Widget errore(String messaggio, Object e) => Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: ErrorBanner(
        messaggio: messaggio,
        suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
        dettaglioTecnico: messaggioErrore(e),
      ),
    );
    const caricamento = Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: LoadingSkeletonList(righe: 5),
    );

    return AppScaffold(
      appBar: AppBar(
        toolbarHeight: TitoloDueRighe.altezzaBarraDueRighe,
        title: TitoloDueRighe(
          titolo: 'Statistiche',
          sottotitolo: '${partita.squadraCasa} - ${partita.squadraTrasferta}',
          righeSottotitolo: 2,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Confronta con un\'altra partita',
            onPressed: () => _confronta(context),
          ),
        ],
      ),
      body: eventiAsync.when(
        data: (eventi) => convocatiAsync.when(
          data: (convocati) => nomiAsync.when(
            data: (nomiPerId) => _Contenuto(
              partita: partita,
              eventi: eventi,
              convocati: convocati,
              nomiPerId: nomiPerId,
            ),
            loading: () => caricamento,
            error: (e, _) =>
                errore('Non è stato possibile caricare i nomi.', e),
          ),
          loading: () => caricamento,
          error: (e, _) =>
              errore('Non è stato possibile caricare la distinta.', e),
        ),
        loading: () => caricamento,
        error: (e, _) =>
            errore('Non è stato possibile caricare gli eventi.', e),
      ),
    );
  }
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({
    required this.partita,
    required this.eventi,
    required this.convocati,
    required this.nomiPerId,
  });

  final Partita partita;
  final List<EventoPartita> eventi;
  final List<DistintaGiocatore> convocati;
  final Map<String, String> nomiPerId;

  @override
  Widget build(BuildContext context) {
    final giocatori = [
      for (final g in convocati)
        if (nomiPerId[g.atletaId] != null) g,
    ]..sort((a, b) => a.numeroCalottina.compareTo(b.numeroCalottina));
    if (giocatori.isEmpty) {
      return const EmptyState(
        icona: Icons.bar_chart_outlined,
        titolo: 'Nessun convocato in distinta',
        descrizione:
            'Le statistiche si calcolano dai convocati e dagli eventi '
            'registrati per questa partita.',
        azionePrincipale: 'Torna indietro',
      );
    }
    final s = StatisticheEventi.da(eventi);
    final n = s.squadra;
    final completa = partita.eventiCompleti || n.haEventiCompleti;
    final haPortiere = convocati.any((g) => g.portiere);
    final colore = partita.inCasa ? CapColore.bianca : CapColore.blu;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        GrigliaNumeri(
          children: [
            StatPanel(
              etichetta: 'Gol',
              valore: rapporto(n.gol, n.tiri),
              confronto: percentuale(n.gol, n.tiri),
            ),
            if (haPortiere || n.tiriSubiti > 0)
              StatPanel(
                etichetta: 'Gol subiti',
                valore: rapporto(n.golSubiti, n.tiriSubiti),
                confronto: percentuale(n.golSubiti, n.tiriSubiti),
              ),
            StatPanel(
              etichetta: 'Superiorità',
              valore: rapporto(n.golInSuperiorita, n.superiorita),
              confronto: percentuale(n.golInSuperiorita, n.superiorita),
            ),
            StatPanel(
              etichetta: 'Inferiorità',
              valore: rapporto(n.golSubitiInInferiorita, n.inferiorita),
              confronto: n.inferiorita > 0
                  ? '${n.inferiorita - n.golSubitiInInferiorita} difese'
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spazioPannelli),
        GrigliaNumeri(
          children: [
            StatPanel(
              etichetta: 'Espulsioni',
              valore: '${n.espulsioni}',
              confronto: n.rigoriConcessi > 0
                  ? '${n.rigoriConcessi} da rigore'
                  : null,
            ),
            StatPanel(
              etichetta: 'Rigori segnati',
              valore: rapporto(n.golRigore, n.rigoriTirati),
              confronto: n.rigoriAvuti > n.rigoriTirati
                  ? '${n.rigoriAvuti} avuti'
                  : null,
            ),
            if (completa)
              StatPanel(
                etichetta: 'Gol in controfuga',
                valore: '${n.golControfuga}',
                confronto: n.golSubitiControfuga > 0
                    ? '${n.golSubitiControfuga} subiti'
                    : null,
              ),
          ],
        ),
        if (completa) ...[
          const SizedBox(height: AppSpacing.spazioPannelli),
          GrigliaNumeri(
            children: [
              StatPanel(etichetta: 'Assist', valore: '${n.assist}'),
              StatPanel(etichetta: 'Palle perse', valore: '${n.pallePerse}'),
              StatPanel(
                etichetta: 'Palle recuperate',
                valore: '${n.palleRecuperate}',
              ),
              StatPanel(
                etichetta: 'Espulsioni guadagnate',
                valore: '${n.espulsioniGuadagnate}',
                confronto: n.rigoriGuadagnati > 0
                    ? '+ ${n.rigoriGuadagnati} rigori'
                    : null,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Superiorità e inferiorità si contano dalle espulsioni (non da '
          'rigore).',
          style: AppTypography.piccolo.copyWith(
            color: context.colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        AppListPanel(
          righe: [
            for (final g in giocatori)
              _RigaGiocatore(
                numero: g.numeroCalottina,
                colore: colore,
                nome: nomiPerId[g.atletaId]!,
                metriche: metricheGiocatore(s.di(g.atletaId)),
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
                if (e.tipo == 'tiro' && e.posX != null && e.posY != null)
                  (x: e.posX!, y: e.posY!, esito: e.esito),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const LegendaCampoTiro(),
        ],
      ],
    );
  }
}

/// Calottina, nome e i numeri del giocatore affiancati (mai uniti da
/// puntini, come nelle statistiche di stagione).
class _RigaGiocatore extends StatelessWidget {
  const _RigaGiocatore({
    required this.numero,
    required this.colore,
    required this.nome,
    required this.metriche,
  });

  final int numero;
  final CapColore colore;
  final String nome;
  final List<String> metriche;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          CapBadge(numero: numero, colore: colore),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
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
          ),
        ],
      ),
    );
  }
}

/// Le altre partite già giocate del club, dalla più recente: si sceglie
/// quella da confrontare.
class _FoglioAltraPartita extends ConsumerWidget {
  const _FoglioAltraPartita({required this.partita});

  final Partita partita;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final oggi = soloGiorno(DateTime.now());
    final altre = [
      for (final p
          in ref.watch(partiteListProvider(partita.clubId)).value ??
              const <Partita>[])
        if (p.id != partita.id && !soloGiorno(p.data).isAfter(oggi)) p,
    ]..sort((a, b) => b.data.compareTo(a.data));
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Text(
              'Con quale partita?',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s12),
            if (altre.isEmpty)
              const RiquadroVuoto('Nessun\'altra partita già giocata.')
            else
              AppListPanel(
                righe: [
                  for (final p in altre)
                    AppListRow(
                      titolo: 'vs ${p.avversario}',
                      sottotitolo: dataEstesa(p.data),
                      trailing: ChipRisultato(partita: p),
                      onTap: () => Navigator.of(context).pop(p),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
