import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/db/database_provider.dart';
import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/home/area_atleta_home_screen.dart';
import 'package:coach_vasca/features/pallanuoto/application/pallanuoto_providers.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/numeri_portiere.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/statistiche/application/statistiche_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta({String? ruolo, String sport = 'pallanuoto'}) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010, 3, 4),
  sport: sport,
  gruppoId: 'g1',
  ruolo: ruolo,
  consensoPrivacyFirmato: true,
  attivo: true,
);

EventoPartita _tiro(String esito) => EventoPartita(
  id: 't$esito',
  partitaId: 'p1',
  clubId: 'c1',
  tipo: 'tiro',
  squadra: 'nostra',
  atletaId: 'a1',
  esito: esito,
  creatoIl: DateTime(2026, 10, 24, 18),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.perTest(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> apri(
    WidgetTester tester,
    Atleta atleta, {
    NumeriPortiere? portiere,
    List<EventoPartita> tiri = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          numeriPortiereProvider.overrideWith(
            (ref, chiave) async => portiere ?? NumeriPortiere.vuoto,
          ),
          tiriAtletaProvider.overrideWith((ref, id) async => tiri),
          partiteListProvider.overrideWith(
            (ref, clubId) => Stream.value(<Partita>[]),
          ),
          allenamentiAtletaProvider.overrideWith(
            (ref, clubId) async => <Allenamento>[],
          ),
          gruppiListProvider.overrideWith(
            (ref, clubId) => Stream.value(const [
              Gruppo(id: 'g1', clubId: 'c1', nome: 'Under 16', ordine: 0),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          // Come "Riduci movimento": l'acqua della testata è animata.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(body: AreaAtletaHomeScreen(atleta: atleta)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('il portiere vede parate, gol subiti e % parate, non i gol', (
    tester,
  ) async {
    await apri(
      tester,
      _atleta(ruolo: 'portiere'),
      portiere: const NumeriPortiere(
        partite: 3,
        parate: 12,
        golSubiti: 8,
        golSubitiDalVivo: 4,
      ),
      // Un gol segnato dal portiere: nella dashboard non si vede.
      tiri: [_tiro('gol')],
    );

    expect(find.text('Parate'), findsOneWidget);
    expect(find.text('Gol subiti'), findsOneWidget);
    expect(find.text('% parate'), findsOneWidget);
    expect(find.text('Presenze'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    // 12 parate su 16 tiri in porta dal vivo.
    expect(find.text('75%'), findsOneWidget);

    expect(find.text('Gol'), findsNothing);
    expect(find.text('Tiri'), findsNothing);
    expect(find.text('Precisione'), findsNothing);
    expect(find.text('Parate e gol subiti'), findsOneWidget);
    expect(find.text('Tiri, gol e dove segni di più'), findsNothing);
  });

  testWidgets('un portiere senza dati vede il trattino', (tester) async {
    await apri(tester, _atleta(ruolo: 'portiere'));

    expect(find.text('Parate'), findsOneWidget);
    // Parate e gol subiti sono 0; la % parate non c'è ancora.
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('chi gioca in campo vede gol, tiri e precisione', (tester) async {
    await apri(
      tester,
      _atleta(ruolo: 'centroboa'),
      tiri: [_tiro('gol'), _tiro('parato')],
    );

    expect(find.text('Gol'), findsOneWidget);
    expect(find.text('Tiri'), findsOneWidget);
    expect(find.text('Precisione'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Parate'), findsNothing);
    expect(find.text('Gol subiti'), findsNothing);
    expect(find.text('Tiri, gol e dove segni di più'), findsOneWidget);
  });
}
