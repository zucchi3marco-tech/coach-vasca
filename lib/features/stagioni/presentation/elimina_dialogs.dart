import 'package:flutter/material.dart';

import '../../../widgets/danger_button.dart';

/// Dialog di conferma condiviso per l'eliminazione di una stagione, usato
/// sia dalla schermata di dettaglio che dal form di modifica.
Future<bool> confermaEliminaStagione(BuildContext context) async {
  final conferma = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminare la stagione?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        DangerButton(
          label: 'Elimina',
          expanded: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return conferma == true;
}
