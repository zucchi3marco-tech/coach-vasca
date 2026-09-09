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
import '../application/mesocicli_providers.dart';
import '../application/microcicli_providers.dart';
import '../data/duplicazione_mesociclo_service.dart';
import '../data/mesocicli_repository.dart';
import '../data/microcicli_repository.dart';
import '../domain/mesociclo.dart';
import '../domain/microciclo.dart';
import 'elimina_dialogs.dart';
import 'mesociclo_form_screen.dart';
import 'microciclo_detail_screen.dart';
import 'microciclo_form_screen.dart';

enum _AzioneMesociclo { duplica, modifica, elimina }

class MesocicloDetailScreen extends ConsumerWidget {
  const MesocicloDetailScreen({
    required this.mesociclo,
    required this.nomeStagione,
    required this.nomeMacrociclo,
    super.key,
  });

  final Mesociclo mesociclo;

  /// Solo per la breadcrumb — vedi `MacrocicloDetailScreen.nomeStagione`.
  final String nomeStagione;
  final String nomeMacrociclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(microcicliListProvider(mesociclo.id));
    final fratelli =
        ref.watch(mesocicliListProvider(mesociclo.macrocicloId)).value ?? [];
    final indiceAttuale = fratelli.indexWhere((m) => m.id == mesociclo.id);
    final precedente = indiceAttuale > 0
        ? fratelli[indiceAttuale - 1]
        : null;
    final successivo =
        indiceAttuale >= 0 && indiceAttuale < fratelli.length - 1
        ? fratelli[indiceAttuale + 1]
        : null;

    void vaiAlFratello(Mesociclo m) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MesocicloDetailScreen(
            mesociclo: m,
            nomeStagione: nomeStagione,
            nomeMacrociclo: nomeMacrociclo,
          ),
        ),
      );
    }

    void apriNuovo() {
      final microcicliAttuali =
          ref.read(microcicliListProvider(mesociclo.id)).value ?? [];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MicrocicloFormScreen(
            mesocicloId: mesociclo.id,
            ordineSuccessivo: microcicliAttuali.length + 1,
          ),
        ),
      );
    }

    Future<void> riordina(
      List<Microciclo> microcicli,
      int oldIndex,
      int newIndex,
    ) async {
      final aggiornati = List<Microciclo>.from(microcicli);
      final spostato = aggiornati.removeAt(oldIndex);
      aggiornati.insert(newIndex, spostato);
      final repository = ref.read(microcicliRepositoryProvider);
      for (var i = 0; i < aggiornati.length; i++) {
        final m = aggiornati[i];
        if (m.ordine != i + 1) {
          await repository.updateMicrociclo(
            id: m.id,
            nome: m.nome,
            numeroSettimana: m.numeroSettimana,
            ordine: i + 1,
            dataInizio: m.dataInizio,
            dataFine: m.dataFine,
            tipo: m.tipo,
          );
        }
      }
    }

    Future<void> elimina() async {
      final conferma = await confermaEliminaMesociclo(context, ref, mesociclo);
      if (conferma && context.mounted) {
        await ref
            .read(mesocicliRepositoryProvider)
            .deleteMesociclo(mesociclo.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    Future<void> duplicaMesociclo() async {
      final messenger = ScaffoldMessenger.of(context);
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Duplica mesociclo?'),
          content: const Text(
            'Verrà creato un nuovo mesociclo subito dopo questo, con tutti '
            'i microcicli e gli allenamenti copiati.',
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
        final nuovoMesociclo = await ref
            .read(duplicazioneMesocicloServiceProvider)
            .duplica(mesociclo);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MesocicloDetailScreen(
              mesociclo: nuovoMesociclo,
              nomeStagione: nomeStagione,
              nomeMacrociclo: nomeMacrociclo,
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
        title: Text(mesociclo.nome),
        actions: [
          PopupMenuButton<_AzioneMesociclo>(
            icon: const Icon(Icons.more_vert),
            onSelected: (azione) {
              switch (azione) {
                case _AzioneMesociclo.duplica:
                  duplicaMesociclo();
                case _AzioneMesociclo.modifica:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MesocicloFormScreen(
                        macrocicloId: mesociclo.macrocicloId,
                        ordineSuccessivo: mesociclo.ordine,
                        mesociclo: mesociclo,
                      ),
                    ),
                  );
                case _AzioneMesociclo.elimina:
                  elimina();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AzioneMesociclo.duplica,
                child: Row(
                  children: [
                    Icon(Icons.content_copy_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Duplica mesociclo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneMesociclo.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: AppSpacing.s12),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AzioneMesociclo.elimina,
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
            tappe: [nomeStagione, nomeMacrociclo, mesociclo.nome],
            trailing: Row(
              children: [
                IconButton(
                  onPressed: precedente == null
                      ? null
                      : () => vaiAlFratello(precedente),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mesociclo precedente',
                ),
                IconButton(
                  onPressed: successivo == null
                      ? null
                      : () => vaiAlFratello(successivo),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mesociclo successivo',
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
                  '${_formattaData(mesociclo.dataInizio)} — '
                  '${_formattaData(mesociclo.dataFine)}',
                  style: AppTypography.sezione,
                ),
                if (mesociclo.obiettivo != null &&
                    mesociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(mesociclo.obiettivo!, style: AppTypography.corpo),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: microcicliAsync.when(
              data: (microcicli) => microcicli.isEmpty
                  ? EmptyState(
                      icona: Icons.timeline_outlined,
                      titolo: 'Nessun microciclo',
                      descrizione:
                          'Aggiungi il primo microciclo per suddividere '
                          'questo mesociclo in settimane.',
                      azionePrincipale: 'Nuovo microciclo',
                      onAzionePrincipale: apriNuovo,
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: ReorderableAppListPanel(
                        onReorderItem: (oldIndex, newIndex) =>
                            riordina(microcicli, oldIndex, newIndex),
                        righe: [
                          for (final m in microcicli)
                            (
                              chiave: ValueKey(m.id),
                              riga: AppListRow(
                                leading: OrdineBadge(numero: m.ordine),
                                titolo: m.nome != null && m.nome!.isNotEmpty
                                    ? m.nome!
                                    : (m.numeroSettimana != null
                                          ? 'Settimana ${m.numeroSettimana}'
                                          : 'Microciclo'),
                                sottotitolo:
                                    '${_formattaData(m.dataInizio)} — '
                                    '${_formattaData(m.dataFine)}'
                                    '${m.tipo != null && m.tipo!.isNotEmpty ? ' · ${m.tipo}' : ''}',
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MicrocicloDetailScreen(
                                      microciclo: m,
                                      nomeStagione: nomeStagione,
                                      nomeMacrociclo: nomeMacrociclo,
                                      nomeMesociclo: mesociclo.nome,
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
                  messaggio: 'Non è stato possibile caricare i microcicli.',
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
        heroTag: 'fab-microcicli',
        onPressed: apriNuovo,
        tooltip: 'Nuovo microciclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
