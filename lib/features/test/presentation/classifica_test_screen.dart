import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/test_club_providers.dart';
import '../data/test_club_repository.dart';
import '../domain/massimale.dart';
import '../domain/test_club.dart';
import 'confronto_test_screen.dart';
import 'inserisci_risultati_screen.dart';
import 'test_club_form_screen.dart';
import 'test_club_widgets.dart';

/// Quanti atleti si confrontano al massimo.
const massimoConfronto = 5;

/// La classifica di un test: per ogni atleta della squadra scelta in alto
/// l'ultima prova o la migliore, dal più bravo, con quanto è cambiato
/// dalla volta prima e, con più prove, l'indice di affaticamento. Si
/// filtra per ruolo e per anno di nascita (le categorie FIN vanno per
/// anno); si scelgono fino a [massimoConfronto] atleti da confrontare.
class ClassificaTestScreen extends ConsumerStatefulWidget {
  const ClassificaTestScreen({required this.test, super.key});

  final TestClub test;

  @override
  ConsumerState<ClassificaTestScreen> createState() =>
      _ClassificaTestScreenState();
}

class _ClassificaTestScreenState extends ConsumerState<ClassificaTestScreen> {
  ModoClassifica _modo = ModoClassifica.ultima;
  String? _ruolo;
  int? _anno;
  bool _confronto = false;
  final _scelti = <String>{};

