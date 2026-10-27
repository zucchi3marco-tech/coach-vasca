import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
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
import '../../allenamenti/domain/variante_spalla.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../allenamenti/presentation/avviso_seduta_aperta.dart';
import '../../allenamenti/presentation/banner_modifica.dart';
import '../../allenamenti/presentation/duplica_allenamento_dialog.dart';
import '../../allenamenti/presentation/per_chi_serie.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../../benessere/application/benessere_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import '../domain/serie_fatta.dart';
import '../domain/varianti_secco.dart';
import 'chili_di_ognuno.dart';
import 'esercizi_secco_screen.dart';
import 'foglio_esercizio.dart';
import 'programma_secco_screen.dart';
import 'programmi_secco_screen.dart';
import 'registrazioni_seduta.dart';
import 'scegli_esercizi_screen.dart';
import 'scelte_variante.dart';
import 'secco_widgets.dart';
import 'tablet_squadra_screen.dart';
import 'variante_atleta_screen.dart';
import 'varianti_nella_seduta.dart';

/// Una seduta a secco vista dall'allenatore: in testata quando, quanti
/// esercizi e quanto dura, con "Presenze"; sotto gli esercizi in ordine.
/// Il "+" li sceglie dall'elenco del club; un tocco su una riga cambia
/// serie, ripetizioni o tempo, carico e recupero. Sotto un esercizio, in
/// piccolo, chi ne fa un altro o non lo fa (la variante per un atleta).
class SedutaSeccoScreen extends ConsumerWidget {
  const SedutaSeccoScreen({
    required this.allenamento,
    this.adesso = DateTime.now,
    super.key,
  });

  final Allenamento allenamento;

  /// L'orologio (nei test, uno finto): la proposta per la spalla è solo
  /// per le sedute di oggi e in programma.
  final DateTime Function() adesso;

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
          'Verranno eliminati per sempre anche i suoi esercizi, le presenze '
          'e le serie registrate dagli atleti.',
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

