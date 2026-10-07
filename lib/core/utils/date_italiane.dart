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

/// "giovedì".
String giornoSettimana(DateTime d) => _giorni[d.weekday - 1];
