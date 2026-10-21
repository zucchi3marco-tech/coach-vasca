import 'dart:math' as math;

import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/domain/monotonia.dart';
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

  test('lo strain con il punto delle migliaia', () {
    expect(formattaStrain(812.4), '812');
    expect(formattaStrain(2340.6), '2.341');
    expect(formattaStrain(1234567), '1.234.567');
  });
}
