import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/stagioni/application/stagioni_providers.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:coach_vasca/features/statistiche/presentation/selettore_stagione.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime.now();

Stagione _stagione(String nome, String? gruppoId) => Stagione(
  id: nome,
  clubId: 'c1',
  nome: nome,
  dataInizio: _oggi.subtract(const Duration(days: 30)),
  dataFine: _oggi.add(const Duration(days: 200)),
  gruppoId: gruppoId,
);

Atleta _atleta(String? gruppoId) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Luca',
  cognome: 'Rossi',
  dataNascita: DateTime(2010),
  sport: 'pallanuoto',
  gruppoId: gruppoId,
  consensoPrivacyFirmato: true,
  attivo: true,
);

Widget _app(
  List<Stagione> stagioni, {
  Atleta? atleta,
  String? idIniziale,
  ValueChanged<Stagione?>? onCambiata,
}) => ProviderScope(
  overrides: [
    stagioniListProvider.overrideWith((ref, clubId) => Stream.value(stagioni)),
  ],
  child: MaterialApp(
    theme: AppTheme.chiaro,
    home: Scaffold(
      body: SelettoreStagione(
        clubId: 'c1',
        atleta: atleta,
        idIniziale: idIniziale,
        onCambiata: onCambiata ?? (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets("un U16 non si vede proporre la stagione dell'U14", (
    tester,
  ) async {
    Stagione? scelta;
    await tester.pumpWidget(
      _app(
        [_stagione('Stagione U14', 'g-u14')],
        atleta: _atleta('g-u16'),
        onCambiata: (s) => scelta = s,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stagione U14'), findsNothing);
    expect(find.textContaining("Non c'è ancora una stagione"), findsOneWidget);
    expect(scelta, isNull);
  });

  testWidgets("a un U16 preseleziona la stagione U16, anche se c'è quella "
      'U14 nelle stesse date', (tester) async {
    Stagione? scelta;
    await tester.pumpWidget(
      _app(
        [
          _stagione('Stagione U14', 'g-u14'),
          _stagione('Stagione U16', 'g-u16'),
        ],
        atleta: _atleta('g-u16'),
        onCambiata: (s) => scelta = s,
      ),
    );
    await tester.pumpAndSettle();

    expect(scelta?.nome, 'Stagione U16');
    expect(find.text('Stagione U14'), findsNothing);
  });

  testWidgets('dal dettaglio di una stagione parte da quella', (tester) async {
    Stagione? scelta;
    await tester.pumpWidget(
      _app(
        [
          _stagione('Stagione U14', 'g-u14'),
          _stagione('Stagione U16', 'g-u16'),
        ],
        idIniziale: 'Stagione U16',
        onCambiata: (s) => scelta = s,
      ),
    );
    await tester.pumpAndSettle();

    expect(scelta?.nome, 'Stagione U16');
  });
}
