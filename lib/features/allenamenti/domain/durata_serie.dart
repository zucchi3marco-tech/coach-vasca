import 'serie.dart';

/// Passo medio della libreria di blocchi (s/100m, foglio Legenda
/// dell'Excel): lo stesso che usa la Edge Function `genera-allenamento`
/// quando non conosce le corsie.
const passoMedioS = 110.0;

/// Il passo di riferimento di un gruppo: quello della sua corsia più
/// lenta (chi arriva per ultimo detta i tempi della seduta), dal primato
/// sui 100 stile libero e dal differenziale T200-T100 quando c'è — gli
/// stessi dati delle corsie del generatore (`assegnaCorsie`).
typedef PassoRiferimento = ({double passo100S, double? differenzialeS});

/// `OFFSET_SOGLIA_B1_S` della Edge Function.
const _offsetSogliaB1S = 3.5;

/// Il passo di nuoto (s/100m) in una zona. Con il [riferimento] del gruppo
/// segue le regole di `passoPerZona` della Edge Function (più lento nelle
/// zone aerobiche, vicino al primato in quelle lattacide); una serie
/// senza zona si conta come A1. Senza riferimento: [passoMedioS].
double passoPerZona(String? zona, PassoRiferimento? riferimento) {
  if (riferimento == null) return passoMedioS;
  final passo100 = riferimento.passo100S;
  // Senza il primato sui 200 (o con uno incoerente, più veloce del passo
  // sui 100) il differenziale si stima dal 100.
  final differenziale = switch (riferimento.differenzialeS) {
    final d? when d >= passo100 => d,
    _ => passo100 * 1.15,
  };
  return switch (zona) {
    null || 'A1' => differenziale + _offsetSogliaB1S + 12,
    'A2' => differenziale + _offsetSogliaB1S + 5,
    'B1' => differenziale + _offsetSogliaB1S,
    'B2' => differenziale,
    'C1' || 'D' => passo100 + 1.5,
    _ => passo100,
  };
}

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
///   della zona per il gruppo ([passoPerZona], il passo medio se non si
///   conosce il gruppo) rallentato per gambe/tecnica — più il recupero
///   scritto o quello tipico della zona.
double secondiPerRipetuta(DatiSerie s, {PassoRiferimento? riferimento}) {
  final durata = s.durataS;
  if (durata != null) return (durata + (s.recuperoS ?? 0)).toDouble();
  final ripartenza = s.ripartenzaS;
  if (ripartenza != null) return ripartenza;
  final distanza = s.distanzaM ?? 0;
  final passo =
      s.passoObiettivoS ??
      passoPerZona(s.zona, riferimento) *
          (fattoreEsecuzione[s.esecuzione] ?? 1);
  return passo * distanza / 100 +
      (s.recuperoS ?? recuperoPredefinito(s.zona, distanza));
}

double secondiSerie(DatiSerie s, {PassoRiferimento? riferimento}) =>
    s.ripetute * secondiPerRipetuta(s, riferimento: riferimento);

/// La durata stimata di un allenamento, in minuti interi.
int minutiStimati(Iterable<DatiSerie> serie, {PassoRiferimento? riferimento}) =>
    (serie.fold<double>(
              0,
              (t, s) => t + secondiSerie(s, riferimento: riferimento),
            ) /
            60)
        .round();
