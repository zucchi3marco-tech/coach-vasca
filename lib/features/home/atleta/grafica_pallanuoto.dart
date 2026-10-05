import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/palette_acqua.dart';

export '../../../theme/palette_acqua.dart';

/// Illustrazioni vettoriali dell'Area atleta, disegnate a mano con
/// CustomPainter (niente immagini da scaricare: nitide a ogni densita' e
/// leggere da caricare a bordo vasca).
///
// ---------------------------------------------------------------------------
// Acqua: fondo della testata, con riflessi di luce che scorrono lenti.
// ---------------------------------------------------------------------------

class AcquaPainter extends CustomPainter {
  AcquaPainter({
    required this.fase,
    this.conCorsia = true,
    this.conPorta = true,
  }) : super(repaint: null);

  /// 0..1, avanza in loop (riflessi): 0 fisso se "riduci movimento".
  final double fase;
  final bool conCorsia;
  final bool conPorta;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fondo: dal blu profondo in basso al turchese della superficie in alto.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AcquaPalette.chiara,
            AcquaPalette.media,
            AcquaPalette.profonda,
          ],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Alone di luce dei fari della piscina.
    canvas.drawCircle(
      Offset(size.width * 0.82, -size.height * 0.15),
      size.height * 1.1,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AcquaPalette.turchese.withValues(alpha: 0.35),
                AcquaPalette.turchese.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.82, -size.height * 0.15),
                radius: size.height * 1.1,
              ),
            ),
    );

    _riflessi(canvas, size);
    if (conPorta) _porta(canvas, size);
    if (conCorsia) _corsia(canvas, size, size.height * 0.80);
  }

  /// Le "caustiche": reticolo di linee ondulate chiare, come la luce sul
  /// fondo della vasca.
  void _riflessi(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AcquaPalette.schiuma.withValues(alpha: 0.10);
    final t = fase * 2 * math.pi;
    const passo = 26.0;
    for (var riga = -1; riga < size.height / passo + 1; riga++) {
      final path = Path();
      final y0 = riga * passo;
      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            y0 +
            math.sin(x / 38 + t + riga * 0.9) * 6 +
            math.sin(x / 17 - t * 1.3) * 2.5;
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
    // Scintille sparse sulla superficie.
    final scintilla = Paint()
      ..color = AcquaPalette.schiuma.withValues(alpha: 0.22);
    final r = math.Random(7);
    for (var i = 0; i < 28; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height * 0.7;
      final vita = (math.sin(t * 2 + i) + 1) / 2;
      canvas.drawCircle(Offset(x, y), 0.8 + vita * 1.4, scintilla);
    }
  }

  /// Porta da pallanuoto in prospettiva, a destra, semitrasparente.
  void _porta(Canvas canvas, Size size) {
    final larghezza = size.height * 0.95;
    final altezza = larghezza * 0.33;
    final base = Offset(size.width - larghezza * 0.72, size.height * 0.62);
    final pali = Paint()
      ..color = AcquaPalette.schiuma.withValues(alpha: 0.42)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final rete = Paint()
      ..color = AcquaPalette.schiuma.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    final sx = base;
    final dx = base.translate(larghezza, 0);
    final sxAlto = sx.translate(0, -altezza);
    final dxAlto = dx.translate(0, -altezza);
    final fondo = Offset(larghezza * 0.12, -altezza * 0.35);
    // Rete: griglia tra traversa e fondo.
    for (var i = 0; i <= 10; i++) {
      final a = Offset.lerp(sxAlto, dxAlto, i / 10)!;
      canvas.drawLine(a, a + fondo + Offset(0, altezza * 0.9), rete);
    }
    for (var j = 0; j <= 4; j++) {
      final f = j / 4;
      canvas.drawLine(
        Offset.lerp(sxAlto, sx, f)! + fondo * f,
        Offset.lerp(dxAlto, dx, f)! + fondo * f,
        rete,
      );
    }
    canvas.drawLine(sx, sxAlto, pali);
    canvas.drawLine(dx, dxAlto, pali);
    canvas.drawLine(sxAlto, dxAlto, pali);
  }

  /// Corsia galleggiante: dischi bianchi e rossi in fila.
  void _corsia(Canvas canvas, Size size, double y) {
    const raggio = 6.0;
    var i = 0;
    for (var x = -raggio; x < size.width + raggio; x += raggio * 2.2, i++) {
      final onda = math.sin(x / 40 + fase * 2 * math.pi) * 1.5;
      final centro = Offset(x, y + onda);
      final colore = (i ~/ 4).isEven
          ? AcquaPalette.galleggianteRosso
          : AcquaPalette.galleggianteBianco;
      canvas.drawOval(
        Rect.fromCenter(
          center: centro,
          width: raggio * 2,
          height: raggio * 1.5,
        ),
        Paint()..color = colore.withValues(alpha: 0.85),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: centro.translate(-1.5, -1.5),
          width: raggio * 0.7,
          height: raggio * 0.45,
        ),
        Paint()..color = AcquaPalette.bianco.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(AcquaPainter old) =>
      old.fase != fase ||
      old.conCorsia != conCorsia ||
      old.conPorta != conPorta;
}

/// Acqua animata: richiama [AcquaPainter] con una fase che scorre in 14 s.
/// Con "riduci movimento" attivo resta ferma.
class AcquaAnimata extends StatefulWidget {
  const AcquaAnimata({this.conCorsia = true, this.conPorta = true, super.key});

  final bool conCorsia;
  final bool conPorta;

  @override
  State<AcquaAnimata> createState() => _AcquaAnimataState();
}

class _AcquaAnimataState extends State<AcquaAnimata>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: AcquaPainter(
            fase: _c.value,
            conCorsia: widget.conCorsia,
            conPorta: widget.conPorta,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calottina: la cuffia da pallanuoto con paraorecchie e numero.
// ---------------------------------------------------------------------------

class CalottinaPainter extends CustomPainter {
  CalottinaPainter({required this.colore, this.numero});

  final ColoreCalottina colore;
  final String? numero;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cupola = Path()
      ..moveTo(w * 0.08, h * 0.78)
      ..cubicTo(w * 0.02, h * 0.18, w * 0.98, h * 0.18, w * 0.92, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.08, h * 0.78)
      ..close();

    // Ombra morbida sotto.
    canvas.drawPath(
      cupola.shift(Offset(0, h * 0.04)),
      Paint()
        ..color = AcquaPalette.nero.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Tessuto con luce dall'alto a sinistra.
    canvas.drawPath(
      cupola,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.6),
          radius: 1.0,
          colors: [
            Color.lerp(colore.tessuto, AcquaPalette.bianco, 0.35)!,
            colore.tessuto,
            colore.ombra,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
    // Cucitura centrale.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.29)
        ..quadraticBezierTo(w * 0.47, h * 0.6, w * 0.5, h * 0.86),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = colore.ombra.withValues(alpha: 0.6),
    );

    // Paraorecchie (a destra, visto di tre quarti).
    final centroOrecchio = Offset(w * 0.78, h * 0.66);
    final raggio = w * 0.15;
    canvas.drawCircle(centroOrecchio, raggio, Paint()..color = colore.ombra);
    canvas.drawCircle(
      centroOrecchio,
      raggio * 0.78,
      Paint()..color = Color.lerp(colore.ombra, AcquaPalette.nero, 0.25)!,
    );
    final griglia = Paint()
      ..color = colore.tessuto.withValues(alpha: 0.55)
      ..strokeWidth = w * 0.012;
    for (var i = -2; i <= 2; i++) {
      final dx = i * raggio * 0.28;
      final mezzaCorda = math.sqrt(
        math.max(0, math.pow(raggio * 0.7, 2) - dx * dx),
      );
      canvas.drawLine(
        centroOrecchio.translate(dx, -mezzaCorda),
        centroOrecchio.translate(dx, mezzaCorda),
        griglia,
      );
    }
    // Laccio sotto il mento.
    canvas.drawPath(
      Path()
        ..moveTo(centroOrecchio.dx - raggio * 0.4, centroOrecchio.dy + raggio)
        ..quadraticBezierTo(w * 0.62, h * 1.02, w * 0.36, h * 0.98),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..color = colore.ombra,
    );

    // Numero sulla cupola, a sinistra del paraorecchie.
    final n = numero;
    if (n != null && n.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: n,
          style: TextStyle(
            color: colore.numero,
            fontSize: h * (n.length > 1 ? 0.34 : 0.4),
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(w * 0.36 - tp.width / 2, h * 0.52 - tp.height / 2),
      );
      tp.dispose();
    }

    // Riflesso lucido.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.5)
        ..quadraticBezierTo(w * 0.24, h * 0.3, w * 0.42, h * 0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round
        ..color = AcquaPalette.bianco.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(CalottinaPainter old) =>
      old.colore != colore || old.numero != numero;
}

class Calottina extends StatelessWidget {
  const Calottina({
    required this.colore,
    this.numero,
    this.dimensione = 72,
    super.key,
  });

  final ColoreCalottina colore;
  final String? numero;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(dimensione, dimensione * 0.86),
      painter: CalottinaPainter(colore: colore, numero: numero),
    );
  }
}

// ---------------------------------------------------------------------------
// Palla da pallanuoto (gialla a spicchi blu).
// ---------------------------------------------------------------------------

void disegnaPalla(Canvas canvas, Offset centro, double raggio) {
  final rect = Rect.fromCircle(center: centro, radius: raggio);
  canvas.drawCircle(
    centro,
    raggio,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Color.lerp(AcquaPalette.palla, AcquaPalette.bianco, 0.4)!,
          AcquaPalette.palla,
          Color.lerp(AcquaPalette.palla, AcquaPalette.nero, 0.25)!,
        ],
        stops: const [0, 0.6, 1],
      ).createShader(rect),
  );
  final righe = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = raggio * 0.16
    ..color = AcquaPalette.pallaRighe;
  canvas.save();
  canvas.clipPath(Path()..addOval(rect));
  canvas.drawArc(
    rect.inflate(raggio * 0.05).shift(Offset(-raggio * 0.9, 0)),
    -math.pi / 2,
    math.pi,
    false,
    righe,
  );
  canvas.drawArc(
    rect.inflate(raggio * 0.05).shift(Offset(raggio * 0.9, 0)),
    math.pi / 2,
    math.pi,
    false,
    righe,
  );
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Illustrazioni dei riquadri. Ognuna disegna il proprio soggetto nel
// colore d'accento del riquadro, su un fondo d'acqua tinta.
// ---------------------------------------------------------------------------

enum SoggettoRiquadro {
  andamento,
  schemi,
  partite,
  statistiche,
  tempi,
  presenze,
  stagione,
}

class IllustrazioneRiquadroPainter extends CustomPainter {
  IllustrazioneRiquadroPainter({
    required this.soggetto,
    required this.accento,
    required this.fondo,
    this.progresso = 1,
  });

  final SoggettoRiquadro soggetto;
  final Color accento;
  final Color fondo;

  /// 0..1: quanto del disegno e' gia' "tracciato" (entrata animata).
  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(fondo, accento, 0.20)!,
            Color.lerp(fondo, accento, 0.06)!,
          ],
        ).createShader(rect),
    );
    // Onde di fondo, comuni a tutti i riquadri.
    final onda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accento.withValues(alpha: 0.16);
    for (var k = 0; k < 3; k++) {
      final p = Path();
      final y0 = size.height * (0.72 + k * 0.1);
      for (var x = 0.0; x <= size.width; x += 6) {
        final y = y0 + math.sin(x / 22 + k) * 3;
        x == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      canvas.drawPath(p, onda);
    }

    final tratto = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accento;
    final pieno = Paint()..color = accento;
    final tenue = Paint()..color = accento.withValues(alpha: 0.22);

    switch (soggetto) {
      case SoggettoRiquadro.andamento:
        _andamento(canvas, size, tratto, tenue);
      case SoggettoRiquadro.schemi:
        _schemi(canvas, size, tratto, pieno);
      case SoggettoRiquadro.partite:
        _partite(canvas, size, tratto, pieno);
      case SoggettoRiquadro.statistiche:
        _statistiche(canvas, size, tratto, pieno);
      case SoggettoRiquadro.tempi:
        _tempi(canvas, size, tratto, pieno);
      case SoggettoRiquadro.presenze:
        _presenze(canvas, size, tratto, pieno, tenue);
      case SoggettoRiquadro.stagione:
        _stagione(canvas, size, tratto, pieno, tenue);
    }
  }

  Path _parziale(Path path) {
    if (progresso >= 1) return path;
    final out = Path();
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * progresso), Offset.zero);
    }
    return out;
  }

  void _andamento(Canvas c, Size s, Paint tratto, Paint tenue) {
    // Curva di forma che sale, con area sotto.
    final p = Path()..moveTo(s.width * 0.08, s.height * 0.7);
    p.cubicTo(
      s.width * 0.3,
      s.height * 0.75,
      s.width * 0.4,
      s.height * 0.35,
      s.width * 0.58,
      s.height * 0.45,
    );
    p.cubicTo(
      s.width * 0.72,
      s.height * 0.52,
      s.width * 0.8,
      s.height * 0.22,
      s.width * 0.92,
      s.height * 0.2,
    );
    final area = Path.from(p)
      ..lineTo(s.width * 0.92, s.height * 0.85)
      ..lineTo(s.width * 0.08, s.height * 0.85)
      ..close();
    c.drawPath(area, tenue);
    c.drawPath(_parziale(p), tratto..strokeWidth = 3);
    if (progresso >= 1) {
      c.drawCircle(
        Offset(s.width * 0.92, s.height * 0.2),
        4.5,
        Paint()..color = tratto.color,
      );
    }
  }

  void _schemi(Canvas c, Size s, Paint tratto, Paint pieno) {
    // Mezzo campo visto dall'alto: area dei 2 m e 5 m, giocatori e frecce.
    final campo = Rect.fromLTWH(
      s.width * 0.1,
      s.height * 0.14,
      s.width * 0.8,
      s.height * 0.72,
    );
    final linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = tratto.color.withValues(alpha: 0.45);
    c.drawRRect(
      RRect.fromRectAndRadius(campo, const Radius.circular(4)),
      linea,
    );
    for (final f in [0.16, 0.36]) {
      final x = campo.left + campo.width * f;
      c.drawLine(Offset(x, campo.top), Offset(x, campo.bottom), linea);
    }
    // Porta a sinistra.
    c.drawLine(
      Offset(campo.left, campo.center.dy - campo.height * 0.14),
      Offset(campo.left, campo.center.dy + campo.height * 0.14),
      tratto..strokeWidth = 4,
    );
    tratto.strokeWidth = 2.2;
    final giocatori = [
      Offset(campo.left + campo.width * 0.55, campo.top + campo.height * 0.25),
      Offset(campo.left + campo.width * 0.7, campo.center.dy),
      Offset(
        campo.left + campo.width * 0.55,
        campo.bottom - campo.height * 0.25,
      ),
    ];
    for (final g in giocatori) {
      c.drawCircle(g, 5.5, pieno);
    }
    for (final g in giocatori) {
      final arrivo = Offset(
        campo.left + campo.width * 0.24,
        campo.center.dy + (g.dy - campo.center.dy) * 0.4,
      );
      final freccia = Path()
        ..moveTo(g.dx - 7, g.dy)
        ..quadraticBezierTo(
          (g.dx + arrivo.dx) / 2,
          g.dy - 10,
          arrivo.dx + 6,
          arrivo.dy,
        );
      c.drawPath(_parziale(freccia), tratto);
    }
  }

  void _partite(Canvas c, Size s, Paint tratto, Paint pieno) {
    // Tabellone: due punteggi e il tempo.
    final tab = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * 0.14,
        s.height * 0.18,
        s.width * 0.72,
        s.height * 0.5,
      ),
      const Radius.circular(8),
    );
    c.drawRRect(tab, Paint()..color = tratto.color.withValues(alpha: 0.16));
    c.drawRRect(tab, tratto..strokeWidth = 2);
    final tp = TextPainter(
      text: TextSpan(
        text: '8 : 6',
        style: TextStyle(
          color: tratto.color,
          fontWeight: FontWeight.w800,
          fontSize: s.height * 0.26,
          letterSpacing: 1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      c,
      Offset(tab.center.dx - tp.width / 2, tab.center.dy - tp.height / 2),
    );
    tp.dispose();
    disegnaPalla(c, Offset(s.width * 0.88, s.height * 0.84), s.height * 0.1);
  }

  void _statistiche(Canvas c, Size s, Paint tratto, Paint pieno) {
    // Porta vista di fronte con i punti dei tiri.
    final porta = Rect.fromLTWH(
      s.width * 0.16,
      s.height * 0.2,
      s.width * 0.68,
      s.height * 0.46,
    );
    final rete = Paint()
      ..strokeWidth = 1
      ..color = tratto.color.withValues(alpha: 0.25);
    for (var i = 1; i < 8; i++) {
      final x = porta.left + porta.width * i / 8;
      c.drawLine(Offset(x, porta.top), Offset(x, porta.bottom), rete);
    }
    for (var j = 1; j < 4; j++) {
      final y = porta.top + porta.height * j / 4;
      c.drawLine(Offset(porta.left, y), Offset(porta.right, y), rete);
    }
    c.drawPath(
      Path()
        ..moveTo(porta.left, porta.bottom)
        ..lineTo(porta.left, porta.top)
        ..lineTo(porta.right, porta.top)
        ..lineTo(porta.right, porta.bottom),
      tratto..strokeWidth = 3.2,
    );
    const tiri = [
      (0.18, 0.25, true),
      (0.82, 0.3, true),
      (0.5, 0.7, false),
      (0.3, 0.6, true),
      (0.72, 0.75, false),
    ];
    final visibili = (tiri.length * progresso).ceil();
    for (final (fx, fy, gol) in tiri.take(visibili)) {
      final p = Offset(
        porta.left + porta.width * fx,
        porta.top + porta.height * fy,
      );
      if (gol) {
        c.drawCircle(p, 5, pieno);
      } else {
        c.drawCircle(p, 4.5, tratto..strokeWidth = 2);
      }
    }
  }

  void _tempi(Canvas c, Size s, Paint tratto, Paint pieno) {
    // Cronometro con lancetta.
    final centro = Offset(s.width * 0.5, s.height * 0.5);
    final r = s.height * 0.3;
    c.drawCircle(
      centro,
      r,
      Paint()..color = tratto.color.withValues(alpha: 0.14),
    );
    c.drawCircle(centro, r, tratto..strokeWidth = 3);
    c.drawLine(
      centro.translate(0, -r - 2),
      centro.translate(0, -r - 9),
      tratto..strokeWidth = 4,
    );
    tratto.strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      final d = Offset(math.sin(a), -math.cos(a));
      c.drawLine(centro + d * r * 0.78, centro + d * r * 0.9, tratto);
    }
    final a = progresso * 1.6 * math.pi;
    c.drawLine(
      centro,
      centro + Offset(math.sin(a), -math.cos(a)) * r * 0.72,
      tratto..strokeWidth = 3,
    );
    c.drawCircle(centro, 3.5, pieno);
  }

  void _presenze(Canvas c, Size s, Paint tratto, Paint pieno, Paint tenue) {
    // Tre corsie con le spunte.
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.28 + i * 0.2);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * 0.14, y - 8, s.width * 0.72, 16),
          const Radius.circular(8),
        ),
        tenue,
      );
      if (i < (3 * progresso).ceil()) {
        final x = s.width * 0.22;
        c.drawPath(
          Path()
            ..moveTo(x - 5, y)
            ..lineTo(x - 1, y + 4)
            ..lineTo(x + 6, y - 4),
          tratto..strokeWidth = 2.6,
        );
      }
      c.drawCircle(Offset(s.width * 0.78, y), 4, pieno);
    }
  }

  void _stagione(Canvas c, Size s, Paint tratto, Paint pieno, Paint tenue) {
    // Calendario con i giorni-partita evidenziati.
    final cal = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s.width * 0.2,
        s.height * 0.16,
        s.width * 0.6,
        s.height * 0.6,
      ),
      const Radius.circular(8),
    );
    c.drawRRect(cal, tenue);
    c.drawRRect(cal, tratto..strokeWidth = 2);
    c.drawLine(
      Offset(cal.left, cal.top + cal.height * 0.24),
      Offset(cal.right, cal.top + cal.height * 0.24),
      tratto,
    );
    final cella = cal.width / 5;
    var k = 0;
    for (var r = 0; r < 3; r++) {
      for (var col = 0; col < 5; col++, k++) {
        final centro = Offset(
          cal.left + cella * (col + 0.5),
          cal.top + cal.height * 0.24 + cal.height * 0.76 * (r + 0.5) / 3,
        );
        if (k == 3 || k == 9 || k == 12) {
          if (k / 15 <= progresso) disegnaPalla(c, centro, 5);
        } else {
          c.drawCircle(
            centro,
            1.8,
            Paint()..color = tratto.color.withValues(alpha: 0.5),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(IllustrazioneRiquadroPainter old) =>
      old.soggetto != soggetto ||
      old.accento != accento ||
      old.fondo != fondo ||
      old.progresso != progresso;
}
