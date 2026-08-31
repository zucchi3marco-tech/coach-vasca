import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/stagioni_providers.dart';
import '../data/stagioni_repository.dart';
import 'stagione_form_screen.dart';

class StagioniListScreen extends ConsumerWidget {
  const StagioniListScreen({required this.clubId, super.key});

  final String clubId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagioniAsync = ref.watch(stagioniListProvider(clubId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(stagioniRepositoryProvider).refreshFromRemote(clubId),
        child: stagioniAsync.when(
          data: (stagioni) => stagioni.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Nessuna stagione. Tocca "+" per crearne una.',
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: stagioni.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = stagioni[index];
                    return ListTile(
                      title: Text(s.nome),
                      subtitle: Text(
                        '${_formattaData(s.dataInizio)} — ${_formattaData(s.dataFine)}'
                        '${s.gruppo != null && s.gruppo!.isNotEmpty ? ' · ${s.gruppo}' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StagioneFormScreen(
                            clubId: clubId,
                            stagione: s,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Errore nel caricamento stagioni: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-stagioni',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StagioneFormScreen(clubId: clubId),
          ),
        ),
        tooltip: 'Nuova stagione',
        child: const Icon(Icons.add),
      ),
    );
  }
}
