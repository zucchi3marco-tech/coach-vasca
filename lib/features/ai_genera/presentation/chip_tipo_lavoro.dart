import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/tipo_lavoro.dart';

/// Un `TonalChip` per una zona/tipo di lavoro, con accanto il pulsante
/// info che ne spiega intensità, frequenza cardiaca indicativa, a cosa
/// serve e i riferimenti pratici — vedi `tipo_lavoro.dart`.
class ChipTipoLavoro extends StatelessWidget {
  const ChipTipoLavoro({
    required this.zona,
    required this.selezionato,
    required this.onSelezionato,
    required this.mostraCodici,
    super.key,
  });

  final String zona;
  final bool selezionato;
  final ValueChanged<bool> onSelezionato;
  final bool mostraCodici;

  @override
  Widget build(BuildContext context) {
    final tipo = tipiLavoro[zona];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TonalChip(
          etichetta: etichettaTipoLavoro(zona, mostraCodici: mostraCodici),
          selezionato: selezionato,
          onSelezionato: onSelezionato,
        ),
        if (tipo != null) ...[
          const SizedBox(width: AppSpacing.s4),
          PulsanteSpiegazione(titolo: tipo.nome, spiegazione: tipo.spiegazione),
        ],
      ],
    );
  }
}
