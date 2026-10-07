import 'package:flutter/material.dart';

/// Entrata a cascata: ogni blocco sale e compare con un piccolo ritardo
/// rispetto al precedente. Fermo se "riduci movimento".
class EntrataACascata extends StatelessWidget {
  const EntrataACascata({required this.indice, required this.child, super.key});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    // Oltre il decimo blocco il ritardo non cresce piu': in un elenco
    // lungo le ultime righe non devono farsi aspettare.
    final passo = indice.clamp(0, 10);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + passo * 70),
      curve: Interval(
        (passo * 70) / (360 + passo * 70),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
