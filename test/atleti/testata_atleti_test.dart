import 'package:coach_vasca/features/allenamenti/application/allenamenti_providers.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/atleti/application/atleti_providers.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/atleti/presentation/atleti_list_screen.dart';
import 'package:coach_vasca/features/gruppi/application/gruppi_providers.dart';
import 'package:coach_vasca/features/gruppi/domain/gruppo.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Atleta _atleta(
  String id,
  String cognome, {
  bool attivo = true,
  String? gruppoId = 'g1',
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: 'Marco',
  cognome: cognome,
  dataNascita: DateTime(2012, 3, 4),
  sport: 'nuoto',
  consensoPrivacyFirmato: true,
  attivo: attivo,
  gruppoId: gruppoId,
);

Widget _app({String? filtroGruppoId = 'g1'}) => ProviderScope(
  overrides: [
    atletiListProvider.overrideWith(
      (ref, filter) => Stream.value([
        _atleta('a1', 'Rossi'),
        _atleta('a2', 'Bianchi'),
        _atleta('a3', 'Verdi', attivo: false),
      ]),
    ),
    gruppiListProvider.overrideWith(
      (ref, clubId) => Stream.value(const [
        Gruppo(id: 'g1', clubId: 'c1', nome: 'Esordienti A', ordine: 0),
      ]),
    ),
    allenamentiListProvider.overrideWith(
      (ref, clubId) => Stream.value(<Allenamento>[]),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    // Come "Riduci movimento": l'acqua della testata e' animata senza fine.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: AtletiListScreen(clubId: 'c1', filtroGruppoId: filtroGruppoId),
  ),
);

void _ignoraOverflowDiTesto() {
  final originale = FlutterError.onError;
  FlutterError.onError = (dettagli) {
    if (dettagli.exceptionAsString().contains('overflowed')) return;
    originale?.call(dettagli);
  };
  addTearDown(() => FlutterError.onError = originale);
}

void main() {
  testWidgets('la testata mostra squadra, attivi, inattivi e "Nuovo atleta"', (
    tester,
  ) async {
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Esordienti A'), findsOneWidget);
    expect(find.text('Atleti'), findsOneWidget);
    expect(find.text('Attivi'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Inattivi'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Nuovo atleta'), findsOneWidget);
  });

  testWidgets('niente doppioni di "Oggi" e niente squadra ripetuta sulle '
      'schede', (tester) async {
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Riepilogo e benessere stanno nella schermata "Oggi".
    expect(find.text('Prossimo allenamento'), findsNothing);
    expect(find.text('Benessere di oggi'), findsNothing);
    // Con una squadra scelta il suo nome compare solo in testata, non
    // ripetuto su ogni atleta (e lo sport non si ripete mai).
    expect(find.textContaining('Esordienti A'), findsOneWidget);
    expect(find.textContaining('Nuoto'), findsNothing);
  });

  testWidgets('gli inattivi compaiono solo toccando il loro numero', (
    tester,
  ) async {
    _ignoraOverflowDiTesto();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Verdi Marco'), findsNothing);
    await tester.tap(find.text('Inattivi'));
    await tester.pumpAndSettle();
    expect(find.text('Verdi Marco'), findsOneWidget);
    expect(find.text('Inattivo'), findsOneWidget);
  });
}
