import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../domain/test_club.dart';

/// L'icona di un test, da cosa misura.
IconData iconaTest(UnitaTest unita) => switch (unita) {
  UnitaTest.secondi => Icons.timer_outlined,
  UnitaTest.metri => Icons.straighten,
  UnitaTest.centimetri => Icons.height,
  UnitaTest.chili => Icons.fitness_center,
  UnitaTest.kmh => Icons.speed,
  UnitaTest.punti => Icons.adjust,
  UnitaTest.ripetizioni => Icons.repeat,
};

/// "Tempo · 2 prove · vince il più basso"; "Massimale in chili · da chili
/// × ripetizioni".
String descrizioneMisura(TestClub t) => t.massimale
    ? 'Massimale in chili · da chili × ripetizioni'
    : [
        t.unita.etichetta,
        t.comeSiLegge,
        if (t.piuBassoMeglio) 'vince il più basso' else 'vince il più alto',
      ].join(' · ');

/// Sceglie un test da un elenco (bottom sheet); null se si chiude.
Future<TestClub?> scegliTest(
  BuildContext context,
  List<TestClub> test, {
  String titolo = 'Quale test?',
}) {
  return showModalBottomSheet<TestClub>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colori = sheetContext.colori;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titolo,
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s12),
            AppListPanel(
              righe: [
                for (final t in test)
                  AppListRow(
                    leading: Icon(
                      iconaTest(t.unita),
                      color: colori.testoSecondario,
                    ),
                    titolo: t.nome,
                    sottotitolo: t.comeSiLegge,
                    onTap: () => Navigator.of(sheetContext).pop(t),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
