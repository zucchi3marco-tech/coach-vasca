import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/presenze/application/presenze_providers.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:coach_vasca/features/presenze/presentation/mie_presenze_screen.dart';
import 'package:coach_vasca/features/presenze/presentation/presenze_stagione_screen.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime.now();
DateTime _giorniFa(int giorni) => DateTime(
  _oggi.year,
  _oggi.month,
  _oggi.day,
  18,
).subtract(Duration(days: giorni));

final _atleta = Atleta(
  id: 'r',
  clubId: 'c1',
  nome: 'Mario',
  cognome: 'Rossi',
  dataNascita: DateTime(2012),
  sport: 'nuoto',
  gruppoId: 'u14',
  consensoPrivacyFirmato: true,
  attivo: true,
);

final _allenamenti = [
  Allenamento(id: 'a1', clubId: 'c1', data: _giorniFa(5), gruppoId: 'u14'),
  Allenamento(id: 'a2', clubId: 'c1', data: _giorniFa(3), gruppoId: 'u14'),
];

Presenza _presenza(String allenamento, String stato) => Presenza(
  id: 'r-$allenamento',
  allenamentoId: allenamento,
  atletaId: 'r',
  clubId: 'c1',
  stato: stato,
);

Future<void> _aspetta(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('le mie presenze: «In ritardo» c\'ero, ma si legge a parte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presenzePerAtletaProvider.overrideWith(
            (ref, id) => Stream.value([
              _presenza('a1', 'presente'),
              _presenza('a2', 'ritardo'),
            ]),
          ),
          allenamentiAtletaProvider.overrideWith(
            (ref, clubId) async => _allenamenti,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: MiePresenzeScreen(atleta: _atleta),
        ),
      ),
    );
    await _aspetta(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Presente'), findsOneWidget);
    expect(find.text('In ritardo'), findsOneWidget);
    // Due presenze (la seconda in ritardo) su due allenamenti: 100%.
    expect(find.text('2'), findsWidgets);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('Assente'), findsNothing);
  });

  testWidgets('la griglia della stagione: legenda e percentuale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          atletiListProvider.overrideWith(
            (ref, filtro) => Stream.value([_atleta]),
          ),
          allenamentiListProvider.overrideWith(
            (ref, clubId) => Stream.value(_allenamenti),
          ),
          presenzeClubProvider.overrideWith(
            (ref, clubId) => Stream.value([
              _presenza('a1', 'ritardo'),
              _presenza('a2', 'ritardo'),
            ]),
          ),
          stagioniListProvider.overrideWith(
            (ref, clubId) => Stream.value(const []),
          ),
          gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.scuro,
          home: const PresenzeStagioneScreen(clubId: 'c1', gruppoId: 'u14'),
        ),
      ),
    );
    await _aspetta(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('In ritardo'), findsOneWidget);
    // Sempre in ritardo ma sempre presente: 100%, due di fila.
    expect(find.text('100%'), findsWidgets);
  });
}
