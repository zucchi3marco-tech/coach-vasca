import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../referti/presentation/leggi_referto_screen.dart';
import '../application/pallanuoto_providers.dart';
import '../data/partite_repository.dart';
import 'distinta_screen.dart';
import 'partita_form_screen.dart';

class PartiteListScreen extends ConsumerWidget {
  const PartiteListScreen({required this.clubId, super.key});

  final String clubId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiteAsync = ref.watch(partiteListProvider(clubId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(partiteRepositoryProvider).refreshFromRemote(clubId),
        child: partiteAsync.when(
          data: (partite) => partite.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Nessuna partita. Tocca "+" per crearne una.',
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: partite.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = partite[index];
                    return ListTile(
                      title: Text('${p.squadraCasa} - ${p.squadraTrasferta}'),
                      subtitle: Text(
                        '${_formattaData(p.data)}'
                        '${p.ora != null && p.ora!.isNotEmpty ? ' · ${p.ora}' : ''}'
                        '${p.campionato != null && p.campionato!.isNotEmpty ? ' · ${p.campionato}' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DistintaScreen(partita: p),
                        ),
                      ),
                      onLongPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PartitaFormScreen(clubId: clubId, partita: p),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Errore nel caricamento partite: ${messaggioErrore(error)}'),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab-leggi-referto',
            mini: true,
            tooltip: 'Leggi referto',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeggiRefertoScreen(clubId: clubId),
              ),
            ),
            child: const Icon(Icons.document_scanner_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab-partite',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartitaFormScreen(clubId: clubId),
              ),
            ),
            tooltip: 'Nuova partita',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
