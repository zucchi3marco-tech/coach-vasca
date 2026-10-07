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
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/data/stagioni_repository.dart';
import '../../stagioni/domain/stagione.dart';
import '../../stagioni/presentation/stagione_detail_screen.dart';
import '../application/gare_providers.dart';
import '../data/gare_repository.dart';
import '../domain/elenco_gare.dart';
import '../domain/gara.dart';
import 'gara_detail_screen.dart';
import 'gara_form_screen.dart';

/// Elenco delle gare della stagione in corso del gruppo (tab «Gare» del
/// nuoto), divise fra prossime (dalla più vicina) e già disputate (dalla
/// più recente). Una gara nuova si crea dalla testata (nella stagione
/// mostrata) o dal calendario della stagione.
class GareListScreen extends ConsumerWidget {
  const GareListScreen({
    required this.clubId,
    this.filtroGruppoId,
    this.onVaiAStagioni,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (gare di tutti i gruppi).
  final String? filtroGruppoId;

  /// Porta alla tab Stagioni (da lì si crea la stagione e le sue gare).
  final VoidCallback? onVaiAStagioni;

  List<Widget> _elenco(BuildContext context, List<Gara> gare) {
    final colori = context.colori;
    final ambra = context.dominio.evidenzaAmbra;
    final oggi = soloData(DateTime.now());
    final prossime = gare.where((g) => !g.data.isBefore(oggi)).toList();
    final disputate = gare.where((g) => g.data.isBefore(oggi)).toList()
      ..sort((a, b) => b.data.compareTo(a.data));

    Widget scheda(Gara g, {required bool passata}) {
      final oggiStesso = giorniTra(oggi, g.data) == 0;
      return SchedaElenco(
        leading: RiquadroData(g.data, colore: ambra, spento: passata),
        occhiello: oggiStesso ? 'Oggi' : null,
        evidenza: oggiStesso ? ambra : null,
        attenuata: passata,
        titolo: g.nome,
        sottotitolo: [
          if (!oggiStesso) traQuanto(g.data),
          if (g.ora != null && g.ora!.isNotEmpty) g.ora!,
          if (g.luogo != null && g.luogo!.isNotEmpty) g.luogo!,
        ].join(' · '),
        sotto: g.diClub || g.importanza == 'alta'
            ? Wrap(
                spacing: AppSpacing.s4,
                runSpacing: AppSpacing.s4,
                children: [
                  if (g.importanza == 'alta')
                    Pastiglia('Importante', colore: colori.attenzione),
                  if (g.diClub)
                    Pastiglia('Tutto il club', colore: colori.testoSecondario),
                ],
              )
            : null,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => GaraDetailScreen(gara: g))),
      );
    }

    return [
      if (prossime.isNotEmpty) ...[
        TitoloSezione('Prossime', conteggio: prossime.length),
        GrigliaSchede(
          figli: [for (final g in prossime) scheda(g, passata: false)],
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
      if (disputate.isNotEmpty) ...[
        TitoloSezione('Già disputate', conteggio: disputate.length),
        GrigliaSchede(
          figli: [for (final g in disputate) scheda(g, passata: true)],
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(clubId));
    final gareAsync = ref.watch(gareListProvider(clubId));
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: filtroGruppoId)),
    );
    final stagione = stagioniAsync.hasValue
        ? stagionePerElenco(stagioniAsync.requireValue, filtroGruppoId)
        : null;

    final List<Widget> corpo;
    final errore = stagioniAsync.error ?? gareAsync.error;
    if (errore != null) {
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare le gare.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(errore),
        ),
      ];
    } else if (!stagioniAsync.hasValue || !gareAsync.hasValue) {
      corpo = const [LoadingSkeletonList(righe: 6)];
    } else if (stagione == null) {
      corpo = [
        EmptyState(
          icona: Icons.emoji_events_outlined,
          titolo: 'Nessuna stagione',
          descrizione:
              'Le gare appartengono a una stagione: crea prima la '
              'stagione del gruppo.',
          azionePrincipale: 'Vai alle stagioni',
          onAzionePrincipale: onVaiAStagioni,
        ),
      ];
    } else {
      final gare = gareDellaStagione(
        stagione,
        gareAsync.requireValue,
        filtroGruppoId,
      );
      corpo = gare.isEmpty
          ? [
              EmptyState(
                icona: Icons.emoji_events_outlined,
                titolo: 'Nessuna gara in questa stagione',
                descrizione:
                    'Aggiungi la prima gara di «${stagione.nome}»: poi '
                    'iscrivi gli atleti e registri i risultati.',
                azionePrincipale: 'Nuova gara',
                onAzionePrincipale: () => _apriNuova(context, stagione),
              ),
            ]
          : _elenco(context, gare);
    }

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(gareRepositoryProvider).refreshFromRemote(clubId);
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
                titolo: 'Gare',
                sottotitolo: stagione?.nome,
                azioni: [
                  if (stagione != null) ...[
                    AzioneTestata(
                      icona: Icons.add,
                      etichetta: 'Nuova gara',
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
          builder: (_) => GaraFormScreen(clubId: clubId, stagione: stagione),
        ),
      );
}
