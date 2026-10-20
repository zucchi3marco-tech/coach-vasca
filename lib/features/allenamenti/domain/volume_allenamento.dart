import 'dart:math' as math;

import '../../../core/utils/giorni.dart';
import 'allenamento.dart';
import 'serie.dart';

/// Il volume di un allenamento (o di una settimana): i metri delle serie a
/// distanza e, a parte, il lavoro a tempo (palleggio, tattica, a secco...):
/// un minuto non diventa metri. Tutte le serie in programma, anche quelle
/// segnate saltate a bordo vasca, come il totale in testa al dettaglio.
class VolumeAllenamento {
  const VolumeAllenamento({this.metri = 0, this.secondi = 0});

  static const zero = VolumeAllenamento();

  final int metri;

  /// Le ripetute per la durata delle serie a tempo, senza i recuperi.
  final int secondi;

  bool get vuoto => metri == 0 && secondi == 0;

  VolumeAllenamento operator +(VolumeAllenamento altro) => VolumeAllenamento(
    metri: metri + altro.metri,
    secondi: secondi + altro.secondi,
  );
}

/// Il volume di ogni allenamento (chiave: id) che ha delle [serie].
/// Conta il volume del gruppo ([Destinatari.delGruppo]): quello di un
/// giocatore di movimento, senza il lavoro dei soli portieri né le serie
/// di alcuni atleti. Con [fatto] quello davvero fatto ([volumeFatto]),
/// non quello scritto.
Map<String, VolumeAllenamento> volumiPerAllenamento(
  Iterable<Serie> serie, {
  bool fatto = false,
}) {
  final perAllenamento = <String, List<Serie>>{};
  for (final s in serie) {
    (perAllenamento[s.allenamentoId] ??= []).add(s);
  }
  return {
    for (final MapEntry(key: id, value: delle) in perAllenamento.entries)
      if (serieDelGruppo(delle) case final gruppo when gruppo.isNotEmpty)
        id: fatto ? volumeFattoDi(gruppo) : volumeDi(gruppo),
  };
}

/// Metri e lavoro a tempo di una serie.
VolumeAllenamento volumeSerie(DatiSerie s) => VolumeAllenamento(
  metri: s.ripetute * (s.distanzaM ?? 0),
  secondi: s.ripetute * (s.durataS ?? 0),
);

/// Il volume di [serie], tutte quelle passate.
VolumeAllenamento volumeDi(Iterable<DatiSerie> serie) =>
    serie.fold(VolumeAllenamento.zero, (t, s) => t + volumeSerie(s));

/// Quanto si è fatto di una serie ("Com'è andata"): niente se è saltata,
/// i metri o i secondi segnati «In parte» (mai più di quelli scritti),
/// altrimenti tutta, anche se non è segnata: come la conta il carico.
VolumeAllenamento volumeFatto(DatiSerie s) {
  if (s.esito == 'saltata') return VolumeAllenamento.zero;
  final scritto = volumeSerie(s);
  return VolumeAllenamento(
    metri: math.min(s.metriFatti ?? scritto.metri, scritto.metri),
    secondi: math.min(s.secondiFatti ?? scritto.secondi, scritto.secondi),
  );
}

/// Il volume fatto di [serie] ([volumeFatto]).
VolumeAllenamento volumeFattoDi(Iterable<DatiSerie> serie) =>
    serie.fold(VolumeAllenamento.zero, (t, s) => t + volumeFatto(s));

/// La parte fatta di una serie, da 0 (saltata) a 1 (tutta, o non
/// segnata): i minuti che contano nel carico sono quelli scritti per
/// questa quota.
double quotaFatta(DatiSerie s) {
  if (s.esito == 'saltata') return 0;
  final scritto = volumeSerie(s);
  final fatto = volumeFatto(s);
  if (s.metriFatti != null && scritto.metri > 0) {
    return fatto.metri / scritto.metri;
  }
  if (s.secondiFatti != null && scritto.secondi > 0) {
    return fatto.secondi / scritto.secondi;
  }
  return 1;
}

/// Le serie che fa il gruppo, cioè un giocatore di movimento qualunque
/// ([Destinatari.delGruppo]): in un momento in parallelo la colonna di
/// tutti, non quella dei portieri o dei centroboa ([serieDellAtleta]).
List<T> serieDelGruppo<T extends DatiSerie>(Iterable<T> serie) =>
    serieDellAtleta(serie, null, 'movimento');

/// Le serie che fa un portiere ([Destinatari.deiPortieri]).
List<T> serieDeiPortieri<T extends DatiSerie>(Iterable<T> serie) =>
    serieDellAtleta(serie, null, 'portiere');

/// C'è almeno una serie per un ruolo (i portieri, i giocatori di
/// movimento, i centroboa...): allora i portieri hanno un volume loro.
bool haSerieDiRuolo(Iterable<DatiSerie> serie) => serie.any(
  (s) => s.destinatari.ruolo != null && s.destinatari.soloAtleti.isEmpty,
);

/// Il lunedì (a mezzanotte) della settimana di [data].
DateTime lunediDi(DateTime data) =>
    soloData(aggiungiGiorni(data, -(data.weekday - 1)));

/// Una settimana di allenamenti: quanti e quanto volume.
typedef VolumeSettimana = ({VolumeAllenamento volume, int allenamenti});

/// Il volume di ogni settimana (chiave: il lunedì) in cui c'è almeno uno
/// degli [allenamenti]; [volumi] da [volumiPerAllenamento].
Map<DateTime, VolumeSettimana> volumiPerSettimana(
  Iterable<Allenamento> allenamenti,
  Map<String, VolumeAllenamento> volumi,
) {
  final settimane = <DateTime, VolumeSettimana>{};
  for (final a in allenamenti) {
    final lunedi = lunediDi(a.data);
    final finora =
        settimane[lunedi] ?? (volume: VolumeAllenamento.zero, allenamenti: 0);
    settimane[lunedi] = (
      volume: finora.volume + (volumi[a.id] ?? VolumeAllenamento.zero),
      allenamenti: finora.allenamenti + 1,
    );
  }
  return settimane;
}
