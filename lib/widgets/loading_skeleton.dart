import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/colori_app.dart';

/// Scheletro di caricamento — vedi DESIGN.md sezione 13, "Caricamento".
/// Un rettangolo `superficieAlt` della forma del contenuto in arrivo,
/// con una pulsazione di opacità continua: senza, un caricamento un po'
/// più lungo del solito è indistinguibile da una lista vuota o rotta.
/// Mai una rotellina sola in mezzo allo schermo.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    this.width = double.infinity,
    this.height = AppSpacing.s16,
    super.key,
  });

  final double width;
  final double height;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _opacita = Tween<double>(
    begin: 0.5,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacita,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colori.superficieAlt,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
        ),
      ),
    );
  }
}

/// Un gruppo di righe scheletro, per un elenco che sta caricando.
class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({this.righe = 4, super.key});

  final int righe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < righe; i++) ...[
          const LoadingSkeleton(height: AppSpacing.altezzaMinimaRiga),
          if (i != righe - 1) const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}
