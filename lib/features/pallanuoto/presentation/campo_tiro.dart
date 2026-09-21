import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';

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

  static Color _coloreEsito(String? esito, ColoriApp colori) {
    switch (esito) {
      case 'gol':
        return colori.ok;
      case 'parato':
        return colori.testoSecondario;
      default:
        return colori.superficie;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pannello),
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
                  color: colori.azioneTenue,
                  border: Border.all(color: colori.linea),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CampoPainter(
                          coloreEvidenziato: colori.testo,
                          colori: colori,
                        ),
                      ),
                    ),
                    for (final p in punti)
                      Positioned(
                        left: (p.x / 100 * larghezza) - 7,
                        top: (p.y / 100 * altezza) - 7,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _coloreEsito(p.esito, colori),
                            shape: BoxShape.circle,
                            border: Border.all(color: colori.testo),
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
  _CampoPainter({required this.coloreEvidenziato, required this.colori});

  /// Nero in chiaro, quasi bianco in scuro: la porta deve restare
  /// leggibile sullo sfondo del campo in entrambi i temi.
  final Color coloreEvidenziato;

  /// Per le linee reali della vasca (2m/5m/6m) — DESIGN.md sezione 14,
  /// eccezione: rosso e giallo qui sono rappresentativi del regolamento,
  /// non uno stato "in corso". Nessun token "giallo" dedicato nel nuovo
  /// sistema: `attenzione` è l'ambra più vicina disponibile.
  final ColoriApp colori;

  @override
  void paint(Canvas canvas, Size size) {
    final trattoPorta = Paint()
      ..color = coloreEvidenziato
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centroX = size.width / 2;
    final larghezzaPorta = size.width * 0.24;
    final yFondoCampo = size.height * 0.035;
    canvas.drawLine(
      Offset(0, yFondoCampo),
      Offset(size.width, yFondoCampo),
      trattoPorta,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        centroX - larghezzaPorta / 2,
        0,
        larghezzaPorta,
        yFondoCampo,
      ),
      trattoPorta,
    );

    // Profondita' rappresentata dal disegno, dalla linea di porta in giu':
    // le linee dei 2/5/6 m restano fra loro nelle proporzioni reali.
    const profonditaMetri = 8.0;
    double yPerMetri(double metri) =>
        yFondoCampo + (size.height - yFondoCampo) * metri / profonditaMetri;

    void lineaOrizzontale(
      double metri,
      String etichetta,
      Color colore,
      double spessore,
    ) {
      final y = yPerMetri(metri);
      final tratto = Paint()
        ..color = colore
        ..strokeWidth = spessore
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tratto);
      final tp = TextPainter(
        text: TextSpan(
          text: etichetta,
          style: AppTypography.etichetta.copyWith(color: colore),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(AppSpacing.s4, y + AppSpacing.s4));
    }

    // Linee reali della vasca, in ordine di distanza dalla porta: 2m e 5m
    // rosse (5m piu' sottile), 6m gialla. Distanze "visive" (non quelle
    // reali) su richiesta esplicita, per una resa piu' leggibile a bordo
    // vasca: la linea dei 2m e' a meta' della sua distanza reale, e lo
    // spazio fra 2m e 5m e' ridotto del 20% (il gap fra 5m e 6m resta
    // quello reale, 1m).
    const distanza2mVisiva = 1.0;
    const distanza5mVisiva = distanza2mVisiva + (5.0 - 2.0) * 0.8;
    const distanza6mVisiva = distanza5mVisiva + (6.0 - 5.0);
    lineaOrizzontale(distanza2mVisiva, '2 m', colori.rosso, 1.5);
    lineaOrizzontale(distanza5mVisiva, '5 m', colori.rosso, 1.0);
    lineaOrizzontale(distanza6mVisiva, '6 m', colori.attenzione, 1.5);

    // Area tratteggiata dai pali verso l'esterno per 2m, ricongiunta alla
    // linea dei 2m: semplificazione grafica, non una misura regolamentare.
    final trattoDash = Paint()
      ..color = colori.rosso
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final offsetPalo = size.width * 0.12;
    final yDue = yPerMetri(distanza2mVisiva);
    for (final lato in [-1, 1]) {
      final x = centroX + lato * (larghezzaPorta / 2 + offsetPalo);
      _disegnaLineaTratteggiata(
        canvas,
        trattoDash,
        Offset(x, yFondoCampo),
        Offset(x, yDue),
      );
    }
  }

  void _disegnaLineaTratteggiata(
    Canvas canvas,
    Paint tratto,
    Offset da,
    Offset a,
  ) {
    const lunghezzaTratto = 4.0;
    const lunghezzaSpazio = 3.0;
    final distanza = (a - da).distance;
    if (distanza == 0) return;
    final direzione = (a - da) / distanza;
    var percorsa = 0.0;
    while (percorsa < distanza) {
      final fine = (percorsa + lunghezzaTratto).clamp(0.0, distanza);
      canvas.drawLine(da + direzione * percorsa, da + direzione * fine, tratto);
      percorsa += lunghezzaTratto + lunghezzaSpazio;
    }
  }

  @override
  bool shouldRepaint(covariant _CampoPainter oldDelegate) =>
      oldDelegate.coloreEvidenziato != coloreEvidenziato ||
      oldDelegate.colori != colori;
}

/// Legenda della mappa di calore, per la sola-lettura — stesso schema
/// della legenda del grafico Banister in `CaricoAtletaScreen`.
class LegendaCampoTiro extends StatelessWidget {
  const LegendaCampoTiro({super.key});

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget voce(Color colore, String etichetta) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.s12,
          height: AppSpacing.s12,
          decoration: BoxDecoration(
            color: colore,
            shape: BoxShape.circle,
            border: Border.all(color: colori.testo),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Text(
          etichetta,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpacing.s16,
      children: [
        voce(colori.ok, 'Gol'),
        voce(colori.testoSecondario, 'Parato'),
        voce(colori.superficie, 'Palo/fuori'),
      ],
    );
  }
}
