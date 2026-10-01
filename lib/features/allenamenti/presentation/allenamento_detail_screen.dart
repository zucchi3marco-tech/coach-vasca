import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/tonal_chip.dart';
import '../../export/export_actions.dart';
import '../../gruppi/application/gruppi_providers.dart';
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

  Future<void> _aggiungiRapida(SerieRapida parsed, String blocco) async {
    try {
      await ref
          .read(serieRepositoryProvider)
          .createSerie(
            allenamentoId: widget.allenamento.id,
            ordine: _ordineSuccessivo(),
            blocco: blocco,
            ripetute: parsed.ripetute,
            distanzaM: parsed.distanzaM,
            stile: parsed.stile,
            esecuzione: 'nuoto',
            zona: parsed.zona,
            passoObiettivoS: parsed.passoObiettivoS,
            recuperoS: parsed.recuperoS,
          );
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

  /// `serie` è già ordinata come mostrata a schermo; `newIndex` arriva già
  /// corretto da `onReorderItem`.
  Future<void> _riordinaSerie(List<Serie> serie, int da, int a) =>
      _scriviOrdine(spostaSerie(serie, da, a));

  Future<void> _azione(List<Serie> serie, int index, AzioneSerie azione) async {
    final s = serie[index];
    switch (azione) {
      case AzioneSerie.su:
        await _riordinaSerie(serie, index, index - 1);
      case AzioneSerie.giu:
        await _riordinaSerie(serie, index, index + 1);
      case AzioneSerie.cambiaBlocco:
        final scelto = await _scegliBlocco(s.blocco);
        if (scelto == null || scelto == s.blocco) return;
        try {
          await _aggiornaSerie(s, blocco: scelto);
        } catch (e) {
          _errore(e);
        }
      case AzioneSerie.duplica:
        await _duplica(serie, index);
      case AzioneSerie.elimina:
        await _elimina(serie, index);
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

  /// La copia va subito dopo l'originale: le serie successive slittano di
  /// una posizione (partendo dall'ultima, così non ci sono mai due serie
  /// con lo stesso numero).
  Future<void> _duplica(List<Serie> serie, int index) async {
    final s = serie[index];
    try {
      for (var i = serie.length - 1; i > index; i--) {
        await _aggiornaSerie(serie[i], ordine: i + 2);
      }
      await ref
          .read(serieRepositoryProvider)
          .createSerie(
            allenamentoId: s.allenamentoId,
            ordine: index + 2,
            blocco: s.blocco,
            ripetute: s.ripetute,
            distanzaM: s.distanzaM,
            stile: s.stile,
            esecuzione: s.esecuzione,
            zona: s.zona,
            passoObiettivoS: s.passoObiettivoS,
            recuperoS: s.recuperoS,
            ripartenzaS: s.ripartenzaS,
            attrezzatura: s.attrezzatura,
            note: s.note,
          );
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _elimina(List<Serie> serie, int index) async {
    final s = serie[index];
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina serie'),
        content: Text(
          'Eliminare ${s.ripetute}×${s.distanzaM} ${labelStile(s.stile)}? '
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
      await ref.read(serieRepositoryProvider).deleteSerie(s.id);
      // Il numero d'ordine non deve avere buchi: la prossima serie
      // aggiunta prende lunghezza+1.
      final restanti = [...serie]..removeAt(index);
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

    final testata = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${allenamento.data.day.toString().padLeft(2, '0')}/'
            '${allenamento.data.month.toString().padLeft(2, '0')}/'
            '${allenamento.data.year}'
            '${nomeGruppo != null ? ' · $nomeGruppo' : ''}',
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          if (allenamento.note != null && allenamento.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            _NoteCompatte(allenamento.note!),
          ],
        ],
      ),
    );

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          allenamento.titolo != null && allenamento.titolo!.isNotEmpty
              ? allenamento.titolo!
              : 'Allenamento',
        ),
        actions: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) => azione(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SchedaBordoVascaScreen(allenamento: allenamento),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.pool,
                  etichetta: 'Vista bordo vasca',
                ),
              ),
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PresenzeScreen(allenamento: allenamento),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.how_to_reg_outlined,
                  etichetta: 'Presenze',
                ),
              ),
              PopupMenuItem(
                value: () => mostraMenuExport(
                  context,
                  titoloDocumento:
                      allenamento.titolo != null &&
                          allenamento.titolo!.isNotEmpty
                      ? allenamento.titolo!
                      : 'Allenamento',
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
                child: const _VoceMenu(
                  icona: Icons.ios_share,
                  etichetta: 'Esporta',
                ),
              ),
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
                  etichetta: 'Modifica',
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                testata,
                const Divider(height: 1),
                Expanded(
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
          // via e le serie occupano lo schermo.
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 88),
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                testata,
                RiepilogoVolumi(serie: serie),
                const SizedBox(height: AppSpacing.s12),
              ],
            ),
            itemCount: serie.length,
            onReorderItem: (da, a) => _riordinaSerie(serie, da, a),
            itemBuilder: (context, index) {
              final s = serie[index];
              return Padding(
                key: ValueKey(s.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: RigaSerie(
                  serie: s,
                  primo: index == 0,
                  ultimo: index == serie.length - 1,
                  maniglia: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      color: colori.testoSecondario,
                    ),
                  ),
                  onApri: () => _apriSerieCompleta(serie: s),
                  onAzione: (azione) => _azione(serie, index, azione),
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
