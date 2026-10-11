import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/carico/application/carico_providers.dart';
import 'package:coach_vasca/features/carico/data/rpe_repository.dart';
import 'package:coach_vasca/features/carico/domain/rpe_seduta.dart';
import 'package:coach_vasca/features/carico/presentation/card_rpe.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RpeFinto implements RpeRepository {
  final salvati = <({String eventoId, int rpe})>[];

  @override
  Future<void> salva({
    required String atletaId,
    required String clubId,
    required String eventoTipo,
    required String eventoId,
    required DateTime data,
    required int rpe,
  }) async => salvati.add((eventoId: eventoId, rpe: rpe));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _atleta = Atleta(
  id: 'at1',
  clubId: 'c1',
  nome: 'Marco',
  cognome: 'Rossi',
  dataNascita: DateTime(2011, 3, 4),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
);

Future<_RpeFinto> _apri(
  WidgetTester tester, {
  List<SedutaDaValutare> sedute = const [],
  List<RpeSeduta> risposte = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final repository = _RpeFinto();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rpeRepositoryProvider.overrideWithValue(repository),
        seduteDaValutareProvider.overrideWith((ref, atleta) => sedute),
        rpeAtletaProvider.overrideWith((ref, id) => Stream.value(risposte)),
      ],
      child: MaterialApp(
        theme: AppTheme.chiaro,
        home: Scaffold(
          body: SingleChildScrollView(child: CardRpe(atleta: _atleta)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  final ieri = (
    tipo: 'allenamento',
    id: 'a1',
    data: DateTime(2026, 10, 9),
    descrizione: 'Allenamento di ieri',
  );
  final partita = (
    tipo: 'partita',
    id: 'p1',
    data: DateTime(2026, 10, 10),
    descrizione: 'Partita di oggi con Brescia',
  );

  testWidgets('un tocco su un numero salva l\'RPE della seduta', (
    tester,
  ) async {
    final repository = await _apri(tester, sedute: [partita, ieri]);

    expect(find.text('Quanto è stato duro?'), findsOneWidget);
    expect(find.text('Partita di oggi con Brescia'), findsOneWidget);
    expect(find.text('Allenamento di ieri'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('7 · Molto duro').first);
    await tester.pumpAndSettle();
    expect(repository.salvati, [(eventoId: 'p1', rpe: 7)]);
  });

  testWidgets('una risposta già data si legge e si può cambiare', (
    tester,
  ) async {
    await _apri(
      tester,
      sedute: [ieri],
      risposte: [
        RpeSeduta(
          id: 'r1',
          atletaId: 'at1',
          clubId: 'c1',
          eventoTipo: 'allenamento',
          eventoId: 'a1',
          data: DateTime(2026, 10, 9),
          rpe: 6,
        ),
      ],
    );
    expect(find.text('6 · Duro'), findsOneWidget);
    expect(find.text('Non c\'ero'), findsNothing);
    // La scala è chiusa finché non si chiede di cambiare.
    expect(find.bySemanticsLabel('0 · Riposo'), findsNothing);

    await tester.tap(find.text('Cambia'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('0 · Riposo'), findsOneWidget);
  });

  testWidgets('"Non c\'ero" toglie la seduta', (tester) async {
    await _apri(tester, sedute: [ieri]);
    await tester.tap(find.text('Non c\'ero'));
    await tester.pumpAndSettle();
    expect(find.text('Quanto è stato duro?'), findsNothing);
  });

  testWidgets('senza sedute recenti non mostra niente', (tester) async {
    await _apri(tester);
    expect(find.text('Quanto è stato duro?'), findsNothing);
  });
}
