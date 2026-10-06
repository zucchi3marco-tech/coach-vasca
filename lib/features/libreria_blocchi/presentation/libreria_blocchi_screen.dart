import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/scarica_file.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
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

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Libreria blocchi'),
        actions: [
          IconButton(
            tooltip: 'Esporta in Excel',
            onPressed: _esportando ? null : _esportaInExcel,
            icon: _esportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Importa da Excel',
            onPressed: _importando ? null : _importaDaExcel,
            icon: _importando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            etichetta: 'Cerca per titolo o codice',
            suffixIcon: const Icon(Icons.search),
            onChanged: (value) => setState(() => _ricerca = value),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              TonalChip(
                etichetta: 'Tutti gli sport',
                selezionato: _filtroSport == null,
                onSelezionato: (_) => setState(() => _filtroSport = null),
              ),
              for (final s in ['nuoto', 'pallanuoto', 'entrambi'])
                TonalChip(
                  etichetta: _labelSport(s),
                  selezionato: _filtroSport == s,
                  onSelezionato: (_) => setState(() => _filtroSport = s),
                ),
              TonalChip(
                etichetta: 'Tutti gli stati',
                selezionato: _filtroStato == null,
                onSelezionato: (_) => setState(() => _filtroStato = null),
              ),
              TonalChip(
                etichetta: 'Approvati',
                selezionato: _filtroStato == 'approvato',
                onSelezionato: (_) =>
                    setState(() => _filtroStato = 'approvato'),
              ),
              TonalChip(
                etichetta: 'Bozze',
                selezionato: _filtroStato == 'bozza',
                onSelezionato: (_) => setState(() => _filtroStato = 'bozza'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(trainingBlocksRepositoryProvider)
                  .refreshFromRemote(widget.clubId),
              child: blocchiAsync.when(
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
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [LoadingSkeletonList(righe: 6)],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ErrorBanner(
                      messaggio: 'Non è stato possibile caricare la libreria.',
                      suggerimento: 'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                      dettaglioTecnico: messaggioErrore(error),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nuovoBlocco,
        tooltip: 'Nuovo blocco',
        child: const Icon(Icons.add),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icona: Icons.view_list_outlined,
            titolo: 'Nessun blocco in libreria',
            descrizione: 'Importa il file Excel della libreria o crea il primo blocco a mano.',
            azionePrincipale: 'Nuovo blocco',
            onAzionePrincipale: onTapNuovo,
          ),
        ],
      );
    }

    final filtrati = _filtrati()..sort((a, b) => a.titolo.compareTo(b.titolo));
    if (filtrati.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icona: Icons.search_off,
            titolo: 'Nessun blocco trovato',
            descrizione: 'Prova a cambiare i filtri o il testo cercato.',
            azionePrincipale: 'Ho capito',
          ),
        ],
      );
    }

    final colori = context.colori;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: AppListPanel(
        righe: [
          for (final b in filtrati)
            AppListRow(
              titolo: b.titolo,
              // Senza fase (blocco scritto a mano) restava un "·" appeso.
              sottotitolo: [
                _labelSport(b.sport),
                if (b.fase.trim().isNotEmpty) b.fase.trim(),
                if (b.metriTotali > 0) '${b.metriTotali} m',
              ].join(' · '),
              extraTitolo: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: b.stato == 'approvato'
                      ? colori.okTenue
                      : colori.attenzioneTenue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  b.stato == 'approvato' ? 'Approvato' : 'Bozza',
                  style: AppTypography.piccolo.copyWith(
                    color: b.stato == 'approvato'
                        ? colori.ok
                        : colori.attenzione,
                  ),
                ),
              ),
              trailing: PopupMenuButton<VoidCallback>(
                icon: Icon(Icons.more_vert, color: colori.testoSecondario),
                onSelected: (azione) => azione(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: () => onApprova(b),
                    child: Text(
                      b.stato == 'approvato' ? 'Rendi bozza' : 'Approva',
                    ),
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
            ),
        ],
      ),
    );
  }
}
