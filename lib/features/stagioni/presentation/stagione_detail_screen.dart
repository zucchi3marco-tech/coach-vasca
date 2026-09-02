import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../application/macrocicli_providers.dart';
import '../domain/stagione.dart';
import 'macrociclo_detail_screen.dart';
import 'macrociclo_form_screen.dart';
import 'stagione_form_screen.dart';

class StagioneDetailScreen extends ConsumerWidget {
  const StagioneDetailScreen({required this.stagione, super.key});

  final Stagione stagione;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrocicliAsync = ref.watch(macrocicliListProvider(stagione.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(stagione.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StagioneFormScreen(
                  clubId: stagione.clubId,
                  stagione: stagione,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formattaData(stagione.dataInizio)} — ${_formattaData(stagione.dataFine)}'
                  '${stagione.gruppo != null && stagione.gruppo!.isNotEmpty ? ' · ${stagione.gruppo}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (stagione.obiettivo != null &&
                    stagione.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(stagione.obiettivo!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: macrocicliAsync.when(
              data: (macrocicli) => macrocicli.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun macrociclo. Tocca "+" per aggiungerne uno.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: macrocicli.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = macrocicli[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${m.ordine}')),
                          title: Text(m.nome),
                          subtitle: Text(
                            '${_formattaData(m.dataInizio)} — ${_formattaData(m.dataFine)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MacrocicloDetailScreen(macrociclo: m),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Errore nel caricamento macrocicli: ${messaggioErrore(error)}',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-macrocicli',
        onPressed: () {
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
        },
        tooltip: 'Nuovo macrociclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
