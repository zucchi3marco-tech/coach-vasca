import '../domain/evento_partita.dart';
import 'selettore_giocatore_partita.dart';

/// Quante espulsioni "a fallo da rigore" ha accumulato ciascun giocatore
/// (nostro o avversario) in questa partita.
Map<GiocatorePartitaId, int> contaEspulsioniRigore(List<EventoPartita> eventi) {
  final conteggi = <GiocatorePartitaId, int>{};
  for (final e in eventi) {
    if (e.tipo != 'espulsione' || !e.espulsioneDaRigore) continue;
    final GiocatorePartitaId? id = e.atletaId != null
        ? NostroGiocatoreId(e.atletaId!)
        : e.numeroCalottinaAvversario != null
        ? AvversarioGiocatoreId(e.numeroCalottinaAvversario!)
        : null;
    if (id == null) continue;
    conteggi[id] = (conteggi[id] ?? 0) + 1;
  }
  return conteggi;
}

/// Un giocatore (nostro o avversario) che accumula 3 espulsioni "a fallo
/// da rigore" nella stessa partita resta escluso per il resto della gara,
/// per qualunque evento (non solo l'espulsione): calcolato al volo dagli
/// eventi già caricati, nessun campo dedicato né sincronizzato.
Set<GiocatorePartitaId> calcolaSqualificati(List<EventoPartita> eventi) {
  return {
    for (final entry in contaEspulsioniRigore(eventi).entries)
      if (entry.value >= 3) entry.key,
  };
}

/// "Timer nascosto": se l'ultima espulsione (qualunque, anche da rigore)
/// registrata risale a meno di 30 secondi fa, la squadra opposta a quella
/// sanzionata è in vantaggio numerico. Se [squadraCheTira] è quella
/// avvantaggiata, il tiro va marcato come superiorità (o rigore, se la
/// sanzione che ha aperto la finestra aveva quel flag) invece di 'azione'.
/// Torna null se non c'è nessuna finestra attiva o se a tirare è la
/// squadra sanzionata (nessun vantaggio per lei).
String? contestoAutomatico(
  List<EventoPartita> eventi,
  String squadraCheTira,
  DateTime ora,
) {
  EventoPartita? ultimaEspulsione;
  for (final e in eventi) {
    if (e.tipo != 'espulsione') continue;
    if (ultimaEspulsione == null ||
        e.creatoIl.isAfter(ultimaEspulsione.creatoIl)) {
      ultimaEspulsione = e;
    }
  }
  if (ultimaEspulsione == null) return null;
  if (ora.difference(ultimaEspulsione.creatoIl) > const Duration(seconds: 30)) {
    return null;
  }
  final squadraSanzionata = ultimaEspulsione.squadra;
  if (squadraCheTira == squadraSanzionata) return null;
  return ultimaEspulsione.espulsioneDaRigore ? 'rigore' : 'superiorita';
}
