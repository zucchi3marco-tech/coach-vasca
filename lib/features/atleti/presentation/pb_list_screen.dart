import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../tabelle_passi/application/tabelle_passi_providers.dart';
import '../../tabelle_passi/presentation/tabelle_passi_screen.dart';
import '../../test/application/test_providers.dart';
import '../../test/application/test_club_providers.dart';
import '../../test/data/spiegazioni_test_repository.dart';
import '../../test/data/test_repository.dart';
import '../../test/domain/massimale.dart';
import '../../test/domain/spiegazioni_test.dart';
import '../../test/domain/test_club.dart';
import '../../test/domain/test_ingresso.dart';
import '../../test/presentation/segna_risultato_screen.dart';
import '../../test/presentation/spiegazione_test.dart';
import '../../test/presentation/test_form_screen.dart';
import '../application/current_atleta_provider.dart';
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

          final slots = slotsPersonalBest;
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
              _TestDiSquadra(atleta: atleta),
              TitoloSezione(
                'Test BVS',
                conteggio: test?.length,
                spiegazione:
                    'Il test di soglia: dal passo medio si calcolano le '
                    'tabelle dei passi per zona, usate dalle ripartenze '
                    'e dalla generazione degli allenamenti.',
              ),
              _ComeSiFannoTestNuoto(atleta: atleta),
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

