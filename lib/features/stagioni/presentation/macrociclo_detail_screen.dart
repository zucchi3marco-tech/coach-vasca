import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/breadcrumb_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/ordine_badge.dart';
import '../application/macrocicli_providers.dart';
import '../application/mesocicli_providers.dart';
import '../data/duplicazione_macrociclo_service.dart';
import '../data/macrocicli_repository.dart';
import '../data/mesocicli_repository.dart';
import '../domain/macrociclo.dart';
import '../domain/mesociclo.dart';
import 'elimina_dialogs.dart';
import 'macrociclo_form_screen.dart';
import 'mesociclo_detail_screen.dart';
import 'mesociclo_form_screen.dart';

enum _AzioneMacrociclo { duplica, modifica, elimina }

class MacrocicloDetailScreen extends ConsumerWidget {
  const MacrocicloDetailScreen({
    required this.macrociclo,
    required this.nomeStagione,
    super.key,
  });

  final Macrociclo macrociclo;

  /// Nome della stagione a cui appartiene, solo per la breadcrumb — evita
  /// una query in più: viene passato da chi apre questa schermata,
  /// che lo conosce già.
  final String nomeStagione;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesocicliAsync = ref.watch(mesocicliListProvider(macrociclo.id));
    final fratelli =
        ref.watch(macrocicliListProvider(macrociclo.stagioneId)).value ?? [];
    final indiceAttuale = fratelli.indexWhere((m) => m.id == macrociclo.id);
    final precedente = indiceAttuale > 0
        ? fratelli[indiceAttuale - 1]
        : null;
    final successivo =
        indiceAttuale >= 0 && indiceAttuale < fratelli.length - 1
        ? fratelli[indiceAttuale + 1]
        : null;

    void vaiAlFratello(Macrociclo m) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MacrocicloDetailScreen(
            macrociclo: m,
            nomeStagione: nomeStagione,
          ),
        ),
      );
    }

    void apriNuovo() {
      final mesocicliAttuali =
          ref.read(mesocicliListProvider(macrociclo.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MesocicloFormScreen(
            macrocicloId: macrociclo.id,
            ordineSuccessivo: mesocicliAttuali.length + 1,
          ),
        ),
      );
    }

    Future<void> riordina(
      List<Mesociclo> mesocicli,
      int oldIndex,
      int newIndex,
    ) async {
      final aggiornati = List<Mesociclo>.from(mesocicli);
      final spostato = aggiornati.removeAt(oldIndex);
      aggiornati.insert(newIndex, spostato);
      final repository = ref.read(mesocicliRepositoryProvider);
      for (var i = 0; i < aggiornati.length; i++) {
        final m = aggiornati[i];
        if (m.ordine != i + 1) {
          await repository.updateMesociclo(
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
      final conferma = await confermaEliminaMacrociclo(
        context,
        ref,
        macrociclo,
      );
      if (conferma && context.mounted) {
        await ref
            .read(macrocicliRepositoryProvider)
            .deleteMacrociclo(macrociclo.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    Future<void> duplicaMacrociclo() async {
      final messenger = ScaffoldMessenger.of(context);
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplica macrociclo?'),
          content: const Text(
            'Verrà creato un nuovo macrociclo subito dopo questo, con tutti '
            'i mesocicli, i microcicli e gli allenamenti copiati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Duplica'),
            ),
          ],
        ),
      );
      if (conferma != true) return;
      try {
        final nuovoMacrociclo = await ref
            .read(duplicazioneMacrocicloServiceProvider)
            .duplica(macrociclo);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MacrocicloDetailScreen(
              macrociclo: nuovoMacrociclo,
              nomeStagione: nomeStagione,
            ),
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
        title: Text(macrociclo.nome),
        actions: [
          PopupMenuButton<_AzioneMacrociclo>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) {
              switch (azione) {
                case _AzioneMacrociclo.duplica:
                  duplicaMacrociclo();
                case _AzioneMacrociclo.modifica:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MacrocicloFormScreen(
                        stagioneId: macrociclo.stagioneId,
                        ordineSuccessivo: macrociclo.ordine,
                        macrociclo: macrociclo,
                      ),
                    ),
                  );
                case _AzioneMacrociclo.elimina:
                  elimina();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AzioneMacrociclo.duplica,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Duplica macrociclo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneMacrociclo.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneMacrociclo.elimina,
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
          BreadcrumbBar(
            tappe: [nomeStagione, macrociclo.nome],
            trailing: Row(
              children: [
                IconButton(
                  onPressed: precedente == null
                      ? null
                      : () => vaiAlFratello(precedente),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Macrociclo precedente',
                ),
                IconButton(
                  onPressed: successivo == null
                      ? null
                      : () => vaiAlFratello(successivo),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Macrociclo successivo',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formattaData(macrociclo.dataInizio)} — '
                  '${_formattaData(macrociclo.dataFine)}',
                  style: AppTypography.sezione,
                ),
                if (macrociclo.obiettivo != null &&
                    macrociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(macrociclo.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: mesocicliAsync.when(
              data: (mesocicli) => mesocicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun mesociclo',
                      descrizione:
                          'Aggiungi il primo mesociclo per suddividere '
                          'questo macrociclo.',
                      azionePrincipale: 'Nuovo mesociclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: ReorderableAppListPanel(
                        onReorderItem: (oldIndex, newIndex) =>
                            riordina(mesocicli, oldIndex, newIndex),
                        righe: [
                          for (final m in mesocicli)
                            (
                              chiave: ValueKey(m.id),
                              riga: AppListRow(
                                leading: OrdineBadge(numero: m.ordine),
                                titolo: m.nome,
                                sottotitolo:
                                    '${_formattaData(m.dataInizio)} — '
                                    '${_formattaData(m.dataFine)}',
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MesocicloDetailScreen(
                                      mesociclo: m,
                                      nomeStagione: nomeStagione,
                                      nomeMacrociclo: macrociclo.nome,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 4),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare i mesocicli.',
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
        heroTag: 'fab-mesocicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo mesociclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
