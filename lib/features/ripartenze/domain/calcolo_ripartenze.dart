/// Calcolo di passo e ripartenza per zona di lavoro, a partire dal passo
/// di riferimento sui 100 stile libero e dal differenziale di gara
/// T200-T100 di una corsia (vedi `corsie_service.dart`, riusato senza
/// modifiche per dividere il gruppo in corsie).
///
/// Formule fornite dal coach (documento "CODICI DI COMUNICAZIONE" +
/// chiarimenti 2026-10-01): dove il documento non dava un numero preciso
/// (il recupero fisso per A1/A2/B2/C1/C2, che il coach aveva specificato
/// solo per B1) si usa una stima di partenza dal punto medio dei range
/// già descritti in `tipo_lavoro.dart` — **da calibrare con l'uso reale**,
/// non è una formula del coach. Tolta la classificazione dinamica del
/// profilo atleta (fondista/mezzofondista/velocista): le soglie fornite
/// erano tarate su un differenziale 10 volte più piccolo di quello reale
/// (errore confermato dal coach), quindi la soglia B1 usa sempre lo
/// stesso offset fisso (+3.5s, "mezzofondista").
library;

/// Una distanza di frazionamento con il coefficiente di correzione del
/// passo (solo per la zona B1 — le altre zone scalano linearmente) e il
/// recupero fisso da sommare al tempo target per la zona B1 e per la
/// zona D (ritmo gara): tabella del coach.
class DistanzaFrazionamento {
  const DistanzaFrazionamento({
    required this.distanzaM,
    required this.coefficienteB1,
    required this.recuperoFissoS,
  });

  final int distanzaM;
  final double coefficienteB1;
  final double recuperoFissoS;
}

const distanzeFrazionamento = [
  DistanzaFrazionamento(
    distanzaM: 50,
    coefficienteB1: 0.900,
    recuperoFissoS: 12,
  ),
  DistanzaFrazionamento(
    distanzaM: 100,
    coefficienteB1: 0.950,
    recuperoFissoS: 15,
  ),
  DistanzaFrazionamento(
    distanzaM: 150,
    coefficienteB1: 0.965,
    recuperoFissoS: 18,
  ),
  DistanzaFrazionamento(
    distanzaM: 200,
    coefficienteB1: 0.975,
    recuperoFissoS: 20,
  ),
  DistanzaFrazionamento(
    distanzaM: 300,
    coefficienteB1: 0.990,
    recuperoFissoS: 25,
  ),
  DistanzaFrazionamento(
    distanzaM: 400,
    coefficienteB1: 1.010,
    recuperoFissoS: 30,
  ),
  DistanzaFrazionamento(
    distanzaM: 500,
    coefficienteB1: 1.020,
    recuperoFissoS: 30,
  ),
];

/// Recupero fisso di default per le zone senza una tabella per distanza
/// (stima di partenza, non una formula del coach — vedi doc del file).
const _recuperoFissoDefaultPerZona = {
  'A1': 20.0,
  'A2': 15.0,
  'B2': 60.0,
  'C1': 60.0,
  'C2': 180.0,
};

/// Offset di soglia fisso per B1 ("mezzofondista"): la classificazione
/// dinamica per profilo atleta è stata tolta, vedi doc del file.
const _offsetSogliaB1S = 3.5;

double arrotondaSu5s(double secondi) => (secondi / 5).ceil() * 5.0;

DistanzaFrazionamento _distanzaPiuVicina(int distanzaM) =>
    distanzeFrazionamento.reduce(
      (a, b) =>
          (a.distanzaM - distanzaM).abs() <= (b.distanzaM - distanzaM).abs()
          ? a
          : b,
    );

