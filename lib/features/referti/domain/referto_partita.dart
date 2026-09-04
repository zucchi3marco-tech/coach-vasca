import 'referto_letto.dart';

/// Referto di una partita gia' salvato e collegato a una Partita, a
/// differenza di [RefertoLetto] che e' il risultato grezzo appena letto
/// dal modello di visione, prima della correzione manuale dell'utente.
class RefertoPartita {
  const RefertoPartita({
    required this.id,
    required this.partitaId,
    required this.clubId,
    required this.squadraCasa,
    required this.squadraTrasferta,
    required this.risultatoCasa,
    required this.risultatoTrasferta,
    required this.parziali,
    required this.giocatoriCasa,
    required this.giocatoriTrasferta,
  });

  final String id;
  final String partitaId;
  final String clubId;
  final String squadraCasa;
  final String squadraTrasferta;
  final int risultatoCasa;
  final int risultatoTrasferta;
  final List<ParzialeReferto> parziali;
  final List<GiocatoreReferto> giocatoriCasa;
  final List<GiocatoreReferto> giocatoriTrasferta;
}
