import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../core/utils/percentuale_presenze.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../benessere/presentation/benessere_squadra.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../home/area_atleta_home_screen.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/domain/presenza.dart';
import '../application/atleti_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import 'atleta_form_screen.dart';
import 'gestisci_account_atleta_dialog.dart';

enum _Ordinamento { cognome, dataNascita, percentualePresenze }

String _formattaData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/'
    '${data.month.toString().padLeft(2, '0')}';

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

  @override
  Widget build(BuildContext context) {
    final filter = (clubId: widget.clubId, includeInactive: _mostraInattivi);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final allenamenti =
        ref.watch(allenamentiListProvider(widget.clubId)).value ?? [];
    final presenze = ref.watch(presenzeClubProvider(widget.clubId)).value ?? [];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RiepilogoClub(
            clubId: widget.clubId,
            filtroGruppoId: widget.filtroGruppoId,
          ),
          const SizedBox(height: AppSpacing.s12),
          CardBenessereSquadra(
            clubId: widget.clubId,
            gruppoId: widget.filtroGruppoId,
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  etichetta: 'Cerca per cognome o nome',
                  suffixIcon: const Icon(Icons.search),
                  onChanged: (value) => setState(() => _ricerca = value),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              PopupMenuButton<_Ordinamento>(
                icon: Icon(Icons.sort, color: context.colori.testoSecondario),
                tooltip: 'Ordina',
                onSelected: (valore) => setState(() => _ordinamento = valore),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _Ordinamento.cognome,
                    child: _VoceMenu(
                      icona: Icons.sort_by_alpha,
                      etichetta: 'Cognome (A-Z)',
                    ),
                  ),
                  PopupMenuItem(
                    value: _Ordinamento.dataNascita,
                    child: _VoceMenu(
                      icona: Icons.cake_outlined,
                      etichetta: 'Data di nascita',
                    ),
                  ),
                  PopupMenuItem(
                    value: _Ordinamento.percentualePresenze,
                    child: _VoceMenu(
                      icona: Icons.percent,
                      etichetta: '% presenze (più alta prima)',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(atletiRepositoryProvider)
                  .refreshFromRemote(widget.clubId),
              child: atletiAsync.when(
                data: (atleti) => _AtletiList(
                  atleti: atleti,
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
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [LoadingSkeletonList(righe: 6)],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ErrorBanner(
                      messaggio: 'Non è stato possibile caricare gli atleti.',
                      suggerimento:
                          'Riprova. Se l\'errore continua, chiudi e riapri '
                          'l\'app.',
                      dettaglioTecnico: messaggioErrore(error),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      persistentFooterButtons: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostra atleti inattivi'),
          value: _mostraInattivi,
          onChanged: (value) => setState(() => _mostraInattivi = value),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _apriForm(context),
        tooltip: 'Nuovo atleta',
        child: const Icon(Icons.add),
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

/// Riepilogo rapido sopra l'elenco: atleti attivi, prossimo allenamento
/// in programma, quanti nei prossimi 7 giorni. Stessa tavolozza
/// "evidenza" della dashboard atleta (DESIGN.md "Dove spendere
/// l'audacia") — qui la sua seconda eccezione esplicita, per dare
/// all'allenatore lo stesso colpo d'occhio a colori sulla propria home.
class _RiepilogoClub extends ConsumerWidget {
  const _RiepilogoClub({required this.clubId, required this.filtroGruppoId});

  final String clubId;
  final String? filtroGruppoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominio = context.dominio;
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: false)),
    );
    final allenamentiAsync = ref.watch(allenamentiListProvider(clubId));

    final tuttiAttivi = atletiAsync.value;
    final atletiAttivi = tuttiAttivi == null
        ? null
        : filtroGruppoId == null
        ? tuttiAttivi.length
        : tuttiAttivi.where((a) => a.gruppoId == filtroGruppoId).length;

    var dataProssimoAllenamento = '—';
    var prossimi7Giorni = 0;
    // Solo gli allenamenti del gruppo scelto (e quelli di tutto il club),
    // come nella tab Allenamenti: così i due conteggi coincidono.
    final allenamenti = allenamentiAsync.value?.where(
      (a) => visibileNelGruppo(
        gruppoDelRecord: a.gruppoId,
        gruppoSelezionato: filtroGruppoId,
      ),
    );
    if (allenamenti != null) {
      final oggi = DateTime.now();
      final inizio = DateTime(oggi.year, oggi.month, oggi.day);
      final fine = inizio.add(const Duration(days: 7));
      final futuri = allenamenti.where((a) => !a.data.isBefore(inizio)).toList()
        ..sort((a, b) => a.data.compareTo(b.data));
      if (futuri.isNotEmpty) {
        dataProssimoAllenamento = _formattaData(futuri.first.data);
      }
      prossimi7Giorni = futuri.where((a) => a.data.isBefore(fine)).length;
    }

    return PoolCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      // Su telefono le didascalie lunghe andrebbero a capo, e le tre
      // colonne avrebbero altezze diverse: sotto i ~140 px per colonna
      // si usa la versione breve, sempre su una riga.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final breve = constraints.maxWidth / 3 < 140;
          return Row(
            children: [
              _VoceRiepilogo(
                icona: Icons.groups_outlined,
                colore: dominio.evidenzaCiano,
                etichetta: 'Atleti attivi',
                valore: atletiAttivi == null ? '—' : '$atletiAttivi',
              ),
              _VoceRiepilogo(
                icona: Icons.calendar_month_outlined,
                colore: dominio.evidenzaVerde,
                etichetta: breve ? 'Prossimo' : 'Prossimo allenamento',
                valore: dataProssimoAllenamento,
              ),
              _VoceRiepilogo(
                icona: Icons.event_available_outlined,
                colore: dominio.evidenzaAmbra,
                etichetta: breve ? 'In 7 giorni' : 'Nei prossimi 7 giorni',
                valore: '$prossimi7Giorni',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VoceRiepilogo extends StatelessWidget {
  const _VoceRiepilogo({
    required this.icona,
    required this.colore,
    required this.etichetta,
    required this.valore,
  });

  final IconData icona;
  final Color colore;
  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    // Icona, dato e una didascalia piccola: la riga resta bassa, ma ogni
    // numero dice cosa conta.
    final colori = context.colori;
    return Expanded(
      child: Semantics(
        label: '$etichetta: $valore',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icona, colore: colore, dimensione: 36),
            const SizedBox(height: AppSpacing.s4),
            Text(
              valore,
              style: AppTypography.numerica(
                AppTypography.numeroMedio.copyWith(color: colori.testo),
              ),
            ),
            Text(
              etichetta,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
        ),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icona: Icons.groups_outlined,
            titolo: 'Nessun atleta',
            descrizione:
                'Aggiungi il primo atleta per iniziare a programmare '
                'allenamenti e tenere le presenze.',
            azionePrincipale: 'Nuovo atleta',
            onAzionePrincipale: onTapNuovo,
          ),
        ],
      );
    }

    final filtrati = _filtrati();
    if (filtrati.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icona: Icons.search_off,
            titolo: 'Nessun atleta trovato',
            descrizione: 'Prova a cercare con un altro nome o cognome.',
            azionePrincipale: 'Ho capito',
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: AppListPanel(
        righe: [
          for (final atleta in filtrati)
            AppListRow(
              leading: _AvatarAtleta(atleta: atleta),
              titolo: atleta.nomeCompleto,
              // La percentuale sta nella riga sotto, non accanto al nome:
              // su telefono il nome ha cosi' tutta la larghezza.
              sottotitolo:
                  [
                    atleta.sport == 'nuoto' ? 'Nuoto' : 'Pallanuoto',
                    ?nomeGruppo[atleta.gruppoId],
                    _etichettaPresenze(_percentuale(atleta)),
                  ].join(' · ') +
                  (atleta.attivo ? '' : ' · inattivo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IndicatoreBenessere(
                    clubId: atleta.clubId,
                    atletaId: atleta.id,
                  ),
                  if (atleta.visitaMedicaScaduta)
                    Tooltip(
                      message: 'Visita medica scaduta',
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: colori.attenzione,
                      ),
                    )
                  else if (atleta.visitaMedicaInScadenza)
                    Tooltip(
                      message: 'Visita medica in scadenza',
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: colori.attenzione,
                      ),
                    ),
                  PopupMenuButton<VoidCallback>(
                    icon: Icon(Icons.more_vert, color: colori.testoSecondario),
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
      ),
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
    'presenze ${percentuale == null ? '—' : '${percentuale.round()}%'}';

class _AvatarAtleta extends StatelessWidget {
  const _AvatarAtleta({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final iniziale = atleta.cognome.isNotEmpty
        ? atleta.cognome[0].toUpperCase()
        : '?';
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: atleta.attivo ? colori.azioneTenue : colori.superficieAlt,
        shape: BoxShape.circle,
      ),
      child: Text(
        iniziale,
        style: AppTypography.corpoForte.copyWith(
          color: atleta.attivo ? colori.azione : colori.testoTenue,
        ),
      ),
    );
  }
}
