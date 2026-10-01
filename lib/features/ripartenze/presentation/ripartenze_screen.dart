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
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../ai_genera/application/corsie_service.dart';
import '../../ai_genera/domain/parametri_generazione.dart';
import '../../ai_genera/domain/tipo_lavoro.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/application/personal_best_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/personal_best.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../domain/calcolo_ripartenze.dart';

const _spiegazioneMetodologia =
    'Gli atleti del gruppo sono divisi per corsia in base al passo sui 100 '
    'stile libero (se lo scarto nel gruppo supera il 10% della media, si '
    'generano due corsie veloci/lente — stessa regola del generatore AI).\n\n'
    'Passo e ripartenza per B2, B1 (con correzione per distanza), A2, A1, '
    'C1 e C2 vengono dalle formule del tuo documento (differenziale di gara '
    'T200-T100 sui 100 stile libero). La zona C3 è velocità pura, senza un '
    'passo di riferimento. La zona D stima il ritmo gara a qualunque '
    'distanza con un modello a due punti (100/200).\n\n'
    'Il recupero per A1, A2, B2, C1 e C2 è una stima di partenza (il tuo '
    'documento dava la tabella completa solo per B1): guardalo con i tuoi '
    'atleti e dimmi cosa correggere.';

/// Scheda di riferimento per il coach: dato un gruppo, mostra gli atleti
/// divisi per corsia di passo e la ripartenza/passo di quella corsia per
/// il tipo di lavoro e la distanza scelti — tutto calcolato in locale dai
/// personal best già salvati, nessuna chiamata AI: cambiare zona o
/// distanza ricalcola all'istante.
class RipartenzeScreen extends ConsumerStatefulWidget {
  const RipartenzeScreen({
    required this.clubId,
    this.gruppoIdIniziale,
    super.key,
  });

  final String clubId;
  final String? gruppoIdIniziale;

  @override
  ConsumerState<RipartenzeScreen> createState() => _RipartenzeScreenState();
}

class _RipartenzeScreenState extends ConsumerState<RipartenzeScreen> {
  late String? _gruppoId = widget.gruppoIdIniziale;
  String _zona = 'B1';
  int _distanzaM = 100;

