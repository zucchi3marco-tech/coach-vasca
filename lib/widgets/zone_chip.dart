import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/domain_tokens.dart';

/// Pillola colorata per una zona di intensità — vedi DESIGN.md sezione 3:
/// "il colore non basta mai da solo", la sigla sta sempre scritta.
class ZoneChip extends StatelessWidget {
  const ZoneChip({required this.sigla, super.key});

  final String sigla;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<DomainTokens>() ?? DomainTokens.standard;
    final colore = tokens.colorePerZona(sigla);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colore,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPillola),
      ),
      child: Text(
        sigla,
        style: AppTypography.piccolo.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
