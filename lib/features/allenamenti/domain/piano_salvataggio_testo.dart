import 'serie.dart';
import 'testo_allenamento.dart';

typedef SerieDaAggiornare = ({
  Serie vecchia,
  SerieScritta nuova,
  int ordine,
  String? piramideId,
  String? momentoId,
});

typedef SerieDaCreare = ({
  SerieScritta nuova,
  int ordine,
  String? piramideId,
  String? momentoId,
});

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
/// gruppo) ne riceve uno da [nuovoId]. Lo stesso per i momenti in
/// parallelo (`momentoId`).
PianoSalvataggio pianoSalvataggio({
  required List<Serie> vecchie,
  required List<SerieScritta> nuove,
  required String Function() nuovoId,
}) {
  String? Function(int) idVeri(String? Function(DatiSerie) campo) {
    final veri = <String, String>{};
    final usati = <String>{};
    return (i) {
      final segnaposto = campo(nuove[i]);
      if (segnaposto == null) return null;
      return veri.putIfAbsent(segnaposto, () {
        final vecchio = i < vecchie.length ? campo(vecchie[i]) : null;
        final id = vecchio != null && !usati.contains(vecchio)
            ? vecchio
            : nuovoId();
        usati.add(id);
        return id;
      });
    };
  }

  final idGruppo = idVeri((s) => s.piramideId);
  final idMomento = idVeri((s) => s.momentoId);

  final aggiorna = <SerieDaAggiornare>[];
  final crea = <SerieDaCreare>[];
  for (var i = 0; i < nuove.length; i++) {
    final nuova = nuove[i];
    final piramideId = idGruppo(i);
    final momentoId = idMomento(i);
    if (i >= vecchie.length) {
      crea.add((
        nuova: nuova,
        ordine: i + 1,
        piramideId: piramideId,
        momentoId: momentoId,
      ));
      continue;
    }
    final vecchia = vecchie[i];
    if (!stessaSerie(vecchia, nuova) ||
        vecchia.recuperoDopoS != nuova.recuperoDopoS ||
        vecchia.ordine != i + 1 ||
        vecchia.piramideId != piramideId ||
        vecchia.momentoId != momentoId) {
      aggiorna.add((
        vecchia: vecchia,
        nuova: nuova,
        ordine: i + 1,
        piramideId: piramideId,
        momentoId: momentoId,
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
