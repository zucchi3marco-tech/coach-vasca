/// Ricostruisce il testo della sessione dai segmenti restituiti dal
/// browser (uno per voce di `event.results`), scartando quelli vuoti e i
/// duplicati consecutivi.
///
/// Il riconoscimento vocale di Chrome (`continuous: true`) a volte
/// "finalizza" due o più volte di fila lo stesso segmento nello stesso
/// evento — un difetto del browser, non nostro — che altrimenti finirebbe
/// ripetuto nel testo ("la stessa frase trascritta molte volte",
/// segnalato più volte dal coach). Confrontare solo con il segmento
/// appena aggiunto (non con tutti i precedenti) collassa una ripetizione
/// lunga quanto vuole il browser, senza impedire che la stessa frase
/// torni più avanti se il coach la ripete davvero in un punto diverso
/// della dettatura.
String ricostruisciTrascrizione(
  Iterable<String> segmentiGrezzi, {
  String separatore = ' ',
}) {
  final pezzi = <String>[];
  for (final grezzo in segmentiGrezzi) {
    final pezzo = grezzo.trim();
    if (pezzo.isEmpty) continue;
    if (pezzi.isNotEmpty && pezzi.last.toLowerCase() == pezzo.toLowerCase()) {
      continue;
    }
    pezzi.add(pezzo);
  }
  return pezzi.join(separatore);
}
