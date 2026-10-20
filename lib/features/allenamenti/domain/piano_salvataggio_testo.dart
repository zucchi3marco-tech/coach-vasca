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
/// scritte [nuove] toccando meno righe possibile, aggiornando una riga
/// solo se cambia qualcosa; quelle in più si creano, quelle avanzate si
/// eliminano.
///
/// Ogni serie scritta riusa la riga della **stessa serie** ([righeRiusate]),
/// non quella che stava nella sua posizione: con una serie aggiunta in
/// cima, il "fatta" o "saltata" segnato a bordo vasca finiva sulla serie
/// sotto, e così i metri fatti e il carico.
///
/// Un gruppo (un "2x", una piramide) riprende il `piramideId` della riga
/// riusata dalla sua prima serie, così un gruppo non toccato resta com'è;
/// se quella riga non ne aveva uno (o l'ha già preso un altro gruppo) ne
/// riceve uno da [nuovoId]. Lo stesso per i momenti in parallelo
/// (`momentoId`).
PianoSalvataggio pianoSalvataggio({
  required List<Serie> vecchie,
  required List<SerieScritta> nuove,
  required String Function() nuovoId,
}) {
  final riusate = righeRiusate(vecchie, nuove);

  String? Function(int) idVeri(String? Function(DatiSerie) campo) {
    final veri = <String, String>{};
    final usati = <String>{};
    return (i) {
      final segnaposto = campo(nuove[i]);
      if (segnaposto == null) return null;
      return veri.putIfAbsent(segnaposto, () {
        final riga = riusate[i];
        final vecchio = riga == null ? null : campo(vecchie[riga]);
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
    final riga = riusate[i];
    if (riga == null) {
      crea.add((
        nuova: nuova,
        ordine: i + 1,
        piramideId: piramideId,
        momentoId: momentoId,
      ));
      continue;
    }
    final vecchia = vecchie[riga];
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
  final tenute = riusate.whereType<int>().toSet();
  return PianoSalvataggio(
    aggiorna: aggiorna,
    crea: crea,
    elimina: [
      for (final (i, s) in vecchie.indexed)
        if (!tenute.contains(i)) s,
    ],
  );
}

/// Per ogni serie di [nuove], l'indice della riga di [vecchie] che riusa,
/// o null se è da creare:
/// 1. le serie rimaste uguali ([stessaSerie], stesso recupero dopo),
///    anche se sono scivolate di posto: la più lunga sequenza in comune;
/// 2. quelle uguali spostate altrove (due serie scambiate);
/// 3. fra due serie del punto 1, quelle cambiate nello stesso punto, una
///    per una: è la stessa serie corretta (un 8x100 diventato 6x100), che
///    tiene il suo "fatta".
List<int?> righeRiusate(List<Serie> vecchie, List<DatiSerie> nuove) {
  bool uguali(int v, int n) =>
      stessaSerie(vecchie[v], nuove[n]) &&
      vecchie[v].recuperoDopoS == nuove[n].recuperoDopoS;

  // comune[v][n]: quante serie uguali, nell'ordine, al massimo fra le
  // vecchie da v in poi e le nuove da n in poi.
  final comune = List.generate(
    vecchie.length + 1,
    (_) => List.filled(nuove.length + 1, 0),
  );
  for (var v = vecchie.length - 1; v >= 0; v--) {
    for (var n = nuove.length - 1; n >= 0; n--) {
      comune[v][n] = uguali(v, n)
          ? comune[v + 1][n + 1] + 1
          : (comune[v + 1][n] > comune[v][n + 1]
                ? comune[v + 1][n]
                : comune[v][n + 1]);
    }
  }

  final riusate = List<int?>.filled(nuove.length, null);
  final usate = <int>{};
  void abbina(int v, int n) {
    riusate[n] = v;
    usate.add(v);
  }

  // 1.
  final coppie = <(int, int)>[];
  var v = 0;
  var n = 0;
  while (v < vecchie.length && n < nuove.length) {
    if (uguali(v, n)) {
      abbina(v, n);
      coppie.add((v++, n++));
    } else if (comune[v + 1][n] >= comune[v][n + 1]) {
      v++;
    } else {
      n++;
    }
  }

  // 2.
  for (var n = 0; n < nuove.length; n++) {
    if (riusate[n] != null) continue;
    for (var v = 0; v < vecchie.length; v++) {
      if (!usate.contains(v) && uguali(v, n)) {
        abbina(v, n);
        break;
      }
    }
  }

  // 3.
  final confini = [(-1, -1), ...coppie, (vecchie.length, nuove.length)];
  for (var k = 0; k + 1 < confini.length; k++) {
    final (v0, n0) = confini[k];
    final (v1, n1) = confini[k + 1];
    final libereVecchie = [
      for (var v = v0 + 1; v < v1; v++)
        if (!usate.contains(v)) v,
    ];
    final libereNuove = [
      for (var n = n0 + 1; n < n1; n++)
        if (riusate[n] == null) n,
    ];
    for (var i = 0; i < libereVecchie.length && i < libereNuove.length; i++) {
      abbina(libereVecchie[i], libereNuove[i]);
    }
  }
  return riusate;
}
