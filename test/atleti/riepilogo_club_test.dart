import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/presentation/atleti_list_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Marco',
  cognome: cognome,
  dataNascita: DateTime(2012, 3, 4),
  sport: 'nuoto',
  consensoPrivacyFirmato: false,
  attivo: true,
);

void main() {
  testWidgets(
    'il riepilogo mostra icone, dato sotto e una didascalia piccola',
    (tester) async {
      final domani = DateTime.now().add(const Duration(days: 1));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            atletiListProvider.overrideWith(
              (ref, filter) => Stream.value([
                _atleta('a1', 'Rossi'),
                _atleta('a2', 'Bianchi'),
              ]),
            ),
            gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
            allenamentiListProvider.overrideWith(
              (ref, clubId) => Stream.value([
                Allenamento(id: 'x', clubId: 'c1', data: domani),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            home: const AtletiListScreen(clubId: 'c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);

      // Il dato sta sotto la sua icona.
      final iconaAtleti = tester.getCenter(find.byIcon(Icons.groups_outlined));
      final datoAtleti = tester.getCenter(find.text('2').first);
      expect(datoAtleti.dy, greaterThan(iconaAtleti.dy));
      expect((datoAtleti.dx - iconaAtleti.dx).abs(), lessThan(2));

      // Sotto ogni dato, la sua didascalia.
      for (final didascalia in [
        'Atleti attivi',
        'Prossimo allenamento',
        'Nei prossimi 7 giorni',
      ]) {
        final centro = tester.getCenter(find.text(didascalia));
        expect(centro.dy, greaterThan(datoAtleti.dy));
      }
    },
  );
}
