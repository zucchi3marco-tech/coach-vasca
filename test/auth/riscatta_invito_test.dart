import 'package:coach_vasca/features/atleti/application/current_atleta_provider.dart';
import 'package:coach_vasca/features/atleti/data/inviti_atleta_repository.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/auth/data/auth_repository.dart';
import 'package:coach_vasca/features/auth/presentation/riscatta_invito_screen.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// L'account esiste già (la sessione è attiva prima del collegamento): si
/// salta `signUp`, come nel vero flusso dopo la creazione dell'account.
class _AuthFinto implements AuthRepository {
  @override
  User? get currentUser => const User(
    id: 'u1',
    appMetadata: {},
    userMetadata: {},
    aud: 'a',
    createdAt: '2026-01-01T00:00:00Z',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InvitiFinti implements InvitiAtletaRepository {
  @override
  Future<AtletaInvitato?> validaCodice(String codice) async =>
      (nome: 'Marco', cognome: 'Rossi');

  @override
  Future<Atleta> collegaConCodice(String codice) async => Atleta(
    id: 'a1',
    clubId: 'c1',
    nome: 'Marco',
    cognome: 'Rossi',
    dataNascita: DateTime(2012, 3, 4),
    sport: 'nuoto',
    consensoPrivacyFirmato: false,
    attivo: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('dopo il collegamento la home rilegge atleta e club', (
    tester,
  ) async {
    var letturePerAtleta = 0;
    var lettureClub = 0;
    final navigatorKey = GlobalKey<NavigatorState>();

    // Simula la home (montata sotto la schermata di registrazione già
    // quando compare la sessione): tiene vivi i due provider e ha letto
    // «nessun atleta / nessun club» PRIMA del collegamento.
    final contenitore = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthFinto()),
        invitiAtletaRepositoryProvider.overrideWithValue(_InvitiFinti()),
        currentAtletaProvider.overrideWith((ref) async {
          letturePerAtleta++;
          return null;
        }),
        currentClubProvider.overrideWith((ref) async {
          lettureClub++;
          return const Club(id: 'c1', nome: 'Club');
        }),
      ],
    );
    addTearDown(contenitore.dispose);
    contenitore.listen(currentAtletaProvider, (_, _) {});
    contenitore.listen(currentClubProvider, (_, _) {});
    await contenitore.read(currentAtletaProvider.future);
    await contenitore.read(currentClubProvider.future);
    expect(letturePerAtleta, 1);
    expect(lettureClub, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenitore,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.chiaro,
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const RiscattaInvitoScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'CODICE1');
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rossi Marco'), findsOneWidget);

    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();

    final campi = find.byType(TextFormField);
    await tester.enterText(campi.at(0), 'marco@example.com');
    await tester.enterText(campi.at(1), 'segreta1');
    await tester.enterText(campi.at(2), 'segreta1');
    await tester.tap(find.text('Crea account'));
    await tester.pumpAndSettle();

    // La schermata si chiude e i provider sono stati ricalcolati.
    expect(find.text('Crea account'), findsNothing);
    expect(letturePerAtleta, 2);
    expect(lettureClub, 2);
  });
}
