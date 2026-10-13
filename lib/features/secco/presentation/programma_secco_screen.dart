import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
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
import '../../../widgets/pool_card.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/secco_providers.dart';
import '../data/secco_repository.dart';
import '../domain/esercizio_secco.dart';
import '../domain/programma_secco.dart';
import 'foglio_esercizio.dart';
import 'metti_nel_calendario_screen.dart';
import 'programma_secco_form_screen.dart';
import 'scegli_esercizi_screen.dart';
import 'secco_widgets.dart';

/// Le settimane al massimo (come nel database).
const _settimaneMassime = 26;

/// Un programma a secco: in testata settimane, sedute a settimana e
/// minuti, con "Metti nel calendario"; dove è già nel calendario; poi una
/// settimana alla volta (i chip in alto), con le sue sedute e gli esercizi
/// di ognuna. "Aggiungi la settimana" copia l'ultima con un po' di più.
class ProgrammaSeccoScreen extends ConsumerStatefulWidget {
  const ProgrammaSeccoScreen({
    required this.clubId,
    required this.programmaId,
    super.key,
  });

  final String clubId;
  final String programmaId;

  @override
  ConsumerState<ProgrammaSeccoScreen> createState() =>
      _ProgrammaSeccoScreenState();
}

class _ProgrammaSeccoScreenState extends ConsumerState<ProgrammaSeccoScreen> {
  int _settimana = 0;

  /// L'ultima versione scritta da qui, mostrata subito mentre si salva:
  /// due tocchi veloci non si perdono a vicenda.
  ProgrammaSecco? _locale;

  /// Il programma com'è adesso (quello mostrato).
  ProgrammaSecco? _attuale;

  /// I salvataggi, uno dopo l'altro.
  Future<void> _coda = Future.value();

