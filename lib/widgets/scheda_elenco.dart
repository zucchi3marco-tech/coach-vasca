import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/colori_app.dart';
import 'entrata_a_cascata.dart';
import 'premibile.dart';

/// Una voce di elenco in stile "Oggi": scheda arrotondata con un
/// riquadro a sinistra (icona, data, avatar), titolo, una riga sotto e
/// la freccia. Si abbassa sotto il dito ([Premibile]).
class SchedaElenco extends StatelessWidget {
  const SchedaElenco({
    required this.titolo,
    this.occhiello,
    this.sottotitolo,
    this.leading,
    this.trailing,
    this.sotto,
    this.onTap,
    this.onLongPress,
    this.evidenza,
    this.attenuata = false,
    this.mostraFreccia = true,
    super.key,
  });

  final String titolo;

  /// Testo piccolo sopra il titolo (es. "Oggi", "Prossimo allenamento").
  final String? occhiello;
  final String? sottotitolo;
  final Widget? leading;

  /// Al posto della freccia (o prima di essa, se [mostraFreccia]).
  final Widget? trailing;

  /// Riga facoltativa sotto il sottotitolo (es. pastiglie di stato).
  final Widget? sotto;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Colore della scheda in evidenza (es. l'allenamento di oggi): fondo
  /// sfumato e bordo di quel colore.
  final Color? evidenza;

  /// Voci passate o inattive: testo piu' tenue.
  final bool attenuata;
  final bool mostraFreccia;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final evidenza = this.evidenza;
    return Premibile(
      onTap: onTap,
      onLongPress: onLongPress,
      etichetta: [?occhiello, titolo, ?sottotitolo].join('. '),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: evidenza == null ? colori.superficie : null,
          gradient: evidenza == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    evidenza.withValues(alpha: 0.26),
                    evidenza.withValues(alpha: 0.08),
                  ],
                ),
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(
            color: evidenza == null
                ? colori.linea
                : evidenza.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (occhiello != null)
                    Text(
                      occhiello!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.etichetta.copyWith(
                        color: evidenza ?? colori.testoSecondario,
                        fontWeight: evidenza == null ? null : FontWeight.w700,
                      ),
                    ),
                  Text(
                    titolo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.corpoForte.copyWith(
                      color: attenuata ? colori.testoSecondario : colori.testo,
                      height: 1.25,
                    ),
                  ),
                  if (sottotitolo != null && sottotitolo!.isNotEmpty) ...[
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
                  if (sotto != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    sotto!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s8),
              trailing!,
            ],
            if (mostraFreccia && onTap != null) ...[
              const SizedBox(width: AppSpacing.s4),
              Icon(Icons.chevron_right, color: colori.testoSecondario),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dispone le schede su una, due o tre colonne secondo lo spazio, con
/// la stessa entrata a cascata della schermata "Oggi".
class GrigliaSchede extends StatelessWidget {
  const GrigliaSchede({
    required this.figli,
    this.larghezzaMinimaColonna = 340,
    this.colonneMassime = 3,
    this.cascata = true,
    super.key,
  });

  final List<Widget> figli;

  /// Sotto questa larghezza per colonna si passa a una colonna in meno.
  final double larghezzaMinimaColonna;
  final int colonneMassime;
  final bool cascata;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, vincoli) {
        const spazio = AppSpacing.spazioPannelli;
        final w = vincoli.maxWidth;
        final colonne = ((w + spazio) / (larghezzaMinimaColonna + spazio))
            .floor()
            .clamp(1, colonneMassime);
        Widget voce(int i) =>
            cascata ? EntrataACascata(indice: i, child: figli[i]) : figli[i];
        if (colonne == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < figli.length; i++) ...[
                if (i > 0) const SizedBox(height: spazio),
                voce(i),
              ],
            ],
          );
        }
        // Righe alte quanto la scheda piu' alta: con un nome su due righe
        // accanto a uno su una, le schede della stessa riga restano pari.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < figli.length; r += colonne) ...[
              if (r > 0) const SizedBox(height: spazio),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < colonne; c++) ...[
                      if (c > 0) const SizedBox(width: spazio),
                      Expanded(
                        child: r + c < figli.length
                            ? voce(r + c)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
