import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/application/tempi_gara_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/pb_slots.dart';
import '../../atleti/domain/tempo_gara.dart';
import '../../atleti/presentation/tempo_gara_form_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/gara_iscritti_providers.dart';
import '../application/gare_providers.dart';
import '../data/gara_iscritti_repository.dart';
import '../domain/elenco_gare.dart';
import '../domain/gara.dart';
import 'gara_form_screen.dart';

/// Scheda di una gara: dati della manifestazione, poi (nei passi
/// successivi) gli atleti iscritti e i loro risultati. Legge la gara
/// dall'elenco, così le modifiche dal form si vedono subito.
class GaraDetailScreen extends ConsumerWidget {
  const GaraDetailScreen({required this.gara, super.key});

  final Gara gara;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final aggiornata = ref
        .watch(gareListProvider(gara.clubId))
        .value
        ?.where((g) => g.id == gara.id)
        .firstOrNull;
    final g = aggiornata ?? gara;
    final nomeGruppo = {
      for (final x in ref.watch(gruppiListProvider(g.clubId)).value ?? [])
        x.id: x.nome,
    }[g.gruppoId];

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: const Text('Gara'),
        actions: [
          IconButton(
            tooltip: 'Modifica',
            onPressed: () async {
              final esito = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => GaraFormScreen(clubId: g.clubId, gara: g),
                ),
              );
              // Gara eliminata dal form: si esce anche dalla sua scheda.
              if (esito == GaraFormScreen.esitoEliminata && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestataPagina(
            occhiello: [
              quandoEsteso(g.data),
              if (g.ora != null && g.ora!.isNotEmpty) 'ore ${g.ora}',
            ].join(' · '),
            titolo: g.nome,
            sottotitolo: [
              if (g.luogo != null && g.luogo!.isNotEmpty) g.luogo!,
              g.diClub ? 'Tutto il club' : (nomeGruppo ?? 'Gruppo'),
            ].join(' · '),
          ),
          if (g.note != null && g.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            PoolCard(
              child: Text(
                g.note!,
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          _SezioneIscritti(gara: g),
          const SizedBox(height: AppSpacing.s24),
          _SezioneRisultati(gara: g),
        ],
      ),
    );
  }
}

/// Gli atleti che partecipano alla gara: una spunta per atleta. Si
/// propongono gli attivi del gruppo della gara (tutti, per una gara di club).
class _SezioneIscritti extends ConsumerWidget {
  const _SezioneIscritti({required this.gara});

  final Gara gara;

  Future<void> _cambia(
    BuildContext context,
    WidgetRef ref,
    String atletaId,
    String? idIscrizione,
    bool iscrivere,
  ) async {
    final repository = ref.read(garaIscrittiRepositoryProvider);
    try {
      if (iscrivere) {
        await repository.iscrivi(
          garaId: gara.id,
          atletaId: atletaId,
          clubId: gara.clubId,
        );
      } else if (idIscrizione != null) {
        await repository.rimuovi(idIscrizione);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Iscrizione non riuscita: ${messaggioErrore(e)}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final atleti =
        ref
            .watch(
              atletiListProvider((clubId: gara.clubId, includeInactive: true)),
            )
            .value ??
        const [];
    final iscritti = ref.watch(garaIscrittiProvider(gara.id)).value ?? const [];
    final idPerAtleta = {for (final i in iscritti) i.atletaId: i.id};
    final elenco = atletiPerIscrizione(gara, atleti, idPerAtleta.keys.toSet());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitoloSezione(
          'Atleti iscritti',
          conteggio: idPerAtleta.length,
          spiegazione:
              'Spunta gli atleti che partecipano alla gara. Si propongono '
              'gli atleti del gruppo della gara; per una gara di tutto il '
              'club, tutti gli atleti attivi.',
        ),
        if (elenco.isEmpty)
          Text(
            'Nessun atleta disponibile per questa gara.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          )
        else
          AppListPanel(
            righe: [
              for (final a in elenco)
                AppListRow(
                  titolo: a.nomeCompleto,
                  trailing: Checkbox(
                    value: idPerAtleta.containsKey(a.id),
                    onChanged: (v) => _cambia(
                      context,
                      ref,
                      a.id,
                      idPerAtleta[a.id],
                      v ?? false,
                    ),
                  ),
                  onTap: () => _cambia(
                    context,
                    ref,
                    a.id,
                    idPerAtleta[a.id],
                    !idPerAtleta.containsKey(a.id),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// I risultati della gara, per ogni atleta iscritto: i tempi nuotati (ogni
/// risultato è anche una voce dello storico tempi dell'atleta) e il
/// pulsante per aggiungerne. Battere il personal best lo aggiorna da solo.
class _SezioneRisultati extends ConsumerWidget {
  const _SezioneRisultati({required this.gara});

  final Gara gara;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final atleti =
        ref
            .watch(
              atletiListProvider((clubId: gara.clubId, includeInactive: true)),
            )
            .value ??
        const <Atleta>[];
    final iscritti = ref.watch(garaIscrittiProvider(gara.id)).value ?? const [];
    final risultati =
        ref.watch(tempiGaraPerGaraProvider(gara.id)).value ??
        const <TempoGara>[];
    final idIscritti = {for (final i in iscritti) i.atletaId};
    final atletiIscritti = [
      for (final a in atleti)
        if (idIscritti.contains(a.id)) a,
    ]..sort((a, b) => a.nomeCompleto.compareTo(b.nomeCompleto));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          'Risultati',
          spiegazione:
              'I tempi nuotati in questa gara, atleta per atleta. Ogni '
              'risultato entra anche nello storico tempi dell\'atleta; se '
              'batte il suo personal best, il personal best si aggiorna da '
              'solo.',
        ),
        const SizedBox(height: AppSpacing.s8),
        if (atletiIscritti.isEmpty)
          Text(
            'Iscrivi gli atleti alla gara per registrarne i risultati.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          )
        else
          for (final a in atletiIscritti) ...[
            _RisultatiAtleta(
              gara: gara,
              atleta: a,
              risultati: [
                for (final r in risultati)
                  if (r.atletaId == a.id) r,
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
      ],
    );
  }
}

class _RisultatiAtleta extends StatelessWidget {
  const _RisultatiAtleta({
    required this.gara,
    required this.atleta,
    required this.risultati,
  });

  final Gara gara;
  final Atleta atleta;
  final List<TempoGara> risultati;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            atleta.nomeCompleto,
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          if (risultati.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            for (final r in risultati)
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TempoGaraFormScreen(atleta: atleta, tempoGara: r),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${r.distanzaM} m ${capitalizzaParola(r.stile)} '
                          '· vasca ${r.vascaM} m',
                          style: AppTypography.corpo.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ),
                      Text(
                        formatPaceSeconds(r.tempoS),
                        style: AppTypography.numerica(
                          AppTypography.corpoForte.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.s4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TempoGaraFormScreen(
                    atleta: atleta,
                    garaId: gara.id,
                    nomeGara: gara.nome,
                    dataIniziale: gara.data,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi risultato'),
            ),
          ),
        ],
      ),
    );
  }
}
