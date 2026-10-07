import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../application/excel_export.dart';
import '../application/excel_import.dart';
import '../application/libreria_blocchi_providers.dart';
import '../data/training_blocks_repository.dart';
import '../domain/training_block.dart';
import 'blocco_detail_screen.dart';
import 'blocco_form_screen.dart';

String _labelSport(String sport) => switch (sport) {
  'nuoto' => 'Nuoto',
  'pallanuoto' => 'Pallanuoto',
  'entrambi' => 'Entrambi',
  _ => sport,
};

class LibreriaBlocchiScreen extends ConsumerStatefulWidget {
  const LibreriaBlocchiScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<LibreriaBlocchiScreen> createState() =>
      _LibreriaBlocchiScreenState();
}

class _LibreriaBlocchiScreenState extends ConsumerState<LibreriaBlocchiScreen> {
  String _ricerca = '';
  String? _filtroSport;
  String? _filtroStato;
  bool _importando = false;
  bool _esportando = false;

  @override
  Widget build(BuildContext context) {
    final blocchiAsync = ref.watch(trainingBlocksListProvider(widget.clubId));
    final blocchi = blocchiAsync.value ?? const <TrainingBlock>[];
    final approvati = blocchi.where((b) => b.stato == 'approvato').length;

    return AppScaffold(
      // Il titolo sta in grande nella testata: qui solo il ritorno.
      appBar: AppBar(),
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(trainingBlocksRepositoryProvider)
            .refreshFromRemote(widget.clubId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          children: [
            // Importa ed esporta erano due icone senza nome in alto: ora
            // sono pulsanti con l'etichetta, accanto a "Nuovo blocco".
            TestataPagina(
              titolo: 'Libreria blocchi',
              sottotitolo:
                  'I blocchi approvati sono quelli che l\'AI usa per '
                  'comporre le sedute.',
              numeri: blocchiAsync.hasValue
                  ? [
                      NumeroTestata(
                        valore: '${blocchi.length}',
                        etichetta: 'Blocchi',
                      ),
                      NumeroTestata(
                        valore: '$approvati',
                        etichetta: 'Approvati',
                      ),
                      NumeroTestata(
                        valore: '${blocchi.length - approvati}',
                        etichetta: 'Bozze',
                      ),
                    ]
                  : const [],
              azioni: [
                AzioneTestata(
                  icona: Icons.add,
                  etichetta: 'Nuovo blocco',
                  principale: true,
                  onTap: _nuovoBlocco,
                ),
                AzioneTestata(
                  icona: Icons.upload_file_outlined,
                  etichetta: _importando ? 'Importo...' : 'Importa da Excel',
                  onTap: _importando ? () {} : _importaDaExcel,
                ),
                AzioneTestata(
                  icona: Icons.download_outlined,
                  etichetta: _esportando ? 'Esporto...' : 'Esporta in Excel',
                  onTap: _esportando ? () {} : _esportaInExcel,
                ),
              ],
            ),
            // Ricerca e filtri solo quando c'e' qualcosa da cercare.
            if (blocchi.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Cerca per titolo o codice',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _ricerca = value),
              ),
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final (valore, etichetta) in const [
                    (null, 'Tutti gli sport'),
                    ('nuoto', 'Nuoto'),
                    ('pallanuoto', 'Pallanuoto'),
                    ('entrambi', 'Entrambi'),
                  ])
                    TonalChip(
                      etichetta: etichetta,
                      selezionato: _filtroSport == valore,
                      onSelezionato: (_) =>
                          setState(() => _filtroSport = valore),
                    ),
                  for (final (valore, etichetta) in const [
                    (null, 'Tutti gli stati'),
                    ('approvato', 'Approvati'),
                    ('bozza', 'Bozze'),
                  ])
                    TonalChip(
                      etichetta: etichetta,
                      selezionato: _filtroStato == valore,
                      onSelezionato: (_) =>
                          setState(() => _filtroStato = valore),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            blocchiAsync.when(
              data: (blocchi) => _Elenco(
                blocchi: blocchi,
                ricerca: _ricerca,
                filtroSport: _filtroSport,
                filtroStato: _filtroStato,
                onTap: (b) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BloccoDetailScreen(blocco: b),
                  ),
                ),
                onTapNuovo: _nuovoBlocco,
                onApprova: _toggleApprovato,
                onDuplica: _duplica,
                onElimina: _elimina,
              ),
              loading: () => const LoadingSkeletonList(righe: 6),
              error: (error, _) => ErrorBanner(
                messaggio: 'Non è stato possibile caricare la libreria.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: messaggioErrore(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _nuovoBlocco() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BloccoFormScreen(clubId: widget.clubId),
      ),
    );
  }

  Future<void> _toggleApprovato(TrainingBlock blocco) async {
    final nuovoStato = blocco.stato == 'approvato' ? 'bozza' : 'approvato';
    try {
      await ref.read(trainingBlocksRepositoryProvider).updateBlocco(blocco.id, {
        'stato': nuovoStato,
      });
    } catch (e) {
      if (mounted) _mostraErrore(e);
    }
  }

  Future<void> _duplica(TrainingBlock blocco) async {
    try {
      await ref.read(trainingBlocksRepositoryProvider).duplicaBlocco(blocco);
    } catch (e) {
      if (mounted) _mostraErrore(e);
    }
  }

  Future<void> _elimina(TrainingBlock blocco) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminare "${blocco.titolo}"?'),
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
    if (conferma != true) return;
    try {
      await ref.read(trainingBlocksRepositoryProvider).deleteBlocco(blocco.id);
    } catch (e) {
      if (mounted) _mostraErrore(e);
    }
  }

