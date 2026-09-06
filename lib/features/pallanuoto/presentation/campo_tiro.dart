import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// Un tiro gia' registrato, per la mappa di calore in sola lettura:
/// posizione (percentuale 0-100 su entrambi gli assi) ed esito.
typedef PuntoTiro = ({double x, double y, String? esito});

/// Campo disegnato tipo lavagnetta (DESIGN.md sezione 9: qui il tocco è
/// l'input, non c'è un form). Semplificazione deliberata per la v1: zona
/// d'attacco con porta in alto e due linee di riferimento (2 e 5 metri)
/// disegnate come rette, non come gli archi reali del regolamento — il
/// tap-target resta comunque preciso, è solo lo sfondo a essere
/// stilizzato.
///
/// Due modalità, mutuamente esclusive:
/// - input: [onTocca] non nullo, ogni tocco restituisce la posizione;
/// - sola lettura: [punti] mostra i tiri già registrati come pallini
///   colorati secondo l'esito (mappa di calore).
class CampoTiro extends StatelessWidget {
  const CampoTiro({this.onTocca, this.punti = const [], super.key});

  final void Function(double x, double y)? onTocca;
  final List<PuntoTiro> punti;

  static Color _coloreEsito(String? esito) {
    switch (esito) {
      case 'gol':
        return AppColors.ok;
      case 'parato':
        return AppColors.testoSecondario;
      default:
        return AppColors.superficie;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final larghezza = constraints.maxWidth;
            final altezza = constraints.maxHeight;

            void gestisciTocco(Offset locale) {
              final tocca = onTocca;
              if (tocca == null) return;
              final x = (locale.dx / larghezza * 100).clamp(0.0, 100.0);
              final y = (locale.dy / altezza * 100).clamp(0.0, 100.0);
              tocca(x, y);
            }

            return GestureDetector(
              onTapDown: onTocca == null
                  ? null
                  : (details) => gestisciTocco(details.localPosition),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bluTenue,
                  border: Border.all(color: AppColors.linea),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _CampoPainter()),
                    ),
                    for (final p in punti)
                      Positioned(
                        left: (p.x / 100 * larghezza) - 7,
                        top: (p.y / 100 * altezza) - 7,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _coloreEsito(p.esito),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.testo),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CampoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tratto = Paint()
      ..color = AppColors.linea
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final centroX = size.width / 2;
    final larghezzaPorta = size.width * 0.24;
    canvas.drawRect(
      Rect.fromLTWH(
        centroX - larghezzaPorta / 2,
        0,
        larghezzaPorta,
        size.height * 0.035,
      ),
      tratto,
    );

    void lineaOrizzontale(double frazioneY, String etichetta) {
      final y = size.height * frazioneY;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tratto);
      final tp = TextPainter(
        text: TextSpan(text: etichetta, style: AppTypography.etichetta),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(AppSpacing.s4, y + AppSpacing.s4));
    }

    lineaOrizzontale(0.18, '2 m');
    lineaOrizzontale(0.42, '5 m');
  }

  @override
  bool shouldRepaint(covariant _CampoPainter oldDelegate) => false;
}

/// Legenda della mappa di calore, per la sola-lettura — stesso schema
/// della legenda del grafico Banister in `CaricoAtletaScreen`.
class LegendaCampoTiro extends StatelessWidget {
  const LegendaCampoTiro({super.key});

  @override
  Widget build(BuildContext context) {
    Widget voce(Color colore, String etichetta) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.s12,
          height: AppSpacing.s12,
          decoration: BoxDecoration(
            color: colore,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.testo),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(etichetta, style: AppTypography.piccolo),
      ],
    );
    return Wrap(
      spacing: AppSpacing.s16,
      children: [
        voce(AppColors.ok, 'Gol'),
        voce(AppColors.testoSecondario, 'Parato'),
        voce(AppColors.superficie, 'Palo/fuori'),
      ],
    );
  }
}
