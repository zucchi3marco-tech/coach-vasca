import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/data/atleti_repository.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/presentation/atleti_list_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:coach_vasca/widgets/danger_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepositoryFinto implements AtletiRepository {
  final eliminati = <String>[];
  Object? errore;

  @override
  Future<void> deleteAtleta(String id) async {
    if (errore != null) throw errore!;
    eliminati.add(id);
  }

  @override
  Future<void> refreshFromRemote(String clubId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _atleta = Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Marco',
  cognome: 'Rossi',
  dataNascita: DateTime(2012, 3, 4),
  sport: 'nuoto',
  consensoPrivacyFirmato: false,
  attivo: true,
);

Widget _app(_RepositoryFinto repository) => ProviderScope(
  overrides: [
    atletiRepositoryProvider.overrideWithValue(repository),
    atletiListProvider.overrideWith((ref, filter) => Stream.value([_atleta])),
    gruppiListProvider.overrideWith((ref, clubId) => Stream.value([])),
    allenamentiListProvider.overrideWith(
      (ref, clubId) => Stream.value(<Allenamento>[]),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    home: const AtletiListScreen(clubId: 'c1'),
  ),
);

/// Nei test il font è quello quadrato di default, molto più largo di quello
/// vero: gli overflow dei testi (per esempio nel menu) non dicono nulla
/// sull'app e si ignorano.
void _ignoraOverflowDiTesto() {
  final originale = FlutterError.onError;
  FlutterError.onError = (dettagli) {
    if (dettagli.exceptionAsString().contains('overflowed')) return;
    originale?.call(dettagli);
  };
  addTearDown(() => FlutterError.onError = originale);
}

Future<void> _apriConferma(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Elimina atleta'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('il menu ⋮ ha «Elimina atleta» e chiede conferma', (
    tester,
  ) async {
    _ignoraOverflowDiTesto();
    final repository = _RepositoryFinto();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _apriConferma(tester);

    expect(find.text('Eliminare Rossi Marco?'), findsOneWidget);
    expect(repository.eliminati, isEmpty);
  });

  testWidgets('Annulla non elimina nulla', (tester) async {
    _ignoraOverflowDiTesto();
    final repository = _RepositoryFinto();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _apriConferma(tester);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(repository.eliminati, isEmpty);
    expect(find.text('Eliminare Rossi Marco?'), findsNothing);
  });

  testWidgets('Elimina cancella l\'atleta e lo conferma con un messaggio', (
    tester,
  ) async {
    _ignoraOverflowDiTesto();
    final repository = _RepositoryFinto();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _apriConferma(tester);
    await tester.tap(find.widgetWithText(DangerButton, 'Elimina'));
    await tester.pumpAndSettle();

    expect(repository.eliminati, ['a1']);
    expect(find.text('Rossi Marco eliminato.'), findsOneWidget);
  });

  testWidgets('se l\'eliminazione fallisce mostra l\'errore', (tester) async {
    _ignoraOverflowDiTesto();
    final repository = _RepositoryFinto()..errore = Exception('boom');
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _apriConferma(tester);
    await tester.tap(find.widgetWithText(DangerButton, 'Elimina'));
    await tester.pumpAndSettle();

    expect(repository.eliminati, isEmpty);
    expect(find.textContaining('Eliminazione non riuscita'), findsOneWidget);
  });
}
