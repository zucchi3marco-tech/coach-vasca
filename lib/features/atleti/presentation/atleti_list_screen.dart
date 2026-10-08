import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/percentuale_presenze.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/entrata_a_cascata.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../benessere/presentation/benessere_squadra.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../home/area_atleta_home_screen.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/presentation/presenze_stagione_screen.dart';
import '../../presenze/domain/presenza.dart';
import '../application/atleti_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import 'atleta_form_screen.dart';
import 'gestisci_account_atleta_dialog.dart';

enum _Ordinamento { cognome, dataNascita, percentualePresenze }

class AtletiListScreen extends ConsumerStatefulWidget {
  const AtletiListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra tutti gli atleti).
  final String? filtroGruppoId;

  @override
  ConsumerState<AtletiListScreen> createState() => _AtletiListScreenState();
}

class _AtletiListScreenState extends ConsumerState<AtletiListScreen> {
  bool _mostraInattivi = false;
  String _ricerca = '';
  _Ordinamento _ordinamento = _Ordinamento.cognome;

  void _apriPresenze() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PresenzeStagioneScreen(
        clubId: widget.clubId,
        gruppoId: widget.filtroGruppoId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Sempre anche gli inattivi: servono per il loro conteggio in testata;
    // in elenco compaiono solo se richiesti.
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: widget.clubId, includeInactive: true)),
    );
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final allenamenti =
        ref.watch(allenamentiListProvider(widget.clubId)).value ?? [];
    final presenze = ref.watch(presenzeClubProvider(widget.clubId)).value ?? [];
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((
        clubId: widget.clubId,
        gruppoId: widget.filtroGruppoId,
      )),
    );

    final delGruppo = (atletiAsync.value ?? const <Atleta>[])
        .where(
          (a) =>
              widget.filtroGruppoId == null ||
              a.gruppoId == widget.filtroGruppoId,
        )
        .toList();
    final attivi = delGruppo.where((a) => a.attivo).toList();
    final inattivi = delGruppo.length - attivi.length;
    final percentuali = [
      for (final a in attivi)
        ?percentualePresenze(
          allenamenti: allenamenti,
          presenze: presenze,
          atletaId: a.id,
          gruppoAtleta: a.gruppoId,
        ),
    ];
    final presenzeMedie = percentuali.isEmpty
        ? '—'
        : '${(percentuali.reduce((a, b) => a + b) / percentuali.length).round()}%';

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(atletiRepositoryProvider).refreshFromRemote(widget.clubId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            EntrataACascata(
              indice: 0,
              child: TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Atleti',
                numeri: [
                  NumeroTestata(
                    valore: '${attivi.length}',
                    etichetta: 'Attivi',
                  ),
                  NumeroTestata(
                    valore: presenzeMedie,
                    etichetta: 'Presenze medie',
                    onTap: _apriPresenze,
                  ),
                  NumeroTestata(
                    valore: '$inattivi',
                    etichetta: _mostraInattivi
                        ? 'Inattivi (in elenco)'
                        : 'Inattivi',
                    onTap: inattivi == 0
                        ? null
                        : () => setState(
                            () => _mostraInattivi = !_mostraInattivi,
                          ),
                  ),
                ],
                azioni: [
                  AzioneTestata(
                    icona: Icons.person_add_alt_1,
                    etichetta: 'Nuovo atleta',
                    principale: true,
                    onTap: () => _apriForm(context),
                  ),
                  AzioneTestata(
                    icona: Icons.calendar_view_month,
                    etichetta: 'Presenze',
                    onTap: _apriPresenze,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cerca per cognome o nome',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _ricerca = value),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                PopupMenuButton<VoidCallback>(
                  icon: Icon(Icons.tune, color: context.colori.testoSecondario),
                  tooltip: 'Ordina e filtra',
                  onSelected: (azione) => azione(),
                  itemBuilder: (context) => [
                    for (final (valore, icona, etichetta) in const [
                      (
                        _Ordinamento.cognome,
                        Icons.sort_by_alpha,
                        'Cognome (A-Z)',
                      ),
                      (
                        _Ordinamento.dataNascita,
                        Icons.cake_outlined,
                        'Data di nascita',
                      ),
                      (
                        _Ordinamento.percentualePresenze,
                        Icons.percent,
                        '% presenze (più alta prima)',
                      ),
                    ])
                      CheckedPopupMenuItem(
                        checked: _ordinamento == valore,
                        value: () => setState(() => _ordinamento = valore),
                        child: _VoceMenu(icona: icona, etichetta: etichetta),
                      ),
                    const PopupMenuDivider(),
                    CheckedPopupMenuItem(
                      checked: _mostraInattivi,
                      value: () =>
                          setState(() => _mostraInattivi = !_mostraInattivi),
                      child: const _VoceMenu(
                        icona: Icons.person_off_outlined,
                        etichetta: 'Mostra anche gli inattivi',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            atletiAsync.when(
              data: (atleti) => _AtletiList(
                atleti: _mostraInattivi
                    ? atleti
                    : atleti.where((a) => a.attivo).toList(),
                gruppi: gruppi,
                allenamenti: allenamenti,
                presenze: presenze,
                filtroGruppoId: widget.filtroGruppoId,
                ricerca: _ricerca,
                ordinamento: _ordinamento,
                onTap: (atleta) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AtletaDashboardScreen(atleta: atleta),
                  ),
                ),
                onTapNuovo: () => _apriForm(context),
                onTapModifica: (atleta) => _apriForm(context, atleta: atleta),
                onTapElimina: (atleta) => _eliminaAtleta(context, atleta),
              ),
              loading: () => const LoadingSkeletonList(righe: 6),
              error: (error, _) => ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli atleti.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri '
                    'l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminaAtleta(BuildContext context, Atleta atleta) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminare ${atleta.nomeCompleto}?'),
        content: const SingleChildScrollView(
          child: Text(
            'L\'atleta viene cancellato per sempre, insieme a presenze, '
            'personal best, tempi di gara, iscrizioni alle gare, test e '
            'convocazioni. Nelle partite già giocate restano gli eventi, '
            'ma senza il suo nome. Se ha un account collegato, lo perde.\n\n'
            'Per toglierlo solo dall\'elenco senza perdere lo storico usa '
            '«Modifica anagrafica» e poi «Archivia».',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    try {
      await ref.read(atletiRepositoryProvider).deleteAtleta(atleta.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${atleta.nomeCompleto} eliminato.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eliminazione non riuscita: ${messaggioErrore(e)}'),
          ),
        );
      }
    }
  }

  Future<void> _apriForm(BuildContext context, {Atleta? atleta}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AtletaFormScreen(clubId: widget.clubId, atleta: atleta),
      ),
    );
  }
}

class _AtletiList extends StatelessWidget {
  const _AtletiList({
    required this.atleti,
    required this.gruppi,
    required this.allenamenti,
    required this.presenze,
    required this.filtroGruppoId,
    required this.ricerca,
    required this.ordinamento,
    required this.onTap,
    required this.onTapNuovo,
    required this.onTapModifica,
    required this.onTapElimina,
  });

  final List<Atleta> atleti;
  final List<Gruppo> gruppi;
  final List<Allenamento> allenamenti;
  final List<Presenza> presenze;
  final String? filtroGruppoId;
  final String ricerca;
  final _Ordinamento ordinamento;

  /// Tocco sulla riga: apre la dashboard dell'atleta.
  final ValueChanged<Atleta> onTap;
  final VoidCallback onTapNuovo;

  /// Menu `⋮`: "Modifica anagrafica" (prima era l'azione della riga).
  final ValueChanged<Atleta> onTapModifica;

  /// Menu `⋮`: "Elimina atleta" (definitivo, dopo conferma).
  final ValueChanged<Atleta> onTapElimina;

  double? _percentuale(Atleta a) => percentualePresenze(
    allenamenti: allenamenti,
    presenze: presenze,
    atletaId: a.id,
    gruppoAtleta: a.gruppoId,
  );

  List<Atleta> _filtrati() {
    final query = ricerca.trim().toLowerCase();
    var filtrati = filtroGruppoId == null
        ? [...atleti]
        : atleti.where((a) => a.gruppoId == filtroGruppoId).toList();
    if (query.isNotEmpty) {
      filtrati = filtrati
          .where((a) => a.nomeCompleto.toLowerCase().contains(query))
          .toList();
    }
    filtrati.sort((a, b) {
      switch (ordinamento) {
        case _Ordinamento.dataNascita:
          return a.dataNascita.compareTo(b.dataNascita);
        case _Ordinamento.percentualePresenze:
          // Più alta prima; senza allenamenti rilevanti in fondo, non
          // confuso con uno 0% (sempre assente).
          final pa = _percentuale(a) ?? -1;
          final pb = _percentuale(b) ?? -1;
          return pb.compareTo(pa);
        case _Ordinamento.cognome:
          final perCognome = a.cognome.compareTo(b.cognome);
          return perCognome != 0 ? perCognome : a.nome.compareTo(b.nome);
      }
    });
    return filtrati;
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final nomeGruppo = {for (final g in gruppi) g.id: g.nome};
    if (atleti.isEmpty) {
      return EmptyState(
        icona: Icons.groups_outlined,
        titolo: 'Nessun atleta',
        descrizione:
            'Aggiungi il primo atleta per iniziare a programmare '
            'allenamenti e tenere le presenze.',
        azionePrincipale: 'Nuovo atleta',
        onAzionePrincipale: onTapNuovo,
      );
    }

    final filtrati = _filtrati();
    if (filtrati.isEmpty) {
      return const EmptyState(
        icona: Icons.search_off,
        titolo: 'Nessun atleta trovato',
        descrizione: 'Prova a cercare con un altro nome o cognome.',
        azionePrincipale: 'Ho capito',
      );
    }

    return GrigliaSchede(
      figli: [
        for (final atleta in filtrati)
          SchedaElenco(
            leading: _AvatarAtleta(atleta: atleta),
            titolo: atleta.nomeCompleto,
            // Sport e squadra non si ripetono su ogni scheda: lo sport e'
            // quello del club e la squadra e' gia' scelta in alto. La
            // squadra compare solo guardando "Tutti gli atleti".
            sottotitolo: [
              _etichettaPresenze(_percentuale(atleta)),
              if (filtroGruppoId == null) ?nomeGruppo[atleta.gruppoId],
            ].join(' · '),
            attenuata: !atleta.attivo,
            sotto:
                !atleta.attivo ||
                    atleta.visitaMedicaScaduta ||
                    atleta.visitaMedicaInScadenza
                ? Wrap(
                    spacing: AppSpacing.s4,
                    runSpacing: AppSpacing.s4,
                    children: [
                      if (!atleta.attivo)
                        Pastiglia('Inattivo', colore: colori.testoSecondario),
                      if (atleta.visitaMedicaScaduta)
                        Pastiglia('Visita scaduta', colore: colori.rosso)
                      else if (atleta.visitaMedicaInScadenza)
                        Pastiglia(
                          'Visita in scadenza',
                          colore: colori.attenzione,
                        ),
                    ],
                  )
                : null,
            mostraFreccia: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IndicatoreBenessere(clubId: atleta.clubId, atletaId: atleta.id),
                PopupMenuButton<VoidCallback>(
                  icon: Icon(Icons.more_vert, color: colori.testoSecondario),
                  tooltip: 'Altre azioni',
                  onSelected: (azione) => azione(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: () => onTapModifica(atleta),
                      child: const _VoceMenu(
                        icona: Icons.edit_outlined,
                        etichetta: 'Modifica anagrafica',
                      ),
                    ),
                    PopupMenuItem(
                      value: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            GestisciAccountAtletaDialog(atleta: atleta),
                      ),
                      child: _VoceMenu(
                        icona: atleta.haAccountCollegato
                            ? Icons.verified_user_outlined
                            : Icons.person_add_alt_outlined,
                        etichetta: 'Account atleta',
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: () => onTapElimina(atleta),
                      child: const _VoceMenu(
                        icona: Icons.delete_outline,
                        etichetta: 'Elimina atleta',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => onTap(atleta),
          ),
      ],
    );
  }
}

class _VoceMenu extends StatelessWidget {
  const _VoceMenu({required this.icona, required this.etichetta});

  final IconData icona;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(icona, size: 20, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(
          etichetta,
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
      ],
    );
  }
}

/// Percentuale di presenze nella riga dei metadati. `null` (nessun
/// allenamento rilevante su cui calcolarla) mostra "—" invece di un
/// fuorviante 0%.
String _etichettaPresenze(double? percentuale) =>
    'Presenze ${percentuale == null ? '—' : '${percentuale.round()}%'}';

class _AvatarAtleta extends StatelessWidget {
  const _AvatarAtleta({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final iniziali = [
      if (atleta.nome.isNotEmpty) atleta.nome[0],
      if (atleta.cognome.isNotEmpty) atleta.cognome[0],
    ].join().toUpperCase();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atleta.attivo
            ? colori.azione.withValues(alpha: 0.16)
            : colori.superficieAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        iniziali.isEmpty ? '?' : iniziali,
        style: AppTypography.corpoForte.copyWith(
          color: atleta.attivo ? colori.azione : colori.testoTenue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
