import 'evento_partita.dart';
import 'partita.dart';

/// Risultato di una partita calcolato dagli eventi tiro/gol registrati
/// (stesso conteggio del punteggio in tempo reale della schermata live) —
/// non un campo salvato a parte. Torna null se non e' stato registrato
/// nessun gol (partita non ancora giocata, o giocata senza usare il
/// campo live).
({int golCasa, int golTrasferta})? risultatoPartita(
  List<EventoPartita> eventi,
  Partita partita,
) {
  if (eventi.isEmpty) return null;
  final golNostri = eventi
      .where(
        (e) => e.tipo == 'tiro' && e.esito == 'gol' && e.squadra == 'nostra',
      )
      .length;
  final golAvversari = eventi
      .where(
        (e) =>
            e.tipo == 'tiro' && e.esito == 'gol' && e.squadra == 'avversaria',
      )
      .length;
  return partita.nostraSquadra == 'casa'
      ? (golCasa: golNostri, golTrasferta: golAvversari)
      : (golCasa: golAvversari, golTrasferta: golNostri);
}
