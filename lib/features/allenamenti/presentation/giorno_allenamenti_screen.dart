import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/allenamenti_providers.dart';
import 'allenamento_detail_screen.dart';
import 'allenamento_form_screen.dart';
import 'calendario/allenamenti_per_giorno.dart';

class GiornoAllenamentiScreen extends ConsumerWidget {
  const GiornoAllenamentiScreen({
    required this.clubId,
    required this.data,
    super.key,
  });

  final String clubId;
  final DateTime data;

  String get _titolo =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: Text(_titolo)),
      body: allenamentiAsync.when(
        data: (tutti) {
          final delGiorno = tutti
              .where((a) => isStessoGiorno(a.data, data))
              .toList();
          if (delGiorno.isEmpty) {
            return const Center(
              child: Text(
                'Nessun allenamento in questo giorno. Tocca "+" per crearne uno.',
              ),
            );
          }
          return ListView.separated(
            itemCount: delGiorno.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = delGiorno[index];
              return ListTile(
                title: Text(
                  a.titolo != null && a.titolo!.isNotEmpty
                      ? a.titolo!
                      : 'Allenamento',
                ),
                subtitle: a.gruppo != null && a.gruppo!.isNotEmpty
                    ? Text(a.gruppo!)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllenamentoDetailScreen(allenamento: a),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Errore nel caricamento allenamenti: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-giorno-allenamenti',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AllenamentoFormScreen(
              clubId: clubId,
              dataPredefinita: data,
            ),
          ),
        ),
        tooltip: 'Nuovo allenamento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
