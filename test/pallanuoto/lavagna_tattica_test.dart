import 'dart:math' as math;

import 'package:coach_vasca/features/pallanuoto/presentation/water_polo_tactics_board.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'ultimo disegno notificato dalla lavagna.
class _Disegno {
  List<GiocatoreLavagna> giocatori = const [];
  List<FrecciaLavagna> frecce = const [];
}

Future<_Disegno> _apriLavagna(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final disegno = _Disegno();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.chiaro,
      home: Scaffold(
        body: SingleChildScrollView(
          child: WaterPoloTacticsBoard(
            campo: CampoLavagna.meta,
            onCambiato: (giocatori, frecce) {
              disegno
                ..giocatori = giocatori
                ..frecce = frecce;
            },
          ),
        ),
      ),
    ),
  );
  return disegno;
}

Rect _vasca(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('vasca-lavagna')));

Offset _punto(WidgetTester tester, double x, double y) {
  final r = _vasca(tester);
  return Offset(r.left + r.width * x, r.top + r.height * y);
}

/// Trascina il dito da [da] ad [a]; con [piega] diversa da zero passa
/// per un arco che si scosta di tanti pixel dalla retta.
Future<void> _disegna(
  WidgetTester tester,
  Offset da,
  Offset a, {
  double piega = 0,
}) async {
  final gesto = await tester.startGesture(da);
  final corda = a - da;
  final normale = Offset(-corda.dy, corda.dx) / corda.distance;
  for (var i = 1; i <= 20; i++) {
    final t = i / 20;
    await gesto.moveTo(
      Offset.lerp(da, a, t)! + normale * (piega * math.sin(math.pi * t)),
    );
  }
  await gesto.up();
  await tester.pump();
}

Finder _semantica(String etichetta) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == etichetta,
);

void main() {
  testWidgets('il portiere ha la calottina rossa con la P, al massimo due', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tap(find.text('Portiere'));
    await tester.pump();

    for (final x in [0.3, 0.5, 0.7]) {
      await tester.tapAt(_punto(tester, x, 0.2));
      await tester.pump();
    }

    expect(disegno.giocatori, hasLength(2));
    expect(
      disegno.giocatori.every((g) => g.colore == ColoreLavagna.rosso),
      isTrue,
    );
    expect(_semantica('Portiere 1'), findsOneWidget);
    expect(find.textContaining('Al massimo 2 portieri'), findsOneWidget);
  });

  testWidgets('ogni calottina va dove si tocca', (tester) async {
    final disegno = await _apriLavagna(tester);
    for (final (x, y) in [(0.2, 0.6), (0.5, 0.4), (0.8, 0.7)]) {
      await tester.tapAt(_punto(tester, x, y));
      await tester.pump();
    }
    expect(
      [
        for (final g in disegno.giocatori)
          (
            double.parse(g.posizione.dx.toStringAsFixed(2)),
            double.parse(g.posizione.dy.toStringAsFixed(2)),
          ),
      ],
      [(0.2, 0.6), (0.5, 0.4), (0.8, 0.7)],
    );
    expect(_semantica('Calottina bianca 3'), findsOneWidget);
  });

  testWidgets('trascinata in fretta, la calottina arriva sotto il dito', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tapAt(_punto(tester, 0.2, 0.5));
    await tester.pump();

    // Più movimenti nello stesso fotogramma, come un dito veloce.
    final gesto = await tester.startGesture(_punto(tester, 0.2, 0.5));
    for (var i = 0; i < 6; i++) {
      await gesto.moveBy(const Offset(40, 0));
    }
    await gesto.up();
    await tester.pump(const Duration(milliseconds: 400));

    final r = _vasca(tester);
    expect(
      disegno.giocatori.single.posizione.dx,
      closeTo(0.2 + 240 / r.width, 0.01),
    );
  });

  testWidgets('una traiettoria ad arco diventa un passaggio curvo', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tap(find.text('Frecce'));
    await tester.pump();
    await tester.tap(find.text('Passaggio'));
    await tester.pump();

    await _disegna(
      tester,
      _punto(tester, 0.2, 0.7),
      _punto(tester, 0.8, 0.7),
      piega: 80,
    );

    final freccia = disegno.frecce.single;
    expect(freccia.tipo, TipoFreccia.passaggio);
    expect(freccia.colore, ColoreLavagna.nero);
    expect(freccia.controllo, isNotNull);
  });

  testWidgets('un tratto dritto resta dritto, e si curva dalla maniglia', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tap(find.text('Frecce'));
    await tester.pump();

    await _disegna(tester, _punto(tester, 0.2, 0.5), _punto(tester, 0.8, 0.5));
    expect(disegno.frecce.single.controllo, isNull);
    // Parte proprio dal punto toccato, non da dove il trascinamento è
    // stato riconosciuto.
    expect(disegno.frecce.single.inizio.dx, closeTo(0.2, 0.005));

    // Appena disegnata resta scelta: la maniglia al centro la piega.
    await tester.drag(_semantica('Curva la freccia'), const Offset(0, 70));
    // La maniglia ascolta anche il doppio tocco: si lascia scadere
    // l'attesa del secondo tocco.
    await tester.pump(const Duration(milliseconds: 400));
    expect(disegno.frecce.single.controllo, isNotNull);
  });

  testWidgets('con una freccia scelta il cestino elimina solo quella', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tap(find.text('Frecce'));
    await tester.pump();

    await _disegna(tester, _punto(tester, 0.2, 0.3), _punto(tester, 0.8, 0.3));
    await _disegna(tester, _punto(tester, 0.2, 0.8), _punto(tester, 0.8, 0.8));
    expect(disegno.frecce, hasLength(2));

    await tester.tap(find.byTooltip('Elimina la freccia scelta'));
    await tester.pump();

    expect(disegno.frecce, hasLength(1));
    expect(disegno.frecce.single.inizio.dy, closeTo(0.3, 0.01));
  });

  testWidgets('cambiare tipo con una freccia scelta cambia lei', (
    tester,
  ) async {
    final disegno = await _apriLavagna(tester);
    await tester.tap(find.text('Frecce'));
    await tester.pump();
    await _disegna(tester, _punto(tester, 0.2, 0.5), _punto(tester, 0.8, 0.5));

    await tester.tap(find.text('Tiro'));
    await tester.pump();

    expect(disegno.frecce.single.tipo, TipoFreccia.tiro);
  });

  testWidgets('chi sfoglia lo schema vede la legenda delle frecce usate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.chiaro,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SchemaTatticoPlayer(
              campo: CampoLavagna.meta,
              passi: [
                (
                  giocatori: [],
                  frecce: [
                    FrecciaLavagna(
                      inizio: Offset(0.2, 0.2),
                      fine: Offset(0.6, 0.6),
                      colore: ColoreLavagna.nero,
                      tipo: TipoFreccia.passaggio,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Passaggio'), findsOneWidget);
    expect(find.text('Tiro'), findsNothing);
  });
}
