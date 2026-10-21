import 'dart:math' as math;

import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/domain/monotonia.dart';
import 'package:coach_vasca/features/carico/presentation/carico_settimane.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CaricoSeduta _seduta(
  DateTime giorno, {
  double acqua = 0,
  double secco = 0,
  double partita = 0,
}) => CaricoSeduta(
  giorno: giorno,
  tipo: partita > 0 ? 'partita' : 'allenamento',
  eventoId: '${giorno.toIso8601String()}-$acqua-$secco-$partita',
  minuti: 60,
  rpe: 5,
  stimato: false,
  acqua: acqua,
  secco: secco,
  partita: partita,
);

void main() {
  // Domenica 18 ottobre 2026: la settimana va da lunedì 12.
  final domenica = DateTime(2026, 10, 18);
  DateTime giorno(int indietro) =>
      DateTime(domenica.year, domenica.month, domenica.day - indietro);

  test('il conto di Foster: media / deviazione standard, strain', () {
    // Lun 300, mer 400 + 100 a secco, sab 600 di partita: 1400 in tutto.
    final sedute = [
      _seduta(giorno(6), acqua: 300),
      _seduta(giorno(4), acqua: 400),
      _seduta(giorno(4), secco: 100),
      _seduta(giorno(1), partita: 600),
    ];
    final m = monotoniaSettimana(sedute, fine: domenica)!;
    const giorni = [300.0, 0, 500, 0, 0, 600, 0];
    const media = 1400 / 7;
    final ds = math.sqrt(
      giorni.fold(0.0, (a, g) => a + (g - media) * (g - media)) / 7,
    );
    expect(m.carico, 1400);
    expect(m.media, closeTo(media, 1e-9));
    expect(m.deviazione, closeTo(ds, 1e-9));
    expect(m.monotonia, closeTo(media / ds, 1e-9));
    expect(m.strain, closeTo(1400 * media / ds, 1e-6));
    expect(m.alta, isFalse);
    expect(formattaMonotonia(m), '0,8');
  });

  test('sedute di fuori dai sette giorni non contano', () {
    final m = monotoniaSettimana([
      _seduta(giorno(7), acqua: 999),
      _seduta(giorno(0), acqua: 100),
      _seduta(giorno(-1), acqua: 999),
    ], fine: domenica)!;
    expect(m.carico, 100);
  });

  test('senza carico niente; tutti i giorni uguali è al massimo', () {
    expect(monotoniaSettimana(const [], fine: domenica), isNull);
    final uguali = monotoniaSettimana([
      for (var i = 0; i < 7; i++) _seduta(giorno(i), acqua: 300),
    ], fine: domenica)!;
    expect(uguali.tuttiUguali, isTrue);
    expect(uguali.monotonia, isNull);
    expect(uguali.strain, isNull);
    expect(uguali.alta, isTrue);
    expect(formattaMonotonia(uguali), 'tutti i giorni uguali');
  });

  test('sei giorni quasi uguali: sopra 2', () {
    final m = monotoniaSettimana([
      for (var i = 1; i < 7; i++) _seduta(giorno(i), acqua: 300 + i * 5.0),
    ], fine: domenica)!;
    expect(m.monotonia, greaterThan(sogliaMonotonia));
    expect(m.alta, isTrue);
  });

  test('oggi e il solito strain delle quattro settimane prima', () {
    final sedute = [
      // Questa settimana e ognuna delle quattro prima: lunedì e giovedì.
      for (var s = 0; s < 5; s++) ...[
        _seduta(giorno(6 + 7 * s), acqua: 400),
        _seduta(giorno(3 + 7 * s), acqua: 200.0 + 100 * s),
      ],
    ];
    final r = monotoniaDiOggi(sedute, oggi: domenica);
    expect(r.adesso!.carico, 600);
    final prima = [
      for (var s = 1; s <= 4; s++)
        monotoniaSettimana(sedute, fine: giorno(7 * s))!.strain!,
    ];
    expect(r.strainSolito, closeTo(prima.reduce((a, b) => a + b) / 4, 1e-6));
    expect(monotoniaDiOggi(const [], oggi: domenica).strainSolito, isNull);
  });

  test('per settimana: da lunedì a domenica, quella in corso vuota', () {
    final mercoledi = DateTime(2026, 10, 21);
    final sedute = [
      _seduta(DateTime(2026, 10, 12), acqua: 300),
      _seduta(DateTime(2026, 10, 15), acqua: 500),
      _seduta(DateTime(2026, 10, 20), acqua: 400),
    ];
    final settimane = monotoniaPerSettimana(
      sedute,
      settimane: 3,
      oggi: mercoledi,
    );
    expect(settimane.map((s) => s.lunedi), [
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
    ]);
    expect(settimane[0].monotonia, isNull);
    expect(settimane[1].monotonia!.carico, 800);
    expect(settimane[2].monotonia, isNull);
  });

  group('a schermo, a 360 px', () {
    Future<void> apri(WidgetTester tester, Widget figlio, ThemeData tema) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: tema,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: figlio,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final (nome, tema) in [
      ('chiaro', AppTheme.chiaro),
      ('scuro', AppTheme.scuro),
    ]) {
      testWidgets('il riquadro: monotonia, strain e il solito ($nome)', (
        tester,
      ) async {
        final simili = monotoniaSettimana([
          for (var i = 1; i < 7; i++) _seduta(giorno(i), acqua: 300 + i * 5.0),
        ], fine: domenica)!;
        await apri(
          tester,
          PannelloMonotonia(monotonia: simili, strainSolito: 2100),
          tema,
        );
        expect(find.text(formattaMonotonia(simili)), findsOneWidget);
        expect(find.text('Giorni troppo simili'), findsOneWidget);
        expect(
          find.textContaining('Strain ${formattaCarico(simili.strain!)}'),
          findsOneWidget,
        );
        expect(find.textContaining('il solito 2.100'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('senza sedute negli ultimi 7 giorni', (tester) async {
      await apri(
        tester,
        const PannelloMonotonia(monotonia: null, strainSolito: null),
        AppTheme.chiaro,
      );
      expect(
        find.text('Negli ultimi 7 giorni non ci sono sedute.'),
        findsOneWidget,
      );
    });

    testWidgets('una settimana passata dice la sua monotonia', (tester) async {
      // Mercoledì 21: la settimana scelta all'inizio è questa; si tocca
      // quella prima (dal 12).
      await apri(
        tester,
        CaricoSettimane(
          oggi: DateTime(2026, 10, 21),
          settimane: 2,
          sedute: [
            _seduta(DateTime(2026, 10, 12), acqua: 300),
            _seduta(DateTime(2026, 10, 14), acqua: 500),
            _seduta(DateTime(2026, 10, 20), acqua: 400),
          ],
        ),
        AppTheme.chiaro,
      );
      expect(find.textContaining('Monotonia'), findsNothing);
      await tester.tap(find.text('12 ott'));
      await tester.pump();
      expect(find.textContaining('Monotonia 0,6 · strain'), findsOneWidget);
    });
  });
}
