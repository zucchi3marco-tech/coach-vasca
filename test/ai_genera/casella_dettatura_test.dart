import 'package:coach_vasca/features/ai_genera/presentation/casella_dettatura.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la casella si scrive a mano anche senza microfono', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController();
    final key = GlobalKey<CasellaDettaturaState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.scuro,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CasellaDettatura(
              key: key,
              controller: controller,
              etichetta: 'Descrivilo a parole',
              aiuto: 'Un aiuto',
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '8x100 sl soglia');
    expect(controller.text, '8x100 sl soglia');
    expect(tester.takeException(), isNull);
    key.currentState!.ferma();
  });
}
