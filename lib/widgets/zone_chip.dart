import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';
import '../theme/tokens_dominio.dart';

/// Pillola per una zona di intensità — vedi DESIGN.md sezione 7: mai
/// fondo pieno con testo sopra (quattro degli otto colori di zona non
/// reggono il bianco né il nero). Fondo = colore della zona a bassa
/// opacità sopra la superficie, bordo dello stesso colore, testo in
/// `testo` — mai colorato. "Il colore non basta mai da solo": la sigla
/// sta sempre scritta.
class ZoneChip extends StatelessWidget {
  const ZoneChip({required this.sigla, super.key});

  final String sigla;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scuro = Theme.of(context).brightness == Brightness.dark;
    final coloreZona = context.dominio.colorePerZona(
      sigla,
      rispetto: colori.testoTenue,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: coloreZona.withValues(alpha: scuro ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pillola),
        border: Border.all(color: coloreZona.withValues(alpha: 0.40)),
      ),
      child: Text(
        sigla,
        style: AppTypography.piccolo.copyWith(
          color: colori.testo,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