/// I risultati dell'atleta nei test della squadra (sprint, verticale,
/// tiro...): per ognuno l'ultimo e il migliore. Niente se non ne ha.
class _TestDiSquadra extends ConsumerWidget {
  const _TestDiSquadra({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final test = ref.watch(testClubProvider(atleta.clubId)).value ?? const [];
    final risultati =
        ref.watch(risultatiTestClubProvider(atleta.clubId)).value ?? const [];
    // Sul telefono dell'atleta: i test aperti agli atleti li segna lui.
    final eLui = ref.watch(currentAtletaProvider).value?.id == atleta.id;
    bool aperto(TestClub t) => eLui && t.apertoAtleti && !t.archiviato;
    final righe = [
      for (final t in test)
        if (storicoAtleta(t, risultati, atleta.id) case final suoi
            when suoi.isNotEmpty || aperto(t))
          (test: t, suoi: suoi),
    ];
    if (righe.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitoloSezione('Test di squadra', conteggio: righe.length),
          AppListPanel(
            righe: [
              for (final (:test, :suoi) in righe)
                Builder(
                  builder: (context) {
                    void apri() => _apriTest(
                      context,
                      test: test,
                      suoi: suoi,
                      puoSegnare: aperto(test),
                    );
                    if (suoi.isEmpty) {
                      return AppListRow(
                        onTap: apri,
                        titolo: test.nome,
                        sottotitolo: 'Da segnare: scrivi il tuo risultato',
                        trailing: Icon(
                          Icons.edit_outlined,
                          color: colori.azione,
                        ),
                      );
                    }
                    final punteggi = [
                      for (final r in suoi) test.punteggioDi(r.valori),
                    ];
                    final migliore = punteggi.reduce(
                      (a, b) => test.meglio(a, b) ? a : b,
                    );
                    // Di un massimale, da cosa viene l'ultimo: "40 kg × 5".
                    final sollevato = test.massimale
                        ? descriviSollevato(
                            suoi.last.caricoKg,
                            suoi.last.ripetizioni,
                          )
                        : null;
                    return AppListRow(
                      // Un tocco: i suoi risultati, come si fa e, se il
                      // test è aperto, "Segna un risultato".
                      onTap: apri,
                      titolo: test.nome,
                      sottotitolo: [
                        traQuanto(suoi.last.data),
                        if (sollevato != null)
                          sollevato
                        else if (suoi.length > 1)
                          'migliore ${formattaValore(test.unita, migliore)}',
                      ].join(' · '),
                      trailing: Text(
                        formattaValore(test.unita, punteggi.last),
                        style: AppTypography.numerica(AppTypography.numeroMedio)
                            .copyWith(color: colori.testo),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Il foglio di un test: i suoi risultati (i suoi, scritti da lui, si
  /// toccano per correggerli), "Segna un risultato" se il test è aperto e
  /// "Come si fa".
  void _apriTest(
    BuildContext context, {
    required TestClub test,
    required List<RisultatoTest> suoi,
    required bool puoSegnare,
  }) {
    void segna([RisultatoTest? esistente]) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SegnaRisultatoScreen(
          test: test,
          atleta: atleta,
          esistente: esistente,
        ),
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colori = sheetContext.colori;
        void chiudiE(VoidCallback poi) {
          Navigator.of(sheetContext).pop();
          poi();
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              0,
              AppSpacing.s16,
              AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  test.nome,
                  style: AppTypography.sezione.copyWith(color: colori.testo),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  test.comeSiLegge,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                if (puoSegnare) ...[
                  PrimaryButton(
                    label: 'Segna un risultato',
                    icon: Icons.edit_outlined,
                    onPressed: () => chiudiE(segna),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Come si fa'),
                    onPressed: () => chiudiE(
                      () => mostraComeSiFaTest(
                        context,
                        titolo: test.nome,
                        sotto: test.comeSiLegge,
                        testo: spiegazioneDi(test),
                      ),
                    ),
                  ),
                ),
                if (suoi.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  AppListPanel(
                    righe: [
                      for (final r in suoi.reversed)
                        AppListRow(
                          titolo: dataEstesa(r.data),
                          sottotitolo: [
                            if (r.dallAtleta) 'segnato da te',
                            if (test.massimale)
                              ?descriviSollevato(r.caricoKg, r.ripetizioni),
                            if (test.prove > 1)
                              r.valori
                                  .map(
                                    (v) => formattaValore(
                                      test.unita,
                                      v,
                                      sigla: false,
                                    ),
                                  )
                                  .join(' · '),
                          ].join(' — '),
                          trailing: Text(
                            formattaValore(
                              test.unita,
                              test.punteggioDi(r.valori),
                            ),
                            style: AppTypography.numerica(
                              AppTypography.numeroMedio,
                            ).copyWith(color: colori.testo),
                          ),
                          onTap: puoSegnare && r.dallAtleta
                              ? () => chiudiE(() => segna(r))
                              : null,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "Come si fa il BVS" e "Come si fa il T30": la spiegazione del club
/// (o l'originale). L'allenatore la può cambiare, l'atleta la legge.
class _ComeSiFannoTestNuoto extends ConsumerWidget {
  const _ComeSiFannoTestNuoto({required this.atleta});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scritte =
        ref.watch(spiegazioniTestNuotoProvider(atleta.clubId)).value ??
        const <String, String>{};
    // Sul telefono dell'atleta c'è il suo profilo: legge soltanto.
    final allenatore = ref.watch(currentAtletaProvider).value?.id != atleta.id;

    void apri(String tipo) {
      final testo = spiegazioneTestNuoto(tipo, scritte[tipo]);
      final originale = spiegazioneTestNuoto(tipo, null);
      mostraComeSiFaTest(
        context,
        titolo: 'Test $tipo',
        sotto: tipo == 'T30'
            ? 'Metri nuotati in 30 minuti'
            : 'Distanza e tempo totale',
        testo: testo,
        onModifica: !allenatore
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ModificaSpiegazioneScreen(
                    titolo: 'Come si fa il $tipo',
                    attuale: testo,
                    originale: originale,
                    salva: (t) async {
                      await ref
                          .read(spiegazioniTestRepositoryProvider)
                          .salva(clubId: atleta.clubId, tipo: tipo, testo: t);
                      ref.invalidate(
                        spiegazioniTestNuotoProvider(atleta.clubId),
                      );
                    },
                  ),
                ),
              ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Wrap(
        spacing: AppSpacing.s8,
        children: [
          for (final tipo in const ['BVS', 'T30'])
            TextButton.icon(
              icon: const Icon(Icons.info_outline),
              label: Text('Come si fa il $tipo'),
              onPressed: () => apri(tipo),
            ),
        ],
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
