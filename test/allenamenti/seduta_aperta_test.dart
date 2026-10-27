import 'package:coach_vasca/features/allenamenti/data/seduta_aperta_repository.dart';
import 'package:coach_vasca/features/allenamenti/presentation/avviso_seduta_aperta.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Il server finto: risponde sempre con [stato] e annota le chiamate.
class _SedutaFinta extends SedutaApertaRepository {
  _SedutaFinta(this.stato) : super(null);

  StatoSeduta? stato;
  var aperture = 0;
  var chiusure = 0;

  @override
  Future<StatoSeduta?> apri(String allenamentoId) async {
    aperture++;
    return stato;
  }

  @override
  Future<void> chiudi(String allenamentoId) async => chiusure++;
}

final _edoardo = StatoSeduta(
  versione: 5,
  cambiataNome: 'Edoardo',
  cambiataAt: DateTime(2026, 10, 27, 18, 7),
  altri: [(nome: 'Edoardo', dal: DateTime(2026, 10, 27, 18, 5))],
);

void main() {
  test('dal server: versione, chi l\'ha cambiata e chi la guarda', () {
    final s = StatoSeduta.fromMap({
      'versione': 3,
      'cambiata_nome': 'Edoardo Bonassisa',
      'cambiata_at': '2026-10-27T05:51:07.172476+00:00',
      'cambiata_da_me': false,
      'altri': [
        {'nome': 'Edoardo Bonassisa', 'dal': '2026-10-27T05:50:00+00:00'},
      ],
    });
    expect(s.versione, 3);
    expect(s.altri.single.nome, 'Edoardo Bonassisa');
    expect(s.cambiataDaUnAltro(2), isTrue);
    expect(s.cambiataDaUnAltro(3), isFalse);
    // Senza una versione letta non si sa.
    expect(s.cambiataDaUnAltro(null), isFalse);
    // Una modifica mia non conta.
    expect(
      const StatoSeduta(versione: 4, cambiataDaMe: true).cambiataDaUnAltro(2),
      isFalse,
    );
    expect(StatoSeduta.fromMap({'versione': 0}).altri, isEmpty);
  });

  test('quando è stata cambiata', () {
    final oggi = DateTime(2026, 10, 27, 20);
    expect(
      quandoCambiata(DateTime(2026, 10, 27, 18, 7), oggi: oggi),
      'alle 18:07',
    );
    expect(
      quandoCambiata(DateTime(2026, 10, 26, 9, 5), oggi: oggi),
      'ieri alle 09:05',
    );
    expect(
      quandoCambiata(DateTime(2026, 10, 20, 9, 5), oggi: oggi),
      startsWith('mar 20 ott alle 09:05'),
    );
  });

  Widget app(_SedutaFinta finto, Widget figlio, {Map<String, int>? lette}) =>
      ProviderScope(
        overrides: [
          sedutaApertaRepositoryProvider.overrideWithValue(finto),
          versioniLetteProvider.overrideWithValue(lette ?? {}),
        ],
        child: MaterialApp(
          theme: AppTheme.chiaro,
          home: Scaffold(body: figlio),
        ),
      );

  testWidgets('chi sta modificando la seduta, e alla chiusura si dice', (
    tester,
  ) async {
    final finto = _SedutaFinta(_edoardo);
    // Il telefono ha già letto la versione 5: niente «Aggiorna».
    await tester.pumpWidget(
      app(
        finto,
        const AvvisoSedutaAperta(allenamentoId: 'a1', clubId: 'c1'),
        lette: {'a1': 5},
      ),
    );
    await tester.pump();
    expect(
      find.text('Edoardo la sta modificando (dalle 18:05)'),
      findsOneWidget,
    );
    expect(find.textContaining('Potete lavorare insieme'), findsOneWidget);
    expect(find.text('Aggiorna'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    expect(finto.chiusure, 1);
  });

  testWidgets('un collega l\'ha cambiata mentre era aperta: «Aggiorna»', (
    tester,
  ) async {
    final finto = _SedutaFinta(const StatoSeduta(versione: 4));
    final lette = {'a1': 4};
    await tester.pumpWidget(
      app(
        finto,
        const AvvisoSedutaAperta(
          allenamentoId: 'a1',
          clubId: 'c1',
          ogni: Duration(seconds: 1),
        ),
        lette: lette,
      ),
    );
    await tester.pump();
    // Nessuno la sta guardando e niente è cambiato: niente avviso.
    expect(find.byIcon(Icons.people_alt_outlined), findsNothing);

    finto.stato = StatoSeduta(
      versione: 5,
      cambiataNome: 'Edoardo',
      cambiataAt: DateTime.now(),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.textContaining('Edoardo l\'ha cambiata alle'), findsOneWidget);
    expect(find.text('Aggiorna'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('prima di salvare: «Salva la mia», «Vedi la sua versione»', (
    tester,
  ) async {
    final finto = _SedutaFinta(_edoardo);
    final lette = {'a1': 4};
    final esiti = <bool?>[];
    await tester.pumpWidget(
      app(
        finto,
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async => esiti.add(
              await controllaPrimaDiSalvare(
                context,
                ref,
                allenamentoId: 'a1',
                clubId: 'c1',
              ),
            ),
            child: const Text('Salva'),
          ),
        ),
        lette: lette,
      ),
    );

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('La seduta è cambiata'), findsOneWidget);
    expect(find.textContaining('Edoardo l\'ha cambiata'), findsOneWidget);
    await tester.tap(find.text('Salva la mia'));
    await tester.pumpAndSettle();
    expect(esiti, [true]);
    // Ora lavora sulla versione 5: la stessa non chiede più.
    expect(lette['a1'], 5);
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('La seduta è cambiata'), findsNothing);
    expect(esiti, [true, true]);

    // Intanto ancora un cambio del collega.
    finto.stato = StatoSeduta(
      versione: 6,
      cambiataNome: 'Edoardo',
      cambiataAt: DateTime(2026, 10, 27, 18, 9),
    );
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vedi la sua versione'));
    await tester.pumpAndSettle();
    expect(esiti, [true, true, false]);
  });

  testWidgets('senza rete, o se l\'ultima modifica è mia, si salva e basta', (
    tester,
  ) async {
    for (final stato in [
      null,
      const StatoSeduta(versione: 9, cambiataDaMe: true),
    ]) {
      final finto = _SedutaFinta(stato);
      bool? esito;
      await tester.pumpWidget(
        app(
          finto,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async => esito = await controllaPrimaDiSalvare(
                context,
                ref,
                allenamentoId: 'a1',
                clubId: 'c1',
              ),
              child: const Text('Salva'),
            ),
          ),
          lette: {'a1': 4},
        ),
      );
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('La seduta è cambiata'), findsNothing);
      expect(esito, isTrue);
    }
  });
}
