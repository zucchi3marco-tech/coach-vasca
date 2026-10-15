import 'atleta.dart';

/// Alcuni atleti si allenano certi giorni con la loro squadra e altri con
/// un'altra (richiesta del coach 2026-10-15): nella scheda resta la loro
/// squadra, in più "Si allena anche con" un'altra squadra nei giorni
/// segnati ([Atleta.altroGruppoId], [Atleta.giorniAltroGruppo]).
///
/// - **Atteso** ([attesoA]): quei giorni agli allenamenti dell'altra
///   squadra e non a quelli della sua; gli altri giorni alla sua. Conta per
///   le presenze e le loro percentuali.
/// - **Vede** ([vedeGruppo]): gli allenamenti, le serie e le partite di
///   tutte e due, ogni giorno (la stessa regola nel database,
///   `nel_gruppo_atleta`).
extension SquadreAtleta on Atleta {
  /// Si allena anche con un'altra squadra.
  bool get conAltraSquadra => altroGruppoId != null;

  /// Un record del gruppo [gruppo] (null: di tutto il club) è anche per
  /// lui? Senza squadra vede tutto, come prima.
  bool vedeGruppo(String? gruppo) =>
      gruppo == null ||
      gruppoId == null ||
      gruppo == gruppoId ||
      gruppo == altroGruppoId;

  /// Il giorno [data] si allena con l'altra squadra.
  bool conAltraSquadraIl(DateTime data) =>
      altroGruppoId != null && giorniAltroGruppo.contains(data.weekday);

  /// È atteso all'allenamento del gruppo [gruppo] del giorno [data]? Un
  /// allenamento di tutto il club è per tutti; un atleta senza squadra è
  /// atteso dappertutto, come prima.
  bool attesoA(String? gruppo, DateTime data) {
    if (gruppo == null || gruppoId == null) return true;
    if (conAltraSquadraIl(data)) return gruppo == altroGruppoId;
    return gruppo == gruppoId;
  }
}

/// I nomi dei giorni, nell'ordine dei chip: "lun", "mar"…
const nomiGiorni = ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'];

/// "mar, gio": i giorni segnati.
String etichettaGiorni(List<int> giorni) => [
  for (final g in giorni)
    if (g >= 1 && g <= 7) nomiGiorni[g - 1],
].join(', ');
