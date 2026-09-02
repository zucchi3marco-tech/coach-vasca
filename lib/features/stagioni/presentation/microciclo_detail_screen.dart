import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_genera/presentation/genera_allenamento_form_screen.dart';
import '../../allenamenti/application/allenamenti_per_microciclo_provider.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/allenamento_form_screen.dart';
import '../../export/csv_export.dart' show AllenamentoConSerie;
import '../../export/export_actions.dart';
import '../data/duplicazione_settimana_service.dart';
import '../domain/microciclo.dart';
import 'microciclo_form_screen.dart';

class MicrocicloDetailScreen extends ConsumerWidget {
  const MicrocicloDetailScreen({required this.microciclo, super.key});

  final Microciclo microciclo;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String get _titolo {
    if (microciclo.nome != null && microciclo.nome!.isNotEmpty) {
      return microciclo.nome!;
    }
    if (microciclo.numeroSettimana != null) {
      return 'Settimana ${microciclo.numeroSettimana}';
    }
    return 'Microciclo';
  }

  Future<void> _duplicaSettimana(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplica settimana'),
        content: const Text(
          'Verrà creata una nuova settimana subito dopo questa, con tutti '
          'gli allenamenti e le serie copiati. Continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Duplica'),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    try {
      final nuovoMicrociclo = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .duplica(microciclo);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MicrocicloDetailScreen(microciclo: nuovoMicrociclo),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Errore nella duplicazione: $e')),
      );
    }
  }

  Future<void> _esportaSettimana(BuildContext context, WidgetRef ref) async {
    final filter = (clubId: microciclo.clubId, microcicloId: microciclo.id);
    await mostraMenuExport(
      context,
      titoloDocumento: _titolo,
      caricaDati: () async {
        final allenamenti =
            ref.read(allenamentiPerMicrocicloProvider(filter)).value ?? [];
        final serieRepository = ref.read(serieRepositoryProvider);
        final elenco = <AllenamentoConSerie>[];
        for (final a in allenamenti) {
          elenco.add((a, await serieRepository.fetchPerAllenamento(a.id)));
        }
        return elenco;
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (
      clubId: microciclo.clubId,
      microcicloId: microciclo.id,
    );
    final allenamentiAsync = ref.watch(allenamentiPerMicrocicloProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(_titolo),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy_outlined),
            tooltip: 'Duplica settimana',
            onPressed: () => _duplicaSettimana(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Esporta settimana',
            onPressed: () => _esportaSettimana(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MicrocicloFormScreen(
                  mesocicloId: microciclo.mesocicloId,
                  ordineSuccessivo: microciclo.ordine,
                  microciclo: microciclo,
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
            child: Text(
              '${_formattaData(microciclo.dataInizio)} — ${_formattaData(microciclo.dataFine)}'
              '${microciclo.tipo != null && microciclo.tipo!.isNotEmpty ? ' · ${microciclo.tipo}' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: allenamentiAsync.when(
              data: (allenamenti) => allenamenti.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun allenamento in questa settimana. Tocca "+" per crearne uno.',
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
                            '${_formattaData(a.data)}'
                            '${a.gruppo != null && a.gruppo!.isNotEmpty ? ' · ${a.gruppo}' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AllenamentoDetailScreen(allenamento: a),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Errore nel caricamento allenamenti: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab-genera-ai-microciclo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GeneraAllenamentoFormScreen(
                  clubId: microciclo.clubId,
                  microcicloId: microciclo.id,
                  dataPredefinita: microciclo.dataInizio,
                ),
              ),
            ),
            tooltip: 'Genera con AI',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab-allenamenti-microciclo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AllenamentoFormScreen(
                  clubId: microciclo.clubId,
                  microcicloId: microciclo.id,
                  dataPredefinita: microciclo.dataInizio,
                ),
              ),
            ),
            tooltip: 'Nuovo allenamento',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
