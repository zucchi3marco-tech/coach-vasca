import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/domain/atleta.dart';
import '../../gare/application/gare_providers.dart';
import '../../gare/domain/gara.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/stagioni_providers.dart';
import '../domain/evento_calendario.dart';
import '../domain/stagione.dart';
import 'calendario_stagione_view.dart';

/// Stagione in corso del gruppo dell'atleta (FASE 13, punto 3): campionato
/// e obiettivo in testata e il calendario con partite (pallanuoto) o gare
/// (nuoto) della squadra. Sola lettura: nessuna delle azioni di gestione
/// della schermata del coach.
class StagioneAtletaScreen extends ConsumerWidget {
  const StagioneAtletaScreen({
    required this.atleta,
    this.vistaAllenatore = false,
    super.key,
  });

  final Atleta atleta;

  /// Aperta dall'allenatore dalla scheda di un atleta.
  final bool vistaAllenatore;

  void _mostraGiorno(
    BuildContext context,
    DateTime giorno,
    List<EventoCalendario> eventi,
  ) {
    if (eventi.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${traQuanto(giorno)} · ${dataEstesa(giorno)}',
                style: AppTypography.sezione.copyWith(
                  color: sheetContext.colori.testo,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppListPanel(
                righe: [
                  for (final e in eventi)
                    AppListRow(titolo: e.titolo, sottotitolo: e.sottotitolo),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(atleta.clubId));
    final pallanuoto = atleta.sport == 'pallanuoto';
    final partite = pallanuoto
        ? ref.watch(partiteListProvider(atleta.clubId)).value ??
              const <Partita>[]
        : const <Partita>[];
    final gare = pallanuoto
        ? const <Gara>[]
        : ref.watch(gareListProvider(atleta.clubId)).value ?? const <Gara>[];

    String periodo(DateTime d) =>
        '${d.day} ${mesiBrevi[d.month - 1]} ${d.year}';

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(),
      body: stagioniAsync.when(
        data: (stagioni) {
          final corrente = stagioneCorrenteDiGruppo(stagioni, atleta.gruppoId);
          if (corrente == null) {
            return EmptyState(
              icona: Icons.event_note_outlined,
              titolo: 'Nessuna stagione in corso',
              descrizione: 'Non risulta una stagione attiva oggi.',
              azionePrincipale: 'Torna indietro',
              onAzionePrincipale: () => Navigator.of(context).maybePop(),
            );
          }
          final eventi = eventiVisibiliInStagione(corrente, [
            for (final p in partite) EventoCalendario.daPartita(p),
            for (final g in gare) EventoCalendario.daGara(g),
          ]);
          final oggi = soloData(DateTime.now());
          final prossimo = eventi
              .where((e) => !e.data.isBefore(oggi))
              .map((e) => e.data)
              .fold<DateTime?>(
                null,
                (min, d) => min == null || d.isBefore(min) ? d : min,
              );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TestataPagina(
                occhiello: [
                  vistaAllenatore ? 'Stagione' : 'La mia stagione',
                  '${periodo(corrente.dataInizio)} – '
                      '${periodo(corrente.dataFine)}',
                ].join(' · '),
                titolo: corrente.nome,
                sottotitolo:
                    (corrente.campionato ?? '').isEmpty &&
                        (corrente.obiettivo ?? '').isEmpty
                    ? null
                    : [
                        if ((corrente.campionato ?? '').isNotEmpty)
                          corrente.campionato!,
                        if ((corrente.obiettivo ?? '').isNotEmpty)
                          'Obiettivo: ${corrente.obiettivo}',
                      ].join(' · '),
                numeri: [
                  NumeroTestata(
                    valore: '${eventi.length}',
                    etichetta: pallanuoto ? 'Partite' : 'Gare',
                  ),
                  NumeroTestata(
                    valore: prossimo == null ? '—' : dataCompatta(prossimo),
                    etichetta: 'La prossima',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              const TitoloSezione(
                'Calendario',
                spiegazione:
                    'I giorni colorati hanno una partita o una gara: '
                    'toccali per vedere cosa c\'è in programma.',
              ),
              PoolCard(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: CalendarioStagioneView(
                      primoGiorno: corrente.dataInizio,
                      ultimoGiorno: corrente.dataFine,
                      eventi: eventi,
                      onGiornoSelezionato: (giorno, eventiDelGiorno) =>
                          _mostraGiorno(context, giorno, eventiDelGiorno),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingSkeletonList(righe: 4),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare la stagione.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }
}
