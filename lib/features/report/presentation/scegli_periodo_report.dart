import 'package:flutter/material.dart';

import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/report_atleta.dart';

/// Il periodo di un report: la stagione, una fase o «Scegli le date», e
/// sotto cosa c'è dentro. [scelto] null vale il primo dei [proposti].
class ScegliPeriodoReport extends StatelessWidget {
  const ScegliPeriodoReport({
    required this.proposti,
    required this.scelto,
    required this.onScelto,
    required this.oggi,
    super.key,
  });

  final List<PeriodoReport> proposti;
  final PeriodoReport? scelto;
  final ValueChanged<PeriodoReport> onScelto;
  final DateTime oggi;

  static bool _uguali(PeriodoReport a, PeriodoReport b) =>
      a.nome == b.nome && a.dal == b.dal && a.al == b.al;

  /// Il periodo che vale adesso.
  static PeriodoReport valore(
    List<PeriodoReport> proposti,
    PeriodoReport? scelto,
  ) => scelto ?? proposti.first;

  Future<void> _scegliDate(BuildContext context, PeriodoReport base) async {
    final giorno = soloData(oggi);
    final scelta = await showDateRangePicker(
      context: context,
      firstDate: DateTime(oggi.year - 3),
      lastDate: giorno,
      initialDateRange: DateTimeRange(
        start: base.dal.isAfter(giorno) ? giorno : base.dal,
        end: base.al.isAfter(giorno) ? giorno : base.al,
      ),
      helpText: 'Il periodo del report',
      saveText: 'Scegli',
    );
    if (scelta == null) return;
    onScelto(
      PeriodoReport(dal: scelta.start, al: scelta.end, nome: 'Periodo scelto'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final attuale = valore(proposti, scelto);
    final indice = proposti.indexWhere((p) => _uguali(p, attuale));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione('Periodo'),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (var i = 0; i < proposti.length; i++)
              TonalChip(
                etichetta: proposti[i].nome,
                selezionato: indice == i,
                onSelezionato: (_) => onScelto(proposti[i]),
              ),
            TonalChip(
              etichetta: 'Scegli le date',
              selezionato: indice < 0,
              onSelezionato: (_) => _scegliDate(context, attuale),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Dentro: ${attuale.descrizione}.',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
  }
}
