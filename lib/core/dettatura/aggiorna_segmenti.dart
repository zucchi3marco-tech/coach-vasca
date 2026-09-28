/// Un segmento di `event.results` della Web Speech API: [indice] è la sua
/// posizione nel vettore, [finale] corrisponde a `SpeechRecognitionResult.
/// isFinal`, [testo] alla trascrizione (non ancora normalizzata).
typedef SegmentoRisultato = ({int indice, bool finale, String testo});

/// Il risultato di [aggiornaSegmenti]: i segmenti finali confermati finora
/// (indice → testo) e l'eventuale segmento ancora provvisorio più recente.
typedef SegmentiAggiornati = ({Map<int, String> committati, String interim});

/// Aggiorna i segmenti finali già confermati ([committatiPrima]) con quelli
/// dell'evento corrente ([segmenti]).
///
/// Due difese indipendenti, per due modi diversi in cui il motore vocale
/// del browser duplica (confermati entrambi su dispositivi reali, non solo
/// teorici):
/// 1. Un indice, una volta diventato finale, resta quello per tutta la
///    sessione: se il browser lo ripropone — identico o con una minima
///    differenza — sotto lo STESSO indice, viene ignorato.
/// 2. Se il browser riconferma la stessa frase sotto un indice NUOVO
///    (il motore "rifinalizza" lo stesso pezzo di audio più volte di
///    fila, capita su Android) — quindi la difesa 1 non basta perché
///    l'indice è davvero diverso ogni volta — si scarta anche un nuovo
///    segmento finale il cui testo (normalizzato) coincide con l'ULTIMO
///    segmento già confermato, indipendentemente dal loro indice. Non si
///    confronta con TUTTI i precedenti: una frase genuinamente ripetuta
///    più avanti nella dettatura, con qualcos'altro nel mezzo, resta.
///
/// Pura: non tocca nulla del browser, testabile senza un vero motore di
/// riconoscimento vocale.
SegmentiAggiornati aggiornaSegmenti({
  required Map<int, String> committatiPrima,
  required List<SegmentoRisultato> segmenti,
}) {
  final committati = Map<int, String>.of(committatiPrima);
  var ultimoTesto = committati.isEmpty
      ? null
      : committati[(committati.keys.toList()..sort()).last];
  var interim = '';
  for (final segmento in segmenti) {
    final testo = segmento.testo.trim();
    if (testo.isEmpty) continue;
    if (segmento.finale) {
      if (committati.containsKey(segmento.indice)) continue;
      if (ultimoTesto != null &&
          ultimoTesto.toLowerCase() == testo.toLowerCase()) {
        continue;
      }
      committati[segmento.indice] = testo;
      ultimoTesto = testo;
    } else {
      interim = testo;
    }
  }
  return (committati: committati, interim: interim);
}

/// Il testo dei segmenti confermati, nell'ordine dei loro indici.
String testoCommittato(Map<int, String> committati) {
  final indiciOrdinati = committati.keys.toList()..sort();
  return indiciOrdinati.map((i) => committati[i]!).join(' ');
}
