import '../domain/piano_salvataggio_testo.dart';
import 'serie_repository.dart';

/// Scrive il [piano] di una seduta: aggiorna, crea ed elimina le serie
/// come dice [pianoSalvataggio]. Lo usano "Scrivi l'allenamento" e
/// l'assistente; rifatto dopo un errore non duplica le serie già create.
Future<void> eseguiPianoSerie(
  SerieRepository repository, {
  required String allenamentoId,
  required PianoSalvataggio piano,
}) async {
  for (final a in piano.aggiorna) {
    final s = a.nuova;
    await repository.updateSerie(
      id: a.vecchia.id,
      ordine: a.ordine,
      blocco: s.blocco,
      ripetute: s.ripetute,
      distanzaM: s.distanzaM,
      durataS: s.durataS,
      stile: s.stile,
      esecuzione: s.esecuzione,
      zona: s.zona,
      passoObiettivoS: s.passoObiettivoS,
      recuperoS: s.recuperoS,
      ripartenzaS: s.ripartenzaS,
      attrezzatura: s.attrezzatura,
      note: s.note,
      piramide: (id: a.piramideId),
      recuperoDopo: (secondi: s.recuperoDopoS),
      destinatari: s.destinatari,
      momento: (id: a.momentoId),
    );
  }
  for (final c in piano.crea) {
    final s = c.nuova;
    await repository.createSerie(
      allenamentoId: allenamentoId,
      ordine: c.ordine,
      blocco: s.blocco,
      ripetute: s.ripetute,
      distanzaM: s.distanzaM,
      durataS: s.durataS,
      stile: s.stile,
      esecuzione: s.esecuzione,
      zona: s.zona,
      passoObiettivoS: s.passoObiettivoS,
      recuperoS: s.recuperoS,
      ripartenzaS: s.ripartenzaS,
      attrezzatura: s.attrezzatura,
      note: s.note,
      piramideId: c.piramideId,
      recuperoDopoS: s.recuperoDopoS,
      destinatari: s.destinatari,
      momentoId: c.momentoId,
    );
  }
  for (final s in piano.elimina) {
    await repository.deleteSerie(s.id);
  }
}
