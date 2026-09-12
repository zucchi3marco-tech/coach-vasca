import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Una singola azione proposta da [FabAzioni].
class AzioneFab {
  const AzioneFab({
    required this.icona,
    required this.etichetta,
    required this.onPressed,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback onPressed;
}

/// Un solo pulsante flottante, anche quando le azioni disponibili sono
/// più di una: con una sola azione si comporta come un FAB normale, con
/// più azioni il tocco apre un elenco con etichette sempre visibili
/// (invece di impilare più FAB uno sopra l'altro — bersagli identici,
/// facili da confondere specialmente con le dita bagnate a bordo vasca,
/// e il tooltip che spiega la differenza non si vede mai su schermo
/// touch). Vedi DESIGN.md sezione 14.
class FabAzioni extends StatelessWidget {
  const FabAzioni({required this.azioni, this.heroTag, super.key})
    : assert(azioni.length > 0, 'Serve almeno un\'azione');

  final List<AzioneFab> azioni;
  final Object? heroTag;

  Future<void> _apriMenu(BuildContext context) async {
    final scelta = await showModalBottomSheet<VoidCallback>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final azione in azioni)
              ListTile(
                leading: Icon(azione.icona, color: AppColors.blu),
                title: Text(azione.etichetta, style: AppTypography.corpo),
                onTap: () => Navigator.of(sheetContext).pop(azione.onPressed),
              ),
            const SizedBox(height: AppSpacing.s8),
          ],
        ),
      ),
    );
    scelta?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (azioni.length == 1) {
      final unica = azioni.single;
      return FloatingActionButton(
        heroTag: heroTag,
        onPressed: unica.onPressed,
        tooltip: unica.etichetta,
        child: Icon(unica.icona),
      );
    }
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _apriMenu(context),
      tooltip: 'Altre azioni',
      child: const Icon(Icons.add),
    );
  }
}
