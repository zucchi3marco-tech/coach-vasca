import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/allenamenti_providers.dart';
import 'allenamento_detail_screen.dart';
import 'allenamento_form_screen.dart';

class AllenamentiListScreen extends ConsumerWidget {
  const AllenamentiListScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(clubId));

    return Scaffold(
      body: allenamentiAsync.when(
        data: (allenamenti) => allenamenti.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nessun allenamento. Tocca "+" per crearne uno.',
                  ),
                ),
              )
            : ListView.separated(
                itemCount: allenamenti.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final a = allenamenti[index];
                  return ListTile(
                    title: Text(
                      a.titolo != null && a.titolo!.isNotEmpty
                          ? a.titolo!
                          : 'Allenamento',
                    ),
                    subtitle: Text(
                      '${a.data.day.toString().padLeft(2, '0')}/'
                      '${a.data.month.toString().padLeft(2, '0')}/'
                      '${a.data.year}'
                      '${a.gruppo != null && a.gruppo!.isNotEmpty ? ' · ${a.gruppo}' : ''}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AllenamentoDetailScreen(allenamento: a),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Errore nel caricamento allenamenti: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _apriForm(context, ref),
        tooltip: 'Nuovo allenamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AllenamentoFormScreen(clubId: clubId)),
    );
    if (saved == true) {
      ref.invalidate(allenamentiListProvider(clubId));
    }
  }
}
