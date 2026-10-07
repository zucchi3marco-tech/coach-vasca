import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/gruppo_visibilita.dart';
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
import '../application/stagioni_providers.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';
import 'stagione_detail_screen.dart';
import 'stagione_form_screen.dart';

class StagioniListScreen extends ConsumerWidget {
  const StagioniListScreen({
    required this.clubId,
    this.filtroGruppoId,
    super.key,
  });

  final String clubId;

  /// null = nessun filtro (stagioni di tutti i gruppi).
  final String? filtroGruppoId;

  String _periodo(Stagione s) =>
      '${s.dataInizio.day} ${mesiBrevi[s.dataInizio.month - 1]} '
      '${s.dataInizio.year} – ${s.dataFine.day} '
      '${mesiBrevi[s.dataFine.month - 1]} ${s.dataFine.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Una stagione con gruppo è visibile solo a quel gruppo; una senza
    // gruppo è una stagione di club, visibile a tutti.
    final stagioniAsync = ref
        .watch(stagioniListProvider(clubId))
        .whenData(
          (stagioni) =>
              stagioni
                  .where(
                    (s) => visibileNelGruppo(
                      gruppoDelRecord: s.gruppoId,
                      gruppoSelezionato: filtroGruppoId,
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio)),
        );
    final nomiGruppi = {
      for (final g in ref.watch(gruppiListProvider(clubId)).value ?? [])
        g.id: g.nome,
    };
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: filtroGruppoId)),
    );
    final colori = context.colori;
    final verde = context.dominio.evidenzaVerde;
    final oggi = DateTime.now();

    void apriNuova() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StagioneFormScreen(clubId: clubId)),
    );

    Widget scheda(Stagione s) {
      final inCorso = !oggi.isBefore(s.dataInizio) && !oggi.isAfter(s.dataFine);
      final conclusa = oggi.isAfter(s.dataFine);
      // Il gruppo si scrive solo quando aggiunge qualcosa (vedi
      // Allenamenti): con una squadra scelta in alto era sempre lo stesso.
      final gruppo = s.gruppoId == null
          ? 'Tutto il club'
          : filtroGruppoId == null
          ? nomiGruppi[s.gruppoId]
          : null;
      return SchedaElenco(
        leading: IconaRiquadro(
          Icons.event_note,
          colore: conclusa ? colori.testoSecondario : verde,
          dimensione: 56,
        ),
        occhiello: inCorso
            ? 'In corso'
            : conclusa
            ? 'Conclusa'
            : 'Inizia ${traQuanto(s.dataInizio).toLowerCase()}',
        evidenza: inCorso ? verde : null,
        attenuata: conclusa,
        titolo: s.nome,
        sottotitolo: [
          _periodo(s),
          ?gruppo,
          if (s.campionato != null && s.campionato!.isNotEmpty) s.campionato!,
        ].join(' · '),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StagioneDetailScreen(stagione: s)),
        ),
      );
    }

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            EntrataACascata(
              indice: 0,
              child: TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Stagioni',
                sottotitolo:
                    'Il calendario di partite e gare, le statistiche e i '
                    'record di ogni stagione.',
                azioni: [
                  AzioneTestata(
                    icona: Icons.add,
                    etichetta: 'Nuova stagione',
                    principale: true,
                    onTap: apriNuova,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            stagioniAsync.when(
              data: (stagioni) => stagioni.isEmpty
                  ? EmptyState(
                      icona: Icons.event_note_outlined,
                      titolo: 'Nessuna stagione',
                      descrizione:
                          'Crea la prima stagione del gruppo: avrà il suo '
                          'calendario, dove aggiungi partite o gare, e le '
                          'statistiche di fine stagione.',
                      azionePrincipale: 'Nuova stagione',
                      onAzionePrincipale: apriNuova,
                    )
                  : GrigliaSchede(figli: [for (final s in stagioni) scheda(s)]),
              loading: () => const LoadingSkeletonList(righe: 4),
              error: (error, _) => ErrorBanner(
                messaggio: 'Non è stato possibile caricare le stagioni.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
