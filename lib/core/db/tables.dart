import 'package:drift/drift.dart';

/// Schema locale Drift, specchio delle tabelle Supabase usate dall'app.
/// Le chiavi primarie sono UUID generati lato client (package `uuid`),
/// cosi' una riga creata offline ha gia' l'id definitivo, identico su
/// locale e remoto una volta sincronizzata (Fase 3, punto 1: solo cache
/// locale + lettura da locale; la coda di scrittura offline e il motore
/// di sync arrivano nel passaggio successivo).

class ClubTable extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get citta => text().nullable()();
  TextColumn get sport => text().nullable()();

  /// Categorie allenate, codificate come lista JSON (es. `["U14","U16"]`):
  /// SQLite non ha un tipo array nativo, stesso schema gia' usato per i
  /// campi lista di `RefertiPartitaTable`.
  TextColumn get categorieJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class AtletiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get nome => text()();
  TextColumn get cognome => text()();
  DateTimeColumn get dataNascita => dateTime()();
  TextColumn get sesso => text().nullable()();
  TextColumn get sport => text()();
  TextColumn get gruppoId => text().nullable()();
  TextColumn get emailGenitore => text().nullable()();
  TextColumn get telefonoGenitore => text().nullable()();
  BoolColumn get consensoPrivacyFirmato =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get consensoPrivacyData => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get attivo => boolean().withDefault(const Constant(true))();
  TextColumn get numeroTesseraFin => text().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get visitaMedicaScadenza => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Personal best inseriti dall'atleta stesso (FASE 9), visibili anche al
