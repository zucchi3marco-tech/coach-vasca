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
  TextColumn get gruppo => text().nullable()();
  TextColumn get emailGenitore => text().nullable()();
  TextColumn get telefonoGenitore => text().nullable()();
  BoolColumn get consensoPrivacyFirmato =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get consensoPrivacyData => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get attivo => boolean().withDefault(const Constant(true))();

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

class AllenamentiTable extends Table {
  TextColumn get id => text()();
  TextColumn get clubId => text()();
  TextColumn get microcicloId => text().nullable()();
  DateTimeColumn get data => dateTime()();
  TextColumn get titolo => text().nullable()();
  TextColumn get gruppo => text().nullable()();
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
