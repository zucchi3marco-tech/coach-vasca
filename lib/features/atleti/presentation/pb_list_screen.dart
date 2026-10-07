import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../tabelle_passi/application/tabelle_passi_providers.dart';
import '../../tabelle_passi/presentation/tabelle_passi_screen.dart';
import '../../test/application/test_providers.dart';
import '../../test/data/test_repository.dart';
import '../../test/domain/test_ingresso.dart';
import '../../test/presentation/test_form_screen.dart';
import '../application/personal_best_providers.dart';
import '../domain/atleta.dart';
import '../domain/pb_slots.dart';
import '../domain/personal_best.dart';
import 'pb_form_screen.dart';
import 'scheda_tempo.dart';

/// Tabella di tutti i personal best possibili per lo sport dell'atleta
/// (FASE 10, punto 3): ogni combinazione stile+distanza è sempre
/// visibile, registrata o no, così si vede a colpo d'occhio cosa manca.
class PbListScreen extends ConsumerWidget {
  const PbListScreen({required this.atleta, super.key});

  final Atleta atleta;

  Future<void> _confermaEliminazioneTest(
    BuildContext context,
    WidgetRef ref,
    TestIngresso test,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il test?'),
        content: Text(
          'Verranno eliminate anche le eventuali tabelle passi collegate a '
          'questo test (${test.tipo} del '
          '${test.dataTest.day.toString().padLeft(2, '0')}/'
          '${test.dataTest.month.toString().padLeft(2, '0')}/'
          '${test.dataTest.year}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (conferma == true) {
      await ref.read(testRepositoryProvider).deleteTest(test.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync = ref.watch(personalBestListProvider(atleta.id));
    final testAsync = ref.watch(testListProvider(atleta.id));

    void apriForm({
      required String stile,
      required int distanzaM,
      PersonalBest? personalBest,
    }) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PbFormScreen(
          atleta: atleta,
          stile: stile,
          distanzaM: distanzaM,
          personalBest: personalBest,
        ),
      ),
    );

    void apriFormTest() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TestFormScreen(atleta: atleta)));

    final test = testAsync.value;

    return AppScaffold(
      // Nome e titolo stanno in grande nella testata.
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: pbAsync.when(
        data: (righe) {
          // Il piu' veloce, se per qualche motivo ci fosse piu' di un
          // tempo salvato per la stessa combinazione stile+distanza.
          final migliorePerSlot = <String, PersonalBest>{};
          for (final pb in righe) {
            final chiave = '${pb.stile}_${pb.distanzaM}';
            final attuale = migliorePerSlot[chiave];
            if (attuale == null || pb.tempoS < attuale.tempoS) {
              migliorePerSlot[chiave] = pb;
            }
          }

          final slots = slotsPerSport(atleta.sport);
          final stiliOrdinati = <String>[];
          for (final s in slots) {
            if (!stiliOrdinati.contains(s.stile)) stiliOrdinati.add(s.stile);
          }
          final registrati = slots
              .where(
                (s) => migliorePerSlot['${s.stile}_${s.distanzaM}'] != null,
              )
              .length;

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                occhiello: atleta.nomeCompleto,
                titolo: 'Personal best',
                numeri: [
                  NumeroTestata(
                    valore: '$registrati/${slots.length}',
                    etichetta: 'Tempi registrati',
                  ),
                  NumeroTestata(
                    valore: test == null ? '—' : '${test.length}',
                    etichetta: 'Test BVS',
                  ),
                ],
                azioni: [
                  AzioneTestata(
                    icona: Icons.speed_outlined,
                    etichetta: 'Nuovo test BVS',
                    principale: true,
                    onTap: apriFormTest,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
              // Un "tabellone" per stile: ogni distanza e' una casella col
              // tempo in grande, registrato o no, cosi' si vede cosa manca.
              for (final stile in stiliOrdinati) ...[
                TitoloSezione(capitalizzaParola(stile)),
                GrigliaSchede(
                  larghezzaMinimaColonna: 150,
                  colonneMassime: 4,
                  cascata: false,
                  figli: [
                    for (final slot in slots.where((s) => s.stile == stile))
                      Builder(
                        builder: (context) {
                          final pb =
                              migliorePerSlot['${slot.stile}_${slot.distanzaM}'];
                          return SchedaTempo(
                            distanza: '${slot.distanzaM} m',
                            tempo: pb == null
                                ? null
                                : formatPaceSeconds(pb.tempoS),
                            sotto: pb == null ? 'Aggiungi' : null,
                            onTap: () => apriForm(
                              stile: slot.stile,
                              distanzaM: slot.distanzaM,
                              personalBest: pb,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
              TitoloSezione(
                'Test BVS',
                conteggio: test?.length,
                spiegazione:
                    'Il test di soglia: dal passo medio si calcolano le '
                    'tabelle dei passi per zona, usate dalle ripartenze '
                    'e dalla generazione degli allenamenti.',
              ),
              testAsync.when(
                data: (test) => AppListPanel(
                  righe: test.isEmpty
                      ? [
                          AppListRow(
                            leading: const Icon(Icons.add_circle_outline),
                            titolo: 'Aggiungi il primo test BVS',
                            onTap: apriFormTest,
                          ),
                        ]
                      : [
                          for (final t in test)
                            _TestTile(
                              test: t,
                              atleta: atleta,
                              onDelete: () =>
                                  _confermaEliminazioneTest(context, ref, t),
                            ),
                        ],
                ),
                loading: () => const LoadingSkeletonList(righe: 2),
                error: (error, _) => ErrorBanner(
                  messaggio: 'Non è stato possibile caricare i test.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare i personal best.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

class _TestTile extends ConsumerWidget {
  const _TestTile({
    required this.test,
    required this.atleta,
    required this.onDelete,
  });

  final TestIngresso test;
  final Atleta atleta;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabellaGenerata =
        ref.watch(tabellePassiProvider(test.id)).value?.isNotEmpty ?? false;

    final colori = context.colori;
    return AppListRow(
      leading: Icon(
        tabellaGenerata ? Icons.table_chart : Icons.table_chart_outlined,
        color: tabellaGenerata ? colori.ok : colori.testoSecondario,
      ),
      titolo: '${test.tipo} — ${formatPaceSeconds(test.passoMedio100S)}/100m',
      sottotitolo:
          '${dataCompatta(test.dataTest)} ${test.dataTest.year} · '
          '${test.distanzaTotaleM} m in ${formatPaceSeconds(test.tempoTotaleS)}',
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Elimina test',
        onPressed: onDelete,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TabellePassiScreen(test: test, atleta: atleta),
        ),
      ),
    );
  }
}
