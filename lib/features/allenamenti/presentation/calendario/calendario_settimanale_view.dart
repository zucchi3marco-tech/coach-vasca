import 'package:flutter/material.dart';

import '../../domain/allenamento.dart';
import 'allenamenti_per_giorno.dart';

class CalendarioSettimanaleView extends StatefulWidget {
  const CalendarioSettimanaleView({
    required this.allenamenti,
    required this.onGiornoSelezionato,
    super.key,
  });

  final List<Allenamento> allenamenti;
  final ValueChanged<DateTime> onGiornoSelezionato;

  @override
  State<CalendarioSettimanaleView> createState() =>
      _CalendarioSettimanaleViewState();
}

class _CalendarioSettimanaleViewState
    extends State<CalendarioSettimanaleView> {
  late DateTime _inizioSettimana;

  static const _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  @override
  void initState() {
    super.initState();
    final oggi = DateTime.now();
    final lunedi = oggi.subtract(Duration(days: oggi.weekday - 1));
    _inizioSettimana = DateTime(lunedi.year, lunedi.month, lunedi.day);
  }

  String _formattaData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final perGiorno = raggruppaPerGiorno(widget.allenamenti);
    final fineSettimana = _inizioSettimana.add(const Duration(days: 6));
    final oggi = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _inizioSettimana = _inizioSettimana.subtract(
                    const Duration(days: 7),
                  ),
                ),
              ),
              Text(
                '${_formattaData(_inizioSettimana)} — ${_formattaData(fineSettimana)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _inizioSettimana = _inizioSettimana.add(
                    const Duration(days: 7),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: 7,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = _inizioSettimana.add(Duration(days: index));
              final sessioni = perGiorno[data] ?? const [];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isStessoGiorno(data, oggi)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  child: Text('${data.day}'),
                ),
                title: Text(_nomiGiorni[index]),
                subtitle: Text(
                  sessioni.isEmpty
                      ? 'Nessun allenamento'
                      : sessioni
                            .map(
                              (a) => a.titolo != null && a.titolo!.isNotEmpty
                                  ? a.titolo!
                                  : 'Allenamento',
                            )
                            .join(', '),
                ),
                onTap: () => widget.onGiornoSelezionato(data),
              );
            },
          ),
        ),
      ],
    );
  }
}
