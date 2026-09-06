import '../domain/evento_partita.dart';
import 'selettore_giocatore_partita.dart';

/// Un giocatore (nostro o avversario) che accumula 3 espulsioni "a fallo
/// da rigore" nella stessa partita resta escluso per il resto della gara,
/// per qualunque evento (non solo l'espulsione): calcolato al volo dagli
/// eventi già caricati, nessun campo dedicato né sincronizzato.
Set<GiocatorePartitaId> calcolaSqualificati(List<EventoPartita> eventi) {
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
  return {
    for (final entry in conteggi.entries)
      if (entry.value >= 3) entry.key,
  };
}
