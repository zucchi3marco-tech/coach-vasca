import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/pannello_orologio.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// I bip suonati, in ordine: 'lungo' o 'breve'.
class _Bip {
  final suonati = <String>[];

  void suona({bool lungo = false}) => suonati.add(lungo ? 'lungo' : 'breve');
}

Future<void> _apri(
  WidgetTester tester,
  String riga,
  _Bip bip, {
  bool suono = true,
  VoidCallback? onFinita,
}) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.chiaro,
      home: Scaffold(
        body: PannelloOrologio(
          serie: leggiRigaSerie(riga, blocco: 'principale')!.single,
          gruppi: 1,
          distaccoS: 10,
          onGruppi: (_) {},
          onDistacco: (_) {},
          onFinita: onFinita ?? () {},
          suono: suono,
          onSuono: (_) {},
          suona: bip.suona,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('bip lungo al via, tre brevi prima della partenza, poi lungo', (
    tester,
  ) async {
    final bip = _Bip();
    var finita = false;
    await _apri(tester, '2x50 sl @0:10', bip, onFinita: () => finita = true);

    await tester.tap(find.text('Via'));
    await tester.pump();
    expect(bip.suonati, ['lungo']);

    // A 7 secondi ne mancano 3 alla prossima partenza.
    for (var s = 0; s < 7; s++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(bip.suonati, ['lungo', 'breve']);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(bip.suonati, ['lungo', 'breve', 'breve', 'breve']);
    await tester.pump(const Duration(seconds: 1));
    expect(bip.suonati, ['lungo', 'breve', 'breve', 'breve', 'lungo']);

    // L'ultima ripetuta non ha una partenza dopo: niente conto alla
    // rovescia, e a 20 secondi la serie è finita.
    for (var s = 0; s < 10; s++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(bip.suonati, hasLength(5));
    expect(finita, isTrue);
  });

  testWidgets('serie a tempo: bip lungo anche alla fine del lavoro', (
    tester,
  ) async {
    final bip = _Bip();
    await _apri(tester, "2x30'' r10", bip);
    await tester.tap(find.text('Via'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(bip.suonati, ['lungo', 'lungo']);
  });

  testWidgets('con il suono spento non suona niente', (tester) async {
    final bip = _Bip();
    await _apri(tester, '2x50 sl @0:10', bip, suono: false);
    expect(find.byTooltip('Metti il suono'), findsOneWidget);
    await tester.tap(find.text('Via'));
    await tester.pump();
    for (var s = 0; s < 12; s++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(bip.suonati, isEmpty);
  });
}