  @override
  Widget build(BuildContext context) {
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: widget.clubId, includeInactive: false)),
    );
    final pbAsync = ref.watch(personalBestClubProvider(widget.clubId));
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Ripartenze')),
      body: atletiAsync.when(
        data: (tuttiGliAtleti) => pbAsync.when(
          data: (tuttiIPb) => _corpo(context, tuttiGliAtleti, tuttiIPb, gruppi),
          loading: () => const LoadingSkeletonList(righe: 4),
          error: (error, _) => ErrorBanner(
            messaggio: 'Non è stato possibile caricare i personal best.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
        loading: () => const LoadingSkeletonList(righe: 4),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }

  Widget _corpo(
    BuildContext context,
    List<Atleta> tuttiGliAtleti,
    List<PersonalBest> tuttiIPb,
    List<Gruppo> gruppi,
  ) {
    final colori = context.colori;
    final atleti = tuttiGliAtleti
        .where(
          (a) => a.attivo && (_gruppoId == null || a.gruppoId == _gruppoId),
        )
        .toList();

    final pbPerAtleta = <String, List<PersonalBest>>{};
    for (final pb in tuttiIPb) {
      (pbPerAtleta[pb.atletaId] ??= []).add(pb);
    }
    final assegnazione = assegnaCorsie(atleti, pbPerAtleta);
    final atletiPerId = {for (final a in atleti) a.id: a};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Ripartenze', spiegazione: _spiegazioneMetodologia),
        const SizedBox(height: AppSpacing.s12),
        AppSelect<String?>(
          etichetta: 'Gruppo',
          value: _gruppoId,
          hint: 'Tutti gli atleti',
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Tutti gli atleti'),
            ),
            for (final g in gruppi)
              DropdownMenuItem(value: g.id, child: Text(g.nome)),
          ],
          onChanged: (valore) => setState(() => _gruppoId = valore),
        ),
        const SizedBox(height: AppSpacing.s12),
        AppSelect<String>(
          etichetta: 'Tipo di lavoro',
          value: _zona,
          items: [
            for (final zona in ordineTipiLavoro)
              DropdownMenuItem(
                value: zona,
                child: Text('$zona — ${tipiLavoro[zona]?.nome ?? ''}'),
              ),
          ],
          onChanged: (valore) => setState(() => _zona = valore ?? 'B1'),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Distanza',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final d in distanzeFrazionamento)
              TonalChip(
                etichetta: '${d.distanzaM}m',
                selezionato: _distanzaM == d.distanzaM,
                onSelezionato: (_) => setState(() => _distanzaM = d.distanzaM),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        if (atleti.isEmpty)
          EmptyState(
            icona: Icons.groups_outlined,
            titolo: 'Nessun atleta',
            descrizione: 'Il gruppo scelto non ha atleti attivi.',
            azionePrincipale: 'Mostra tutti gli atleti',
            onAzionePrincipale: _gruppoId == null
                ? null
                : () => setState(() => _gruppoId = null),
          )
        else ...[
          for (final corsia in assegnazione.corsie) ...[
            _RiquadroCorsia(
              corsia: corsia,
              zona: _zona,
              distanzaM: _distanzaM,
              atletiPerId: atletiPerId,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (assegnazione.senzaTempo.isNotEmpty)
            _RiquadroSenzaTempo(
              idAtleti: assegnazione.senzaTempo,
              atletiPerId: atletiPerId,
            ),
        ],
      ],
    );
  }
}

class _RiquadroCorsia extends StatelessWidget {
  const _RiquadroCorsia({
    required this.corsia,
    required this.zona,
    required this.distanzaM,
    required this.atletiPerId,
  });

  final CorsiaGenerazione corsia;
  final String zona;
  final int distanzaM;
  final Map<String, Atleta> atletiPerId;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tempo200S = corsia.differenzialeS == null
        ? null
        : corsia.passo100S + corsia.differenzialeS!;
    final risultato = ripartenzaEPasso(
      zona: zona,
      passo100S: corsia.passo100S,
      differenzialeS: corsia.differenzialeS,
      tempo200S: tempo200S,
      distanzaM: distanzaM,
    );

    final atletiCorsia =
        corsia.atletiIds
            .map((id) => atletiPerId[id])
            .whereType<Atleta>()
            .toList()
          ..sort((a, b) => a.cognome.compareTo(b.cognome));

    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            corsia.nome,
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s8),
          if (zona == 'C3')
            Text(
              'Lavoro di velocità pura: nessuna ripartenza calcolata dal '
              'passo, gestiscila a sensazione/cronometro.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            )
          else if (risultato.ripartenzaS == null || risultato.passoS == null)
            Text(
              'Dati insufficienti per calcolare la ripartenza in questa '
              'zona (serve il differenziale di gara T200-T100).',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    etichetta: 'Passo /100m',
                    valore: formatPaceSeconds(risultato.passoS!),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    etichetta: 'Ripartenza ${distanzaM}m',
                    valore: formatPaceSeconds(risultato.ripartenzaS!),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.s12),
          AppListPanel(
            righe: [
              for (final atleta in atletiCorsia)
                AppListRow(titolo: atleta.nomeCompleto),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiquadroSenzaTempo extends StatelessWidget {
  const _RiquadroSenzaTempo({
    required this.idAtleti,
    required this.atletiPerId,
  });

  final List<String> idAtleti;
  final Map<String, Atleta> atletiPerId;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final atleti =
        idAtleti.map((id) => atletiPerId[id]).whereType<Atleta>().toList()
          ..sort((a, b) => a.cognome.compareTo(b.cognome));
    if (atleti.isEmpty) return const SizedBox.shrink();

    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Senza personal best sui 100 stile libero',
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Serve il PB sui 100 stile libero per calcolare una corsia di '
            'passo: inseriscilo nella scheda dell\'atleta.',
            style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppListPanel(
            righe: [
              for (final atleta in atleti)
                AppListRow(titolo: atleta.nomeCompleto),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.etichetta, required this.valore});

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etichetta,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        Text(
          valore,
          style: AppTypography.numerica(
            AppTypography.numeroMedio.copyWith(color: colori.testo),
          ),
        ),
      ],
    );
  }
}
