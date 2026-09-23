/// Unisce quello che c'era già nel campo prima di iniziare ad ascoltare
/// ([prefisso], fisso per tutta la sessione) con il testo della sessione
/// di ascolto corrente ([testoSessione], che [DettatoreVocale] ricostruisce
/// per intero ad ogni aggiornamento — mai un pezzo da sommare al
/// precedente). Pura e idempotente: chiamarla più volte con lo stesso
/// [testoSessione] dà sempre lo stesso risultato, non lo fa crescere —
/// la difesa "lato campo" contro il bug per cui la stessa frase compariva
/// ripetuta più volte quando il browser rimandava lo stesso risultato.
String testoConPrefisso(String prefisso, String testoSessione) =>
    [prefisso, testoSessione].where((t) => t.isNotEmpty).join(' ');
