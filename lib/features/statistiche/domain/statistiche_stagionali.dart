import '../../pallanuoto/domain/statistiche_eventi.dart';

/// Statistiche di squadra/atleta calcolate dai referti salvati (Fase 8):
/// non contano i tiri sbagliati, perche' il referto registra solo reti ed
/// espulsioni, non ogni singolo tentativo.
class RiepilogoSquadraReferti {
  const RiepilogoSquadraReferti({
    required this.partite,
    required this.vittorie,
    required this.pareggi,
    required this.sconfitte,
    required this.golFatti,
    required this.golSubiti,
    required this.perAtleta,
  });

  static const vuoto = RiepilogoSquadraReferti(
    partite: 0,
    vittorie: 0,
    pareggi: 0,
    sconfitte: 0,
    golFatti: 0,
    golSubiti: 0,
    perAtleta: [],
  );

  final int partite;
  final int vittorie;
  final int pareggi;
  final int sconfitte;
  final int golFatti;
  final int golSubiti;
  final List<RigaAtletaReferti> perAtleta;

  double get mediaGolPartita => partite > 0 ? golFatti / partite : 0.0;
}

class RigaAtletaReferti {
  const RigaAtletaReferti({
    required this.atletaId,
    required this.reti,
    required this.espulsioni,
    required this.partite,
  });

  final String atletaId;
  final int reti;
  final int espulsioni;
  final int partite;

  double get mediaRetiPartita => partite > 0 ? reti / partite : 0.0;
}

/// Statistiche di squadra/atleta calcolate dagli eventi partita tracciati
/// live: piu' accurate (includono anche i tiri sbagliati e il contesto
/// del gol), ma disponibili solo per le partite seguite dal vivo
/// dall'app, non per quelle digitalizzate solo da referto. `partite`
/// conta solo le partite con almeno un evento registrato, non tutte
/// quelle della stagione. I conteggi stanno in [numeri] (vedi
/// `StatisticheEventi`); qui restano le voci usate piu' spesso.
class RiepilogoSquadraEventi {
  const RiepilogoSquadraEventi({
    required this.partite,
    required this.numeri,
    required this.perAtleta,
  });

  static const vuoto = RiepilogoSquadraEventi(
    partite: 0,
    numeri: NumeriEventi.zero,
    perAtleta: [],
  );

  factory RiepilogoSquadraEventi.da(StatisticheEventi s) =>
      RiepilogoSquadraEventi(
        partite: s.partite,
        numeri: s.squadra,
        perAtleta: [
          for (final MapEntry(:key, :value) in s.perAtleta.entries)
            RigaAtletaEventi(atletaId: key, numeri: value),
        ],
      );

  final int partite;
  final NumeriEventi numeri;
  final List<RigaAtletaEventi> perAtleta;

  int get tiri => numeri.tiri;
  int get gol => numeri.gol;
  int get golSuperiorita => numeri.golSuperiorita;
  int get golRigore => numeri.golRigore;
  int get golControfuga => numeri.golControfuga;
  int get golAzione => numeri.golAzione;
  int get espulsioni => numeri.espulsioni;

  /// Tiri e gol dell'avversario contro di noi ("tiro avversario", nessuna
  /// posizione né identità del tiratore: solo l'esito).
  int get tiriSubiti => numeri.tiriSubiti;
  int get golSubiti => numeri.golSubiti;

  double get mediaGolPartita => partite > 0 ? gol / partite : 0.0;
  double get percentualeGolSubiti =>
      tiriSubiti > 0 ? golSubiti / tiriSubiti * 100 : 0.0;
}

class RigaAtletaEventi {
  const RigaAtletaEventi({required this.atletaId, required this.numeri});

  final String atletaId;
  final NumeriEventi numeri;

  int get tiri => numeri.tiri;
  int get gol => numeri.gol;
  int get golSuperiorita => numeri.golSuperiorita;
  int get golRigore => numeri.golRigore;
  int get golControfuga => numeri.golControfuga;
  int get golAzione => numeri.golAzione;
  int get espulsioni => numeri.espulsioni;
}
