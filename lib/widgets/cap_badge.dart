import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens_dominio.dart';

/// Numero di calottina dentro un cerchio del colore reale — vedi
/// DESIGN.md sezione 7: unica eccezione ammessa alla regola sul rosso,
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
    final dominio = context.dominio;
    final (sfondo, bordo, testo) = switch (colore) {
      CapColore.bianca => (
        dominio.calottinaBiancaFondo,
        dominio.calottinaBiancaBordo,
        dominio.calottinaNumeroSuBianca,
      ),
      CapColore.blu => (
        dominio.calottinaBluFondo,
        null,
        dominio.calottinaNumeroSuBlu,
      ),
      CapColore.rossaPortiere => (
        dominio.calottinaRossaFondo,
        null,
        dominio.calottinaNumeroSuRossa,
      ),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: sfondo,
        shape: BoxShape.circle,
        border: bordo == null ? null : Border.all(color: bordo),
      ),
      alignment: Alignment.center,
      child: Text(
        '$numero',
        style: AppTypography.condensata(
          AppTypography.numerica(
            AppTypography.corpoForte.copyWith(color: testo),
          ),
        ),
      ),
    );
  }
}

enum CapColore { bianca, blu, rossaPortiere }
