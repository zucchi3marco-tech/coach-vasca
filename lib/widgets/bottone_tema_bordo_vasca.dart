import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tema_provider.dart';

/// Selettore del tema per le tre schermate da bordo vasca — DESIGN.md
/// sezione 15. Va nell'AppBar di ciascuna delle tre. Tre scelte esplicite
/// (Segui l'app / Chiaro / Scuro) invece di un singolo tap che cicla,
/// perché la scelta va compresa a colpo d'occhio da chi non conosce
/// il gergo tecnico.
class BottoneTemaBordoVasca extends ConsumerWidget {
  const BottoneTemaBordoVasca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scelta = ref.watch(temaBordoVascaOverrideProvider);
    return PopupMenuButton<TemaBordoVasca>(
      icon: Icon(scelta.icona),
      tooltip: 'Tema di questa schermata',
      initialValue: scelta,
      onSelected: (nuova) =>
          ref.read(temaBordoVascaOverrideProvider.notifier).imposta(nuova),
      itemBuilder: (context) => [
        for (final opzione in TemaBordoVasca.values)
          PopupMenuItem(
            value: opzione,
            child: Row(
              children: [
                Icon(opzione.icona, size: 20),
                const SizedBox(width: 12),
                Text(opzione.etichetta),
                if (opzione == scelta) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 20),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
