import 'serie.dart';
import 'testo_allenamento.dart';

typedef SerieDaAggiornare = ({
  Serie vecchia,
  SerieScritta nuova,
  int ordine,
  String? piramideId,
});

typedef SerieDaCreare = ({SerieScritta nuova, int ordine, String? piramideId});

class PianoSalvataggio {
  const PianoSalvataggio({
    required this.aggiorna,
    required this.crea,
    required this.elimina,
  });

  final List<SerieDaAggiornare> aggiorna;
  final List<SerieDaCreare> crea;
  final List<Serie> elimina;

  bool get vuoto => aggiorna.isEmpty && crea.isEmpty && elimina.isEmpty;
}

/// Come passare dalle serie salvate [vecchie] (nell'ordine) a quelle
/// scritte [nuove] toccando meno righe possibile: la serie in posizione i
/// riusa la riga che era in posizione i, aggiornandola solo se cambia
/// qualcosa; quelle in più si creano, quelle avanzate si eliminano.
///
/// Un gruppo (un "2x", una piramide) riprende il `piramideId` della riga
/// che stava nella sua prima posizione, così un gruppo non toccato resta
/// com'è; se quella riga non ne aveva uno (o l'ha già preso un altro
/// gruppo) ne riceve uno da [nuovoId].
PianoSalvataggio pianoSalvataggio({
  required List<Serie> vecchie,
  required List<SerieScritta> nuove,
  required String Function() nuovoId,
}) {
  final veri = <String, String>{};
  final usati = <String>{};
  String? idGruppo(int i) {
    final segnaposto = nuove[i].piramideId;
    if (segnaposto == null) return null;
    return veri.putIfAbsent(segnaposto, () {
      final vecchio = i < vecchie.length ? vecchie[i].piramideId : null;
      final id = vecchio != null && !usati.contains(vecchio)
          ? vecchio
          : nuovoId();
      usati.add(id);
      return id;
    });
  }

  final aggiorna = <SerieDaAggiornare>[];
  final crea = <SerieDaCreare>[];
  for (var i = 0; i < nuove.length; i++) {
    final nuova = nuove[i];
    final piramideId = idGruppo(i);
    if (i >= vecchie.length) {
      crea.add((nuova: nuova, ordine: i + 1, piramideId: piramideId));
      continue;
    }
    final vecchia = vecchie[i];
    if (!stessaSerie(vecchia, nuova) ||
        vecchia.ordine != i + 1 ||
        vecchia.piramideId != piramideId) {
      aggiorna.add((
        vecchia: vecchia,
        nuova: nuova,
        ordine: i + 1,
        piramideId: piramideId,
      ));
    }
  }
  return PianoSalvataggio(
    aggiorna: aggiorna,
    crea: crea,
    elimina: vecchie.length > nuove.length
        ? vecchie.sublist(nuove.length)
        : const [],
  );
}
