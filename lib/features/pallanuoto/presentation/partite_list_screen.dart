import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/entrata_a_cascata.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/data/stagioni_repository.dart';
import '../../stagioni/domain/stagione.dart';
import '../../stagioni/presentation/stagione_detail_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import '../domain/elenco_partite.dart';
import '../domain/partita.dart';
import 'chip_risultato.dart';
import 'distinta_screen.dart';
import 'partita_form_screen.dart';

/// Elenco delle partite della stagione in corso del gruppo, divise fra
/// prossime (dalla più vicina) e giocate (dalla più recente, con il
/// risultato). Una partita nuova si crea dalla testata (nella stagione
/// mostrata) o dal calendario della stagione.
class PartiteListScreen extends ConsumerWidget {
  const PartiteListScreen({
    required this.clubId,
    this.filtroGruppoId,
    this.onVaiAStagioni,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (mostra le partite di tutti i gruppi).
  final String? filtroGruppoId;

  /// Porta alla tab Stagioni (da lì si crea la stagione e le sue partite).
  final VoidCallback? onVaiAStagioni;

  List<Widget> _elenco(BuildContext context, List<Partita> partite) {
    final colori = context.colori;
    final ambra = context.dominio.evidenzaAmbra;
    final oggi = soloData(DateTime.now());
    final prossime = partite.where((p) => !p.data.isBefore(oggi)).toList();
    final giocate = partite.where((p) => p.data.isBefore(oggi)).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    Widget scheda(Partita p, {required bool giocata}) {
      final oggiStesso = giorniTra(oggi, p.data) == 0;
      void modifica() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartitaFormScreen(clubId: clubId, partita: p),
        ),
      );
      return SchedaElenco(
        leading: RiquadroData(p.data, colore: ambra, spento: giocata),
        occhiello: oggiStesso ? 'Oggi' : null,
        evidenza: oggiStesso ? ambra : null,
        titolo: 'vs ${p.avversario}',
        sottotitolo: [
          if (!oggiStesso) traQuanto(p.data),
          if (p.ora != null && p.ora!.isNotEmpty) p.ora!,
          p.inCasa ? 'In casa' : 'In trasferta',
        ].join(' · '),
        sotto: p.gruppoId == null || p.importanza == 'alta'
            ? Wrap(
                spacing: AppSpacing.s4,
                runSpacing: AppSpacing.s4,
                children: [
                  if (p.importanza == 'alta')
                    Pastiglia('Importante', colore: colori.attenzione),
                  if (p.gruppoId == null)
                    Pastiglia('Tutto il club', colore: colori.testoSecondario),
                ],
              )
            : null,
        trailing: giocata
            ? ChipRisultato(partita: p)
            : IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifica partita',
                onPressed: modifica,
              ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DistintaScreen(partita: p))),
        onLongPress: modifica,
      );
    }

    return [
      if (prossime.isNotEmpty) ...[
        SezioneSchede(
          titolo: 'Prossime',
          figli: [for (final p in prossime) scheda(p, giocata: false)],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      if (giocate.isNotEmpty)
        SezioneSchede(
          titolo: 'Giocate',
          figli: [for (final p in giocate) scheda(p, giocata: true)],
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(clubId));
    final partiteAsync = ref.watch(partiteListProvider(clubId));
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: filtroGruppoId)),
    );
    final stagione = stagioniAsync.hasValue
        ? stagionePerElenco(stagioniAsync.requireValue, filtroGruppoId)
        : null;

    final List<Widget> corpo;
    final errore = stagioniAsync.error ?? partiteAsync.error;
    if (errore != null) {
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare le partite.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(errore),
        ),
      ];
    } else if (!stagioniAsync.hasValue || !partiteAsync.hasValue) {
      corpo = const [LoadingSkeletonList(righe: 6)];
    } else if (stagione == null) {
      corpo = [
        EmptyState(
          icona: Icons.sports_handball_outlined,
          titolo: 'Nessuna stagione',
          descrizione:
              'Le partite appartengono a una stagione: crea prima la '
              'stagione del gruppo.',
          azionePrincipale: 'Vai alle stagioni',
          onAzionePrincipale: onVaiAStagioni,
        ),
      ];
    } else {
      final partite = partiteDellaStagione(
        stagione,
        partiteAsync.requireValue,
        filtroGruppoId,
      );
      corpo = partite.isEmpty
          ? [
              EmptyState(
                icona: Icons.sports_handball_outlined,
                titolo: 'Nessuna partita in questa stagione',
                descrizione:
                    'Aggiungi la prima partita di «${stagione.nome}»: poi '
                    'prepari la distinta e la segui dal vivo.',
                azionePrincipale: 'Nuova partita',
                onAzionePrincipale: () => _apriNuova(context, stagione),
              ),
            ]
          : _elenco(context, partite);
    }

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(partiteRepositoryProvider).refreshFromRemote(clubId);
          await ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            EntrataACascata(
              indice: 0,
              child: TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Partite',
                sottotitolo: stagione?.nome,
                azioni: [
                  if (stagione != null) ...[
                    AzioneTestata(
                      icona: Icons.add,
                      etichetta: 'Nuova partita',
                      principale: true,
                      onTap: () => _apriNuova(context, stagione),
                    ),
                    AzioneTestata(
                      icona: Icons.calendar_month_outlined,
                      etichetta: 'Calendario',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              StagioneDetailScreen(stagione: stagione),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            ...corpo,
          ],
        ),
      ),
    );
  }

  void _apriNuova(BuildContext context, Stagione stagione) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartitaFormScreen(clubId: clubId, stagione: stagione),
        ),
      );
}
