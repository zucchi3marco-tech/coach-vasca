import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../atleti/domain/atleta.dart';
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
                  return ListTile(
                    title: Text(
                      '${t.tipo} — ${formatPaceSeconds(t.passoMedio100S)}/100m',
                    ),
                    subtitle: Text(
                      '${t.dataTest.day.toString().padLeft(2, '0')}/'
                      '${t.dataTest.month.toString().padLeft(2, '0')}/'
                      '${t.dataTest.year} · '
                      '${t.distanzaTotaleM} m in ${formatPaceSeconds(t.tempoTotaleS)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Elimina',
                      onPressed: () => _confermaEliminazione(context, ref, t),
                    ),
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
