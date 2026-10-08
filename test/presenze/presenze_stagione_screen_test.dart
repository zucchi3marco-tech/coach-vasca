import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/presentation/presenze_stagione_screen.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime.now();
DateTime _giorniFa(int giorni) => DateTime(
  _oggi.year,
  _oggi.month,
  _oggi.day,
).subtract(Duration(days: giorni));

Atleta _atleta(String id, String cognome) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Mario',
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  gruppoId: 'u14',
  consensoPrivacyFirmato: true,
  attivo: true,
);

Presenza _presenza(String atleta, String allenamento, String stato) => Presenza(
  id: '$atleta-$allenamento',
  allenamentoId: allenamento,
  atletaId: atleta,
  clubId: 'c1',
  stato: stato,
);

Future<void> _apri(WidgetTester tester, Size schermo, ThemeData tema) async {
  tester.view.physicalSize = schermo;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Due allenamenti nell'ultimo mese, uno di due mesi fa.
  final allenamenti = [
    Allenamento(
      id: 'vecchio',
      clubId: 'c1',
      data: _giorniFa(60),
      gruppoId: 'u14',
    ),
    Allenamento(id: 'a1', clubId: 'c1', data: _giorniFa(10), gruppoId: 'u14'),
    Allenamento(id: 'a2', clubId: 'c1', data: _giorniFa(3), gruppoId: 'u14'),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        atletiListProvider.overrideWith(
          (ref, filtro) =>
              Stream.value([_atleta('r', 'Rossi'), _atleta('b', 'Bianchi')]),
        ),
        allenamentiListProvider.overrideWith(
          (ref, clubId) => Stream.value(allenamenti),
        ),
        presenzeClubProvider.overrideWith(
          (ref, clubId) => Stream.value([
            _presenza('r', 'vecchio', 'assente'),
            _presenza('r', 'a1', 'presente'),
            _presenza('r', 'a2', 'presente'),
            _presenza('b', 'vecchio', 'presente'),
            _presenza('b', 'a1', 'assente'),
            _presenza('b', 'a2', 'giustificato'),
          ]),
        ),
        stagioniListProvider.overrideWith(
          (ref, clubId) => Stream.value([
            Stagione(
              id: 's1',
              clubId: 'c1',
              nome: '2026/27',
              dataInizio: _giorniFa(20),
              dataFine: _giorniFa(-200),
              gruppoId: 'u14',
            ),
          ]),
        ),
        gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: tema,
        home: const PresenzeStagioneScreen(clubId: 'c1', gruppoId: 'u14'),
      ),
    ),
  );
  // La testata ha l'acqua animata: non si ferma mai.
  await _aspetta(tester);
}

Future<void> _aspetta(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final (nome, schermo, tema) in [
    ('telefono, scuro', const Size(390, 844), AppTheme.scuro),
    ('tablet, chiaro', const Size(1280, 800), AppTheme.chiaro),
  ]) {
    testWidgets('$nome: la stagione in corso, poi gli ultimi 3 mesi', (
      tester,
    ) async {
      await _apri(tester, schermo, tema);
      expect(tester.takeException(), isNull);

      // Stagione da 20 giorni fa: due allenamenti.
      expect(find.text('Stagione 2026/27'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      // Rossi 100%, Bianchi 0%: media 50%, prima chi viene di più.
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      final rossi = tester.getTopLeft(find.textContaining('Rossi')).dy;
      final bianchi = tester.getTopLeft(find.textContaining('Bianchi')).dy;
      expect(rossi, lessThan(bianchi));

      // Tre mesi: entra anche l'allenamento di due mesi fa.
      await tester.tap(find.text('Ultimi 3 mesi'));
      await _aspetta(tester);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
