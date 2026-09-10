import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../application/macrocicli_providers.dart';
import '../data/duplicazione_stagione_service.dart';
import '../data/macrocicli_repository.dart';
import '../data/stagioni_repository.dart';
import '../domain/macrociclo.dart';
import '../domain/stagione.dart';
import 'albero_stagione.dart';
import 'allenamenti_stagione_screen.dart';
import 'elimina_dialogs.dart';
import 'macrociclo_form_screen.dart';
import 'stagione_form_screen.dart';

enum _AzioneStagione { duplica, modifica, elimina }

class StagioneDetailScreen extends ConsumerStatefulWidget {
  const StagioneDetailScreen({required this.stagione, super.key});

  final Stagione stagione;

  @override
  ConsumerState<StagioneDetailScreen> createState() =>
      _StagioneDetailScreenState();
}

class _StagioneDetailScreenState extends ConsumerState<StagioneDetailScreen> {
  final _ricercaController = TextEditingController();
  String _ricerca = '';

  @override
  void dispose() {
    _ricercaController.dispose();
    super.dispose();
  }

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context) {
    final stagione = widget.stagione;
    final macrocicliAsync = ref.watch(macrocicliListProvider(stagione.id));
    final nomeGruppo = {
      for (final g in ref.watch(gruppiListProvider(stagione.clubId)).value ?? [])
        g.id: g.nome,
    }[stagione.gruppoId];

    void apriNuovo() {
      final macrocicliAttuali =
          ref.read(macrocicliListProvider(stagione.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MacrocicloFormScreen(
            stagioneId: stagione.id,
            ordineSuccessivo: macrocicliAttuali.length + 1,
          ),
        ),
      );
    }

    Future<void> riordina(
      List<Macrociclo> macrocicli,
      int oldIndex,
      int newIndex,
    ) async {
      final aggiornati = List<Macrociclo>.from(macrocicli);
      final spostato = aggiornati.removeAt(oldIndex);
      aggiornati.insert(newIndex, spostato);
      final repository = ref.read(macrocicliRepositoryProvider);
      for (var i = 0; i < aggiornati.length; i++) {
        final m = aggiornati[i];
        if (m.ordine != i + 1) {
          await repository.updateMacrociclo(
            id: m.id,
            nome: m.nome,
            ordine: i + 1,
            dataInizio: m.dataInizio,
            dataFine: m.dataFine,
            obiettivo: m.obiettivo,
          );
        }
      }
    }

    Future<void> elimina() async {
      final conferma = await confermaEliminaStagione(context, ref, stagione);
      if (conferma && context.mounted) {
        await ref.read(stagioniRepositoryProvider).deleteStagione(stagione.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    Future<void> duplicaStagione() async {
      final messenger = ScaffoldMessenger.of(context);
      final nuovaDataInizio = await showDatePicker(
        context: context,
        initialDate: stagione.dataInizio,
        firstDate: DateTime(DateTime.now().year - 2),
        lastDate: DateTime(DateTime.now().year + 5),
        helpText: 'Data di inizio della nuova stagione',
      );
      if (nuovaDataInizio == null) return;
      try {
        final nuovaStagione = await ref
            .read(duplicazioneStagioneServiceProvider)
            .duplica(stagione, nuovaDataInizio);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StagioneDetailScreen(stagione: nuovaStagione),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Errore nella duplicazione: ${messaggioErrore(e)}'),
          ),
        );
      }
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(stagione.nome),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AllenamentiStagioneScreen(stagione: stagione),
              ),
            ),
            icon: const Icon(Icons.calendar_view_day_outlined),
            tooltip: 'Tutti gli allenamenti',
          ),
          PopupMenuButton<_AzioneStagione>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) {
              switch (azione) {
                case _AzioneStagione.duplica:
                  duplicaStagione();
                case _AzioneStagione.modifica:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StagioneFormScreen(
                        clubId: stagione.clubId,
                        stagione: stagione,
                      ),
                    ),
                  );
                case _AzioneStagione.elimina:
                  elimina();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AzioneStagione.duplica,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Duplica stagione'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneStagione.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneStagione.elimina,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.rosso),
                    SizedBox(width: AppSpacing.s12),
                    Text('Elimina', style: TextStyle(color: AppColors.rosso)),
                  ],
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
                  '${_formattaData(stagione.dataInizio)} — '
                  '${_formattaData(stagione.dataFine)}'
                  '${nomeGruppo != null ? ' · $nomeGruppo' : ''}'
                  '${stagione.campionato != null && stagione.campionato!.isNotEmpty ? ' · ${stagione.campionato}' : ''}',
                  style: AppTypography.sezione,
                ),
                if (stagione.obiettivo != null &&
                    stagione.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(stagione.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: macrocicliAsync.when(
              data: (macrocicli) => macrocicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun macrociclo',
                      descrizione:
                          'Aggiungi il primo macrociclo per suddividere la '
                          'stagione.',
                      azionePrincipale: 'Nuovo macrociclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : _elencoMacrocicli(macrocicli, stagione, riordina),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 4),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare i macrocicli.',
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-macrocicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo macrociclo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _elencoMacrocicli(
    List<Macrociclo> macrocicli,
    Stagione stagione,
    Future<void> Function(List<Macrociclo> macrocicli, int oldIndex, int newIndex)
    riordina,
  ) {
    final query = _ricerca.trim().toLowerCase();
    final filtrati = query.isEmpty
        ? macrocicli
        : macrocicli.where((m) => m.nome.toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            0,
          ),
          child: AppTextField(
            etichetta: 'Cerca macrociclo per nome',
            controller: _ricercaController,
            suffixIcon: const Icon(Icons.search),
            onChanged: (value) => setState(() => _ricerca = value),
          ),
        ),
        Expanded(
          child: filtrati.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Text(
                    'Nessun macrociclo corrisponde alla ricerca.',
                    style: AppTypography.corpo,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: query.isEmpty
                      ? ReorderableAppListPanel(
                          onReorderItem: (oldIndex, newIndex) =>
                              riordina(macrocicli, oldIndex, newIndex),
                          righe: [
                            for (final m in filtrati)
                              (
                                chiave: ValueKey(m.id),
                                riga: RigaAlberoMacrociclo(
                                  macrociclo: m,
                                  nomeStagione: stagione.nome,
                                  formattaData: _formattaData,
                                ),
                              ),
                          ],
                        )
                      : AppListPanel(
                          righe: [
                            for (final m in filtrati)
                              RigaAlberoMacrociclo(
                                macrociclo: m,
                                nomeStagione: stagione.nome,
                                formattaData: _formattaData,
                              ),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}
