import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';

/// Un recupero come si scrive a bordo vasca, senza arrotondare: 30",
/// 2', 2'30".
String formattaRecupero(int secondi) {
  if (secondi < 60) return '$secondi"';
  final resto = secondi % 60;
  return resto == 0
      ? "${secondi ~/ 60}'"
      : "${secondi ~/ 60}'${resto.toString().padLeft(2, '0')}\"";
}

/// Il testo di una nota, o null se vuota.
String? notaPiena(String? nota) =>
    nota == null || nota.trim().isEmpty ? null : nota.trim();

/// La nota di una serie: di solito come svolgerla, quindi sempre in vista
/// e mai tagliata (richiesta del coach 2026-10-11). [grande] a bordo
/// vasca.
class NotaSerie extends StatelessWidget {
  const NotaSerie(this.testo, {this.grande = false, super.key});

  final String testo;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.notes,
            size: grande ? 22 : 16,
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            testo,
            style: (grande ? AppTypography.corpo : AppTypography.piccolo)
                .copyWith(color: colori.testo),
          ),
        ),
      ],
    );
  }
}

/// [principale] (titolo e dati della serie) con la [nota] accanto, a
/// destra, su uno schermo largo; sotto su un telefono. Decide la
/// larghezza dello schermo e non lo spazio della riga: le righe stanno
/// dentro `LaneRule`, che misura l'altezza in anticipo e non ammette un
/// `LayoutBuilder`.
class ConNotaAccanto extends StatelessWidget {
  const ConNotaAccanto({
    required this.principale,
    required this.nota,
    this.grande = false,
    super.key,
  });

  final Widget principale;
  final String? nota;
  final bool grande;

  static const larghezzaPerAffiancare = 700.0;

  @override
  Widget build(BuildContext context) {
    final testo = nota;
    if (testo == null) return principale;
    if (MediaQuery.sizeOf(context).width >= larghezzaPerAffiancare) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: principale),
          const SizedBox(width: AppSpacing.s16),
          Expanded(flex: 2, child: NotaSerie(testo, grande: grande)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        principale,
        const SizedBox(height: AppSpacing.s4),
        NotaSerie(testo, grande: grande),
      ],
    );
  }
}

/// Il recupero fra una serie e la successiva, fra le due righe.
class RecuperoFraSerie extends StatelessWidget {
  const RecuperoFraSerie(this.secondi, {this.grande = false, super.key});

  final int secondi;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stile = (grande ? AppTypography.corpo : AppTypography.piccolo)
        .copyWith(color: colori.testoSecondario);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: grande ? 20 : 16,
            color: colori.testoSecondario,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Recupero '),
                  TextSpan(
                    text: formattaRecupero(secondi),
                    style: AppTypography.numerica(stile).copyWith(
                      color: colori.testo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' prima della serie successiva'),
                ],
              ),
              style: stile,
            ),
          ),
        ],
      ),
    );
  }
}
