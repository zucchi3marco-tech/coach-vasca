import 'package:coach_vasca/features/notifiche/data/notifiche_repository.dart';
import 'package:coach_vasca/features/notifiche/domain/notifica.dart';
import 'package:coach_vasca/features/notifiche/presentation/notifiche_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepositoryFinto implements NotificheRepository {
  Object? errore;
  final lette = <String>[];

  @override
  Future<void> segnaLetta(String id) async {
    if (errore != null) throw errore!;
    lette.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_RepositoryFinto repository) => ProviderScope(
  overrides: [
    notificheRepositoryProvider.overrideWithValue(repository),
    notificheNonLetteProvider.overrideWith(
      (ref, clubId) async => [
        Notifica(
          id: 'n1',
          tipo: 'atleta_registrato',
          messaggio: 'Marco Rossi si è registrato',
          letta: false,
          creataIl: DateTime(2026, 9, 21, 10, 30),
        ),
      ],
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    home: const NotificheScreen(clubId: 'c1'),
  ),
);

void main() {
  testWidgets('segna come letta chiama il repository', (tester) async {
    final repository = _RepositoryFinto();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_outlined));
    await tester.pumpAndSettle();

    expect(repository.lette, ['n1']);
    expect(find.textContaining('Non è stato possibile'), findsNothing);
  });

  testWidgets('se non riesce, lo dice invece di far finta di niente', (
    tester,
  ) async {
    final repository = _RepositoryFinto()..errore = Exception('offline');
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_outlined));
    await tester.pumpAndSettle();

    expect(repository.lette, isEmpty);
    expect(
      find.textContaining('Non è stato possibile segnarla come letta'),
      findsOneWidget,
    );
  });
}
