import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/allenamenti_providers.dart';
import '../data/allenamenti_repository.dart';
import '../domain/allenamento.dart';
import 'allenamento_detail_screen.dart';
import 'allenamento_form_screen.dart';
import 'calendario/calendario_mensile_view.dart';
import 'calendario/calendario_settimanale_view.dart';
import 'giorno_allenamenti_screen.dart';

enum _Vista { elenco, settimana, mese }

class AllenamentiListScreen extends ConsumerStatefulWidget {
  const AllenamentiListScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<AllenamentiListScreen> createState() =>
      _AllenamentiListScreenState();
}

class _AllenamentiListScreenState
    extends ConsumerState<AllenamentiListScreen> {
  _Vista _vista = _Vista.elenco;

  @override
  Widget build(BuildContext context) {
    final allenamentiAsync = ref.watch(allenamentiListProvider(widget.clubId));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<_Vista>(
              segments: const [
                ButtonSegment(value: _Vista.elenco, label: Text('Elenco')),
                ButtonSegment(
                  value: _Vista.settimana,
                  label: Text('Settimana'),
                ),
                ButtonSegment(value: _Vista.mese, label: Text('Mese')),
              ],
              selected: {_vista},
              onSelectionChanged: (selezione) =>
                  setState(() => _vista = selezione.first),
            ),
          ),
          Expanded(
            child: allenamentiAsync.when(
              data: (allenamenti) => switch (_vista) {
                _Vista.elenco => _buildElenco(allenamenti),
                _Vista.settimana => CalendarioSettimanaleView(
                  allenamenti: allenamenti,
                  onGiornoSelezionato: (data) => _apriGiorno(data),
                ),
                _Vista.mese => CalendarioMensileView(
                  allenamenti: allenamenti,
                  onGiornoSelezionato: (data) => _apriGiorno(data),
                ),
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Errore nel caricamento allenamenti: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-allenamenti',
        onPressed: _apriForm,
        tooltip: 'Nuovo allenamento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildElenco(List<Allenamento> allenamenti) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(allenamentiRepositoryProvider)
          .refreshFromRemote(widget.clubId),
      child: allenamenti.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Nessun allenamento. Tocca "+" per crearne uno.',
                    ),
                  ),
                ),
              ],
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
                    '${a.data.day.toString().padLeft(2, '0')}/'
                    '${a.data.month.toString().padLeft(2, '0')}/'
                    '${a.data.year}'
                    '${a.gruppo != null && a.gruppo!.isNotEmpty ? ' · ${a.gruppo}' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllenamentoDetailScreen(allenamento: a),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _apriGiorno(DateTime data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GiornoAllenamentiScreen(clubId: widget.clubId, data: data),
      ),
    );
  }

  Future<void> _apriForm() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AllenamentoFormScreen(clubId: widget.clubId),
      ),
    );
  }
}
