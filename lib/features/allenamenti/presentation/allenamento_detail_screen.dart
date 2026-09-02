import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/pace_format.dart';
import '../../export/export_actions.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import 'allenamento_form_screen.dart';
import 'scheda_bordo_vasca_screen.dart';
import 'serie_form_screen.dart';
import 'serie_labels.dart';
import 'sposta_allenamento_screen.dart';

class AllenamentoDetailScreen extends ConsumerWidget {
  const AllenamentoDetailScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  String _sottotitoloSerie(Serie s) {
    final parti = <String>[labelBlocco(s.blocco)];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.passoObiettivoS != null) {
      parti.add('${formatPaceSeconds(s.passoObiettivoS!)}/100m');
    }
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.ripartenzaS != null) {
      parti.add('rip ${formatPaceSeconds(s.ripartenzaS!)}');
    }
    if (s.attrezzatura != null && s.attrezzatura!.isNotEmpty) {
      parti.add(s.attrezzatura!);
    }
    return parti.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serieAsync = ref.watch(serieListProvider(allenamento.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          allenamento.titolo != null && allenamento.titolo!.isNotEmpty
              ? allenamento.titolo!
              : 'Allenamento',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pool),
            tooltip: 'Vista bordo vasca',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchedaBordoVascaScreen(allenamento: allenamento),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: 'Presenze',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PresenzeScreen(allenamento: allenamento),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            tooltip: 'Sposta',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SpostaAllenamentoScreen(allenamento: allenamento),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Esporta',
            onPressed: () => mostraMenuExport(
              context,
              titoloDocumento: allenamento.titolo != null &&
                      allenamento.titolo!.isNotEmpty
                  ? allenamento.titolo!
                  : 'Allenamento',
              caricaDati: () async => [
                (
                  allenamento,
                  await ref
                      .read(serieRepositoryProvider)
                      .fetchPerAllenamento(allenamento.id),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AllenamentoFormScreen(
                  clubId: allenamento.clubId,
                  allenamento: allenamento,
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
                  '${allenamento.data.day.toString().padLeft(2, '0')}/'
                  '${allenamento.data.month.toString().padLeft(2, '0')}/'
                  '${allenamento.data.year}'
                  '${allenamento.gruppo != null && allenamento.gruppo!.isNotEmpty ? ' · ${allenamento.gruppo}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (allenamento.note != null &&
                    allenamento.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(allenamento.note!),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: serieAsync.when(
              data: (serie) => serie.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessuna serie. Tocca "+" per aggiungerne una.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: serie.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = serie[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${s.ordine}')),
                          title: Text(
                            '${s.ripetute}×${s.distanzaM}m '
                            '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                          ),
                          subtitle: Text(_sottotitoloSerie(s)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SerieFormScreen(
                                allenamentoId: allenamento.id,
                                ordineSuccessivo: serie.length + 1,
                                serie: s,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Errore nel caricamento serie: ${messaggioErrore(error)}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-serie',
        onPressed: () {
          final serieAttuale =
              ref.read(serieListProvider(allenamento.id)).value ?? [];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SerieFormScreen(
                allenamentoId: allenamento.id,
                ordineSuccessivo: serieAttuale.length + 1,
              ),
            ),
          );
        },
        tooltip: 'Nuova serie',
        child: const Icon(Icons.add),
      ),
    );
  }
}