  void _mostraErrore(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
  }

  Future<void> _esportaInExcel() async {
    if (!scaricaFileDisponibile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esportazione disponibile solo da browser.'),
        ),
      );
      return;
    }
    setState(() => _esportando = true);
    try {
      final repository = ref.read(trainingBlocksRepositoryProvider);
      final blocchi = await ref.read(
        trainingBlocksListProvider(widget.clubId).future,
      );
      final parti = await repository.fetchPartiPerBlocchi([
        for (final b in blocchi) b.id,
      ]);
      final bytes = generaExcelLibreria(blocchi, parti);
      scaricaFile(
        bytes,
        'libreria_blocchi.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (mounted) _mostraErrore(e);
    } finally {
      if (mounted) setState(() => _esportando = false);
    }
  }

  Future<void> _importaDaExcel() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      dialogTitle: 'Scegli il file Excel della libreria',
    );
    if (file == null || !mounted) return;

    setState(() => _importando = true);
    try {
      final bytes = await file.readAsBytes();
      final parsed = parseLibreriaExcel(bytes);
      if (parsed.blocchi.isEmpty && parsed.errori.isNotEmpty) {
        if (mounted) await _mostraRiepilogoErrori(parsed.errori);
        return;
      }
      final riepilogo = await ref
          .read(trainingBlocksRepositoryProvider)
          .importa(widget.clubId, parsed);
      if (mounted) await _mostraRiepilogoImportazione(riepilogo);
    } catch (e) {
      if (mounted) _mostraErrore(e);
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<void> _mostraRiepilogoErrori(List<RigaErrore> errori) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('File non valido'),
        content: SingleChildScrollView(
          child: Text(errori.map((e) => e.toString()).join('\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostraRiepilogoImportazione(RiepilogoImportazione r) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importazione completata'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${r.importati} nuovi blocchi importati'),
              Text('${r.aggiornati} aggiornati'),
              Text('${r.saltati} saltati perché modificati da te'),
              if (r.errori.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Text('${r.errori.length} errori:'),
                ...r.errori.take(20).map((e) => Text('• $e')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }
}

class _Elenco extends StatelessWidget {
  const _Elenco({
    required this.blocchi,
    required this.ricerca,
    required this.filtroSport,
    required this.filtroStato,
    required this.onTap,
    required this.onTapNuovo,
    required this.onApprova,
    required this.onDuplica,
    required this.onElimina,
  });

  final List<TrainingBlock> blocchi;
  final String ricerca;
  final String? filtroSport;
  final String? filtroStato;
  final ValueChanged<TrainingBlock> onTap;
  final VoidCallback onTapNuovo;
  final ValueChanged<TrainingBlock> onApprova;
  final ValueChanged<TrainingBlock> onDuplica;
  final ValueChanged<TrainingBlock> onElimina;

  List<TrainingBlock> _filtrati() {
    final query = ricerca.trim().toLowerCase();
    return blocchi.where((b) {
      if (filtroSport != null && b.sport != filtroSport) return false;
      if (filtroStato != null && b.stato != filtroStato) return false;
      if (query.isNotEmpty &&
          !b.titolo.toLowerCase().contains(query) &&
          !b.codice.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (blocchi.isEmpty) {
      return EmptyState(
        icona: Icons.view_list_outlined,
        titolo: 'Nessun blocco in libreria',
        descrizione:
            'Importa il file Excel della libreria o crea il primo blocco '
            'a mano.',
        azionePrincipale: 'Nuovo blocco',
        onAzionePrincipale: onTapNuovo,
      );
    }

    final filtrati = _filtrati()..sort((a, b) => a.titolo.compareTo(b.titolo));
    if (filtrati.isEmpty) {
      return const EmptyState(
        icona: Icons.search_off,
        titolo: 'Nessun blocco trovato',
        descrizione: 'Prova a cambiare i filtri o il testo cercato.',
        azionePrincipale: 'Ho capito',
      );
    }

    // Raggruppati per fase (riscaldamento, principale...): con centinaia
    // di blocchi un elenco unico in ordine alfabetico non si leggeva.
    final perFase = <String, List<TrainingBlock>>{};
    for (final b in filtrati) {
      final fase = b.fase.trim().isEmpty ? 'Senza fase' : b.fase.trim();
      perFase.putIfAbsent(fase, () => []).add(b);
    }
    final fasi = perFase.keys.toList()
      ..sort((a, b) {
        if ((a == 'Senza fase') != (b == 'Senza fase')) {
          return a == 'Senza fase' ? 1 : -1;
        }
        return a.compareTo(b);
      });

    final colori = context.colori;
    final ciano = context.dominio.evidenzaCiano;
    Widget scheda(TrainingBlock b) {
      final approvato = b.stato == 'approvato';
      return SchedaElenco(
        leading: IconaRiquadro(
          Icons.view_list_outlined,
          colore: approvato ? ciano : colori.attenzione,
          dimensione: 48,
        ),
        titolo: b.titolo,
        sottotitolo: [
          b.codice,
          [
            if (b.metriTotali > 0) '${b.metriTotali} m',
            if (b.durataStimataMin > 0) '~${b.durataStimataMin} min',
          ].join(', '),
        ].where((t) => t.isNotEmpty).join(' · '),
        // Solo le bozze hanno l'etichetta: "Approvato" su centinaia di
        // schede era rumore. Lo sport solo se non si sta gia' filtrando.
        sotto: approvato && filtroSport != null
            ? null
            : Wrap(
                spacing: AppSpacing.s4,
                runSpacing: AppSpacing.s4,
                children: [
                  if (!approvato) Pastiglia('Bozza', colore: colori.attenzione),
                  if (filtroSport == null)
                    Pastiglia(
                      _labelSport(b.sport),
                      colore: colori.testoSecondario,
                    ),
                ],
              ),
        mostraFreccia: false,
        trailing: PopupMenuButton<VoidCallback>(
          icon: Icon(Icons.more_vert, color: colori.testoSecondario),
          tooltip: 'Altre azioni',
          onSelected: (azione) => azione(),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: () => onApprova(b),
              child: Text(approvato ? 'Rendi bozza' : 'Approva'),
            ),
            PopupMenuItem(
              value: () => onDuplica(b),
              child: const Text('Duplica'),
            ),
            PopupMenuItem(
              value: () => onElimina(b),
              child: const Text('Elimina'),
            ),
          ],
        ),
        onTap: () => onTap(b),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final fase in fasi) ...[
          SezioneSchede(
            titolo: fase,
            vociIniziali: 6,
            figli: [for (final b in perFase[fase]!) scheda(b)],
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
      ],
    );
  }
}
