import 'dart:math' as math;

/// Un giorno della curva Banister: carico di quel giorno e i tre valori
/// derivati (fitness, fatica, forma = fitness - fatica).
class PuntoBanister {
  const PuntoBanister({
    required this.data,
    required this.carico,
    required this.fitness,
    required this.fatica,
  });

  final DateTime data;
  final double carico;
  final double fitness;
  final double fatica;

  double get forma => fitness - fatica;
}

/// Modello Fitness-Fatigue di Banister (lo stesso principio di CTL/ATL/TSB
/// usato da TrainingPeaks): ogni giorno la fitness e la fatica del giorno
/// prima decadono in modo esponenziale e si somma il carico del giorno.
/// Costanti di tempo classiche: 42 giorni per la fitness (adattamento
/// lento), 7 giorni per la fatica (recupero rapido).
///
/// [caricoPerGiorno] deve avere le chiavi normalizzate a mezzanotte (solo
/// anno/mese/giorno). La curva viene estesa fino a oggi anche se l'ultimo
/// allenamento e' nel passato, cosi' si vede il decadimento durante lo
/// scarico pre-gara.
List<PuntoBanister> calcolaBanister(
  Map<DateTime, double> caricoPerGiorno, {
  double tauFitness = 42,
  double tauFatica = 7,
}) {
  if (caricoPerGiorno.isEmpty) return [];

  final giorni = caricoPerGiorno.keys.toList()..sort();
  final oggi = DateTime.now();
  final oggiNormalizzato = DateTime(oggi.year, oggi.month, oggi.day);
  final fine = oggiNormalizzato.isAfter(giorni.last)
      ? oggiNormalizzato
      : giorni.last;

  final decayFitness = math.exp(-1 / tauFitness);
  final decayFatica = math.exp(-1 / tauFatica);

  var fitness = 0.0;
  var fatica = 0.0;
  final punti = <PuntoBanister>[];
  for (
    var giorno = giorni.first;
    !giorno.isAfter(fine);
    giorno = giorno.add(const Duration(days: 1))
  ) {
    final carico = caricoPerGiorno[giorno] ?? 0.0;
    fitness = fitness * decayFitness + carico;
    fatica = fatica * decayFatica + carico;
    punti.add(
      PuntoBanister(data: giorno, carico: carico, fitness: fitness, fatica: fatica),
    );
  }
  return punti;
}