  void _avviso(String testo) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(testo)));

  void _cambia(ProgrammaSecco nuovo) {
    setState(() => _locale = nuovo);
    _attuale = nuovo;
    final repository = ref.read(seccoRepositoryProvider);
    _coda = _coda.then((_) async {
      try {
        await repository.aggiornaProgramma(nuovo);
      } catch (e) {
        if (!mounted) return;
        setState(() => _locale = null);
        _avviso(messaggioErrore(e));
      }
    });
  }

  void _cambiaSeduta(int settimana, int seduta, List<DoseEsercizio> dosi) {
    final p = _attuale!;
    _cambia(
      p.conSettimana(settimana, p.settimane[settimana].conSeduta(seduta, dosi)),
    );
  }

  Future<void> _apri(Widget schermata) async {
    await _coda;
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => schermata));
  }

  Future<void> _modifica(ProgrammaSecco p) async {
    await _apri(ProgrammaSeccoFormScreen(clubId: widget.clubId, programma: p));
    // Dal form si salva il programma intero: si torna a quello salvato.
    if (mounted) setState(() => _locale = null);
  }

  void _metti(ProgrammaSecco p) {
    if (p.settimane.every((s) => s.sedute.every((e) => e.isEmpty))) {
      _avviso('Aggiungi prima gli esercizi delle sedute');
      return;
    }
    _apri(MettiNelCalendarioScreen(programma: p));
  }

  void _scegli(int settimana, int seduta) => _apri(
    ScegliEserciziScreen(
      clubId: widget.clubId,
      aggiungi: (scelti) async {
        final repository = ref.read(seccoRepositoryProvider);
        final dosi = [..._attuale!.settimane[settimana].sedute[seduta]];
        for (final e in scelti) {
          final p = prescrizioneProposta(
            e,
            ultima: await repository.ultimaVolta(e.id),
          );
          dosi.add(
            DoseEsercizio(
              esercizioId: e.id,
              serie: p.serie,
              ripetizioni: p.ripetizioni,
              durataS: p.durataS,
              carico: p.carico,
              recuperoS: p.recuperoS,
            ),
          );
        }
        _cambiaSeduta(settimana, seduta, dosi);
        await _coda;
      },
    ),
  );

  void _sposta(int settimana, int seduta, int da, int a) {
    final dosi = [..._attuale!.settimane[settimana].sedute[seduta]];
    dosi.insert(a, dosi.removeAt(da));
    _cambiaSeduta(settimana, seduta, dosi);
  }

  void _togliEsercizio(int settimana, int seduta, int indice) {
    final dosi = [..._attuale!.settimane[settimana].sedute[seduta]]
      ..removeAt(indice);
    _cambiaSeduta(settimana, seduta, dosi);
  }

  void _aggiungiSettimana(Map<String, EsercizioSecco> esercizi) {
    final p = _attuale!;
    _cambia(
      p.copyWith(
        settimane: [
          ...p.settimane,
          settimanaSuccessiva(p.settimane, esercizi: esercizi),
        ],
      ),
    );
    setState(() => _settimana = p.settimane.length);
  }

  /// La settimana prima, con un po' di più (o, per una settimana di
  /// scarico, con una serie in meno), al posto di questa.
  Future<void> _copiaPrima(int w, Map<String, EsercizioSecco> esercizi) async {
    final p = _attuale!;
    final questa = p.settimane[w];
    if (questa.sedute.any((s) => s.isNotEmpty)) {
      final conferma = await _conferma(
        titolo: 'Rifare la settimana ${w + 1}?',
        testo:
            'Gli esercizi della settimana ${w + 1} si sostituiscono con '
            'quelli della settimana $w, ${questa.scarico ? 'con una serie in meno' : 'con un po\' di più'}.',
        azione: 'Rifai',
      );
      if (!conferma) return;
    }
    final prima = p.settimane[w - 1];
    final nuova = questa.scarico
        ? SettimanaProgramma(
            scarico: true,
            sedute: [
              for (final s in prima.sedute)
                [for (final d in s) unaSerieInMeno(d)],
            ],
          )
        : settimanaSuccessiva(p.settimane.sublist(0, w), esercizi: esercizi);
    _cambia(p.conSettimana(w, nuova));
  }

  Future<void> _togliSettimana(int w) async {
    final conferma = await _conferma(
      titolo: 'Togliere la settimana ${w + 1}?',
      testo:
          'Si toglie dal programma con le sue sedute; le settimane dopo '
          'scalano di uno. Le sedute già nel calendario restano.',
      azione: 'Togli',
    );
    if (!conferma) return;
    final p = _attuale!;
    _cambia(p.copyWith(settimane: [...p.settimane]..removeAt(w)));
    setState(() => _settimana = (w - 1).clamp(0, p.settimane.length - 2));
  }

  Future<bool> _conferma({
    required String titolo,
    required String testo,
    required String azione,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(titolo),
          content: Text(testo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            DangerButton(
              label: azione,
              expanded: false,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _elimina(ProgrammaSecco p) async {
    final conferma = await _conferma(
      titolo: 'Eliminare «${p.nome}»?',
      testo:
          'Il programma si elimina. Le sedute già nel calendario restano, '
          'con i loro esercizi.',
      azione: 'Elimina',
    );
    if (!conferma || !mounted) return;
    final navigatore = Navigator.of(context);
    try {
      await _coda;
      await ref.read(seccoRepositoryProvider).eliminaProgramma(p.id);
      navigatore.pop();
    } catch (e) {
      if (mounted) _avviso(messaggioErrore(e));
    }
  }

  /// Toglie dal calendario le sedute del programma per una squadra da
  /// oggi in poi, tranne quelle con le presenze già segnate.
  Future<void> _togliDalCalendario(
    ProgrammaSecco p,
    String? gruppoId,
    String squadra,
  ) async {
    final ids = await ref
        .read(seccoRepositoryProvider)
        .seduteDaTogliere(
          programmaId: p.id,
          gruppoId: gruppoId,
          daGiorno: DateTime.now(),
        );
    if (!mounted) return;
    if (ids.isEmpty) {
      _avviso(
        'Nessuna seduta da togliere: quelle rimaste sono passate o hanno '
        'le presenze segnate.',
      );
      return;
    }
    final conferma = await _conferma(
      titolo: ids.length == 1
          ? 'Togliere 1 seduta dal calendario?'
          : 'Togliere ${ids.length} sedute dal calendario?',
      testo:
          'Le sedute di «${p.nome}» per $squadra da oggi in poi si '
          'eliminano con i loro esercizi. Quelle passate e quelle con le '
          'presenze segnate restano.',
      azione: 'Togli',
    );
    if (!conferma || !mounted) return;
    final allenamenti = ref.read(allenamentiRepositoryProvider);
    try {
      for (final id in ids) {
        await allenamenti.deleteAllenamento(id);
      }
      if (mounted) {
        _avviso(
          ids.length == 1
              ? '1 seduta tolta dal calendario'
              : '${ids.length} sedute tolte dal calendario',
        );
      }
    } catch (e) {
      if (mounted) _avviso(messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final programmiAsync = ref.watch(programmiSeccoProvider(widget.clubId));
    final daServer = programmiAsync.value
        ?.where((p) => p.id == widget.programmaId)
        .firstOrNull;
    final p = _locale ?? daServer;
    _attuale = p;

    if (p == null) {
      return AppScaffold(
        appBar: AppBar(),
        body: programmiAsync.hasError
            ? ErrorBanner(
                messaggio: 'Non è stato possibile caricare il programma.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(programmiAsync.error!),
              )
            : programmiAsync.isLoading
            ? const LoadingSkeletonList(righe: 5)
            : const RiquadroVuoto('Questo programma non c\'è più.'),
      );
    }

    final colori = context.colori;
    final esercizi = {
      for (final e
          in ref.watch(eserciziSeccoProvider(widget.clubId)).value ??
              const <EsercizioSecco>[])
        e.id: e,
    };
    final w = _settimana.clamp(0, p.settimane.length - 1);
    final settimana = p.settimane[w];
    final quante = p.sedutePerSettimana;
    // La settimana che copia "Aggiungi la settimana": l'ultima non di
    // scarico (vedi [settimanaSuccessiva]).
    final ultimaPiena = p.settimane.lastIndexWhere((s) => !s.scarico);
    final daCopiare =
        (ultimaPiena < 0 ? p.settimane.length - 1 : ultimaPiena) + 1;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Programma a secco'),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
            onSelected: (azione) => azione(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _modifica(p),
                child: const Text('Modifica nome, sedute e minuti'),
              ),
              PopupMenuItem(
                value: () => _elimina(p),
                child: const Text('Elimina il programma'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          TestataPagina(
            occhiello: 'Programma a secco',
            titolo: p.nome,
            numeri: [
              NumeroTestata(
                valore: '${p.settimane.length}',
                etichetta: 'Settimane',
              ),
              NumeroTestata(valore: '$quante', etichetta: 'A settimana'),
              NumeroTestata(
                valore: "${p.durataMin}'",
                etichetta: 'Ogni seduta',
              ),
            ],
            azioni: [
              AzioneTestata(
                icona: Icons.event_available,
                etichetta: 'Metti nel calendario',
                principale: true,
                onTap: () => _metti(p),
              ),
            ],
          ),
          if (p.descrizione case final d? when d.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            PoolCard(
              child: Text(
                d,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ),
          ],
          ..._nelCalendario(p),
          const SizedBox(height: AppSpacing.s24),
          // Le settimane: un chip corto per ognuna, tutte in vista.
          Text(
            'Settimane',
            style: AppTypography.etichetta.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final (i, s) in p.settimane.indexed)
                TonalChip(
                  etichetta: s.scarico ? '${i + 1} · scarico' : '${i + 1}',
                  selezionato: i == w,
                  onSelezionato: (_) => setState(() => _settimana = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Settimana ${w + 1} di ${p.settimane.length}',
                  style: AppTypography.sezione.copyWith(color: colori.testo),
                ),
              ),
              if (w > 0 || p.settimane.length > 1)
                PopupMenuButton<VoidCallback>(
                  icon: Icon(Icons.more_vert, color: colori.testoSecondario),
                  tooltip: 'Azioni della settimana',
                  onSelected: (azione) => azione(),
                  itemBuilder: (_) => [
                    if (w > 0)
                      PopupMenuItem(
                        value: () => _copiaPrima(w, esercizi),
                        child: Text(
                          settimana.scarico
                              ? 'Rifai dalla settimana prima, con una serie in meno'
                              : 'Rifai dalla settimana prima, un po\' di più',
                        ),
                      ),
                    if (p.settimane.length > 1)
                      PopupMenuItem(
                        value: () => _togliSettimana(w),
                        child: const Text('Togli questa settimana'),
                      ),
                  ],
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Settimana di scarico'),
            subtitle: const Text('Meno serie, per recuperare.'),
            value: settimana.scarico,
            onChanged: (v) =>
                _cambia(p.conSettimana(w, settimana.copyWith(scarico: v))),
          ),
          if (settimana.scarico &&
              settimana.sedute.any((s) => s.any((d) => d.serie > 1)))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _cambia(
                  p.conSettimana(
                    w,
                    settimana.copyWith(
                      sedute: [
                        for (final s in settimana.sedute)
                          [for (final d in s) unaSerieInMeno(d)],
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.remove),
                label: const Text('Togli una serie a ogni esercizio'),
              ),
            ),
          for (var j = 0; j < quante; j++) ...[
            const SizedBox(height: AppSpacing.s20),
            ..._seduta(w, j, settimana.sedute[j], esercizi, quante),
          ],
          const SizedBox(height: AppSpacing.s32),
          if (p.settimane.length < _settimaneMassime) ...[
            SecondaryButton(
              label: 'Aggiungi la settimana ${p.settimane.length + 1}',
              icon: Icons.add,
              onPressed: () => _aggiungiSettimana(esercizi),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Copia la settimana $daCopiare con un po\' di più: una serie '
              'in più fino a 4, poi qualche ripetizione o qualche secondo. '
              'La mobilità resta com\'è.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Una seduta della settimana: il titolo con "Aggiungi esercizi" e gli
  /// esercizi, con il menu per spostarli e toglierli.
  List<Widget> _seduta(
    int w,
    int j,
    List<DoseEsercizio> dosi,
    Map<String, EsercizioSecco> esercizi,
    int quante,
  ) {
    final colori = context.colori;
    return [
      TitoloSezione(
        nomeSeduta(j, quante),
        conteggio: dosi.length,
        spiegazione: dosi.isEmpty
            ? null
            : "Fatti come scritti durano circa ${minutiDosi(dosi)}'.",
        azione: 'Aggiungi esercizi',
        onAzione: () => _scegli(w, j),
      ),
      if (dosi.isEmpty)
        const RiquadroVuoto(
          'Nessun esercizio: tocca «Aggiungi esercizi» e scegli quelli da '
          'fare, nell\'ordine.',
          icona: Icons.fitness_center,
        )
      else
        AppListPanel(
          righe: [
            for (final (i, d) in dosi.indexed)
              RigaEsercizio(
                numero: i + 1,
                esercizio: esercizi[d.esercizioId],
                riga: d.comeRiga(ordine: i + 1),
                sotto: d.note,
                onTap: () => mostraFoglioEsercizio(
                  context,
                  esercizio: esercizi[d.esercizioId],
                  riga: d.comeRiga(ordine: i + 1),
                  salva: (r) async {
                    final nuove = [..._attuale!.settimane[w].sedute[j]];
                    nuove[i] = DoseEsercizio.daRiga(r);
                    _cambiaSeduta(w, j, nuove);
                    await _coda;
                  },
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Azioni dell\'esercizio',
                  icon: Icon(Icons.more_vert, color: colori.testoSecondario),
                  onSelected: (azione) => switch (azione) {
                    'su' => _sposta(w, j, i, i - 1),
                    'giu' => _sposta(w, j, i, i + 1),
                    _ => _togliEsercizio(w, j, i),
                  },
                  itemBuilder: (_) => [
                    if (i > 0)
                      const PopupMenuItem(
                        value: 'su',
                        child: Text('Sposta su'),
                      ),
                    if (i < dosi.length - 1)
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
    ];
  }

  /// Dove il programma è già nel calendario: una riga per squadra, con le
  /// date, quante sedute sono passate e il menu per togliere quelle da
  /// fare.
  List<Widget> _nelCalendario(ProgrammaSecco p) {
    final sedute = [
      for (final a
          in ref.watch(allenamentiListProvider(widget.clubId)).value ??
              const <Allenamento>[])
        if (a.programmaId == p.id) a,
    ];
    if (sedute.isEmpty) return const [];
    final nomi = {
      for (final g in ref.watch(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };
    final perSquadra = <String?, List<Allenamento>>{};
    for (final a in sedute) {
      (perSquadra[a.gruppoId] ??= []).add(a);
    }
    return [
      const SizedBox(height: AppSpacing.s24),
      TitoloSezione('Nel calendario', conteggio: sedute.length),
      AppListPanel(
        righe: [
          for (final MapEntry(key: gruppoId, value: elenco)
              in perSquadra.entries)
            _rigaCalendario(
              p,
              gruppoId: gruppoId,
              nome: gruppoId == null ? null : nomi[gruppoId],
              sedute: elenco,
            ),
        ],
      ),
    ];
  }

  Widget _rigaCalendario(
    ProgrammaSecco p, {
    required String? gruppoId,
    required String? nome,
    required List<Allenamento> sedute,
  }) {
    final colori = context.colori;
    final oggi = soloData(DateTime.now());
    final ordinate = [...sedute]..sort((a, b) => a.data.compareTo(b.data));
    final passate = ordinate.where((a) => a.data.isBefore(oggi)).length;
    return AppListRow(
      titolo: gruppoId == null ? 'Tutto il club' : nome ?? 'Squadra',
      sottotitolo:
          'Dal ${dataCompatta(ordinate.first.data)} al '
          '${dataCompatta(ordinate.last.data)} · '
          '$passate passate su ${ordinate.length}',
      trailing: PopupMenuButton<String>(
        tooltip: 'Azioni del calendario',
        icon: Icon(Icons.more_vert, color: colori.testoSecondario),
        onSelected: (_) => _togliDalCalendario(
          p,
          gruppoId,
          gruppoId == null ? 'tutto il club' : nome ?? 'la squadra',
        ),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'togli',
            child: Text('Togli le sedute da oggi in poi'),
          ),
        ],
      ),
    );
  }
}
