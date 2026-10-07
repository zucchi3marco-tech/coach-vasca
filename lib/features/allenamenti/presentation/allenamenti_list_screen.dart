import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/entrata_a_cascata.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../ai_genera/presentation/genera_settimana_form_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../ripartenze/presentation/ripartenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';
import 'allenamento_detail_screen.dart';
import 'calendario/allenamenti_per_giorno.dart';
import 'calendario/calendario_mensile_view.dart';
import 'calendario/calendario_settimanale_view.dart';
import 'giorno_allenamenti_screen.dart';

enum _Vista { elenco, settimana, mese }

class AllenamentiListScreen extends ConsumerStatefulWidget {
  const AllenamentiListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra gli allenamenti di tutti i gruppi).
  final String? filtroGruppoId;

  @override
  ConsumerState<AllenamentiListScreen> createState() =>
      _AllenamentiListScreenState();
}

class _AllenamentiListScreenState extends ConsumerState<AllenamentiListScreen> {
  _Vista _vista = _Vista.elenco;

  @override
  Widget build(BuildContext context) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(widget.clubId));
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((
        clubId: widget.clubId,
        gruppoId: widget.filtroGruppoId,
      )),
    );
    // Un allenamento con gruppo assegnato è visibile solo a chi lavora
    // con quel gruppo; uno senza gruppo resta visibile a tutti (stessa
    // regola di PresenzeScreen).
    final allenamenti = allenamentiAsync.value
        ?.where(
          (a) =>
              widget.filtroGruppoId == null ||
              a.gruppoId == widget.filtroGruppoId ||
              a.gruppoId == null,
        )
        .toList();

    final oggi = soloData(DateTime.now());
    final inProgramma =
        allenamenti?.where((a) => !a.data.isBefore(oggi)).length ?? 0;
    final svolti = (allenamenti?.length ?? 0) - inProgramma;

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(allenamentiRepositoryProvider)
            .refreshFromRemote(widget.clubId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            EntrataACascata(
              indice: 0,
              child: TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Allenamenti',
                sottotitolo: allenamenti == null || allenamenti.isEmpty
                    ? null
                    : '$inProgramma in programma · $svolti già svolti',
                azioni: [
                  AzioneTestata(
                    icona: Icons.add,
                    etichetta: 'Nuovo allenamento',
                    principale: true,
                    onTap: _apriNuovo,
                  ),
                  AzioneTestata(
                    icona: Icons.view_week_outlined,
                    etichetta: 'Genera la settimana',
                    onTap: _apriGeneraSettimana,
                  ),
                  AzioneTestata(
                    icona: Icons.speed,
                    etichetta: 'Ripartenze',
                    onTap: _apriRipartenze,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Center(
              child: SegmentedButton<_Vista>(
                // Senza spunta: la scelta e' gia' evidenziata dal colore, e
                // la spunta toglieva spazio all'etichetta che su telefono
                // andava a capo a meta' parola.
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Vista.elenco, label: Text('Elenco')),
                  ButtonSegment(
                    value: _Vista.settimana,
                    label: Text('Settimana'),
                  ),
                  ButtonSegment(value: _Vista.mese, label: Text('Mese')),
                ],
                selected: {_vista},
                onSelectionChanged: (selezione) =>
                    setState(() => _vista = selezione.first),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            ...allenamentiAsync.when(
              data: (_) => switch (_vista) {
                _Vista.elenco => _elenco(allenamenti!),
                _Vista.settimana => [
                  CalendarioSettimanaleView(
                    clubId: widget.clubId,
                    allenamenti: allenamenti!,
                    onGiornoSelezionato: _apriGiorno,
                  ),
                ],
                _Vista.mese => [
                  PoolCard(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    child: CalendarioMensileView(
                      allenamenti: allenamenti!,
                      onGiornoSelezionato: _apriGiorno,
                    ),
                  ),
                ],
              },
              loading: () => const [LoadingSkeletonList(righe: 6)],
              error: (error, _) => [
                ErrorBanner(
                  messaggio:
                      'Non è stato possibile caricare gli '
                      'allenamenti.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Prima oggi, poi i prossimi (dal piu' vicino), poi quelli gia' svolti
  /// (dal piu' recente). Con una stagione programmata in anticipo,
  /// l'ordine unico dal piu' lontano costringeva a scorrere mesi di sedute
  /// future per trovare quella di oggi.
  List<Widget> _elenco(List<Allenamento> allenamenti) {
    if (allenamenti.isEmpty) {
      return [
        EmptyState(
          icona: Icons.calendar_month_outlined,
          titolo: 'Nessun allenamento',
          descrizione:
              'Scrivi o detta il primo allenamento, oppure impostane i '
              'parametri: l\'AI ti propone la scheda.',
          azionePrincipale: 'Nuovo allenamento',
          onAzionePrincipale: _apriNuovo,
        ),
      ];
    }
    final oggi = soloData(DateTime.now());
    final diOggi = allenamenti
        .where((a) => isStessoGiorno(a.data, oggi))
        .toList();
    final prossimi =
        allenamenti
            .where((a) => a.data.isAfter(oggi) && !isStessoGiorno(a.data, oggi))
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    final svolti = allenamenti.where((a) => a.data.isBefore(oggi)).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };
    final ciano = context.dominio.evidenzaCiano;

    Widget scheda(Allenamento a, {bool passato = false, bool oggi = false}) {
      // Il gruppo si scrive solo quando aggiunge qualcosa: con una squadra
      // scelta in alto era ripetuto identico su ogni riga.
      final gruppo = a.gruppoId == null
          ? 'Tutto il club'
          : widget.filtroGruppoId == null
          ? nomiGruppi[a.gruppoId]
          : null;
      return SchedaElenco(
        leading: RiquadroData(a.data, colore: ciano, spento: passato),
        occhiello: oggi ? 'Oggi' : null,
        evidenza: oggi ? ciano : null,
        titolo: a.titolo != null && a.titolo!.isNotEmpty
            ? a.titolo!
            : 'Allenamento',
        sottotitolo: [
          if (!oggi) traQuanto(a.data),
          giornoSettimana(a.data),
          ?gruppo,
        ].join(' · '),
        attenuata: passato,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AllenamentoDetailScreen(allenamento: a),
          ),
        ),
      );
    }

    return [
      if (diOggi.isNotEmpty) ...[
        const TitoloSezione('Oggi'),
        GrigliaSchede(figli: [for (final a in diOggi) scheda(a, oggi: true)]),
        const SizedBox(height: AppSpacing.s16),
      ],
      if (prossimi.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s8),
        SezioneSchede(
          titolo: 'Prossimi',
          figli: [for (final a in prossimi) scheda(a)],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      if (svolti.isNotEmpty)
        SezioneSchede(
          titolo: 'Già svolti',
          figli: [for (final a in svolti) scheda(a, passato: true)],
        ),
    ];
  }

  void _apriGiorno(DateTime data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GiornoAllenamentiScreen(clubId: widget.clubId, data: data),
      ),
    );
  }

  Future<void> _apriNuovo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneraAllenamentoFormScreen(clubId: widget.clubId),
      ),
    );
  }

  Future<void> _apriGeneraSettimana() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneraSettimanaFormScreen(clubId: widget.clubId),
      ),
    );
  }

  Future<void> _apriRipartenze() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RipartenzeScreen(
          clubId: widget.clubId,
          gruppoIdIniziale: widget.filtroGruppoId,
        ),
      ),
    );
  }
}
