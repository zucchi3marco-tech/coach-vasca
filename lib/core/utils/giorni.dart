/// Calcoli sui giorni di calendario che reggono il cambio dell'ora.
///
/// In Italia l'ultima domenica di marzo dura 23 ore e l'ultima di ottobre
/// 25: `data.add(Duration(days: 1))` in quelle settimane non arriva alla
/// mezzanotte del giorno dopo ma alle 23:00 o all'01:00, e
/// `b.difference(a).inDays` fra due mezzanotti puo' dare un giorno in
/// meno. Qui si lavora sempre su anno/mese/giorno.
library;

/// [data] spostata di [giorni] giorni di calendario, alla stessa ora.
DateTime aggiungiGiorni(DateTime data, int giorni) => DateTime(
  data.year,
  data.month,
  data.day + giorni,
  data.hour,
  data.minute,
  data.second,
);

/// La mezzanotte del giorno di [data].
DateTime soloData(DateTime data) => DateTime(data.year, data.month, data.day);

/// Quanti giorni di calendario da [da] ad [a] (negativo se [a] e' prima).
int giorniTra(DateTime da, DateTime a) => DateTime.utc(
  a.year,
  a.month,
  a.day,
).difference(DateTime.utc(da.year, da.month, da.day)).inDays;
