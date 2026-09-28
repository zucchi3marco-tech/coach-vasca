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
/// Un indice, una volta diventato finale, resta quello per tutta la
/// sessione: se il browser lo ripropone — identico o con una minima
/// differenza (uno spazio, una maiuscola) — in questo stesso evento o in
/// uno successivo, in coda o intercalato ad altro, viene ignorato. Questo
/// è il difetto reale di Chrome in modalità `continuous`: non ripropone
/// sempre il duplicato subito consecutivo, quindi un confronto solo con
/// "l'ultimo pezzo aggiunto" (come faceva la versione precedente di
/// questa logica) non basta a scartarlo sempre.
///
/// Pura: non tocca nulla del browser, testabile senza un vero motore di
/// riconoscimento vocale.
SegmentiAggiornati aggiornaSegmenti({
  required Map<int, String> committatiPrima,
  required List<SegmentoRisultato> segmenti,
}) {
  final committati = Map<int, String>.of(committatiPrima);
  var interim = '';
  for (final segmento in segmenti) {
    final testo = segmento.testo.trim();
    if (testo.isEmpty) continue;
    if (segmento.finale) {
      committati.putIfAbsent(segmento.indice, () => testo);
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
