import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Chip riutilizzabile, variante neutro/selezionato — DESIGN.md sezione
/// 13 "Chip e badge": **neutro** fondo `superficieAlt`, bordo `linea`,
/// testo `testoSecondario`; **selezionato** fondo `azioneTenue`, bordo
/// e testo `azione`, spunta a sinistra.
///
/// Sostituisce `FilterChip`/`ChoiceChip`/`InputChip` grezzi: il loro
/// stato "selezionato" di default non è legato ai token dell'app (usa i
/// colori Material generici), che nel tema scuro risultava troppo poco
/// contrastato rispetto al fondo non selezionato — bug segnalato dal
/// coach nella schermata "Genera settimana" (i giorni selezionati non
/// si distinguevano).
class TonalChip extends StatelessWidget {
  const TonalChip({
    required this.etichetta,
    required this.selezionato,
    this.onSelezionato,
    this.onEliminato,
    super.key,
  });

  final String etichetta;
  final bool selezionato;

  /// `null` per un chip non interattivo (es. mostrato durante un'altra
  /// azione in corso, come già succedeva con `FilterChip`/`ChoiceChip`).
  final ValueChanged<bool>? onSelezionato;

  /// Se non nullo, aggiunge la "x" per rimuovere il chip (equivalente a
  /// `InputChip.onDeleted`).
  final VoidCallback? onEliminato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return RawChip(
      label: Text(etichetta),
      selected: selezionato,
      onSelected: onSelezionato,
      onDeleted: onEliminato,
      showCheckmark: selezionato,
      checkmarkColor: colori.azione,
      visualDensity: VisualDensity.compact,
      labelStyle: AppTypography.piccolo.copyWith(
        fontWeight: selezionato ? FontWeight.w600 : FontWeight.w500,
        color: selezionato ? colori.azione : colori.testoSecondario,
      ),
      backgroundColor: colori.superficieAlt,
      selectedColor: colori.azioneTenue,
      side: BorderSide(color: selezionato ? colori.azione : colori.linea),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      deleteIcon: onEliminato == null
          ? null
          : Icon(Icons.close, size: 16, color: colori.testoSecondario),
    );
  }
}
