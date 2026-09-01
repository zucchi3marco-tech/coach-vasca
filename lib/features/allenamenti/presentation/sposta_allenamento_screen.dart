import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stagioni/application/microcicli_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';

class SpostaAllenamentoScreen extends ConsumerWidget {
  const SpostaAllenamentoScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final microcicliAsync = ref.watch(
      microcicliDelClubProvider(allenamento.clubId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Sposta scheda')),
      body: microcicliAsync.when(
        data: (microcicli) => ListView(
          children: [
            ListTile(
              leading: Icon(
                allenamento.microcicloId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: const Text('Nessun microciclo'),
              subtitle: const Text('Scollega la scheda dalla settimana'),
              onTap: () => _seleziona(context, ref, null),
            ),
            const Divider(height: 1),
            for (final m in microcicli)
              ListTile(
                leading: Icon(
                  allenamento.microcicloId == m.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(
                  m.nome != null && m.nome!.isNotEmpty
                      ? m.nome!
                      : (m.numeroSettimana != null
                            ? 'Settimana ${m.numeroSettimana}'
                            : 'Microciclo'),
                ),
                subtitle: Text(
                  '${_formattaData(m.dataInizio)} — ${_formattaData(m.dataFine)}',
                ),
                onTap: () => _seleziona(context, ref, m.id),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Errore nel caricamento microcicli: $error')),
      ),
    );
  }

  Future<void> _seleziona(
    BuildContext context,
    WidgetRef ref,
    String? microcicloId,
  ) async {
    await ref
        .read(allenamentiRepositoryProvider)
        .setMicrociclo(id: allenamento.id, microcicloId: microcicloId);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
