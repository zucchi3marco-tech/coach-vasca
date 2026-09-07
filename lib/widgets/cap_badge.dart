import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/domain_tokens.dart';

/// Numero di calottina dentro un cerchio del colore reale — vedi
/// DESIGN.md sezione 3: unica eccezione ammessa alla regola sul rosso,
/// perché nel contesto (distinta, eventi partita) è inequivocabile.
class CapBadge extends StatelessWidget {
  const CapBadge({
    required this.numero,
    this.colore = CapColore.bianca,
    super.key,
  });

  final int numero;
  final CapColore colore;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<DomainTokens>() ?? DomainTokens.standard;
    final (sfondo, testo) = switch (colore) {
      CapColore.bianca => (tokens.calottinaBianca, AppColors.testo),
      CapColore.blu => (tokens.calottinaBlu, Colors.white),
      CapColore.rossaPortiere => (tokens.calottinaRossaPortiere, Colors.white),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: sfondo,
        shape: BoxShape.circle,
        border: colore == CapColore.bianca
            ? Border.all(color: AppColors.linea)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$numero',
        style: AppTypography.condensata(
          AppTypography.cifreTabulari(
            AppTypography.corpoForte.copyWith(color: testo),
          ),
        ),
      ),
    );
  }
}

enum CapColore { bianca, blu, rossaPortiere }
