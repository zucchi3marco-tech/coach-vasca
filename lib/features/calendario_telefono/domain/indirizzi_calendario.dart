/// Gli indirizzi con cui il calendario del telefono si collega alle partite
/// e alle gare del coach o dell'atleta. Il calendario vero lo serve la
/// funzione `calendario` di Supabase: qui si compongono solo gli indirizzi
/// a partire dall'indirizzo del progetto e dal codice personale.
library;

/// L'indirizzo https del calendario:
/// `<base>/functions/v1/calendario?c=<codice>`. Quello da copiare e da
/// incollare in un'app calendario qualsiasi. Un "/" finale in
/// [supabaseUrl] si ignora.
String indirizzoCalendario(String supabaseUrl, String codice) {
  final base = supabaseUrl.endsWith('/')
      ? supabaseUrl.substring(0, supabaseUrl.length - 1)
      : supabaseUrl;
  return '$base/functions/v1/calendario?c=$codice';
}

/// Lo stesso indirizzo con lo schema `webcal://`: su iPhone apre
/// direttamente la richiesta di iscrizione al calendario.
String indirizzoWebcal(String supabaseUrl, String codice) {
  return indirizzoCalendario(
    supabaseUrl,
    codice,
  ).replaceFirst(RegExp(r'^https?://'), 'webcal://');
}

/// Il collegamento che apre Google Calendar già pronto ad aggiungere il
/// calendario (su Android compare poi insieme agli altri calendari di
/// Google): l'indirizzo [indirizzoWebcal] va codificato per stare in un
/// parametro.
String indirizzoGoogleCalendar(String supabaseUrl, String codice) {
  return 'https://calendar.google.com/calendar/r?cid='
      '${Uri.encodeComponent(indirizzoWebcal(supabaseUrl, codice))}';
}
