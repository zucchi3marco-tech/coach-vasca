import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/lane_rule.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/zone_chip.dart';
import '../../export/export_actions.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import '../domain/serie_rapida.dart';
import 'allenamento_form_screen.dart';
import 'scheda_bordo_vasca_screen.dart';
import 'serie_form_screen.dart';
import 'serie_labels.dart';

const _blocchiRapidi = [
  ('riscaldamento', 'Risc.'),
  ('principale', 'Princ.'),
  ('defaticamento', 'Defat.'),
  ('altro', 'Altro'),
];

class AllenamentoDetailScreen extends ConsumerStatefulWidget {
  const AllenamentoDetailScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<AllenamentoDetailScreen> createState() =>
      _AllenamentoDetailScreenState();
}

class _AllenamentoDetailScreenState
    extends ConsumerState<AllenamentoDetailScreen> {
  final _quickController = TextEditingController();
  final _quickFocusNode = FocusNode();
  String _bloccoRapido = 'principale';
  bool _aggiuntaInCorso = false;

  @override
  void dispose() {
    _quickController.dispose();
    _quickFocusNode.dispose();
    super.dispose();
  }

  void _apriSerieCompleta({
    required int ordineSuccessivo,
    required Serie? serie,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SerieFormScreen(
          allenamentoId: widget.allenamento.id,
          ordineSuccessivo: ordineSuccessivo,
          serie: serie,
        ),
      ),
    );
  }

  Future<void> _aggiungiRapida(int ordineSuccessivo) async {
    final parsed = parseSerieRapida(_quickController.text);
    if (parsed == null || _aggiuntaInCorso) return;

    setState(() => _aggiuntaInCorso = true);
    try {
      await ref
          .read(serieRepositoryProvider)
          .createSerie(
            allenamentoId: widget.allenamento.id,
            ordine: ordineSuccessivo,
            blocco: _bloccoRapido,
            ripetute: parsed.ripetute,
            distanzaM: parsed.distanzaM,
            stile: parsed.stile,
            esecuzione: 'nuoto',
            zona: parsed.zona,
            passoObiettivoS: parsed.passoObiettivoS,
            recuperoS: parsed.recuperoS,
          );
      _quickController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    } finally {
      if (mounted) setState(() => _aggiuntaInCorso = false);
    }
  }

  /// Trascinare una serie nell'elenco la sposta e rinumera tutto l'ordine
  /// di conseguenza (nessun campo "Ordine" da compilare a mano, vedi
  /// SerieFormScreen). `serie` e' gia' ordinata come mostrata a schermo;
  /// `newIndex` arriva gia' corretto da `onReorderItem` (a differenza del
  /// vecchio `onReorder`, deprecato, non serve piu' aggiustarlo a mano).
  Future<void> _riordinaSerie(
    List<Serie> serie,
    int oldIndex,
    int newIndex,
  ) async {
    final riordinate = List<Serie>.of(serie);
    final spostata = riordinate.removeAt(oldIndex);
    riordinate.insert(newIndex, spostata);

    final repository = ref.read(serieRepositoryProvider);
    try {
      for (var i = 0; i < riordinate.length; i++) {
        final s = riordinate[i];
        if (s.ordine == i + 1) continue;
        await repository.updateSerie(
          id: s.id,
          ordine: i + 1,
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  String _aiutoRapido(SerieRapida? parsed) {
    if (_quickController.text.trim().isEmpty) {
      return 'Es. 10x100 A2 1:25 r15 sl';
    }
    if (parsed == null) {
      return 'Scrivi almeno ripetute×distanza (es. 10x100)';
    }
    final parti = <String>[
      '${parsed.ripetute} × ${parsed.distanzaM}m ${labelStile(parsed.stile)}',
    ];
    if (parsed.zona != null) parti.add('zona ${parsed.zona}');
    if (parsed.passoObiettivoS != null) {
      parti.add('passo ${formatPaceSeconds(parsed.passoObiettivoS!)}/100m');
    }
    if (parsed.recuperoS != null) parti.add("rec ${parsed.recuperoS}''");
    return '→ ${parti.join(' · ')}';
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
    final serieAttuale = serieAsync.value ?? const [];
    final parsedRapida = parseSerieRapida(_quickController.text);
    final colori = context.colori;

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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
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
                if (allenamento.note != null &&
                    allenamento.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    allenamento.note!,
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: serieAsync.when(
              data: (serie) {
                if (serie.isEmpty) {
                  return EmptyState(
                    icona: Icons.pool_outlined,
                    titolo: 'Nessuna serie',
                    descrizione:
                        'Scrivi la prima serie qui sotto per costruire '
                        'questo allenamento.',
                    azionePrincipale: 'Scrivi la prima serie',
                    onAzionePrincipale: () => _quickFocusNode.requestFocus(),
                  );
                }
                // Riepilogo, non un campo a se': l'attrezzatura resta
                // scritta sulla singola serie (vedi SerieFormScreen), qui
                // si mostra solo l'elenco senza doppioni di quanto già
                // compilato, per prepararsi prima di andare in vasca.
                final materiale = {
                  for (final s in serie)
                    if (s.attrezzatura != null &&
                        s.attrezzatura!.trim().isNotEmpty)
                      s.attrezzatura!.trim(),
                }.toList()..sort();
                final totaleMetri = serie.fold<int>(
                  0,
                  (tot, s) => tot + s.distanzaTotaleM,
                );
                final metriPerBlocco = <String, int>{};
                for (final s in serie) {
                  metriPerBlocco[s.blocco] =
                      (metriPerBlocco[s.blocco] ?? 0) + s.distanzaTotaleM;
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s16,
                        AppSpacing.s16,
                        AppSpacing.s16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Totale: $totaleMetri m',
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Wrap(
                            spacing: AppSpacing.s12,
                            runSpacing: AppSpacing.s4,
                            children: [
                              for (final blocco in ordineBlocchi)
                                if (metriPerBlocco[blocco] != null)
                                  Text(
                                    '${labelBlocco(blocco)} '
                                    '${metriPerBlocco[blocco]} m',
                                    style: AppTypography.piccolo.copyWith(
                                      color: colori.testoSecondario,
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (materiale.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          AppSpacing.s16,
                          AppSpacing.s16,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Materiale utilizzato',
                              style: AppTypography.etichetta.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: [
                                for (final m in materiale) Chip(label: Text(m)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        itemCount: serie.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            _riordinaSerie(serie, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final s = serie[index];
                          final coloreZona = context.dominio.colorePerZona(
                            s.zona,
                            rispetto: colori.linea,
                          );
                          final meta = <String>[];
                          if (s.passoObiettivoS != null) {
                            meta.add(
                              '${formatPaceSeconds(s.passoObiettivoS!)}/100m',
                            );
                          }
                          if (s.recuperoS != null) {
                            meta.add("rec ${s.recuperoS}''");
                          }
                          if (s.ripartenzaS != null) {
                            meta.add(
                              'rip ${formatPaceSeconds(s.ripartenzaS!)}',
                            );
                          }
                          if (s.attrezzatura != null &&
                              s.attrezzatura!.isNotEmpty) {
                            meta.add(s.attrezzatura!);
                          }
                          return Padding(
                            key: ValueKey(s.id),
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s12,
                            ),
                            child: LaneRule(
                              colore: coloreZona,
                              child: InkWell(
                                onTap: () => _apriSerieCompleta(
                                  ordineSuccessivo: serie.length + 1,
                                  serie: s,
                                ),
                                child: PoolCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: colori.azioneTenue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${s.ordine}',
                                              style: AppTypography.piccolo
                                                  .copyWith(
                                                    color: colori.azione,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.s12),
                                          Expanded(
                                            child: Text(
                                              '${s.ripetute}×${s.distanzaM}m '
                                              '${labelStile(s.stile)} '
                                              '${labelEsecuzione(s.esecuzione)}',
                                              style: AppTypography.corpoForte
                                                  .copyWith(
                                                    color: colori.testo,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.s8),
                                      Row(
                                        children: [
                                          Text(
                                            labelBlocco(s.blocco),
                                            style: AppTypography.etichetta
                                                .copyWith(
                                                  color: colori.testoSecondario,
                                                ),
                                          ),
                                          if (s.zona != null) ...[
                                            const SizedBox(
                                              width: AppSpacing.s8,
                                            ),
                                            ZoneChip(sigla: s.zona!),
                                          ],
                                        ],
                                      ),
                                      if (meta.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.s8),
                                        Wrap(
                                          spacing: AppSpacing.s16,
                                          runSpacing: AppSpacing.s4,
                                          children: [
                                            for (final m in meta)
                                              Text(
                                                m,
                                                style: AppTypography.piccolo
                                                    .copyWith(
                                                      color: colori
                                                          .testoSecondario,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                  messaggio: 'Non è stato possibile caricare le serie.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri '
                      'l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Serie completa',
                    onPressed: () => _apriSerieCompleta(
                      ordineSuccessivo: serieAttuale.length + 1,
                      serie: null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: SegmentedButton<String>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        for (final (valore, etichetta) in _blocchiRapidi)
                          ButtonSegment(value: valore, label: Text(etichetta)),
                      ],
                      selected: {_bloccoRapido},
                      onSelectionChanged: (s) =>
                          setState(() => _bloccoRapido = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              AppTextField(
                etichetta: 'Aggiungi serie',
                controller: _quickController,
                focusNode: _quickFocusNode,
                aiuto: _aiutoRapido(parsedRapida),
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) =>
                    _aggiungiRapida(serieAttuale.length + 1),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: parsedRapida != null
                      ? colori.azione
                      : colori.testoTenue,
                  onPressed: (parsedRapida != null && !_aggiuntaInCorso)
                      ? () => _aggiungiRapida(serieAttuale.length + 1)
                      : null,
                ),
              ),
            ],
          ),
        ),
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
