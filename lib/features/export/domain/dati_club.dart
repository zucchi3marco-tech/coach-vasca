import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/serie.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/personal_best.dart';
import '../../atleti/domain/tempo_gara.dart';
import '../../benessere/domain/scheda_benessere.dart';
import '../../carico/domain/rpe_seduta.dart';
import '../../club/domain/ruolo_club.dart';
import '../../gare/domain/gara.dart';
import '../../gare/domain/gara_iscritto.dart';
import '../../gruppi/domain/gruppo.dart';
import '../../pallanuoto/domain/distinta_giocatore.dart';
import '../../pallanuoto/domain/evento_partita.dart';
import '../../pallanuoto/domain/partita.dart';
import '../../presenze/domain/presenza.dart';
import '../../referti/domain/referto_partita.dart';
import '../../secco/domain/esercizio_secco.dart';
import '../../secco/domain/serie_fatta.dart';
import '../../stagioni/domain/stagione.dart';
import '../../tabelle_passi/domain/tabella_passo.dart';
import '../../test/domain/test_club.dart';
import '../../test/domain/test_ingresso.dart';

/// Tutto quello che il club ha nell'app, com'è sul server: il materiale da
/// cui nasce il file Excel di "Scarica i dati del club". Sono gli stessi
/// modelli che usa il resto dell'app, senza filtri: il periodo si applica
/// solo quando si scrive il file.
class DatiClub {
  const DatiClub({
    this.squadre = const [],
    this.squadreConCapo = const [],
    this.membri = const [],
    this.atleti = const [],
    this.stagioni = const [],
    this.allenamenti = const [],
    this.serie = const [],
    this.presenze = const [],
    this.eserciziSecco = const [],
    this.eserciziSeduta = const [],
    this.serieSeccoFatte = const [],
    this.partite = const [],
    this.distinte = const [],
    this.eventiPartita = const [],
    this.referti = const [],
    this.gare = const [],
    this.iscrittiGare = const [],
    this.tempiGara = const [],
    this.personalBest = const [],
    this.testIngresso = const [],
    this.tabellePassi = const [],
    this.testClub = const [],
    this.risultatiTest = const [],
    this.rpeSedute = const [],
    this.schedeBenessere,
  });

  /// Le squadre (nel database `gruppi`), con lo sport.
  final List<Gruppo> squadre;

  /// Le stesse squadre con il loro capo allenatore.
  final List<SquadraConCapo> squadreConCapo;

  /// Chi lavora nel club; l'email la dà il server solo al responsabile.
  final List<MembroClub> membri;
  final List<Atleta> atleti;
  final List<Stagione> stagioni;
  final List<Allenamento> allenamenti;
  final List<Serie> serie;
  final List<Presenza> presenze;

  /// L'elenco degli esercizi a secco del club.
  final List<EsercizioSecco> eserciziSecco;

  /// Gli esercizi previsti in ogni seduta a secco.
  final List<EsercizioSeduta> eserciziSeduta;

  /// Le serie a secco che gli atleti hanno registrato.
  final List<SerieFatta> serieSeccoFatte;
  final List<Partita> partite;
  final List<DistintaGiocatore> distinte;
  final List<EventoPartita> eventiPartita;
  final List<RefertoPartita> referti;
  final List<Gara> gare;
  final List<GaraIscritto> iscrittiGare;
  final List<TempoGara> tempiGara;
  final List<PersonalBest> personalBest;
  final List<TestIngresso> testIngresso;
  final List<TabellaPasso> tabellePassi;
  final List<TestClub> testClub;
  final List<RisultatoTest> risultatiTest;
  final List<RpeSeduta> rpeSedute;

  /// Le schede benessere (salute degli atleti): null se non sono state
  /// chieste, e in quel caso non sono mai state lette dal server.
  final List<SchedaBenessere>? schedeBenessere;
}