  /// Sposta un esercizio di tutti da [da] ad [a] fra [principali]; le sue
  /// varianti lo seguono (per questo il repository vuole anche [tutte]).
  Future<void> _sposta(
    BuildContext context,
    WidgetRef ref,
    List<EsercizioSeduta> principali,
    List<EsercizioSeduta> tutte,
    int da,
    int a,
  ) async {
    final ordinate = [...principali];
    final r = ordinate.removeAt(da);
    ordinate.insert(a, r);
    try {
      await ref.read(seccoRepositoryProvider).riordina(ordinate, tutte: tutte);
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
    List<Atleta> atleti,
  ) async {
    // Se ha delle varianti se ne vanno con lui, con le serie fatte.
    final varianti = variantiDi(riga, righe);
    final nomiVarianti = <String>[
      for (final v in varianti)
        for (final id in v.destinatari.soloAtleti)
          ?atleti
              .where((a) => a.id == id)
              .map((a) => nomeBreve(a, atleti))
              .firstOrNull,
    ];
    // Se qualcuno l'ha già fatto, togliendolo si perdono le sue serie.
    final tolte = {riga.id, for (final v in varianti) v.id};
    final chi = {
      for (final f
          in ref.read(serieFatteSedutaProvider(riga.allenamentoId)).value ??
              const <SerieFatta>[])
        if (tolte.contains(f.rigaId)) f.atletaId,
    };
    if (chi.isNotEmpty || varianti.isNotEmpty) {
      final conferma = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Togliere l\'esercizio dalla seduta?'),
          content: Text(
            [
              if (varianti.isNotEmpty)
                nomiVarianti.isEmpty
                    ? 'Si tolgono anche le varianti degli atleti.'
                    : 'Si tolgono anche le varianti per '
                          '${elencoNomi(nomiVarianti)}.',
              if (chi.isNotEmpty)
                chi.length == 1
                    ? 'Un atleta l\'ha già registrato: si perdono anche le '
                          'sue serie.'
                    : '${chi.length} atleti l\'hanno già registrato: si '
                          'perdono anche le loro serie.',
            ].join(' '),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            DangerButton(
              label: 'Togli',
              expanded: false,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      );
      if (conferma != true || !context.mounted) return;
    }
    try {
      final repository = ref.read(seccoRepositoryProvider);
      await repository.eliminaRiga(riga.id);
      await repository.riordina([
        for (final r in righePrincipali(righe))
          if (r.id != riga.id) r,
      ], tutte: righe);
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
    // Gli esercizi di tutti: le varianti stanno sotto il loro esercizio.
    final principali = righePrincipali(righe);
    final stima = minutiStimati(righe);
    // Gli atleti della seduta, e chi fra loro ha male alla spalla.
    final tuttiAtleti =
        ref
            .watch(
              atletiListProvider((clubId: a.clubId, includeInactive: false)),
            )
            .value ??
        const <Atleta>[];
    final atleti = atletiDellAllenamento(tuttiAtleti, gruppoId: a.gruppoId);
    // Come in acqua: chi ha male alla spalla adesso, solo per le sedute di
    // oggi e in programma (una passata non si cambia più).
    final ora = adesso();
    final doloranti = soloData(a.data).isBefore(soloData(ora))
        ? const <String, DateTime>{}
        : conDoloreSpalla(
            ref.watch(schedeBenessereClubProvider(a.clubId)).value ?? const [],
            {for (final x in atleti) x.id},
            oggi: ora,
          );
    String nomeDi(String atletaId) =>
        atleti
            .where((x) => x.id == atletaId)
            .map((x) => nomeBreve(x, atleti))
            .firstOrNull ??
        tuttiAtleti
            .where((x) => x.id == atletaId)
            .map((x) => nomeBreve(x, tuttiAtleti))
            .firstOrNull ??
        'Un atleta';
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
            _aggiungi(ref, a, scelti, daOrdine: principali.length + 1),
      ),
    );

    // La variante per un atleta: la schermata con tutti gli esercizi, con
    // quello di [rigaId] in evidenza.
    void preparaVariante(Atleta atleta, {String? rigaId}) => _apri(
      context,
      VarianteAtletaScreen(allenamento: a, atleta: atleta, rigaId: rigaId),
    );

    Future<void> variantePerUnAtleta(EsercizioSeduta riga) async {
      final atleta = await scegliAtletaPerVariante(
        context,
        riga: riga,
        righe: righe,
        esercizi: esercizi,
        atleti: atleti,
        doloranti: doloranti,
      );
      if (atleta != null && context.mounted) {
        preparaVariante(atleta, rigaId: riga.id);
      }
    }

    /// Le righe piccole sotto un esercizio di tutti: chi fa un altro
    /// esercizio e chi non lo fa.
    List<Widget> sottoRighe(EsercizioSeduta r) => [
      for (final v in variantiDi(r, righe))
        for (final id in v.destinatari.soloAtleti)
          SottoRigaVariante(
            testo:
                '${nomeDi(id)}: '
                '${esercizi[v.esercizioId]?.nome ?? 'Esercizio tolto dall\'elenco'}'
                ' · ${prescrizioneEsercizio(v)}',
            onTap: () => mostraScelteVariante(
              context,
              ref,
              allenamento: a,
              riga: r,
              atletaId: id,
              nome: nomeDi(id),
              dalleSottoRighe: true,
            ),
          ),
      for (final id in r.destinatari.tranneAtleti)
        SottoRigaVariante(
          testo: '${nomeDi(id)}: non lo fa',
          onTap: () => mostraScelteVariante(
            context,
            ref,
            allenamento: a,
            riga: r,
            atletaId: id,
            nome: nomeDi(id),
            dalleSottoRighe: true,
          ),
        ),
    ];

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
            NumeroTestata(
              valore: '${principali.length}',
              etichetta: 'Esercizi',
            ),
            NumeroTestata(valore: "${minutiSeduta(a)}'", etichetta: 'Durata'),
          ],
          azioni: [
            AzioneTestata(
              icona: Icons.how_to_reg_outlined,
              etichetta: 'Presenze',
              principale: true,
              onTap: () => _apri(context, PresenzeScreen(allenamento: a)),
            ),
            // Per chi non ha il telefono: registra dal tablet del club.
            if (principali.isNotEmpty)
              AzioneTestata(
                icona: Icons.tablet_android_outlined,
                etichetta: 'Tablet della squadra',
                onTap: () =>
                    _apri(context, TabletSquadraScreen(allenamento: a)),
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
        BannerModifica(allenamento: a),
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
          // Un collega ha aperta la stessa seduta, o l'ha cambiata intanto.
          AvvisoSedutaAperta(
            allenamentoId: allenamento.id,
            clubId: allenamento.clubId,
          ),
          ...righeAsync.when(
            data: (_) => principali.isEmpty
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
                    AvvisoSpallaSecco(
                      righe: righe,
                      atleti: atleti,
                      doloranti: doloranti,
                      onPrepara: preparaVariante,
                    ),
                    TitoloSezione(
                      'Esercizi',
                      conteggio: principali.length,
                      // La stima solo quando dice qualcosa in più della
                      // durata scritta.
                      spiegazione: (stima - minutiSeduta(a)).abs() >= 5
                          ? "Fatti come scritto durano circa $stima'."
                          : null,
                    ),
                    AppListPanel(
                      righe: [
                        for (final (i, r) in principali.indexed)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                    'variante' => variantePerUnAtleta(r),
                                    'su' => _sposta(
                                      context,
                                      ref,
                                      principali,
                                      righe,
                                      i,
                                      i - 1,
                                    ),
                                    'giu' => _sposta(
                                      context,
                                      ref,
                                      principali,
                                      righe,
                                      i,
                                      i + 1,
                                    ),
                                    _ => _togli(context, ref, righe, r, atleti),
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'variante',
                                      child: Text('Variante per un atleta'),
                                    ),
                                    if (i > 0)
                                      const PopupMenuItem(
                                        value: 'su',
                                        child: Text('Sposta su'),
                                      ),
                                    if (i < principali.length - 1)
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
                              ...sottoRighe(r),
                            ],
                          ),
                      ],
                    ),
                    ChiliDiOgnuno(
                      allenamento: a,
                      righe: righe,
                      esercizi: esercizi,
                    ),
                    RegistrazioniSeduta(
                      allenamento: a,
                      righe: righe,
                      esercizi: esercizi,
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
