import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../export/export_actions.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../libreria_blocchi/data/training_blocks_repository.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/allenamenti_repository.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/riordino_serie.dart';
import '../domain/serie.dart';
import '../domain/serie_rapida.dart';
import 'allenamento_form_screen.dart';
import 'pannello_aggiungi_serie.dart';
import 'riepilogo_volumi.dart';
import 'riga_gruppo_piramide.dart';
import 'riga_serie.dart';
import 'scheda_bordo_vasca_screen.dart';
import 'scrivi_serie_screen.dart';
import 'serie_form_screen.dart';
import 'serie_labels.dart';

class AllenamentoDetailScreen extends ConsumerStatefulWidget {
  const AllenamentoDetailScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<AllenamentoDetailScreen> createState() =>
      _AllenamentoDetailScreenState();
}

class _AllenamentoDetailScreenState
    extends ConsumerState<AllenamentoDetailScreen> {
  String _bloccoRapido = 'principale';

  void _errore(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
  }

  int _ordineSuccessivo() {
    final serie =
        ref.read(serieListProvider(widget.allenamento.id)).value ?? const [];
    return serie.fold<int>(0, (m, s) => s.ordine > m ? s.ordine : m) + 1;
  }

  void _apriSerieCompleta({required Serie? serie}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SerieFormScreen(
          allenamentoId: widget.allenamento.id,
          ordineSuccessivo: _ordineSuccessivo(),
          serie: serie,
        ),
      ),
    );
  }

  void _apriScriviSerie() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScriviSerieScreen(
          allenamento: widget.allenamento,
          ordineSuccessivo: _ordineSuccessivo(),
        ),
      ),
    );
  }

  void _apriPannello() {
    mostraPannelloAggiungiSerie(
      context,
      bloccoIniziale: _bloccoRapido,
      onBloccoCambiato: (b) => _bloccoRapido = b,
      aggiungiRapida: _aggiungiRapida,
      onScrivi: _apriScriviSerie,
      onSerieCompleta: () => _apriSerieCompleta(serie: null),
    );
  }

  /// Una riga rapida può interpretarsi in più serie (piramide: una
  /// distanza diversa per serie, vedi [parseSerieRapida]): l'ordine si
  /// calcola una sola volta prima del giro, non ad ogni iterazione — il
  /// provider locale potrebbe non essersi ancora aggiornato fra una
  /// creazione e la successiva. Più di una serie dalla stessa riga
  /// condividono un `piramideId`, per restare raggruppate in un'unica
  /// riga visiva (vedi `raggruppaPerPiramide`).
  Future<void> _aggiungiRapida(
    List<SerieRapida> parsedList,
    String blocco,
  ) async {
    try {
      final repository = ref.read(serieRepositoryProvider);
      final piramideId = parsedList.length > 1 ? const Uuid().v4() : null;
      var ordine = _ordineSuccessivo();
      for (final parsed in parsedList) {
        await repository.createSerie(
          allenamentoId: widget.allenamento.id,
          ordine: ordine,
          blocco: blocco,
          ripetute: parsed.ripetute,
          distanzaM: parsed.distanzaM,
          stile: parsed.stile,
          esecuzione: 'nuoto',
          zona: parsed.zona,
          passoObiettivoS: parsed.passoObiettivoS,
          recuperoS: parsed.recuperoS,
          piramideId: piramideId,
        );
        ordine++;
      }
    } catch (e) {
      _errore(e);
      rethrow;
    }
  }

  Future<void> _aggiornaSerie(Serie s, {int? ordine, String? blocco}) {
    return ref
        .read(serieRepositoryProvider)
        .updateSerie(
          id: s.id,
          ordine: ordine ?? s.ordine,
          blocco: blocco ?? s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
        );
  }

  /// Riscrive il numero d'ordine solo delle serie che cambiano (nessun
  /// campo "Ordine" da compilare a mano, vedi SerieFormScreen).
  Future<void> _scriviOrdine(List<Serie> ordinate) async {
    try {
      for (final c in cambiDiOrdine(ordinate)) {
        await _aggiornaSerie(c.serie, ordine: c.ordine);
      }
    } catch (e) {
      _errore(e);
    }
  }

  /// `gruppi` è già nell'ordine mostrato a schermo (una serie normale è
  /// un gruppo da sola, una piramide un gruppo di più righe, vedi
  /// `raggruppaPerPiramide`); `newIndex` arriva già corretto da
  /// `onReorderItem`. Spostare un gruppo lo muove intero, come un solo
  /// elemento dell'elenco.
  Future<void> _riordinaGruppi(List<List<Serie>> gruppi, int da, int a) {
    final riordinati = spostaSerie(gruppi, da, a);
    return _scriviOrdine([for (final g in riordinati) ...g]);
  }

  Future<void> _azioneGruppo(
    List<List<Serie>> gruppi,
    int index,
    AzioneSerie azione,
  ) async {
    final gruppo = gruppi[index];
    switch (azione) {
      case AzioneSerie.su:
        await _riordinaGruppi(gruppi, index, index - 1);
      case AzioneSerie.giu:
        await _riordinaGruppi(gruppi, index, index + 1);
      case AzioneSerie.cambiaBlocco:
        final scelto = await _scegliBlocco(gruppo.first.blocco);
        if (scelto == null || scelto == gruppo.first.blocco) return;
        try {
          for (final s in gruppo) {
            await _aggiornaSerie(s, blocco: scelto);
          }
        } catch (e) {
          _errore(e);
        }
      case AzioneSerie.duplica:
        await _duplicaGruppo(gruppi, index);
      case AzioneSerie.salvaComeBlocco:
        await _salvaComeBlocco(gruppo);
      case AzioneSerie.elimina:
        await _eliminaGruppo(gruppi, index);
    }
  }

  Future<String?> _scegliBlocco(String attuale) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sposta in',
              style: AppTypography.sezione.copyWith(
                color: sheetContext.colori.testo,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final b in ordineBlocchi)
                  TonalChip(
                    etichetta: labelBlocco(b),
                    selezionato: b == attuale,
                    onSelezionato: (_) => Navigator.of(sheetContext).pop(b),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// La copia (tutte le righe del gruppo, con un nuovo `piramideId`
  /// condiviso se è una piramide) va subito dopo l'originale: le righe
  /// successive slittano di conseguenza. Le nuove righe si creano con un
  /// ordine provvisorio (in fondo), poi `_scriviOrdine` riscrive tutto
  /// l'elenco nell'ordine finale voluto, toccando solo chi deve cambiare.
  Future<void> _duplicaGruppo(List<List<Serie>> gruppi, int index) async {
    final gruppo = gruppi[index];
    final nuovoPiramideId = gruppo.length > 1 ? const Uuid().v4() : null;
    try {
      final repository = ref.read(serieRepositoryProvider);
      final nuove = <Serie>[];
      var ordineProvvisorio = _ordineSuccessivo();
      for (final s in gruppo) {
        nuove.add(
          await repository.createSerie(
            allenamentoId: s.allenamentoId,
            ordine: ordineProvvisorio,
            blocco: s.blocco,
            ripetute: s.ripetute,
            distanzaM: s.distanzaM,
            durataS: s.durataS,
            stile: s.stile,
            esecuzione: s.esecuzione,
            zona: s.zona,
            passoObiettivoS: s.passoObiettivoS,
            recuperoS: s.recuperoS,
            ripartenzaS: s.ripartenzaS,
            attrezzatura: s.attrezzatura,
            note: s.note,
            piramideId: nuovoPiramideId,
          ),
        );
        ordineProvvisorio++;
      }
      await _scriviOrdine([
        for (var i = 0; i <= index; i++) ...gruppi[i],
        ...nuove,
        for (var i = index + 1; i < gruppi.length; i++) ...gruppi[i],
      ]);
    } catch (e) {
      _errore(e);
    }
  }

  /// "Salva come blocco": crea subito un blocco in bozza in libreria con
  /// le righe del gruppo (una piramide intera diventa un blocco a più
  /// parti) — da approvare poi nella schermata "Libreria blocchi".
  Future<void> _salvaComeBlocco(List<Serie> gruppo) async {
    final titolo = gruppo.length > 1
        ? '${gruppo.map((s) => s.distanzaM ?? s.durataS).join('-')} ${labelStile(gruppo.first.stile)}'
        : '${labelVolumeSerie(gruppo.first)} ${labelStile(gruppo.first.stile)}';
    try {
      await ref
          .read(trainingBlocksRepositoryProvider)
          .salvaSerieComeBlocco(
            clubId: widget.allenamento.clubId,
            codice: 'M-${DateTime.now().millisecondsSinceEpoch}',
            sport: 'entrambi',
            titolo: titolo,
            serieGruppo: gruppo,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Salvato in libreria come bozza: da approvare nella schermata "Libreria blocchi".',
            ),
          ),
        );
      }
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _eliminaGruppo(List<List<Serie>> gruppi, int index) async {
    final gruppo = gruppi[index];
    final piramide = gruppo.length > 1;
    final prima = gruppo.first;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(piramide ? 'Eliminare la piramide?' : 'Elimina serie'),
        content: Text(
          piramide
              ? 'Eliminare le ${gruppo.length} distanze di questa piramide '
                    '(${gruppo.map((s) => s.distanzaM).join('-')})? '
                    "L'operazione non si può annullare."
              : 'Eliminare ${labelVolumeSerie(prima)} '
                    '${labelStile(prima.stile)}? '
                    "L'operazione non si può annullare.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      final repository = ref.read(serieRepositoryProvider);
      for (final s in gruppo) {
        await repository.deleteSerie(s.id);
      }
      // Il numero d'ordine non deve avere buchi: la prossima serie
      // aggiunta prende lunghezza+1.
      final restanti = [
        for (var i = 0; i < gruppi.length; i++)
          if (i != index) ...gruppi[i],
      ];
      await _scriviOrdine(restanti);
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _eliminaAllenamento(Allenamento allenamento) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare l\'allenamento?'),
        content: const Text(
          'Verranno eliminate per sempre anche le serie e le presenze '
          'registrate per questo allenamento.',
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
    if (conferma != true) return;
    try {
      await ref
          .read(allenamentiRepositoryProvider)
          .deleteAllenamento(allenamento.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _errore(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allenamento = widget.allenamento;
    final serieAsync = ref.watch(serieListProvider(allenamento.id));
    final Map<String, String> nomiGruppi = {
      for (final g
          in ref.watch(gruppiListProvider(allenamento.clubId)).value ?? [])
        g.id: g.nome,
    };
    final nomeGruppo = nomiGruppi[allenamento.gruppoId];
    final colori = context.colori;
    final titolo = allenamento.titolo != null && allenamento.titolo!.isNotEmpty
        ? allenamento.titolo!
        : 'Allenamento';
    final serieCaricate = serieAsync.value ?? const <Serie>[];
    final metri = serieCaricate.fold<int>(0, (t, s) => t + s.distanzaTotaleM);

    // Le due cose che si fanno a bordo vasca stanno in vista nella
    // testata (prima erano nel menu ⋮); "Aggiungi serie" resta il "+".
    final testata = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestataPagina(
          occhiello: [
            traQuanto(allenamento.data),
            dataEstesa(allenamento.data),
            ?nomeGruppo,
          ].join(' · '),
          titolo: titolo,
          numeri: serieCaricate.isEmpty
              ? const []
              : [
                  NumeroTestata(
                    valore: formattaMetri(metri),
                    etichetta: 'Metri',
                  ),
                  NumeroTestata(
                    valore: '${raggruppaPerPiramide(serieCaricate).length}',
                    etichetta: 'Serie',
                  ),
                ],
          azioni: [
            AzioneTestata(
              icona: Icons.pool,
              etichetta: 'Bordo vasca',
              principale: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SchedaBordoVascaScreen(allenamento: allenamento),
                ),
              ),
            ),
            AzioneTestata(
              icona: Icons.how_to_reg_outlined,
              etichetta: 'Presenze',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PresenzeScreen(allenamento: allenamento),
                ),
              ),
            ),
          ],
        ),
        if (allenamento.note != null && allenamento.note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          PoolCard(child: _NoteCompatte(allenamento.note!)),
        ],
        const SizedBox(height: AppSpacing.s16),
      ],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Allenamento'),
        actions: [
          IconButton(
            tooltip: 'Esporta',
            icon: const Icon(Icons.ios_share),
            onPressed: () => mostraMenuExport(
              context,
              titoloDocumento: titolo,
              nomiGruppi: nomiGruppi,
              caricaDati: () async => [
                (
                  allenamento,
                  await ref
                      .read(serieRepositoryProvider)
                      .fetchPerAllenamento(allenamento.id),
                ),
              ],
            ),
          ),
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
            onSelected: (azione) => azione(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllenamentoFormScreen(
                      clubId: allenamento.clubId,
                      allenamento: allenamento,
                    ),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.edit_outlined,
                  etichetta: 'Modifica data, titolo e note',
                ),
              ),
              PopupMenuItem(
                value: () => _eliminaAllenamento(allenamento),
                child: const _VoceMenu(
                  icona: Icons.delete_outline,
                  etichetta: 'Elimina',
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-dettaglio-allenamento',
        onPressed: _apriPannello,
        tooltip: 'Aggiungi serie',
        child: const Icon(Icons.add),
      ),
      body: serieAsync.when(
        data: (serie) {
          if (serie.isEmpty) {
            return ListView(
              children: [
                testata,
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: EmptyState(
                    icona: Icons.pool_outlined,
                    titolo: 'Nessuna serie',
                    descrizione:
                        'Aggiungi la prima serie con il pulsante +, '
                        'oppure scrivi o detta più serie insieme.',
                    azionePrincipale: 'Aggiungi la prima serie',
                    onAzionePrincipale: _apriPannello,
                    azioneSecondaria: 'Scrivi o detta più serie insieme',
                    onAzioneSecondaria: _apriScriviSerie,
                  ),
                ),
              ],
            );
          }
          // Testata e riepilogo stanno DENTRO l'elenco (header): scorrono
          // via e le serie occupano lo schermo. Una piramide (più righe
          // con lo stesso piramideId) è un solo elemento dell'elenco, non
          // una per distanza — si trascina, duplica ed elimina insieme.
          final gruppi = raggruppaPerPiramide(serie);
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 88),
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                testata,
                TitoloSezione('Serie', conteggio: gruppi.length),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    bottom: AppSpacing.s12,
                  ),
                  child: RiepilogoVolumi(serie: serie, mostraTotale: false),
                ),
              ],
            ),
            itemCount: gruppi.length,
            onReorderItem: (da, a) => _riordinaGruppi(gruppi, da, a),
            itemBuilder: (context, index) {
              final gruppo = gruppi[index];
              final maniglia = ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  color: colori.testoSecondario,
                ),
              );
              return Padding(
                key: ValueKey(gruppo.first.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: gruppo.length == 1
                    ? RigaSerie(
                        serie: gruppo.single,
                        primo: index == 0,
                        ultimo: index == gruppi.length - 1,
                        maniglia: maniglia,
                        onApri: () => _apriSerieCompleta(serie: gruppo.single),
                        onAzione: (azione) =>
                            _azioneGruppo(gruppi, index, azione),
                      )
                    : RigaGruppoPiramide(
                        gruppo: gruppo,
                        primo: index == 0,
                        ultimo: index == gruppi.length - 1,
                        maniglia: maniglia,
                        onAzione: (azione) =>
                            _azioneGruppo(gruppi, index, azione),
                      ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 5),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare le serie.',
            suggerimento:
                'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
            dettaglioTecnico: messaggioErrore(error),
          ),
        ),
      ),
    );
  }
}

/// Le note libere dell'allenamento su due righe, con "Mostra tutto".
class _NoteCompatte extends StatefulWidget {
  const _NoteCompatte(this.testo);

  final String testo;

  @override
  State<_NoteCompatte> createState() => _NoteCompatteState();
}

class _NoteCompatteState extends State<_NoteCompatte> {
  bool _aperte = false;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return GestureDetector(
      onTap: () => setState(() => _aperte = !_aperte),
      child: Text(
        widget.testo,
        maxLines: _aperte ? null : 2,
        overflow: _aperte ? TextOverflow.visible : TextOverflow.ellipsis,
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
    );
  }
}

class _VoceMenu extends StatelessWidget {
  const _VoceMenu({required this.icona, required this.etichetta});

  final IconData icona;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(icona, size: 20, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(
          etichetta,
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
      ],
    );
  }
}