/// coach ma modificabili solo dall'atleta a cui appartengono.
class PersonalBestTable extends Table {
  TextColumn get id => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  TextColumn get stile => text()();
  IntColumn get distanzaM => integer()();
  RealColumn get tempoS => real()();
  DateTimeColumn get data => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TempiGaraTable extends Table {
  TextColumn get id => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  TextColumn get stile => text()();
  IntColumn get distanzaM => integer()();
  IntColumn get vascaM => integer()();
  RealColumn get tempoS => real()();
  DateTimeColumn get data => dateTime()();
  TextColumn get note => text().nullable()();

  /// Gara in cui e' stato nuotato (null = tempo inserito a mano).
  TextColumn get garaId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SchemiTatticiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get titolo => text()();

  /// Gruppi di allenamento (squadre) a cui appartiene lo schema — lista
  /// vuota se condiviso con tutto il club. Prima una singola colonna
  /// nullable `gruppo_id` (un solo gruppo): JSON con gli id, come il
  /// campo `gruppo_ids` jsonb lato Supabase — stesso schema di
  /// [ClubTable.categorieJson]. Da non confondere con [categoria] (il
  /// tipo di azione tattica, es. "Superiorità").
  TextColumn get gruppoIdsJson => text().withDefault(const Constant('[]'))();

  /// Gruppo libero scelto dall'allenatore (es. "Transizioni",
  /// "Superiorità"...): non un elenco chiuso, se ne possono creare
  /// quanti se ne vogliono.
  TextColumn get categoria => text().withDefault(const Constant(''))();

  /// 'intero' | 'meta' — vedi `CampoLavagna` in `WaterPoloTacticsBoard`.
  TextColumn get campo => text().withDefault(const Constant('intero'))();

  /// JSON con giocatori/frecce (vedi `SchemiTatticiRepository`), come
  /// il campo `dati` jsonb lato Supabase: qui e' testo perche' Drift/
  /// sqlite non ha un tipo json nativo.
  TextColumn get dati => text()();
  DateTimeColumn get aggiornatoIl => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TestIngressoTable extends Table {
  TextColumn get id => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  TextColumn get tipo => text()();
  DateTimeColumn get dataTest => dateTime()();
  IntColumn get distanzaTotaleM => integer()();
  RealColumn get tempoTotaleS => real()();
  RealColumn get passoMedio100S => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TabellePassiTable extends Table {
  TextColumn get id => text()();
  TextColumn get testId => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  TextColumn get zona => text()();
  RealColumn get passo100S => real()();
  RealColumn get percentualeRiferimento => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StagioniTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get nome => text()();
  DateTimeColumn get dataInizio => dateTime()();
  DateTimeColumn get dataFine => dateTime()();
  TextColumn get obiettivo => text().nullable()();
  TextColumn get gruppoId => text().nullable()();
  TextColumn get campionato => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GruppiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get nome => text()();
  IntColumn get ordine => integer().withDefault(const Constant(1))();
  TextColumn get sport => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AllenamentiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  DateTimeColumn get data => dateTime()();
  TextColumn get titolo => text().nullable()();
  TextColumn get gruppoId => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SerieTable extends Table {
  TextColumn get id => text()();
  TextColumn get allenamentoId => text()();
  TextColumn get clubId => text()();
  IntColumn get ordine => integer()();
  TextColumn get blocco => text()();
  IntColumn get ripetute => integer()();

  /// Una serie usa distanza o durata, mai entrambe — vedi [durataS].
  IntColumn get distanzaM => integer().nullable()();

  /// Serie "a tempo" (es. lavoro a secco, tattica a tempo): alternativa
  /// a [distanzaM], non un campo aggiuntivo.
  IntColumn get durataS => integer().nullable()();
  TextColumn get stile => text()();
  TextColumn get esecuzione => text()();
  TextColumn get zona => text().nullable()();
  RealColumn get passoObiettivoS => real().nullable()();
  IntColumn get recuperoS => integer().nullable()();
  RealColumn get ripartenzaS => real().nullable()();
  TextColumn get attrezzatura => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Righe della stessa piramide (es. 50-100-200-100-50, dalla barra
  /// rapida) condividono questo id, per raggrupparle in un'unica riga
  /// visiva — null per una serie normale.
  TextColumn get piramideId => text().nullable()();

  /// 'fatta' | 'saltata', segnato a bordo vasca; null se non segnata.
  TextColumn get esito => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PresenzeTable extends Table {
  TextColumn get id => text()();
  TextColumn get allenamentoId => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  TextColumn get stato => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PartiteTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();

  /// Gruppo di allenamento (squadra) a cui appartiene la partita — null
  /// se condivisa con tutto il club.
  TextColumn get gruppoId => text().nullable()();
  DateTimeColumn get data => dateTime()();
  TextColumn get ora => text().nullable()();
  TextColumn get luogo => text().nullable()();
  TextColumn get campionato => text().nullable()();
  TextColumn get coloreCalottina => text().nullable()();
  TextColumn get squadraCasa => text()();
  TextColumn get squadraTrasferta => text()();
  IntColumn get numeroMaxConvocati =>
      integer().withDefault(const Constant(15))();
  TextColumn get note => text().nullable()();
  TextColumn get dettaglioTiro =>
      text().withDefault(const Constant('semplice'))();
  BoolColumn get tracciaTempo => boolean().withDefault(const Constant(true))();
  TextColumn get modalitaSuperiorita =>
      text().withDefault(const Constant('singolo'))();
  TextColumn get nostraSquadra =>
      text().withDefault(const Constant('casa'))(); // casa | trasferta

  /// bassa | media | alta — lo scarico pre-partita del generatore
  /// settimanale (FASE 3) scatta solo per "alta".
  TextColumn get importanza => text().withDefault(const Constant('media'))();

  @override
  Set<Column> get primaryKey => {id};
}

class DistintaGiocatoriTable extends Table {
  TextColumn get id => text()();
  TextColumn get partitaId => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  IntColumn get numeroCalottina => integer()();
  BoolColumn get capitano => boolean().withDefault(const Constant(false))();
  BoolColumn get viceCapitano => boolean().withDefault(const Constant(false))();
  BoolColumn get portiere => boolean().withDefault(const Constant(false))();
  BoolColumn get fuoriquota => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Log base degli eventi di una partita (tiro, espulsione, superiorita'
/// numerica). Include creatoIl (a differenza delle altre tabelle di
/// pallanuoto) perche' qui l'ordine cronologico e' l'unico ordinamento
/// sensato, senza un campo di dominio equivalente (come numeroCalottina
/// per la distinta).
class EventiPartitaTable extends Table {
  TextColumn get id => text()();
  TextColumn get partitaId => text()();
  TextColumn get clubId => text()();
  TextColumn get tipo => text()(); // tiro | espulsione | superiorita
  TextColumn get squadra =>
      text().withDefault(const Constant('nostra'))(); // nostra | avversaria
  TextColumn get atletaId => text().nullable()();
  IntColumn get periodo => integer().nullable()();
  TextColumn get esito =>
      text().nullable()(); // gol | non_gol | parato | palo_fuori
  TextColumn get contestoTiro => text().withDefault(
    const Constant('azione'),
  )(); // azione | superiorita | rigore
  RealColumn get posX => real().nullable()();
  RealColumn get posY => real().nullable()();
  IntColumn get numeroCalottinaAvversario => integer().nullable()();
  BoolColumn get espulsioneDaRigore =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get creatoIl => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Referto di una partita gia' giocata (risultato finale, parziali e rose
/// complete di reti/espulsioni per entrambe le squadre), letto via AI
/// vision da una foto e corretto a mano. Un solo referto per partita
/// (upsert su partitaId, come "presenze" su allenamentoId+atletaId).
/// parziali/giocatoriCasa/giocatoriTrasferta sono liste codificate come
/// stringa JSON: niente query locali su questi campi, solo lettura
/// integrale per mostrarli in UI.
class RefertiPartitaTable extends Table {
  TextColumn get id => text()();
  TextColumn get partitaId => text()();
  TextColumn get clubId => text()();
  TextColumn get squadraCasa => text()();
  TextColumn get squadraTrasferta => text()();
  IntColumn get risultatoCasa => integer()();
  IntColumn get risultatoTrasferta => integer()();
  TextColumn get parzialiJson => text().withDefault(const Constant('[]'))();
  TextColumn get giocatoriCasaJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get giocatoriTrasfertaJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Coda delle scritture non ancora sincronizzate con Supabase: una riga per
/// ogni insert/update/delete fallito per un problema di rete (non per un
/// errore reale del server, quello resta visibile subito in UI). Un motore
/// di sync la svuota quando la connessione torna disponibile, nell'ordine
/// in cui le operazioni sono state accodate.
class PendingOperationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tabella => text()();
  TextColumn get operazione => text()(); // insert | update | delete
  TextColumn get rigaId => text()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get creatoIl => dateTime().withDefault(currentDateAndTime)();
}

class GareTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();

  /// Gruppo a cui appartiene la gara — null se di tutto il club.
  TextColumn get gruppoId => text().nullable()();
  DateTimeColumn get data => dateTime()();
  TextColumn get ora => text().nullable()();
  TextColumn get luogo => text().nullable()();
  TextColumn get nome => text()();
  TextColumn get note => text().nullable()();

  /// bassa | media | alta — lo scarico pre-gara del generatore
  /// settimanale (FASE 3) scatta solo per "alta".
  TextColumn get importanza => text().withDefault(const Constant('media'))();

  @override
  Set<Column> get primaryKey => {id};
}

class GaraIscrittiTable extends Table {
  TextColumn get id => text()();
  TextColumn get garaId => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Scheda benessere compilata dall'atleta prima di allenamento/partita:
/// una per atleta al giorno (chiave naturale atletaId + data, come
/// `schede_benessere` lato Supabase).
class SchedeBenessereTable extends Table {
  TextColumn get id => text()();
  TextColumn get atletaId => text()();
  TextColumn get clubId => text()();
  DateTimeColumn get data => dateTime()();
  TextColumn get eventoTipo => text().nullable()(); // allenamento | partita
  TextColumn get eventoId => text().nullable()();
  BoolColumn get dolori => boolean()();

  /// Zone del corpo come lista JSON (es. `["spalla","ginocchio"]`).
  TextColumn get zoneDoloreJson => text().withDefault(const Constant('[]'))();
  IntColumn get intensitaDolore => integer().nullable()();
  RealColumn get oreSonno => real()();
  DateTimeColumn get compilataIl => dateTime()();

  /// Voci del questionario di McLean (1-5, 5 = meglio): null per le
  /// schede compilate prima della seconda versione.
  IntColumn get qualitaSonno => integer().nullable()();
  IntColumn get energia => integer().nullable()();
  IntColumn get muscoli => integer().nullable()();
  IntColumn get stress => integer().nullable()();
  IntColumn get umore => integer().nullable()();

  /// Sintomi di malattia come lista JSON (es. `["febbre"]`).
  TextColumn get sintomiJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Libreria di blocchi di allenamento approvati (RIPROGETTAZIONE AI,
/// FASE 1) — cache locale, stesso pattern di [SerieTable]/[AllenamentiTable].
class TrainingBlocksTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get codice => text()();
  TextColumn get sport => text()();
  TextColumn get fase => text()();
  TextColumn get obiettivo => text()();
  TextColumn get zoneCoinvolte => text()();
  TextColumn get titolo => text()();
  TextColumn get descrizione => text()();
  TextColumn get stilePrincipale => text().nullable()();
  TextColumn get livelli => text().withDefault(const Constant(''))();
  TextColumn get attrezzi => text().nullable()();
  IntColumn get metriTotali => integer().withDefault(const Constant(0))();
  IntColumn get durataStimataMin => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  TextColumn get stato => text().withDefault(const Constant('bozza'))();
  TextColumn get fonte => text().withDefault(const Constant('Allenatore'))();
  DateTimeColumn get importatoIl => dateTime().nullable()();
  BoolColumn get modificatoInApp =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class TrainingBlockPartiTable extends Table {
  TextColumn get id => text()();
  TextColumn get bloccoId => text()();
  TextColumn get clubId => text()();
  IntColumn get ordine => integer().withDefault(const Constant(1))();
  IntColumn get giri => integer().withDefault(const Constant(1))();
  IntColumn get ripetizioni => integer().withDefault(const Constant(1))();
  IntColumn get distanzaM => integer().nullable()();
  IntColumn get durataS => integer().nullable()();
  TextColumn get stile => text().nullable()();
  TextColumn get esercizio => text().nullable()();
  TextColumn get zona => text()();
  TextColumn get esecuzione => text()();
  IntColumn get recuperoS => integer().nullable()();
  TextColumn get attrezzi => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
