import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../pallanuoto/presentation/distinta_screen.dart';
import '../application/impegni_providers.dart';
import '../domain/impegno.dart';
import 'impegno_form_screen.dart';

/// Un impegno: che cosa, quando, per chi, dove e le note; per un torneo,
/// una trasferta o un collegiale anche le partite della squadra in quei
/// giorni. Con [modificabile] (lo staff) la matita apre il modulo.
class ImpegnoScreen extends ConsumerWidget {
  const ImpegnoScreen({
    required this.impegno,
    this.modificabile = true,
    super.key,
  });

  final Impegno impegno;
  final bool modificabile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    // La versione aggiornata dopo una modifica (o null se è stato tolto).
    final elenco = ref.watch(impegniListProvider(impegno.clubId)).value;
    final attuale = elenco == null
        ? impegno
        : elenco.where((i) => i.id == impegno.id).firstOrNull;
    if (attuale == null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('Impegno')),
        body: Center(
          child: Text(
            'Questo impegno è stato tolto.',
            style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
          ),
        ),
      );
    }
    final squadre = {
      for (final g in ref.watch(gruppiListProvider(attuale.clubId)).value ?? [])
        g.id: g.nome,
    };
    final conPartite = attuale.tipo != TipoImpegno.riposo;
    final partite = conPartite
        ? [
            for (final p
                in ref.watch(partiteListProvider(attuale.clubId)).value ??
                    const <Partita>[])
              if (attuale.contiene(p.data) &&
                  visibileNelGruppo(
                    gruppoDelRecord: p.gruppoId,
                    gruppoSelezionato: attuale.gruppoId,
                  ))
                p,
          ]
        : const <Partita>[];
    partite.sort((a, b) => a.data.compareTo(b.data));

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(attuale.tipo.etichetta),
        actions: [
          if (modificabile)
            IconButton(
              tooltip: 'Modifica',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ImpegnoFormScreen(
                    clubId: attuale.clubId,
                    impegno: attuale,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TestataPagina(
            occhiello: [
              attuale.tipo.etichetta,
              attuale.gruppoId == null
                  ? 'Tutto il club'
                  : squadre[attuale.gruppoId] ?? 'Una squadra',
            ].join(' · '),
            titolo: attuale.titolo,
            sottotitolo: [
              periodoImpegno(attuale, dataCompatta),
              if (attuale.giorni > 1) '${attuale.giorni} giorni',
              if ((attuale.luogo ?? '').isNotEmpty) attuale.luogo!,
            ].join(' · '),
          ),
          if ((attuale.note ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              attuale.note!,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
          if (partite.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s24),
            TitoloSezione(
              'Le partite in questi giorni',
              conteggio: partite.length,
            ),
            AppListPanel(
              righe: [
                for (final p in partite)
                  AppListRow(
                    titolo: '${p.squadraCasa} - ${p.squadraTrasferta}',
                    sottotitolo: [
                      dataCompatta(p.data),
                      if ((p.ora ?? '').isNotEmpty) p.ora!,
                      if ((p.luogo ?? '').isNotEmpty) p.luogo!,
                    ].join(' · '),
                    trailing: modificabile
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: modificabile
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DistintaScreen(partita: p),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
