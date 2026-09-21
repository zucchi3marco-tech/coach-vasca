import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../core/utils/error_messages.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
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

  static const _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  String _formattaData(DateTime d) =>
      '${_nomiGiorni[d.weekday - 1]} ${d.day}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

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

    Widget riga(IconData icona, String testo) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Icon(icona, size: 20, color: colori.testoSecondario),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              testo,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ),
        ],
      ),
    );

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(g.nome),
        actions: [
          TextButton.icon(
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
            label: const Text('Modifica'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          riga(Icons.calendar_today_outlined, _formattaData(g.data)),
          if (g.ora != null && g.ora!.isNotEmpty)
            riga(Icons.access_time, g.ora!),
          if (g.luogo != null && g.luogo!.isNotEmpty)
            riga(Icons.place_outlined, g.luogo!),
          riga(
            Icons.groups_outlined,
            g.diClub ? 'Tutto il club' : (nomeGruppo ?? 'Gruppo'),
          ),
          if (g.note != null && g.note!.isNotEmpty)
            riga(Icons.notes_outlined, g.note!),
          const SizedBox(height: AppSpacing.s24),
          _SezioneIscritti(gara: g),
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
        SectionHeader(
          'Atleti iscritti (${idPerAtleta.length})',
          spiegazione:
              'Spunta gli atleti che partecipano alla gara. Si propongono '
              'gli atleti del gruppo della gara; per una gara di tutto il '
              'club, tutti gli atleti attivi.',
        ),
        const SizedBox(height: AppSpacing.s8),
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
