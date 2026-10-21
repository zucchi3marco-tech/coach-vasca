import 'dart:math' as math;

import '../../../core/utils/giorni.dart';
import '../../allenamenti/domain/volume_allenamento.dart' show lunediDi;
import 'carico_rpe.dart';

/// Sopra questa monotonia i giorni della settimana si somigliano troppo:
/// anche con un carico non alto il rischio di sovraccarico sale (Foster,
/// 1998). Una soglia di riferimento, non una diagnosi.
const sogliaMonotonia = 2.0;

/// Monotonia e strain di sette giorni (Foster, 1998; da Vigør, proposta
/// 12 del «Piano di WaterTactics»): oltre all'ACWR, quanto il carico
/// della settimana è uniforme. Contano acqua, secco e partite, e i giorni
/// senza sedute valgono zero.
class Monotonia {
  const Monotonia({
    required this.carico,
    required this.media,
    required this.deviazione,
  });

  /// Il carico dei sette giorni.
  final double carico;

  /// Il carico medio di un giorno.
  final double media;

  /// La deviazione standard dei sette carichi giornalieri.
  final double deviazione;

  /// I sette giorni hanno tutti lo stesso carico (non zero): la monotonia
  /// non ha un numero, ed è al massimo.
  bool get tuttiUguali => deviazione <= 1e-9;

  /// Media / deviazione standard; null se [tuttiUguali].
  double? get monotonia => tuttiUguali ? null : media / deviazione;

  /// Carico della settimana × monotonia; null se [tuttiUguali].
  double? get strain => switch (monotonia) {
    final m? => carico * m,
    null => null,
  };

  /// Sopra [sogliaMonotonia], o tutti i giorni uguali.
  bool get alta => tuttiUguali || monotonia! > sogliaMonotonia;
}

/// La monotonia dei sette giorni che finiscono con [fine] (compreso);
/// null se in quei giorni non c'è carico.
Monotonia? monotoniaSettimana(
  Iterable<CaricoSeduta> sedute, {
  required DateTime fine,
}) {
  final ultimo = soloData(fine);
  final primo = aggiungiGiorni(ultimo, -6);
  final giorni = List<double>.filled(7, 0);
  for (final s in sedute) {
    if (s.giorno.isBefore(primo) || s.giorno.isAfter(ultimo)) continue;
    giorni[giorniTra(primo, s.giorno)] += s.totale;
  }
  final carico = giorni.fold(0.0, (a, b) => a + b);
  if (carico <= 0) return null;
  final media = carico / 7;
  final varianza =
      giorni.fold(0.0, (a, g) => a + (g - media) * (g - media)) / 7;
  return Monotonia(
    carico: carico,
    media: media,
    deviazione: math.sqrt(varianza),
  );
}

/// La monotonia degli ultimi sette giorni a [oggi] (di solito adesso) e il
/// solito strain: la media di quello delle quattro settimane prima (i
/// sette giorni che finiscono 7, 14, 21 e 28 giorni prima), contando solo
/// quelle con un carico e uno strain; null se non ce n'è nessuna.
({Monotonia? adesso, double? strainSolito}) monotoniaDiOggi(
  Iterable<CaricoSeduta> sedute, {
  DateTime? oggi,
}) {
  final fine = soloData(oggi ?? DateTime.now());
  final prima = [
    for (var i = 1; i <= 4; i++)
      ?monotoniaSettimana(sedute, fine: aggiungiGiorni(fine, -7 * i))?.strain,
  ];
  return (
    adesso: monotoniaSettimana(sedute, fine: fine),
    strainSolito: prima.isEmpty
        ? null
        : prima.fold(0.0, (a, b) => a + b) / prima.length,
  );
}

/// La monotonia di ognuna delle ultime [settimane] settimane, da lunedì a
/// domenica, come `caricoPerSettimana`; quella di [oggi], non ancora
/// finita, è null (i giorni che mancano varrebbero zero): per quella c'è
/// [monotoniaDiOggi].
List<({DateTime lunedi, Monotonia? monotonia})> monotoniaPerSettimana(
  Iterable<CaricoSeduta> sedute, {
  int settimane = 8,
  DateTime? oggi,
}) {
  final questa = lunediDi(oggi ?? DateTime.now());
  return [
    for (var i = settimane - 1; i >= 0; i--)
      (
        lunedi: aggiungiGiorni(questa, -7 * i),
        monotonia: i == 0
            ? null
            : monotoniaSettimana(
                sedute,
                fine: aggiungiGiorni(questa, -7 * i + 6),
              ),
      ),
  ];
}

/// "1,8" (una cifra dopo la virgola); "tutti i giorni uguali" senza numero.
/// Lo strain si scrive come un carico (`formattaCarico`).
String formattaMonotonia(Monotonia m) => switch (m.monotonia) {
  final v? => v.toStringAsFixed(1).replaceAll('.', ','),
  null => 'tutti i giorni uguali',
};
