import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../tabelle_passi/domain/zone_defaults.dart';
import '../domain/durata_serie.dart';
import '../domain/serie.dart';

/// Quanto è alta la barra di una zona: più intensa, più alta.
const _altezzaZona = <String, double>{
  'A1': 0.30,
  'A2': 0.40,
  'B1': 0.52,
  'B2': 0.64,
  'C1': 0.74,
  'C': 0.82,
  'C2': 0.82,
  'C3': 0.90,
  'D': 1.0,
};
const _altezzaSenzaZona = 0.18;

/// La forma della seduta a colpo d'occhio, come nell'editor di
/// Swimtraxx: una barra per ripetuta, larga quanto dura (stima di
/// [secondiPerRipetuta]) e alta e colorata secondo la zona. Sopra, la
/// legenda delle zone usate (il colore non basta mai da solo, DESIGN.md
/// sezione 7); sotto, i minuti.
class GraficoIntensita extends StatelessWidget {
  const GraficoIntensita({required this.serie, this.altezza = 56, super.key});

  final List<DatiSerie> serie;

  /// Altezza delle barre, senza legenda e minuti.
  final double altezza;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final dominio = context.dominio;
    final totale = serie.fold<double>(0, (t, s) => t + secondiSerie(s));
    if (totale <= 0) return const SizedBox.shrink();

    final usate = {for (final s in serie) ?s.zona};
    final zone = [
      for (final z in [...ordineZone, 'C'])
        if (usate.contains(z)) z,
    ];
    final senzaZona = colori.testoTenue.withValues(alpha: 0.5);
    final barre = [
      for (final s in serie)
        (
          secondi: secondiPerRipetuta(s),
          ripetute: s.ripetute,
          altezza: _altezzaZona[s.zona] ?? _altezzaSenzaZona,
          colore: s.zona == null
              ? senzaZona
              : dominio.colorePerZona(s.zona, rispetto: senzaZona),
        ),
    ];
    final minuti = (totale / 60).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (zone.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s4,
            children: [
              for (final z in zone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dominio.colorePerZona(z, rispetto: senzaZona),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      z,
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testo,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        Semantics(
          label: "Andamento dell'intensità della seduta, circa $minuti minuti",
          child: ExcludeSemantics(
            child: SizedBox(
              height: altezza + 20,
              width: double.infinity,
              child: CustomPaint(
                painter: _GraficoPainter(
                  barre: barre,
                  totale: totale,
                  altezzaBarre: altezza,
                  coloreAsse: colori.linea,
                  stileMinuti: AppTypography.numerica(AppTypography.etichetta)
                      .copyWith(color: colori.testoTenue),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

typedef _Barra = ({double secondi, int ripetute, double altezza, Color colore});

class _GraficoPainter extends CustomPainter {
  _GraficoPainter({
    required this.barre,
    required this.totale,
    required this.altezzaBarre,
    required this.coloreAsse,
    required this.stileMinuti,
  });

  final List<_Barra> barre;
  final double totale;
  final double altezzaBarre;
  final Color coloreAsse;
  final TextStyle stileMinuti;

  @override
  void paint(Canvas canvas, Size size) {
    final scala = size.width / totale;
    final base = altezzaBarre;
    const raggio = Radius.circular(2);
    var x = 0.0;
    for (final b in barre) {
      final larghezza = b.secondi * scala;
      final alta = base * b.altezza;
      final pennello = Paint()..color = b.colore;
      // Una barra per ripetuta finché ci stanno; se sono troppo fitte,
      // una barra sola per tutta la serie.
      final perRipetuta = larghezza >= 3;
      final pezzi = perRipetuta ? b.ripetute : 1;
      final larghezzaPezzo = perRipetuta ? larghezza : larghezza * b.ripetute;
      for (var i = 0; i < pezzi; i++) {
        final sinistra = x + i * larghezzaPezzo;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              sinistra,
              base - alta,
              math.max(larghezzaPezzo - 1, 1),
              alta,
            ),
            topLeft: raggio,
            topRight: raggio,
          ),
          pennello,
        );
      }
      x += larghezza * b.ripetute;
    }

    final asse = Paint()
      ..color = coloreAsse
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, base + 0.5),
      Offset(size.width, base + 0.5),
      asse,
    );

    final minuti = totale / 60;
    final passo = minuti <= 40
        ? 10
        : minuti <= 90
        ? 15
        : 30;
    for (var m = passo; m < minuti; m += passo) {
      final xm = m * 60 * scala;
      canvas.drawLine(Offset(xm, base), Offset(xm, base + 4), asse);
      final testo = TextPainter(
        text: TextSpan(text: "$m'", style: stileMinuti),
        textDirection: TextDirection.ltr,
      )..layout();
      final sinistra = xm - testo.width / 2;
      if (sinistra + testo.width > size.width) break;
      testo.paint(canvas, Offset(sinistra, base + 4));
    }
  }

  @override
  bool shouldRepaint(_GraficoPainter old) =>
      old.barre != barre ||
      old.totale != totale ||
      old.coloreAsse != coloreAsse ||
      old.stileMinuti != stileMinuti;
}
