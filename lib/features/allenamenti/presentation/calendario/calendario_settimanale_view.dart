import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/app_list_panel.dart';
import '../../../../widgets/app_list_row.dart';
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.testoSecondario,
                ),
                onPressed: () => setState(
                  () => _inizioSettimana = _inizioSettimana.subtract(
                    const Duration(days: 7),
                  ),
                ),
              ),
              Text(
                '${_formattaData(_inizioSettimana)} — ${_formattaData(fineSettimana)}',
                style: AppTypography.sezione,
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.testoSecondario,
                ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: AppListPanel(
              righe: [
                for (var index = 0; index < 7; index++)
                  Builder(
                    builder: (context) {
                      final data = _inizioSettimana.add(Duration(days: index));
                      final sessioni = perGiorno[data] ?? const [];
                      final oggiStesso = isStessoGiorno(data, oggi);
                      return AppListRow(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: oggiStesso
                                ? AppColors.blu
                                : AppColors.superficieTenue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${data.day}',
                            style: AppTypography.corpoForte.copyWith(
                              color: oggiStesso
                                  ? Colors.white
                                  : AppColors.testo,
                            ),
                          ),
                        ),
                        titolo: _nomiGiorni[index],
                        sottotitolo: sessioni.isEmpty
                            ? 'Nessun allenamento'
                            : sessioni
                                  .map(
                                    (a) =>
                                        a.titolo != null &&
                                            a.titolo!.isNotEmpty
                                        ? a.titolo!
                                        : 'Allenamento',
                                  )
                                  .join(', '),
                        onTap: () => widget.onGiornoSelezionato(data),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
