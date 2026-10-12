import 'package:flutter/material.dart';

import '../domain/video_partita.dart';
import 'geometria_frecce.dart';
import 'water_polo_tactics_board.dart' show ColoreLavagna;

/// L'inchiostro di un segno dal suo nome (giallo se sconosciuto).
ColoreLavagna inchiostroDi(String nome) =>
    ColoreLavagna.values.asNameMap()[nome] ?? ColoreLavagna.giallo;

/// Frecce e cerchi sopra il fotogramma del video, in coordinate 0-1 sul
/// riquadro: stesso inchiostro e stessa punta delle frecce della lavagna
/// tattica, più spessi perché il video sotto è pieno di dettagli.
class SegniVideoPainter extends CustomPainter {
  SegniVideoPainter({required this.segni, this.anteprima});

  final List<SegnoVideo> segni;

  /// Il segno che il dito sta tracciando.
  final SegnoVideo? anteprima;

  static const _punta = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in segni) {
      _disegna(canvas, size, s, 1);
    }
    final a = anteprima;
    if (a != null) _disegna(canvas, size, a, 0.7);
  }

  void _disegna(Canvas canvas, Size size, SegnoVideo s, double opacita) {
    Offset inPixel((double, double) p) =>
        Offset(p.$1 * size.width, p.$2 * size.height);
    final inchiostro = inchiostroDi(s.colore);
    Paint tratto(Color colore, double spessore) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = spessore
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colore;
    final contorno = tratto(
      inchiostro.controcolore.withValues(alpha: 0.5 * opacita),
      8,
    );
    final pieno = tratto(inchiostro.colore.withValues(alpha: opacita), 4);

    switch (s.forma) {
      case FormaSegno.cerchio:
        final rettangolo = Rect.fromPoints(inPixel(s.da), inPixel(s.a));
        canvas
          ..drawOval(rettangolo, contorno)
          ..drawOval(rettangolo, pieno);
      case FormaSegno.freccia:
        final punti = campionaCurva(
          inPixel(s.da),
          s.controllo == null ? null : inPixel(s.controllo!),
          inPixel(s.a),
          segmenti: 48,
        );
        final vertice = punti.last;
        final direzione = vertice - punti[punti.length - 2];
        if (direzione.distance == 0) return;
        final linea = percorsoFreccia(punti, accorciamento: _punta * 0.7);
        final punta = puntaFreccia(
          vertice,
          direzione,
          lunghezza: _punta,
          semiApertura: 0.5,
        );
        canvas
          ..drawPath(linea, contorno)
          ..drawPath(punta, contorno..strokeWidth = 4)
          ..drawPath(linea, pieno)
          ..drawPath(
            punta,
            Paint()..color = inchiostro.colore.withValues(alpha: opacita),
          );
    }
  }

  @override
  bool shouldRepaint(covariant SegniVideoPainter vecchio) => true;
}

/// Il fotogramma fermo su cui si disegna: trascinando si traccia una
/// freccia (dritta, o curva se il dito curva) o un cerchio.
class TavolaDisegnoVideo extends StatefulWidget {
  const TavolaDisegnoVideo({
    required this.segni,
    required this.forma,
    required this.colore,
    required this.onSegno,
    super.key,
  });

  final List<SegnoVideo> segni;
  final FormaSegno forma;
  final ColoreLavagna colore;
  final ValueChanged<SegnoVideo> onSegno;

  @override
  State<TavolaDisegnoVideo> createState() => _TavolaDisegnoVideoState();
}

class _TavolaDisegnoVideoState extends State<TavolaDisegnoVideo> {
  final _traccia = <Offset>[];
  SegnoVideo? _anteprima;

  (double, double) _normale(Offset p, Size size) => (
    (p.dx / size.width).clamp(0.0, 1.0),
    (p.dy / size.height).clamp(0.0, 1.0),
  );

  SegnoVideo? _segno(Size size, {required bool finito}) {
    if (_traccia.length < 2) return null;
    final inizio = _traccia.first;
    final fine = _traccia.last;
    // Un tocco solo, o un trattino: non è un segno.
    if ((fine - inizio).distance < 12) return null;
    final controllo = widget.forma == FormaSegno.freccia && finito
        ? controlloDaTraccia(_traccia)
        : null;
    return SegnoVideo(
      forma: widget.forma,
      colore: widget.colore.name,
      da: _normale(inizio, size),
      a: _normale(fine, size),
      controllo: controllo == null ? null : _normale(controllo, size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, vincoli) {
        final size = vincoli.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => setState(() {
            _traccia
              ..clear()
              ..add(d.localPosition);
            _anteprima = null;
          }),
          onPanUpdate: (d) => setState(() {
            _traccia.add(d.localPosition);
            _anteprima = _segno(size, finito: false);
          }),
          onPanEnd: (_) {
            final segno = _segno(size, finito: true);
            setState(() {
              _traccia.clear();
              _anteprima = null;
            });
            if (segno != null) widget.onSegno(segno);
          },
          child: CustomPaint(
            size: size,
            painter: SegniVideoPainter(
              segni: widget.segni,
              anteprima: _anteprima,
            ),
          ),
        );
      },
    );
  }
}