/// Passo base (s/100m) per una zona, dato il passo di riferimento sui
/// 100 ([passo100S]) e il differenziale di gara T200-T100
/// ([differenzialeS]) della corsia. `null` per C1/C2 se manca
/// [passo100S], per B1/B2/A1/A2 se manca [differenzialeS]; sempre `null`
/// per 'C3' (lavoro di velocità pura, non legato al passo100) e per 'D'
/// (vedi [tempoGaraStimato], usa un modello diverso).
double? passoBasePerZona(
  String zona, {
  required double? passo100S,
  required double? differenzialeS,
}) {
  switch (zona) {
    case 'B2':
      return differenzialeS;
    case 'B1':
      return differenzialeS == null ? null : differenzialeS + _offsetSogliaB1S;
    case 'A2':
      final b1 = passoBasePerZona(
        'B1',
        passo100S: passo100S,
        differenzialeS: differenzialeS,
      );
      return b1 == null ? null : b1 + 5.0;
    case 'A1':
      final b1 = passoBasePerZona(
        'B1',
        passo100S: passo100S,
        differenzialeS: differenzialeS,
      );
      return b1 == null ? null : b1 + 12.0;
    case 'C1':
      return passo100S == null ? null : passo100S + 1.5;
    case 'C2':
      return passo100S;
    default:
      return null;
  }
}

/// Velocità critica di nuoto (CSS, m/s) dal differenziale T200-T100 —
/// modello a due punti: CSS = Δdistanza / Δtempo = 100 / differenzialeS.
double cssMetriAlSecondo(double differenzialeS) => 100 / differenzialeS;

/// Riserva anaerobica (D', metri): quanta distanza "in più" rispetto a
/// una velocità costante pari al CSS l'atleta riesce a coprire grazie al
/// meccanismo anaerobico, sui 200m massimali.
double riservaAnaerobicaMetri({
  required double differenzialeS,
  required double tempo200S,
}) => 200 - cssMetriAlSecondo(differenzialeS) * tempo200S;

/// Tempo di gara stimato per la zona D (ritmo gara) a una distanza
/// qualunque, dal modello CSS: tempo = (distanza - riservaM) / CSS.
/// Autoconsistente: applicato a d=100 o d=200 restituisce esattamente il
/// tempo da cui è stato ricavato il differenziale.
double tempoGaraStimato({
  required double differenzialeS,
  required double tempo200S,
  required int distanzaM,
}) {
  final css = cssMetriAlSecondo(differenzialeS);
  final riservaM = riservaAnaerobicaMetri(
    differenzialeS: differenzialeS,
    tempo200S: tempo200S,
  );
  return (distanzaM - riservaM) / css;
}

/// Passo e ripartenza per una corsia, in una zona e a una distanza di
/// frazionamento scelte. `(null, null)` se la zona è 'C3' (nessun
/// calcolo: lavoro di velocità pura) o se mancano i dati necessari
/// (es. zona 'D' senza [tempo200S], o zona che richiede il differenziale
/// quando la corsia non ne ha uno).
({double? passoS, double? ripartenzaS}) ripartenzaEPasso({
  required String zona,
  required double? passo100S,
  required double? differenzialeS,
  double? tempo200S,
  required int distanzaM,
}) {
  if (zona == 'C3') return (passoS: null, ripartenzaS: null);

  if (zona == 'D') {
    if (differenzialeS == null || tempo200S == null) {
      return (passoS: null, ripartenzaS: null);
    }
    final tempoTarget = tempoGaraStimato(
      differenzialeS: differenzialeS,
      tempo200S: tempo200S,
      distanzaM: distanzaM,
    );
    final recupero = _distanzaPiuVicina(distanzaM).recuperoFissoS;
    return (
      passoS: tempoTarget * 100 / distanzaM,
      ripartenzaS: arrotondaSu5s(tempoTarget + recupero),
    );
  }

  final passoBase = passoBasePerZona(
    zona,
    passo100S: passo100S,
    differenzialeS: differenzialeS,
  );
  if (passoBase == null) return (passoS: null, ripartenzaS: null);

  final distanza = _distanzaPiuVicina(distanzaM);
  final coefficiente = zona == 'B1' ? distanza.coefficienteB1 : 1.0;
  final passoCorretto = passoBase * coefficiente;
  final tempoTarget = passoCorretto * distanzaM / 100;
  final recupero = zona == 'B1'
      ? distanza.recuperoFissoS
      : (_recuperoFissoDefaultPerZona[zona] ?? distanza.recuperoFissoS);

  return (
    passoS: passoCorretto,
    ripartenzaS: arrotondaSu5s(tempoTarget + recupero),
  );
}
