import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../allenamenti/presentation/serie_labels.dart';
import '../data/generazioni_ai_repository.dart';
import '../domain/generazione_ai_registrata.dart';

class StoricoGenerazioniScreen extends ConsumerWidget {
  const StoricoGenerazioniScreen({required this.clubId, super.key});

  final String clubId;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year} ${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}';

  String _riassuntoParametri(Map<String, dynamic> p) {
    final parti = <String>[];
    if (p['gruppo'] != null) parti.add(p['gruppo'] as String);
    if (p['livello'] != null) parti.add(p['livello'] as String);
    if (p['volumeMetri'] != null) parti.add('${p['volumeMetri']} m');
    if (p['focus'] != null) parti.add(p['focus'] as String);
    return parti.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storicoAsync = ref.watch(storicoGenerazioniAiProvider(clubId));

    return Scaffold(
      appBar: AppBar(title: const Text('Storico generazioni AI')),
      body: storicoAsync.when(
        data: (storico) => storico.isEmpty
            ? const Center(child: Text('Nessuna generazione ancora effettuata.'))
            : ListView.separated(
                itemCount: storico.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final voce = storico[index];
                  final salvata = voce.allenamentoId != null;
                  return ListTile(
                    leading: Icon(
                      !voce.successo
                          ? Icons.error_outline
                          : salvata
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: !voce.successo
                          ? Colors.red
                          : salvata
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(_riassuntoParametri(voce.parametri)),
                    subtitle: Text(
                      '${_formattaData(voce.creatoIl)} · '
                      '${!voce.successo ? 'generazione fallita' : salvata ? 'salvata come allenamento' : 'generata, non salvata'}',
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => _DialogDettaglioVoce(voce: voce),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Errore nel caricamento storico: ${messaggioErrore(error)}'),
        ),
      ),
    );
  }
}

class _DialogDettaglioVoce extends StatelessWidget {
  const _DialogDettaglioVoce({required this.voce});

  final GenerazioneAiRegistrata voce;

  @override
  Widget build(BuildContext context) {
    final scheda = voce.scheda;
    final salvata = voce.allenamentoId != null;
    return AlertDialog(
      title: Text(
        !voce.successo
            ? 'Generazione fallita'
            : salvata
            ? 'Salvata come allenamento'
            : 'Generata, non salvata',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parametri',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final voceParam in voce.parametri.entries)
                Text('${voceParam.key}: ${voceParam.value}'),
              const SizedBox(height: 16),
              if (voce.messaggioErrore != null) ...[
                Text('Errore', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(voce.messaggioErrore!),
              ],
              if (scheda != null) ...[
                Text(
                  scheda['titolo'] as String? ?? 'Scheda generata',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                for (final s in (scheda['serie'] as List? ?? []))
                  Text(
                    '${s['ordine']}. ${s['ripetute']}×${s['distanzaM']}m '
                    '${labelStile(s['stile'] as String)} '
                    '${labelEsecuzione(s['esecuzione'] as String)}',
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}
