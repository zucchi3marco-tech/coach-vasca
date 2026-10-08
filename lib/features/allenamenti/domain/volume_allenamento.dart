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
Map<String, VolumeAllenamento> volumiPerAllenamento(Iterable<Serie> serie) {
  final volumi = <String, VolumeAllenamento>{};
  for (final s in serie) {
    volumi[s.allenamentoId] =
        (volumi[s.allenamentoId] ?? VolumeAllenamento.zero) +
        VolumeAllenamento(
          metri: s.distanzaTotaleM,
          secondi: s.ripetute * (s.durataS ?? 0),
        );
  }
  return volumi;
}

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
