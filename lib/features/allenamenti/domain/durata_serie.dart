import 'serie.dart';

/// Passo medio della libreria di blocchi (s/100m, foglio Legenda
/// dell'Excel): lo stesso che usa la Edge Function `genera-allenamento`
/// quando non conosce le corsie.
const passoMedioS = 110.0;

/// Gambe e tecnica sono più lente del nuoto completo: stessi fattori di
/// `FATTORE_ESECUZIONE` nella Edge Function (stima di partenza, non una
/// formula del coach — da calibrare con l'uso reale).
const fattoreEsecuzione = <String, double>{
  'gambe': 1.3,
  'tecnica': 1.15,
  'braccia': 1.05,
  'pull': 1.05,
};

/// Recupero fra le ripetute quando la serie non lo dice: stessi valori di
/// `RECUPERO_PER_ZONA` / `RECUPERO_PER_DISTANZA` nella Edge Function (B1
/// e D, e le serie senza zona, guardano la distanza).
const _recuperoPerZona = <String, int>{
  'A1': 20,
  'A2': 15,
  'B2': 60,
  'C1': 60,
  'C2': 180,
  'C3': 60,
};
const _recuperoPerDistanza = <(int, int)>[
  (50, 12),
  (100, 15),
  (150, 18),
  (200, 20),
  (300, 25),
  (400, 30),
  (500, 30),
];

int recuperoPredefinito(String? zona, int distanzaM) {
  final perZona = _recuperoPerZona[zona];
  if (perZona != null) return perZona;
  return _recuperoPerDistanza
      .reduce(
        (a, b) => (b.$1 - distanzaM).abs() < (a.$1 - distanzaM).abs() ? b : a,
      )
      .$2;
}

/// Quanto dura **una** ripetuta, recupero compreso, in secondi.
///
/// - Serie a tempo: la durata più il recupero scritto.
/// - Con la ripartenza: la ripartenza (comprende già il recupero).
/// - Altrimenti: la distanza al passo obiettivo — o, senza, al passo
///   medio rallentato per gambe/tecnica — più il recupero scritto o
///   quello tipico della zona.
double secondiPerRipetuta(DatiSerie s) {
  final durata = s.durataS;
  if (durata != null) return (durata + (s.recuperoS ?? 0)).toDouble();
  final ripartenza = s.ripartenzaS;
  if (ripartenza != null) return ripartenza;
  final distanza = s.distanzaM ?? 0;
  final passo =
      s.passoObiettivoS ?? passoMedioS * (fattoreEsecuzione[s.esecuzione] ?? 1);
  return passo * distanza / 100 +
      (s.recuperoS ?? recuperoPredefinito(s.zona, distanza));
}

double secondiSerie(DatiSerie s) => s.ripetute * secondiPerRipetuta(s);

/// La durata stimata di un allenamento, in minuti interi.
int minutiStimati(Iterable<DatiSerie> serie) =>
    (serie.fold<double>(0, (t, s) => t + secondiSerie(s)) / 60).round();
