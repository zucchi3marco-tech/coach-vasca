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

  @override
  Set<Column> get primaryKey => {id};
}

class SchemiTatticiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get titolo => text()();

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
  IntColumn get distanzaM => integer()();
  TextColumn get stile => text()();
  TextColumn get esecuzione => text()();
  TextColumn get zona => text().nullable()();
  RealColumn get passoObiettivoS => real().nullable()();
  IntColumn get recuperoS => integer().nullable()();
  RealColumn get ripartenzaS => real().nullable()();
  TextColumn get attrezzatura => text().nullable()();
  TextColumn get note => text().nullable()();

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
