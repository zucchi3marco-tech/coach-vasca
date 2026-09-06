import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Cerchio con un numero d'ordine (macrociclo, mesociclo, microciclo,
/// serie...) — usato come `leading` di un [AppListRow] o in una scheda.
/// Non è nell'elenco di DESIGN.md sezione 14: aggiunto qui perché lo
/// stesso badge ricorre in più schermate della gerarchia stagione →
/// macrociclo → mesociclo → microciclo → allenamento → serie.
class OrdineBadge extends StatelessWidget {
  const OrdineBadge({required this.numero, super.key});

  final int numero;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bluTenue,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$numero',
        style: AppTypography.piccolo.copyWith(
          color: AppColors.blu,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
