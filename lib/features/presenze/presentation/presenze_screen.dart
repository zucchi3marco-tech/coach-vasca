import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/presenze_providers.dart';
import '../data/presenze_repository.dart';

class PresenzeScreen extends ConsumerWidget {
  const PresenzeScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (clubId: allenamento.clubId, includeInactive: false);
    final atletiAsync = ref.watch(atletiListProvider(filter));
    final presenzeAsync = ref.watch(presenzeListProvider(allenamento.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Presenze — ${allenamento.data.day.toString().padLeft(2, '0')}/'
          '${allenamento.data.month.toString().padLeft(2, '0')}/'
          '${allenamento.data.year}',
        ),
      ),
      body: atletiAsync.when(
        data: (atleti) {
          // Nessun filtro per gruppo: e' un campo testo libero (vedi
          // supabase/README.md), un confronto esatto rischia di
          // nascondere atleti per un semplice refuso o campo vuoto.
          return presenzeAsync.when(
            data: (presenze) {
              if (atleti.isEmpty) {
                return const Center(
                  child: Text('Nessun atleta attivo in questo club.'),
                );
              }

              final statoPerAtleta = {
                for (final p in presenze) p.atletaId: p.stato,
              };

              return ListView.separated(
                itemCount: atleti.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final atleta = atleti[index];
                  return _RigaPresenza(
                    atleta: atleta,
                    statoAttuale: statoPerAtleta[atleta.id],
                    onSelect: (nuovoStato) => ref
                        .read(presenzeRepositoryProvider)
                        .segnaPresenza(
                          allenamentoId: allenamento.id,
                          atletaId: atleta.id,
                          stato: nuovoStato,
                        ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Errore nel caricamento presenze: ${messaggioErrore(error)}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Errore nel caricamento atleti: ${messaggioErrore(error)}'),
        ),
      ),
    );
  }
}

class _RigaPresenza extends StatelessWidget {
  const _RigaPresenza({
    required this.atleta,
    required this.statoAttuale,
    required this.onSelect,
  });

  final Atleta atleta;
  final String? statoAttuale;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(atleta.nomeCompleto),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'presente',
            label: Text('P'),
            tooltip: 'Presente',
          ),
          ButtonSegment(value: 'assente', label: Text('A'), tooltip: 'Assente'),
          ButtonSegment(
            value: 'giustificato',
            label: Text('G'),
            tooltip: 'Giustificato',
          ),
        ],
        selected: statoAttuale == null ? const {} : {statoAttuale!},
        emptySelectionAllowed: true,
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) onSelect(selection.first);
        },
      ),
    );
  }
}
