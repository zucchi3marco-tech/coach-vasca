import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/microcicli_providers.dart';
import '../domain/mesociclo.dart';
import 'mesociclo_form_screen.dart';
import 'microciclo_form_screen.dart';

class MesocicloDetailScreen extends ConsumerWidget {
  const MesocicloDetailScreen({required this.mesociclo, super.key});

  final Mesociclo mesociclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(microcicliListProvider(mesociclo.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(mesociclo.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MesocicloFormScreen(
                  macrocicloId: mesociclo.macrocicloId,
                  ordineSuccessivo: mesociclo.ordine,
                  mesociclo: mesociclo,
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
                  '${_formattaData(mesociclo.dataInizio)} — ${_formattaData(mesociclo.dataFine)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (mesociclo.obiettivo != null &&
                    mesociclo.obiettivo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(mesociclo.obiettivo!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: microcicliAsync.when(
              data: (microcicli) => microcicli.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun microciclo. Tocca "+" per aggiungerne uno.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: microcicli.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = microcicli[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${m.ordine}')),
                          title: Text(
                            m.nome != null && m.nome!.isNotEmpty
                                ? m.nome!
                                : (m.numeroSettimana != null
                                      ? 'Settimana ${m.numeroSettimana}'
                                      : 'Microciclo'),
                          ),
                          subtitle: Text(
                            '${_formattaData(m.dataInizio)} — ${_formattaData(m.dataFine)}'
                            '${m.tipo != null && m.tipo!.isNotEmpty ? ' · ${m.tipo}' : ''}',
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MicrocicloFormScreen(
                                mesocicloId: mesociclo.id,
                                ordineSuccessivo: microcicli.length + 1,
                                microciclo: m,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Errore nel caricamento microcicli: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-microcicli',
        onPressed: () {
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
        },
        tooltip: 'Nuovo microciclo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
