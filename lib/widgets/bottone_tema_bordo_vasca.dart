import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tema_bordo_vasca_provider.dart';

/// Interruttore chiaro/scuro per le tre schermate da bordo vasca — vedi
/// DESIGN.md sezione 9. Va nell'AppBar di ciascuna delle tre.
class BottoneTemaBordoVasca extends ConsumerWidget {
  const BottoneTemaBordoVasca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scuro = ref.watch(temaBordoVascaScuroProvider);
    return IconButton(
      icon: Icon(scuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: scuro ? 'Passa al chiaro' : 'Passa allo scuro',
      onPressed: () => ref.read(temaBordoVascaScuroProvider.notifier).commuta(),
    );
  }
}
