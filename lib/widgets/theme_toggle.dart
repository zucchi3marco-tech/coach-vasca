import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tema_provider.dart';

/// Selettore del tema per tutta l'app — DESIGN.md sezione 15,
/// "Impostazioni → Aspetto" (Sistema/Chiaro/Scuro). Tre scelte esplicite
/// invece di un singolo tap che cicla, come [BottoneTemaBordoVasca] per
/// lo stesso motivo: vanno comprese a colpo d'occhio da chi non conosce
/// il gergo tecnico.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scelta = ref.watch(temaAppProvider);
    return PopupMenuButton<ThemeMode>(
      icon: Icon(scelta.icona),
      tooltip: 'Aspetto',
      initialValue: scelta,
      onSelected: (nuova) => ref.read(temaAppProvider.notifier).imposta(nuova),
      itemBuilder: (context) => [
        for (final opzione in ThemeMode.values)
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
