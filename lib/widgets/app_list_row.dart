import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';

/// Una riga di elenco — vedi DESIGN.md sezione 13, "Elenchi": titolo
/// `corpoForte`, riga di metadati sotto in `piccolo`/`testoSecondario`.
/// Va dentro un [AppListPanel], mai appoggiata direttamente sul fondo.
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.titolo,
    this.extraTitolo,
    this.sottotitolo,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String titolo;

  /// Widget facoltativo subito dopo il titolo, sulla stessa riga (es. una
  /// percentuale): il titolo si tronca con i puntini se non c'è spazio.
  final Widget? extraTitolo;
  final String? sottotitolo;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaRiga,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.s12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          // Fino a due righe: su telefono un nome lungo
                          // va a capo intero invece di perdere le lettere.
                          child: Text(
                            titolo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                        ),
                        if (extraTitolo != null) ...[
                          const SizedBox(width: AppSpacing.s8),
                          extraTitolo!,
                        ],
                      ],
                    ),
                    if (sottotitolo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sottotitolo!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.s12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
