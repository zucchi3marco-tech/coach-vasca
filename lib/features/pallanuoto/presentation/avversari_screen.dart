import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../theme/app_spacing.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/pallanuoto_providers.dart';
import '../domain/scheda_avversario.dart';
import 'scheda_avversario_screen.dart';

/// Gli avversari della squadra, dalle partite (anche delle stagioni
/// passate): prima chi si incontra presto. Un tocco apre la scheda.
class AvversariScreen extends ConsumerWidget {
  const AvversariScreen({
    required this.clubId,
    this.gruppoId,
    this.vistaStaff = true,
    this.oggi,
    super.key,
  });

  final String clubId;

  /// null = tutte le squadre.
  final String? gruppoId;
  final bool vistaStaff;

  /// Per i test.
  final DateTime? oggi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiteAsync = ref.watch(partiteListProvider(clubId));
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: gruppoId)),
    );
    final gruppi = ref.watch(gruppiListProvider(clubId)).value ?? const [];
    final nomeGruppo = {for (final g in gruppi) g.id: g.nome};

    final List<Widget> corpo;
    if (partiteAsync.hasError && !partiteAsync.hasValue) {
      corpo = [
        ErrorBanner(
          messaggio: 'Non è stato possibile caricare le partite.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(partiteAsync.error!),
        ),
      ];
    } else if (!partiteAsync.hasValue) {
      corpo = const [LoadingSkeletonList(righe: 6)];
    } else {
      final elenco = avversariDellaSquadra(
        gruppoId: gruppoId,
        partite: partiteAsync.requireValue,
        oggi: oggi ?? DateTime.now(),
      );
      corpo = elenco.isEmpty
          ? const [
              RiquadroVuoto(
                'Gli avversari arrivano dalle partite: aggiungi la prima '
                'partita della squadra.',
                icona: Icons.shield_outlined,
              ),
            ]
          : [
              GrigliaSchede(
                figli: [
                  for (final a in elenco)
                    SchedaElenco(
                      leading: const IconaRiquadro(Icons.shield_outlined),
                      titolo: a.nome,
                      occhiello: gruppoId == null
                          ? (a.gruppoId == null
                                ? 'Tutto il club'
                                : nomeGruppo[a.gruppoId])
                          : null,
                      sottotitolo: [
                        a.partite == 1 ? '1 partita' : '${a.partite} partite',
                        if (a.prossima != null)
                          'la prossima ${dataCompatta(a.prossima!)}',
                      ].join(' · '),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SchedaAvversarioScreen(
                            clubId: clubId,
                            gruppoId: a.gruppoId,
                            nome: a.nome,
                            vistaStaff: vistaStaff,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ];
    }

    return AppScaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: nomeSquadra.isEmpty ? null : nomeSquadra,
            titolo: 'Avversari',
            sottotitolo: 'Le squadre che avete incontrato o incontrerete',
          ),
          const SizedBox(height: AppSpacing.s24),
          ...corpo,
        ],
      ),
    );
  }
}