  void _apri(Widget pagina) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => pagina));

  void _esporta(TestClub test, List<PostoClassifica> posti) {
    final csv = csvClassifica(test, posti);
    // Con il BOM Excel legge gli accenti.
    scaricaFile(
      Uint8List.fromList(utf8.encode('﻿$csv')),
      '${test.nome.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.csv',
      mimeType: 'text/csv',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final clubId = widget.test.clubId;
    // Il test aggiornato, se lo si è appena modificato.
    final test =
        ref
            .watch(testClubProvider(clubId))
            .value
            ?.where((t) => t.id == widget.test.id)
            .firstOrNull ??
        widget.test;
    final risultatiAsync = ref.watch(risultatiTestClubProvider(clubId));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: false)),
    );
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final gruppi = ref.watch(gruppiListProvider(clubId)).value ?? const [];
    final nomeSquadra = gruppi.where((g) => g.id == gruppoId).firstOrNull?.nome;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Test'),
        actions: [
          IconButton(
            tooltip: 'Modifica il test',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                _apri(TestClubFormScreen(clubId: clubId, test: test)),
          ),
        ],
      ),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      bottomNavigationBar: _confronto
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: PrimaryButton(
                  label: _scelti.length < 2
                      ? 'Scegli da 2 a $massimoConfronto atleti'
                      : 'Confronta ${_scelti.length} atleti',
                  onPressed: _scelti.length < 2
                      ? null
                      : () => _apri(
                          ConfrontoTestScreen(
                            test: test,
                            atletiIds: _scelti.toList(),
                          ),
                        ),
                ),
              ),
            )
          : null,
      body: risultatiAsync.when(
        data: (risultati) => atletiAsync.when(
          data: (tuttiAtleti) {
            final squadra = [
              for (final a in tuttiAtleti)
                if (gruppoId == null || a.gruppoId == gruppoId) a,
            ];
            final conRisultato = {
              for (final r in risultati)
                if (r.testId == test.id) r.atletaId,
            };
            final anni = {
              for (final a in squadra)
                if (conRisultato.contains(a.id)) a.dataNascita.year,
            }.toList()..sort();
            final pallanuoto = squadra.any((a) => a.sport == 'pallanuoto');
            final filtrati = [
              for (final a in squadra)
                if ((_ruolo == null || (a.ruolo ?? 'movimento') == _ruolo) &&
                    (_anno == null || a.dataNascita.year == _anno))
                  a,
            ];
            final posti = classifica(test, risultati, filtrati, modo: _modo);
            final tutti = classifica(test, risultati, squadra, modo: _modo);
            final ultima =
                [
                  for (final r in risultati)
                    if (r.testId == test.id &&
                        conRisultato.contains(r.atletaId))
                      r.data,
                ].fold<DateTime?>(
                  null,
                  (m, d) => m == null || d.isAfter(m) ? d : m,
                );

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s32),
              children: [
                TestataPagina(
                  occhiello: nomeSquadra ?? 'Tutto il club',
                  titolo: test.nome,
                  sottotitolo: descrizioneMisura(test),
                  numeri: [
                    NumeroTestata(
                      valore: '${tutti.length}',
                      etichetta: tutti.length == 1 ? 'Atleta' : 'Atleti',
                    ),
                    if (tutti.isNotEmpty)
                      NumeroTestata(
                        valore: formattaValore(
                          test.unita,
                          tutti.first.punteggio,
                        ),
                        etichetta: _modo == ModoClassifica.ultima
                            ? 'Il migliore ora'
                            : 'Il migliore',
                      ),
                    if (ultima != null)
                      NumeroTestata(
                        valore: traQuanto(ultima),
                        etichetta: 'Ultima prova',
                      ),
                  ],
                  azioni: [
                    AzioneTestata(
                      icona: Icons.dialpad,
                      etichetta: 'Inserisci risultati',
                      principale: true,
                      onTap: () => _apri(InserisciRisultatiScreen(test: test)),
                    ),
                    if (tutti.length >= 2)
                      AzioneTestata(
                        icona: _confronto ? Icons.close : Icons.compare_arrows,
                        etichetta: _confronto
                            ? 'Chiudi il confronto'
                            : 'Confronta',
                        onTap: () => setState(() {
                          _confronto = !_confronto;
                          _scelti.clear();
                        }),
                      ),
                  ],
                ),
                if (test.descrizione case final d?
                    when d.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    d,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s20),
                if (tutti.isEmpty)
                  EmptyState(
                    icona: Icons.leaderboard_outlined,
                    titolo: 'Nessun risultato',
                    descrizione:
                        'Segna i risultati a bordo vasca, un atleta dopo '
                        "l'altro con il tastierino: qui compare la "
                        'classifica.',
                    azionePrincipale: 'Inserisci risultati',
                    onAzionePrincipale: () =>
                        _apri(InserisciRisultatiScreen(test: test)),
                  )
                else ...[
                  SegmentedButton<ModoClassifica>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in ModoClassifica.values)
                        ButtonSegment(value: m, label: Text(m.etichetta)),
                    ],
                    selected: {_modo},
                    onSelectionChanged: (s) => setState(() => _modo = s.first),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (pallanuoto) ...[
                          for (final (valore, etichetta) in const [
                            (null, 'Tutti i ruoli'),
                            ('portiere', 'Portieri'),
                            ('movimento', 'Movimento'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.s8,
                              ),
                              child: TonalChip(
                                etichetta: etichetta,
                                selezionato: _ruolo == valore,
                                onSelezionato: (_) =>
                                    setState(() => _ruolo = valore),
                              ),
                            ),
                          const SizedBox(width: AppSpacing.s8),
                        ],
                        if (anni.length > 1)
                          for (final anno in [null, ...anni])
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.s8,
                              ),
                              child: TonalChip(
                                etichetta: anno == null
                                    ? 'Tutti gli anni'
                                    : 'Nati nel $anno',
                                selezionato: _anno == anno,
                                onSelezionato: (_) =>
                                    setState(() => _anno = anno),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TitoloSezione(
                    'Classifica',
                    conteggio: posti.length,
                    azione: kIsWeb ? 'Esporta CSV' : null,
                    onAzione: kIsWeb ? () => _esporta(test, posti) : null,
                  ),
                  if (posti.isEmpty)
                    const RiquadroVuoto(
                      'Nessun atleta con questi filtri ha un risultato.',
                    )
                  else
                    AppListPanel(
                      righe: [
                        for (final p in posti)
                          _RigaClassifica(
                            test: test,
                            posto: p,
                            modoConfronto: _confronto,
                            scelto: _scelti.contains(p.atleta.id),
                            onTap: _confronto
                                ? () => setState(() {
                                    if (!_scelti.remove(p.atleta.id) &&
                                        _scelti.length < massimoConfronto) {
                                      _scelti.add(p.atleta.id);
                                    }
                                  })
                                : () => _mostraStorico(
                                    context,
                                    test,
                                    p.atleta,
                                    risultati,
                                  ),
                          ),
                      ],
                    ),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: LoadingSkeletonList(righe: 6),
          ),
          error: (e, _) => _Errore(e),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 6),
        ),
        error: (e, _) => _Errore(e),
      ),
    );
  }

  /// I risultati di un atleta in questo test, dal più recente, con le
  /// prove; da qui si elimina un risultato sbagliato.
  Future<void> _mostraStorico(
    BuildContext context,
    TestClub test,
    Atleta atleta,
    List<RisultatoTest> risultati,
  ) {
    final storico = storicoAtleta(test, risultati, atleta.id).reversed.toList();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colori = sheetContext.colori;
        return SingleChildScrollView(
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
                atleta.nomeCompleto,
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              Text(
                test.nome,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppListPanel(
                righe: [
                  for (final r in storico)
                    AppListRow(
                      titolo: dataEstesa(r.data),
                      sottotitolo: [
                        if (test.massimale)
                          ?descriviSollevato(r.caricoKg, r.ripetizioni),
                        if (test.prove > 1)
                          r.valori
                              .map(
                                (v) =>
                                    formattaValore(test.unita, v, sigla: false),
                              )
                              .join(' · '),
                        if (indiceAffaticamento(test, r.valori) case final f?)
                          'affaticamento ${formattaPercentuale(f)}',
                      ].join(' — '),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattaValore(
                              test.unita,
                              test.punteggioDi(r.valori),
                            ),
                            style: AppTypography.numerica(
                              AppTypography.numeroMedio,
                            ).copyWith(color: colori.testo),
                          ),
                          IconButton(
                            tooltip: 'Elimina questo risultato',
                            icon: Icon(
                              Icons.delete_outline,
                              color: colori.testoSecondario,
                            ),
                            onPressed: () async {
                              final navigatore = Navigator.of(sheetContext);
                              final ok = await _confermaEliminazione(
                                sheetContext,
                                r,
                              );
                              if (!ok) return;
                              await ref
                                  .read(testClubRepositoryProvider)
                                  .eliminaRisultato(r.id);
                              navigatore.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confermaEliminazione(
    BuildContext context,
    RisultatoTest r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminare il risultato del ${dataNumerica(r.data)}?'),
        content: const Text("L'operazione non si può annullare."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

/// Una riga della classifica: posizione, atleta, quando e quanto è
/// cambiato, il valore a destra.
class _RigaClassifica extends StatelessWidget {
  const _RigaClassifica({
    required this.test,
    required this.posto,
    required this.modoConfronto,
    required this.scelto,
    required this.onTap,
  });

  final TestClub test;
  final PostoClassifica posto;
  final bool modoConfronto;
  final bool scelto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = posto;
    final precedente = p.precedente;
    final differenza = precedente == null ? null : p.punteggio - precedente;
    final migliorato =
        differenza != null &&
        differenza != 0 &&
        test.meglio(p.punteggio, precedente!);
    final affaticamento = indiceAffaticamento(test, p.risultato.valori);
    // Per un massimale, da cosa viene: "40 kg × 5".
    final sollevato = test.massimale
        ? descriviSollevato(p.risultato.caricoKg, p.risultato.ripetizioni)
        : null;
    return AppListRow(
      leading: modoConfronto
          ? Checkbox(value: scelto, onChanged: (_) => onTap())
          : SizedBox(
              width: 32,
              child: Text(
                '${p.posizione}',
                textAlign: TextAlign.center,
                style: AppTypography.numerica(AppTypography.numeroMedio)
                    .copyWith(color: colori.testoSecondario),
              ),
            ),
      titolo: p.atleta.nomeCompleto,
      // Quando, e com'è andata rispetto alla volta prima.
      sottotitolo: [
        traQuanto(p.risultato.data),
        if (differenza != null && differenza != 0)
          '${formattaValore(test.unita, differenza.abs())} '
              '${migliorato ? 'meglio' : 'peggio'}',
      ].join(' · '),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattaValore(test.unita, p.punteggio),
            style: AppTypography.numerica(AppTypography.numeroMedio)
                .copyWith(color: colori.testo),
          ),
          if (affaticamento != null)
            Text(
              'affaticamento ${formattaPercentuale(affaticamento)}',
              style: AppTypography.numerica(AppTypography.piccolo)
                  .copyWith(color: colori.testoSecondario),
            ),
          if (sollevato != null)
            Text(
              sollevato,
              style: AppTypography.numerica(AppTypography.piccolo)
                  .copyWith(color: colori.testoSecondario),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Errore extends StatelessWidget {
  const _Errore(this.errore);

  final Object errore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.s16),
    child: ErrorBanner(
      messaggio: 'Non è stato possibile caricare la classifica.',
      suggerimento: "Riprova. Se l'errore continua, chiudi e riapri l'app.",
      dettaglioTecnico: messaggioErrore(errore),
    ),
  );
}
