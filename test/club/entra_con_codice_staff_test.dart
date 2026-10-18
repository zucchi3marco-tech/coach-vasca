import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/data/membri_club_repository.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/club/presentation/entra_con_codice_staff_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: conosce un solo codice valido e annota chi entra.
class _ClubFinto implements MembriClubRepository {
  final validazioni = <String>[];
  final ingressi = <(String, String)>[];
  Object? erroreIngresso;
  Object? erroreValidazione;

  static const codiceBuono = 'ABCDE12345';

  @override
  Future<InvitoStaff?> validaInvito(String codice) async {
    validazioni.add(codice);
    if (erroreValidazione != null) throw erroreValidazione!;
    if (codice == codiceBuono) {
      return const InvitoStaff(
        clubNome: 'Mako Pallanuoto',
        ruolo: RuoloClub.assistente,
      );
    }
    return null;
  }

  @override
  Future<String> entraConInvito(String codice, String nome) async {
    if (erroreIngresso != null) throw erroreIngresso!;
    ingressi.add((codice, nome));
    return 'c1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Una «home» che guarda il club e da cui si apre la schermata, come
/// «Crea il tuo club» dentro la home vera.
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentClubProvider);
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EntraConCodiceStaffScreen(),
            ),
          ),
          child: const Text('Ho un codice da allenatore'),
        ),
      ),
    );
  }
}

class _Prova {
  _Prova(this.server);

  final _ClubFinto server;
  var letturedelClub = 0;
}

Future<_Prova> _apri(WidgetTester tester, _ClubFinto server) async {
  final prova = _Prova(server);
  tester.view.physicalSize = const Size(360, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        membriClubRepositoryProvider.overrideWithValue(server),
        currentClubProvider.overrideWith((ref) {
          prova.letturedelClub++;
          return Future<Club?>.value();
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const _Home(),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Ho un codice da allenatore'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return prova;
}

Future<void> _passa(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scriviCodice(WidgetTester tester, String codice) async {
  await tester.enterText(find.byType(TextFormField).at(0), codice);
  await _passa(tester);
}

Future<void> _scriviNome(WidgetTester tester, String nome) async {
  await tester.enterText(find.byType(TextFormField).at(1), nome);
  await _passa(tester);
}

void main() {
  testWidgets('mostra la testata e i due campi', (tester) async {
    await _apri(tester, _ClubFinto());

    expect(find.text('Entra nel club'), findsOneWidget);
    expect(
      find.text(
        'Il responsabile del club ti ha mandato un codice: scrivilo qui con il '
        'tuo nome.',
      ),
      findsOneWidget,
    );
    expect(find.text('Codice'), findsOneWidget);
    expect(find.text('Il tuo nome'), findsOneWidget);
    // Finché mancano codice e nome non si può entrare.
    final entra = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(entra.onPressed, isNull);
  });

  testWidgets('un codice valido dice in che club e con che ruolo si entra', (
    tester,
  ) async {
    final server = _ClubFinto();
    await _apri(tester, server);

    // Minuscolo: lo scrive in maiuscolo.
    await _scriviCodice(tester, 'abcde12345');

    expect(server.validazioni, [_ClubFinto.codiceBuono]);
    expect(find.text('ABCDE12345'), findsOneWidget);
    expect(find.text('Entri in Mako Pallanuoto come Assistente.'), findsOne);
  });

  testWidgets('un codice che non vale lo dice', (tester) async {
    await _apri(tester, _ClubFinto());

    await _scriviCodice(tester, 'ZZZZZZZZZZ');

    expect(
      find.text(
        'Questo codice non vale: controlla di averlo scritto bene o chiedine '
        'uno nuovo.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Entri in'), findsNothing);
  });

  testWidgets('prima delle 10 lettere non chiede niente al server', (
    tester,
  ) async {
    final server = _ClubFinto();
    await _apri(tester, server);

    await _scriviCodice(tester, 'ABCDE');

    expect(server.validazioni, isEmpty);
    expect(find.textContaining('Entri in'), findsNothing);
  });

  testWidgets('il codice si ferma a 10 caratteri', (tester) async {
    final server = _ClubFinto();
    await _apri(tester, server);

    await _scriviCodice(tester, 'ABCDE12345XYZ');

    expect(find.text('ABCDE12345'), findsOneWidget);
    expect(server.validazioni, [_ClubFinto.codiceBuono]);
  });

  testWidgets('se la verifica non arriva al server, mostra l\'errore', (
    tester,
  ) async {
    final server = _ClubFinto()
      ..erroreValidazione = const MessaggioClub('Serve un utente collegato');
    await _apri(tester, server);

    await _scriviCodice(tester, _ClubFinto.codiceBuono);

    expect(find.text('Serve un utente collegato'), findsOneWidget);
  });

  testWidgets('«Entra» chiama il server, rilegge il club e torna indietro', (
    tester,
  ) async {
    final server = _ClubFinto();
    final prova = await _apri(tester, server);
    final letture = prova.letturedelClub;

    await _scriviCodice(tester, _ClubFinto.codiceBuono);
    await _scriviNome(tester, '  Anna Verdi ');
    await tester.tap(find.text('Entra'));
    await _passa(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(server.ingressi, [(_ClubFinto.codiceBuono, 'Anna Verdi')]);
    // Il club è riletto (la home lo guarda) e la schermata si è chiusa.
    expect(prova.letturedelClub, greaterThan(letture));
    expect(find.text('Entra nel club'), findsNothing);
    expect(find.text('Ho un codice da allenatore'), findsOneWidget);
  });

  testWidgets('se il server rifiuta, l\'errore è sotto il pulsante', (
    tester,
  ) async {
    final server = _ClubFinto()
      ..erroreIngresso = const MessaggioClub('Questo codice è già stato usato');
    final prova = await _apri(tester, server);
    final letture = prova.letturedelClub;

    await _scriviCodice(tester, _ClubFinto.codiceBuono);
    await _scriviNome(tester, 'Anna Verdi');
    await tester.tap(find.text('Entra'));
    await _passa(tester);

    expect(find.text('Questo codice è già stato usato'), findsOneWidget);
    // Resta sulla schermata e il club non viene riletto.
    expect(find.text('Entra nel club'), findsOneWidget);
    expect(prova.letturedelClub, letture);

    // Riprovando, l'errore sparisce mentre si scrive.
    await _scriviNome(tester, 'Anna Verdi B');
    expect(find.text('Questo codice è già stato usato'), findsNothing);
  });
}
