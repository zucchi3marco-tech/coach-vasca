import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text('Test — ${atleta.nomeCompleto}')),
      body: testAsync.when(
        data: (test) => test.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nessun test registrato. Tocca "+" per aggiungerne uno.',
                  ),
                ),
              )
            : ListView.separated(
                itemCount: test.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = test[index];
                  return _TestTile(
                    test: t,
                    atleta: atleta,
                    onDelete: () => _confermaEliminazione(context, ref, t),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Errore nel caricamento test: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _apriForm(context, ref),
        tooltip: 'Nuovo test',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TestFormScreen(atleta: atleta)),
    );
    if (saved == true) {
      ref.invalidate(testListProvider(atleta.id));
    }
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
          'Verranno eliminate anche le eventuali tabelle passi collegate a questo test (${test.tipo} del '
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
      ref.invalidate(testListProvider(atleta.id));
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

    return ListTile(
      title: Text(
        '${test.tipo} — ${formatPaceSeconds(test.passoMedio100S)}/100m',
      ),
      subtitle: Text(
        '${test.dataTest.day.toString().padLeft(2, '0')}/'
        '${test.dataTest.month.toString().padLeft(2, '0')}/'
        '${test.dataTest.year} · '
        '${test.distanzaTotaleM} m in ${formatPaceSeconds(test.tempoTotaleS)}'
        '${tabellaGenerata ? ' · tabella passi generata' : ''}',
      ),
      leading: tabellaGenerata
          ? const Icon(Icons.table_chart, color: Colors.green)
          : const Icon(Icons.table_chart_outlined),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Elimina',
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
