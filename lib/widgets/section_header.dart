import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Intestazione di un gruppo (form, elenco): stile `sezione` con un
/// filetto sotto — vedi DESIGN.md sezione 13, "Form".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.titolo, {super.key});

  final String titolo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titolo,
          style: AppTypography.sezione.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        Divider(color: colori.linea, height: 1),
      ],
    );
  }
}
