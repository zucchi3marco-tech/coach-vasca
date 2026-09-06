import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../atleti/domain/atleta.dart';
import '../../tabelle_passi/application/tabelle_passi_providers.dart';
import '../../tabelle_passi/presentation/tabelle_passi_screen.dart';
import '../application/test_providers.dart';
import '../data/test_repository.dart';
import '../domain/test_ingresso.dart';
import 'test_form_screen.dart';

class TestListScreen extends ConsumerWidget {
  const TestListScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(testListProvider(atleta.id));

    return AppScaffold(
      appBar: AppBar(title: Text('Test — ${atleta.nomeCompleto}')),
      body: testAsync.when(
        data: (test) => test.isEmpty
            ? EmptyState(
                icona: Icons.speed_outlined,
                titolo: 'Nessun test registrato',
                descrizione:
                    'I passi delle zone si calcolano dal primo test BVS '
                    'o T30.',
                azionePrincipale: 'Nuovo test',
                onAzionePrincipale: () => _apriForm(context, ref),
              )
            : AppListPanel(
                righe: [
                  for (final t in test)
                    _TestTile(
                      test: t,
                      atleta: atleta,
                      onDelete: () => _confermaEliminazione(context, ref, t),
                    ),
                ],
              ),
        loading: () => const LoadingSkeletonList(righe: 5),
        error: (error, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare i test.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-test',
        onPressed: () => _apriForm(context, ref),
        tooltip: 'Nuovo test',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TestFormScreen(atleta: atleta)),
    );
  }

  Future<void> _confermaEliminazione(
    BuildContext context,
    WidgetRef ref,
    TestIngresso test,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il test?'),
        content: Text(
          'Verranno eliminate anche le eventuali tabelle passi collegate a '
          'questo test (${test.tipo} del '
          '${test.dataTest.day.toString().padLeft(2, '0')}/'
          '${test.dataTest.month.toString().padLeft(2, '0')}/'
          '${test.dataTest.year}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma == true) {
      await ref.read(testRepositoryProvider).deleteTest(test.id);
    }
  }
}

class _TestTile extends ConsumerWidget {
  const _TestTile({
    required this.test,
    required this.atleta,
    required this.onDelete,
  });

  final TestIngresso test;
  final Atleta atleta;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabellaGenerata =
        ref.watch(tabellePassiProvider(test.id)).value?.isNotEmpty ?? false;

    return AppListRow(
      leading: Icon(
        tabellaGenerata ? Icons.table_chart : Icons.table_chart_outlined,
        color: tabellaGenerata ? AppColors.ok : AppColors.testoSecondario,
      ),
      titolo: '${test.tipo} — ${formatPaceSeconds(test.passoMedio100S)}/100m',
      sottotitolo:
          '${test.dataTest.day.toString().padLeft(2, '0')}/'
          '${test.dataTest.month.toString().padLeft(2, '0')}/'
          '${test.dataTest.year} · '
          '${test.distanzaTotaleM} m in ${formatPaceSeconds(test.tempoTotaleS)}',
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Elimina test',
        onPressed: onDelete,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TabellePassiScreen(test: test, atleta: atleta),
        ),
      ),
    );
  }
}
