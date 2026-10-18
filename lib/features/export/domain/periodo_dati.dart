import '../../../core/utils/date_italiane.dart';

/// L'anno in cui comincia la stagione sportiva che contiene [giorno]: la
/// stagione va dal 1 settembre al 31 agosto, quindi da settembre in poi è
/// l'anno stesso, prima è quello prima.
int annoInizioStagione(DateTime giorno) =>
    giorno.month >= 9 ? giorno.year : giorno.year - 1;

/// Quali dati scaricare: tutto, oppure una stagione sportiva.
///
/// Una stagione va dal 1 settembre di [annoInizio] al 31 agosto dell'anno
/// dopo, estremi compresi, contando i giorni di calendario (l'ora non
/// conta).
class PeriodoDati {
  const PeriodoDati.tutto() : annoInizio = null;

  const PeriodoDati.stagione(int this.annoInizio);

  /// L'anno in cui comincia la stagione; null per "Tutto".
  final int? annoInizio;

  bool get eTutto => annoInizio == null;

  /// Il primo giorno della stagione; null per "Tutto".
  DateTime? get dal => annoInizio == null ? null : DateTime(annoInizio!, 9, 1);

  /// L'ultimo giorno della stagione; null per "Tutto".
  DateTime? get al =>
      annoInizio == null ? null : DateTime(annoInizio! + 1, 8, 31);

  /// [giorno] cade nel periodo? Si guarda solo la data, nel fuso del
  /// telefono.
  bool comprende(DateTime giorno) {
    final inizio = dal;
    final fine = al;
    if (inizio == null || fine == null) return true;
    final locale = giorno.isUtc ? giorno.toLocal() : giorno;
    final data = DateTime(locale.year, locale.month, locale.day);
    return !data.isBefore(inizio) && !data.isAfter(fine);
  }

  /// "Tutto", "Stagione 2026-2027".
  String get etichetta =>
      annoInizio == null ? 'Tutto' : 'Stagione $annoInizio-${annoInizio! + 1}';

  /// "Tutti i dati", "dal 01/09/2026 al 31/08/2027".
  String get descrizione => annoInizio == null
      ? 'Tutti i dati'
      : 'dal ${dataNumerica(dal!)} al ${dataNumerica(al!)}';

  @override
  bool operator ==(Object other) =>
      other is PeriodoDati && other.annoInizio == annoInizio;

  @override
  int get hashCode => Object.hash(PeriodoDati, annoInizio);

  @override
  String toString() => 'PeriodoDati($etichetta)';
}

/// I periodi fra cui scegliere: "Tutto" e poi le stagioni, dalla più
/// recente (quella che contiene [oggi]) all'indietro, fino a quella che
/// contiene [daQuando] (di solito il giorno in cui è nato il club). Senza
/// [daQuando], la stagione in corso e la precedente. Al massimo sei
/// stagioni.
List<PeriodoDati> periodiDisponibili(DateTime oggi, {DateTime? daQuando}) {
  const massimoStagioni = 6;
  final corrente = annoInizioStagione(oggi);
  final piuVecchia = daQuando == null
      ? corrente - 1
      : annoInizioStagione(daQuando);
  var primo = piuVecchia;
  if (primo < corrente - (massimoStagioni - 1)) {
    primo = corrente - (massimoStagioni - 1);
  }
  // Un club "nato" dopo oggi (orologio sballato) ha comunque la stagione in
  // corso.
  if (primo > corrente) primo = corrente;
  return [
    const PeriodoDati.tutto(),
    for (var anno = corrente; anno >= primo; anno--) PeriodoDati.stagione(anno),
  ];
}
