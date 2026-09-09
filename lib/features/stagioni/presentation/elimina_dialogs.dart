import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/danger_button.dart';
import '../application/macrocicli_providers.dart';
import '../application/mesocicli_providers.dart';
import '../application/microcicli_providers.dart';
import '../domain/macrociclo.dart';
import '../domain/mesociclo.dart';
import '../domain/stagione.dart';

/// Dialog di conferma condivisi per l'eliminazione della gerarchia
/// Stagione → Macrociclo → Mesociclo → Microciclo, usati sia dalle schermate
/// di dettaglio che dai form di modifica. Contano i figli reali prima di
/// mostrare il messaggio, invece del testo generico precedente.
Future<bool> _confermaEliminazione(
  BuildContext context, {
  required String titolo,
  required String messaggio,
}) async {
  final conferma = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titolo),
      content: Text(messaggio),
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

String _elenco(List<String> parti) {
  if (parti.length == 1) return parti.first;
  return '${parti.sublist(0, parti.length - 1).join(', ')} e ${parti.last}';
}

Future<bool> confermaEliminaStagione(
  BuildContext context,
  WidgetRef ref,
  Stagione stagione,
) async {
  final macrocicli = await ref.read(
    macrocicliListProvider(stagione.id).future,
  );
  var mesocicli = 0;
  var microcicli = 0;
  for (final m in macrocicli) {
    final figli = await ref.read(mesocicliListProvider(m.id).future);
    mesocicli += figli.length;
    for (final me in figli) {
      microcicli += (await ref.read(
        microcicliListProvider(me.id).future,
      )).length;
    }
  }
  final parti = [
    if (macrocicli.isNotEmpty) '${macrocicli.length} macrocicli',
    if (mesocicli > 0) '$mesocicli mesocicli',
    if (microcicli > 0) '$microcicli microcicli (con i relativi allenamenti)',
  ];
  final messaggio = parti.isEmpty
      ? 'La stagione non ha ancora macrocicli collegati.'
      : 'Verranno eliminati anche ${_elenco(parti)}.';
  if (!context.mounted) return false;
  return _confermaEliminazione(
    context,
    titolo: 'Eliminare la stagione?',
    messaggio: messaggio,
  );
}

Future<bool> confermaEliminaMacrociclo(
  BuildContext context,
  WidgetRef ref,
  Macrociclo macrociclo,
) async {
  final mesocicli = await ref.read(
    mesocicliListProvider(macrociclo.id).future,
  );
  var microcicli = 0;
  for (final m in mesocicli) {
    microcicli += (await ref.read(microcicliListProvider(m.id).future)).length;
  }
  final parti = [
    if (mesocicli.isNotEmpty) '${mesocicli.length} mesocicli',
    if (microcicli > 0) '$microcicli microcicli (con i relativi allenamenti)',
  ];
  final messaggio = parti.isEmpty
      ? 'Il macrociclo non ha ancora mesocicli collegati.'
      : 'Verranno eliminati anche ${_elenco(parti)}.';
  if (!context.mounted) return false;
  return _confermaEliminazione(
    context,
    titolo: 'Eliminare il macrociclo?',
    messaggio: messaggio,
  );
}

Future<bool> confermaEliminaMesociclo(
  BuildContext context,
  WidgetRef ref,
  Mesociclo mesociclo,
) async {
  final microcicli = await ref.read(
    microcicliListProvider(mesociclo.id).future,
  );
  final messaggio = microcicli.isEmpty
      ? 'Il mesociclo non ha ancora microcicli collegati.'
      : 'Verranno eliminati anche ${microcicli.length} microcicli '
            '(con i relativi allenamenti).';
  if (!context.mounted) return false;
  return _confermaEliminazione(
    context,
    titolo: 'Eliminare il mesociclo?',
    messaggio: messaggio,
  );
}

Future<bool> confermaEliminaMicrociclo(
  BuildContext context,
  int numeroAllenamentiCollegati,
) {
  final messaggio = numeroAllenamentiCollegati == 0
      ? 'Il microciclo non ha ancora allenamenti collegati.'
      : '$numeroAllenamentiCollegati allenamenti collegati non verranno '
            'eliminati: resteranno senza settimana assegnata.';
  return _confermaEliminazione(
    context,
    titolo: 'Eliminare il microciclo?',
    messaggio: messaggio,
  );
}
