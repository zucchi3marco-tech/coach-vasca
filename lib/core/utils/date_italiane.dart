import 'giorni.dart';

const _giorni = [
  'lunedì',
  'martedì',
  'mercoledì',
  'giovedì',
  'venerdì',
  'sabato',
  'domenica',
];

/// Mesi abbreviati in minuscolo ("gen", "feb", ...): per le date estese
/// e per il riquadro data delle schede (in maiuscolo).
const mesiBrevi = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

const _mesiInteri = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// "19 ottobre 2026": la versione dell'app e le novità.
String dataLunga(DateTime d) =>
    '${d.day} ${_mesiInteri[d.month - 1]} ${d.year}';

/// "Ottobre 2026": il mese per esteso con l'anno, come titolo.
String meseAnno(DateTime d) {
  final mese = _mesiInteri[d.month - 1];
  return '${mese[0].toUpperCase()}${mese.substring(1)} ${d.year}';
}

/// "19 ottobre": il giorno e il mese per esteso, senza l'anno.
String giornoMese(DateTime d) => '${d.day} ${_mesiInteri[d.month - 1]}';

/// "18:42".
String oraMinuti(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

/// "19 ottobre alle 18:42": quando è successo qualcosa, che si legga
/// anche giorni dopo (a differenza di [quandoFa]).
String dataEOra(DateTime d) => '${giornoMese(d)} alle ${oraMinuti(d)}';

/// "giovedì 8 ott".
String dataEstesa(DateTime d) =>
    '${_giorni[d.weekday - 1]} ${d.day} ${mesiBrevi[d.month - 1]}';

/// "gio 8 ott": per le righe dove lo spazio e' poco.
String dataCompatta(DateTime d) =>
    '${_giorni[d.weekday - 1].substring(0, 3)} ${d.day} '
    '${mesiBrevi[d.month - 1]}';

/// "08/10/2026".
String dataNumerica(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

/// "Oggi", "Domani", "Tra 5 giorni"; per il passato "Ieri", "5 giorni fa".
String traQuanto(DateTime d, {DateTime? oggi}) {
  final giorni = giorniTra(oggi ?? DateTime.now(), d);
  return switch (giorni) {
    < -1 => '${-giorni} giorni fa',
    -1 => 'Ieri',
    0 => 'Oggi',
    1 => 'Domani',
    _ => 'Tra $giorni giorni',
  };
}

/// Quanto tempo fa è successo qualcosa, come lo direbbe un allenatore:
/// "adesso", "25 minuti fa", "oggi alle 18:30", "ieri alle 18:30", "12 ott
/// alle 18:30". [momento] e [adesso] sono nello stesso fuso (di solito
/// quello del telefono).
String quandoFa(DateTime momento, {DateTime? adesso}) {
  final ora = adesso ?? DateTime.now();
  final minuti = ora.difference(momento).inMinutes;
  if (minuti < 1) return 'adesso';
  if (minuti < 60) return minuti == 1 ? '1 minuto fa' : '$minuti minuti fa';
  final alle =
      '${momento.hour.toString().padLeft(2, '0')}:'
      '${momento.minute.toString().padLeft(2, '0')}';
  final giorni = giorniTra(momento, ora);
  if (giorni <= 0) return 'oggi alle $alle';
  if (giorni == 1) return 'ieri alle $alle';
  return '${momento.day} ${mesiBrevi[momento.month - 1]} alle $alle';
}

/// "giovedì".
String giornoSettimana(DateTime d) => _giorni[d.weekday - 1];

/// "Domani, ore 15:00" (o solo "Domani" senza ora): quando e a che ora
/// sono una sola informazione, non due da separare con un puntino.
String quandoConOra(DateTime d, String? ora) =>
    ora == null || ora.trim().isEmpty
    ? traQuanto(d)
    : '${traQuanto(d)}, ore ${ora.trim()}';

/// "Domani, giovedì 8 ott".
String quandoEsteso(DateTime d) => '${traQuanto(d)}, ${dataEstesa(d)}';

/// "a ottobre", "ad aprile", "ad agosto": il mese con la preposizione.
String inMese(DateTime d) {
  final mese = _mesiInteri[d.month - 1];
  return '${mese.startsWith('a') ? 'ad' : 'a'} $mese';
}
