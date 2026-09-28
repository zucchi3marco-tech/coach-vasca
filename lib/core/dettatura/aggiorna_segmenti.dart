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
/// Verificato su un dispositivo reale (log grezzo mandato dal coach):
/// alcuni motori vocali (osservato su Android) non usano `isFinal` come
/// promesso dallo standard — non mandano mai un risultato provvisorio,
/// ogni aggiornamento arriva già segnato come definitivo, sotto un
/// indice sempre nuovo, anche quando è solo la stessa frase con una
/// parola in più ("Quattrocento" → "Quattrocento metri" → "Quattrocento
/// metri di" ..., ciascuno un indice diverso, tutti "finali"). Trattarli
/// come frasi separate (comportamento corretto per un browser che li usa
/// bene) le accumula tutte invece di tenere solo l'ultima.
///
/// La difesa: quando un nuovo segmento finale, confrontato senza
/// maiuscole, è la CRESCITA del segmento finale confermato più di
/// recente (lo stesso testo, o quel testo seguito da altro), sostituisce
/// quella voce invece di aggiungersi come frase nuova. Una frase
/// genuinamente diversa — che non prosegue quella precedente — resta
/// comunque una voce a sé.
///
/// Pura: non tocca nulla del browser, testabile senza un vero motore di
/// riconoscimento vocale.
SegmentiAggiornati aggiornaSegmenti({
  required Map<int, String> committatiPrima,
  required List<SegmentoRisultato> segmenti,
}) {
  final committati = Map<int, String>.of(committatiPrima);
  int? chiaveAttiva = committati.isEmpty
      ? null
      : (committati.keys.toList()..sort()).last;
  var interim = '';
  for (final segmento in segmenti) {
    final testo = segmento.testo.trim();
    if (testo.isEmpty) continue;
    if (segmento.finale) {
      final ultimoTesto = chiaveAttiva == null
          ? null
          : committati[chiaveAttiva];
      if (ultimoTesto != null &&
          testo.toLowerCase().startsWith(ultimoTesto.toLowerCase())) {
        committati[chiaveAttiva!] = testo;
      } else {
        committati[segmento.indice] = testo;
        chiaveAttiva = segmento.indice;
      }
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
