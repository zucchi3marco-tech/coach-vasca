import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/barra_club_providers.dart';

/// Avvolge una schermata su cui la barra fissa in alto (logo + nome del
/// club) non deve comparire: lavagna tattica, partita dal vivo, schermate
/// da bordo vasca. La barra torna da sola quando la schermata si chiude.
class NascondiBarraClub extends ConsumerStatefulWidget {
  const NascondiBarraClub({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NascondiBarraClub> createState() => _NascondiBarraClubState();
}

class _NascondiBarraClubState extends ConsumerState<NascondiBarraClub> {
  late final BarraClubNascostaNotifier _notifier;
  bool _attivo = true;
  bool _incrementato = false;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(barraClubNascostaProvider.notifier);
    // Dopo il primo frame: un provider non si modifica durante il build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_attivo) return;
      _incrementato = true;
      _notifier.incrementa();
    });
  }

  @override
  void dispose() {
    _attivo = false;
    if (_incrementato) {
      // Dopo lo smontaggio: un provider non si modifica mentre l'albero
      // dei widget si sta smontando.
      Future.microtask(_notifier.decrementa);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
