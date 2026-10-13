import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/programma_secco.dart';
import 'programma_secco_form_screen.dart';
import 'programma_secco_screen.dart';

/// "6 settimane · 2 sedute da 15'".
String riassuntoProgramma({
  required int settimane,
  required int sedute,
  required int minuti,
}) => [
  settimane == 1 ? '1 settimana' : '$settimane settimane',
  '${sedute == 1 ? '1 seduta' : '$sedute sedute'} da $minuti\'',
].join(' · ');

/// I programmi a secco del club e, sotto, quelli pronti non ancora
/// aggiunti: un tocco apre un programma, un tocco su uno pronto lo porta
/// nel club con i suoi esercizi e lo apre.
class ProgrammiSeccoScreen extends ConsumerStatefulWidget {
  const ProgrammiSeccoScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<ProgrammiSeccoScreen> createState() =>
      _ProgrammiSeccoScreenState();
}

class _ProgrammiSeccoScreenState extends ConsumerState<ProgrammiSeccoScreen> {
  /// Il programma pronto che si sta aggiungendo.
  String? _aggiungo;

  void _apri(ProgrammaSecco p) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ProgrammaSeccoScreen(clubId: widget.clubId, programmaId: p.id),
    ),
  );

  Future<void> _nuovo() async {
    final creato = await Navigator.of(context).push<ProgrammaSecco>(
      MaterialPageRoute(
        builder: (_) => ProgrammaSeccoFormScreen(clubId: widget.clubId),
      ),
    );
    if (creato != null && mounted) _apri(creato);
  }

  Future<void> _aggiungiPronto(ProgrammaPronto pronto) async {
    setState(() => _aggiungo = pronto.chiave);
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final programma = await ref
          .read(seccoRepositoryProvider)
          .aggiungiProgrammaPronto(widget.clubId, pronto);
      if (!mounted) return;
      messaggero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Programma aggiunto: ora puoi cambiarlo'),
          ),
        );
      _apri(programma);
    } catch (e) {
      messaggero
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
    } finally {
      if (mounted) setState(() => _aggiungo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final viola = context.dominio.evidenzaViola;
    final programmiAsync = ref.watch(programmiSeccoProvider(widget.clubId));
    final oggi = soloData(DateTime.now());
    // I programmi con sedute ancora da fare.
    final inCorso = {
      for (final a
          in ref.watch(allenamentiListProvider(widget.clubId)).value ??
              const [])
        if (a.programmaId != null && !a.data.isBefore(oggi)) a.programmaId,
    };

    return AppScaffold(
      appBar: AppBar(),
      body: programmiAsync.when(
        data: (programmi) {
          final giaNelClub = {for (final p in programmi) ?p.modello};
          final pronti = [
            for (final m in modelliProgrammi)
              if (!giaNelClub.contains(m.chiave)) m,
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                occhiello: 'A secco',
                titolo: 'Programmi',
                sottotitolo:
                    'Settimane di sedute già scritte: le metti nel '
                    'calendario di una squadra e le sedute si creano da sole.',
                numeri: [
                  NumeroTestata(
                    valore: '${programmi.length}',
                    etichetta: 'Programmi',
                  ),
                ],
                azioni: [
                  AzioneTestata(
                    icona: Icons.add,
                    etichetta: 'Nuovo programma',
                    principale: true,
                    onTap: _nuovo,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              if (programmi.isEmpty)
                const RiquadroVuoto(
                  'Nessun programma del club: parti da uno pronto qui sotto, '
                  'o creane uno nuovo.',
                  icona: Icons.event_repeat,
                )
              else ...[
                TitoloSezione(
                  'I programmi del club',
                  conteggio: programmi.length,
                ),
                GrigliaSchede(
                  figli: [
                    for (final p in programmi)
                      SchedaElenco(
                        leading: IconaRiquadro(
                          Icons.event_repeat,
                          colore: viola,
                          dimensione: 48,
                        ),
                        titolo: p.nome,
                        sottotitolo: riassuntoProgramma(
                          settimane: p.settimane.length,
                          sedute: p.sedutePerSettimana,
                          minuti: p.durataMin,
                        ),
                        trailing: inCorso.contains(p.id)
                            ? Pastiglia('Nel calendario', colore: colori.ok)
                            : null,
                        onTap: () => _apri(p),
                      ),
                  ],
                ),
              ],
              if (pronti.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                TitoloSezione(
                  'Programmi pronti',
                  conteggio: pronti.length,
                  spiegazione:
                      'Da usare così o da cambiare: un tocco li aggiunge al '
                      'club, con i loro esercizi.',
                ),
                GrigliaSchede(
                  figli: [
                    for (final m in pronti)
                      SchedaElenco(
                        leading: IconaRiquadro(
                          Icons.event_repeat,
                          colore: colori.testoSecondario,
                          dimensione: 48,
                        ),
                        titolo: m.nome,
                        sottotitolo: riassuntoProgramma(
                          settimane: m.settimane,
                          sedute: m.sedute.length,
                          minuti: m.durataMin,
                        ),
                        sotto: Text(
                          m.descrizione,
                          style: AppTypography.piccolo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                        trailing: _aggiungo == m.chiave
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.add_circle_outline,
                                color: colori.azione,
                                semanticLabel: 'Aggiungi',
                              ),
                        mostraFreccia: false,
                        onTap: _aggiungo == null
                            ? () => _aggiungiPronto(m)
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (errore, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i programmi.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(errore),
          ),
        ),
      ),
    );
  }
}
