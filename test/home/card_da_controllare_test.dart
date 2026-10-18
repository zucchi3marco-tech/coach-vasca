import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/data/modifiche_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/features/home/allenatore/card_da_controllare.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ModificheFinte implements ModificheRepository {
  _ModificheFinte(this.elenco);

  final List<ModificaAllenamento> elenco;
  var letture = 0;

  @override
  Future<List<ModificaAllenamento>> daControllare(String clubId) async {
    letture++;
    return elenco;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ModificaAllenamento _modifica(
  int n, {
  List<String> autori = const ['Luca Bianchi'],
  bool nuovo = false,
  String? titolo,
  int minutiFa = 25,
}) {
  final ultima = DateTime.now().toUtc().subtract(Duration(minutes: minutiFa));
  return ModificaAllenamento.fromMap({
    'id': 'm$n',
    'allenamento_id': 'a$n',
    'club_id': 'c1',
    'capo_user_id': 'u-capo',
    'autori': autori,
    'nuovo': nuovo,
    'prima': null,
    'aperta_at': ultima.toIso8601String(),
    'ultima_at': ultima.toIso8601String(),
    'visto_at': null,
    'allenamenti': {'titolo': titolo, 'data': '2026-10-20', 'gruppo_id': 'g14'},
  });
}

Future<List<ModificaAllenamento>> _apri(
  WidgetTester tester,
  List<ModificaAllenamento> elenco, {
  List<ModificaAllenamento>? apriti,
}) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final aperte = apriti ?? <ModificaAllenamento>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        modificheRepositoryProvider.overrideWithValue(_ModificheFinte(elenco)),
        gruppiListProvider.overrideWith(
          (ref, clubId) => Stream.value(const [
            Gruppo(id: 'g14', clubId: 'c1', nome: 'U14', ordine: 1),
          ]),
        ),
        allenamentiListProvider.overrideWith(
          (ref, clubId) => Stream.value(<Allenamento>[]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardDaControllare(clubId: 'c1', onApri: aperte.add),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return aperte;
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'SUPABASE_URL=https://abc.supabase.co/');
  });

  testWidgets('con una modifica mostra chi, che cosa, dove e quando', (
    tester,
  ) async {
    await _apri(tester, [_modifica(1, titolo: 'Tecnica')]);

    expect(find.text('Da controllare'), findsOneWidget);
    expect(find.text('Luca Bianchi ha modificato «Tecnica»'), findsOneWidget);
    expect(find.text('U14 · mar 20 ott · 25 minuti fa'), findsOneWidget);
    expect(find.textContaining('Vedi tutte'), findsNothing);
  });

  testWidgets('più autori, allenamento aggiunto e senza titolo', (
    tester,
  ) async {
    await _apri(tester, [
      _modifica(1, autori: ['Luca', 'Anna', 'Gino']),
      _modifica(2, autori: ['Anna'], nuovo: true, titolo: 'Salto'),
    ]);

    expect(
      find.text('Luca, Anna e Gino hanno modificato «Allenamento»'),
      findsOneWidget,
    );
    expect(find.text('Anna ha aggiunto «Salto»'), findsOneWidget);
  });

  testWidgets('mostra al massimo tre voci e «Vedi tutte (N)»', (tester) async {
    await _apri(tester, [for (var i = 1; i <= 5; i++) _modifica(i)]);

    expect(find.textContaining('Luca Bianchi ha modificato'), findsNWidgets(3));
    expect(find.text('Vedi tutte (5)'), findsOneWidget);
  });

  testWidgets('con esattamente tre voci non c\'è «Vedi tutte»', (tester) async {
    await _apri(tester, [for (var i = 1; i <= 3; i++) _modifica(i)]);
    expect(find.textContaining('Luca Bianchi ha modificato'), findsNWidgets(3));
    expect(find.textContaining('Vedi tutte'), findsNothing);
  });

  testWidgets('senza modifiche la scheda non c\'è', (tester) async {
    await _apri(tester, []);
    expect(find.text('Da controllare'), findsNothing);
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('toccare una voce la apre', (tester) async {
    final aperte = await _apri(tester, [
      _modifica(1, titolo: 'Tecnica'),
      _modifica(2, titolo: 'Salto'),
    ]);

    await tester.tap(find.text('Luca Bianchi ha modificato «Salto»'));
    await tester.pump();

    expect(aperte.map((m) => m.id), ['m2']);
  });

  testWidgets('«Vedi tutte» apre l\'elenco completo', (tester) async {
    await _apri(tester, [for (var i = 1; i <= 5; i++) _modifica(i)]);

    await tester.tap(find.text('Vedi tutte (5)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Da controllare'), findsWidgets);
    expect(
      find.text('Allenamenti cambiati da altri nelle tue squadre.'),
      findsOneWidget,
    );
    expect(find.textContaining('Luca Bianchi ha modificato'), findsNWidgets(5));
  });

  testWidgets('nella demo non c\'è e non chiede niente alla rete', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=true');
    final server = _ModificheFinte([_modifica(1)]);
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modificheRepositoryProvider.overrideWithValue(server),
          gruppiListProvider.overrideWith(
            (ref, clubId) => Stream.value(<Gruppo>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: const Scaffold(body: CardDaControllare(clubId: 'c1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Da controllare'), findsNothing);
    expect(server.letture, 0);
  });

  testWidgets('se non si legge (senza rete) la scheda non c\'è', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Nessun repository finto: senza Supabase la lettura fallisce.
          gruppiListProvider.overrideWith(
            (ref, clubId) => Stream.value(<Gruppo>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: const Scaffold(body: CardDaControllare(clubId: 'c1')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Da controllare'), findsNothing);
  });
}
