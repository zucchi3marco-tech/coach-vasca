import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../application/mesocicli_providers.dart';
import '../domain/macrociclo.dart';
import 'macrociclo_form_screen.dart';
import 'mesociclo_detail_screen.dart';
import 'mesociclo_form_screen.dart';

class MacrocicloDetailScreen extends ConsumerWidget {
  const MacrocicloDetailScreen({required this.macrociclo, super.key});

  final Macrociclo macrociclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesocicliAsync = ref.watch(mesocicliListProvider(macrociclo.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(macrociclo.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MacrocicloFormScreen(
                  stagioneId: macrociclo.stagioneId,
                  ordineSuccessivo: macrociclo.ordine,
                  macrociclo: macrociclo,
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
                  '${_formattaData(macrociclo.dataInizio)} — ${_formattaData(macrociclo.dataFine)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (macrociclo.obiettivo != null &&
                    macrociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(macrociclo.obiettivo!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: mesocicliAsync.when(
              data: (mesocicli) => mesocicli.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun mesociclo. Tocca "+" per aggiungerne uno.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: mesocicli.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = mesocicli[index];
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
                                  MesocicloDetailScreen(mesociclo: m),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Errore nel caricamento mesocicli: ${messaggioErrore(error)}',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-mesocicli',
        onPressed: () {
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
        },
        tooltip: 'Nuovo mesociclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
