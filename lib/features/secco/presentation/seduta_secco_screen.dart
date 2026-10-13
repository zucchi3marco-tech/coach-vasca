import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/duplicazione_settimana_service.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../allenamenti/presentation/duplica_allenamento_dialog.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import 'esercizi_secco_screen.dart';
import 'foglio_esercizio.dart';
import 'programma_secco_screen.dart';
import 'programmi_secco_screen.dart';
import 'scegli_esercizi_screen.dart';
import 'secco_widgets.dart';

/// Una seduta a secco vista dall'allenatore: in testata quando, quanti
/// esercizi e quanto dura, con "Presenze"; sotto gli esercizi in ordine.
/// Il "+" li sceglie dall'elenco del club; un tocco su una riga cambia
/// serie, ripetizioni o tempo, carico e recupero.
class SedutaSeccoScreen extends ConsumerWidget {
  const SedutaSeccoScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  void _apri(BuildContext context, Widget schermata) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => schermata));

  void _avviso(BuildContext context, String testo) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(testo)));

  Future<void> _duplica(
    BuildContext context,
    WidgetRef ref,
    Allenamento a,
  ) async {
    final gruppi = ref.read(gruppiListProvider(a.clubId)).value ?? const [];
    final dove = await chiediDoveDuplicare(
      context,
      allenamento: a,
      gruppi: gruppi,
    );
    if (dove == null || !context.mounted) return;
    final navigatore = Navigator.of(context);
    try {
      final copia = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .copiaAllenamento(a, data: dove.data, gruppoId: dove.gruppoId);
      if (!context.mounted) return;
      _avviso(context, 'Seduta copiata: ora puoi modificarla');
      await navigatore.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SedutaSeccoScreen(allenamento: copia),
        ),
      );
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  Future<void> _elimina(
    BuildContext context,
    WidgetRef ref,
    Allenamento a,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare la seduta a secco?'),
        content: const Text(
          'Verranno eliminati per sempre anche i suoi esercizi e le presenze '
          'registrate.',
        ),
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
    if (conferma != true || !context.mounted) return;
    try {
      await ref.read(allenamentiRepositoryProvider).deleteAllenamento(a.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  Future<void> _sposta(
    BuildContext context,
    WidgetRef ref,
    List<EsercizioSeduta> righe,
    int da,
    int a,
  ) async {
    final ordinate = [...righe];
    final r = ordinate.removeAt(da);
    ordinate.insert(a, r);
    try {
      await ref.read(seccoRepositoryProvider).riordina(ordinate);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  /// Gli esercizi scelti in fondo alla seduta, ognuno con la prescrizione
  /// dell'ultima volta (o di quello pronto).
  Future<void> _aggiungi(
    WidgetRef ref,
    Allenamento a,
    List<EsercizioSecco> scelti, {
    required int daOrdine,
  }) async {
    final repository = ref.read(seccoRepositoryProvider);
    var ordine = daOrdine;
    for (final e in scelti) {
      final p = prescrizioneProposta(
        e,
        ultima: await repository.ultimaVolta(e.id),
      );
      await repository.aggiungiAllaSeduta(
        EsercizioSeduta(
          id: '',
          allenamentoId: a.id,
          clubId: a.clubId,
          esercizioId: e.id,
          ordine: ordine++,
          serie: p.serie,
          ripetizioni: p.ripetizioni,
          durataS: p.durataS,
          carico: p.carico,
          recuperoS: p.recuperoS,
        ),
      );
    }
  }

  Future<void> _togli(
    BuildContext context,
    WidgetRef ref,
    List<EsercizioSeduta> righe,
    EsercizioSeduta riga,
  ) async {
    try {
      final repository = ref.read(seccoRepositoryProvider);
      await repository.eliminaRiga(riga.id);
      await repository.riordina([
        for (final r in righe)
          if (r.id != riga.id) r,
      ]);
    } catch (e) {
      if (context.mounted) _avviso(context, messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    // La seduta com'è adesso (dopo una modifica di data, titolo o durata).
    final a =
        ref
            .watch(allenamentiListProvider(allenamento.clubId))
            .value
            ?.where((x) => x.id == allenamento.id)
            .firstOrNull ??
        allenamento;
    final righeAsync = ref.watch(eserciziSedutaProvider(a.id));
    final esercizi = {
      for (final e
          in ref.watch(eserciziSeccoProvider(a.clubId)).value ??
              const <EsercizioSecco>[])
        e.id: e,
    };
    String? nomeGruppo;
    for (final g in ref.watch(gruppiListProvider(a.clubId)).value ?? []) {
      if (g.id == a.gruppoId) nomeGruppo = g.nome;
    }
    final righe = righeAsync.value ?? const <EsercizioSeduta>[];
    final stima = minutiStimati(righe);
    // Il programma da cui è nata, se c'è ancora.
    final programma = a.programmaId == null
        ? null
        : ref
              .watch(programmiSeccoProvider(a.clubId))
              .value
              ?.where((p) => p.id == a.programmaId)
              .firstOrNull;
    final settimana = a.programmaSettimana;
    final diScarico =
        programma != null &&
        settimana != null &&
        settimana <= programma.settimane.length &&
        programma.settimane[settimana - 1].scarico;

    void scegli() => _apri(
      context,
      ScegliEserciziScreen(
        clubId: a.clubId,
        aggiungi: (scelti) =>
            _aggiungi(ref, a, scelti, daOrdine: righe.length + 1),
      ),
    );

    final testata = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestataPagina(
          occhiello: [quandoEsteso(a.data), ?nomeGruppo].join(' · '),
          titolo: a.titoloMostrato,
          sottotitolo: programma != null
              ? diScarico
                    ? 'Programma a secco · settimana di scarico'
                    : 'Programma a secco di ${programma.settimane.length} '
                          'settimane'
              : a.titolo != null && a.titolo!.trim().isNotEmpty
              ? 'Seduta a secco'
              : null,
          numeri: [
            NumeroTestata(valore: '${righe.length}', etichetta: 'Esercizi'),
            NumeroTestata(valore: "${minutiSeduta(a)}'", etichetta: 'Durata'),
          ],
          azioni: [
            AzioneTestata(
              icona: Icons.how_to_reg_outlined,
              etichetta: 'Presenze',
              principale: true,
              onTap: () => _apri(context, PresenzeScreen(allenamento: a)),
            ),
            if (programma != null)
              AzioneTestata(
                icona: Icons.event_repeat,
                etichetta: 'Programma',
                onTap: () => _apri(
                  context,
                  ProgrammaSeccoScreen(
                    clubId: a.clubId,
                    programmaId: programma.id,
                  ),
                ),
              ),
          ],
        ),
        if (a.note != null && a.note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          PoolCard(
            child: Text(
              a.note!,
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
      ],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Seduta a secco'),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
            onSelected: (azione) => azione(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _apri(
                  context,
                  AllenamentoFormScreen(clubId: a.clubId, allenamento: a),
                ),
                child: const Text('Modifica data, titolo, durata e note'),
              ),
              PopupMenuItem(
                value: () =>
                    _apri(context, EserciziSeccoScreen(clubId: a.clubId)),
                child: const Text('Elenco esercizi del club'),
              ),
              PopupMenuItem(
                value: () =>
                    _apri(context, ProgrammiSeccoScreen(clubId: a.clubId)),
                child: const Text('Programmi a secco'),
              ),
              PopupMenuItem(
                value: () => _duplica(context, ref, a),
                child: const Text('Duplica'),
              ),
              PopupMenuItem(
                value: () => _elimina(context, ref, a),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-seduta-secco',
        tooltip: 'Aggiungi esercizi',
        onPressed: scegli,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          testata,
          ...righeAsync.when(
            data: (righe) => righe.isEmpty
                ? [
                    EmptyState(
                      icona: Icons.fitness_center,
                      titolo: 'Nessun esercizio',
                      descrizione:
                          'Scegli gli esercizi dall\'elenco del club: spalla, '
                          'scapole, core, gambe. Per ognuno serie, '
                          'ripetizioni o tempo e recupero.',
                      azionePrincipale: 'Aggiungi esercizi',
                      onAzionePrincipale: scegli,
                    ),
                  ]
                : [
                    TitoloSezione(
                      'Esercizi',
                      conteggio: righe.length,
                      // La stima solo quando dice qualcosa in più della
                      // durata scritta.
                      spiegazione: (stima - minutiSeduta(a)).abs() >= 5
                          ? "Fatti come scritto durano circa $stima'."
                          : null,
                    ),
                    AppListPanel(
                      righe: [
                        for (final (i, r) in righe.indexed)
                          RigaEsercizio(
                            numero: i + 1,
                            esercizio: esercizi[r.esercizioId],
                            riga: r,
                            sotto: r.note,
                            onTap: () => mostraFoglioEsercizio(
                              context,
                              esercizio: esercizi[r.esercizioId],
                              riga: r,
                              salva: ref
                                  .read(seccoRepositoryProvider)
                                  .aggiornaRiga,
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Azioni dell\'esercizio',
                              icon: Icon(
                                Icons.more_vert,
                                color: colori.testoSecondario,
                              ),
                              onSelected: (azione) => switch (azione) {
                                'su' => _sposta(context, ref, righe, i, i - 1),
                                'giu' => _sposta(context, ref, righe, i, i + 1),
                                _ => _togli(context, ref, righe, r),
                              },
                              itemBuilder: (_) => [
                                if (i > 0)
                                  const PopupMenuItem(
                                    value: 'su',
                                    child: Text('Sposta su'),
                                  ),
                                if (i < righe.length - 1)
                                  const PopupMenuItem(
                                    value: 'giu',
                                    child: Text('Sposta giù'),
                                  ),
                                const PopupMenuItem(
                                  value: 'togli',
                                  child: Text('Togli dalla seduta'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
            loading: () => const [LoadingSkeletonList(righe: 4)],
            error: (errore, _) => [
              ErrorBanner(
                messaggio: 'Non è stato possibile caricare gli esercizi.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(errore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
