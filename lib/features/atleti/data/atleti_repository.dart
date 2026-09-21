import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/utils/date_format.dart';
import '../domain/atleta.dart';

const _uuid = Uuid();

class AtletiRepository {
  AtletiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Atleta _fromRow(AtletiTableData row) {
    return Atleta(
      id: row.id,
      clubId: row.clubId,
      nome: row.nome,
      cognome: row.cognome,
      dataNascita: row.dataNascita,
      sesso: row.sesso,
      sport: row.sport,
      gruppoId: row.gruppoId,
      emailGenitore: row.emailGenitore,
      telefonoGenitore: row.telefonoGenitore,
      consensoPrivacyFirmato: row.consensoPrivacyFirmato,
      consensoPrivacyData: row.consensoPrivacyData,
      note: row.note,
      attivo: row.attivo,
      numeroTesseraFin: row.numeroTesseraFin,
      userId: row.userId,
      visitaMedicaScadenza: row.visitaMedicaScadenza,
    );
  }

  Stream<List<Atleta>> watchAtleti({
    required String clubId,
    bool includeInactive = false,
  }) {
    final query = _db.select(_db.atletiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.cognome),
        (t) => OrderingTerm.asc(t.nome),
      ]);
    if (!includeInactive) {
      query.where((t) => t.attivo.equals(true));
    }
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo club (non insertOrReplace): un atleta
  /// eliminato fuori dall'app (es. SQL Editor) altrimenti resterebbe in
  /// cache locale a tempo indeterminato.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client.from('atleti').select().eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.atletiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.atletiTable, _companionFromMap(row));
        }
      });
    });
  }

  AtletiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return AtletiTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      dataNascita: DateTime.parse(map['data_nascita'] as String),
      sesso: Value(map['sesso'] as String?),
      sport: map['sport'] as String,
      gruppoId: Value(map['gruppo_id'] as String?),
      emailGenitore: Value(map['email_genitore'] as String?),
      telefonoGenitore: Value(map['telefono_genitore'] as String?),
      consensoPrivacyFirmato: Value(
        map['consenso_privacy_firmato'] as bool? ?? false,
      ),
      consensoPrivacyData: Value(
        map['consenso_privacy_data'] == null
            ? null
            : DateTime.parse(map['consenso_privacy_data'] as String),
      ),
      note: Value(map['note'] as String?),
      attivo: Value(map['attivo'] as bool? ?? true),
      numeroTesseraFin: Value(map['numero_tessera_fin'] as String?),
      userId: Value(map['user_id'] as String?),
      visitaMedicaScadenza: Value(
        map['visita_medica_scadenza'] == null
            ? null
            : DateTime.parse(map['visita_medica_scadenza'] as String),
      ),
    );
  }

  Future<void> _salvaLocale(Map<String, dynamic> row) {
    return _db
        .into(_db.atletiTable)
        .insertOnConflictUpdate(_companionFromMap(row));
  }

  Future<Atleta> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.atletiTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  /// L'atleta collegato all'utente autenticato corrente (FASE 9), o null
  /// se questo login non e' (ancora) un account atleta collegato. La RLS
  /// su `atleti` lascia leggere il proprio record via `user_id` anche a
  /// chi non e' membro di nessun club.
  Future<Atleta?> fetchAtletaCollegato() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final rows = await _client.from('atleti').select().eq('user_id', userId);
      if (rows.isEmpty) return null;
      final row = rows.first;
      await _salvaLocale(row);
      return Atleta.fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locale = await (_db.select(
        _db.atletiTable,
      )..where((t) => t.userId.equals(userId))).getSingleOrNull();
      return locale == null ? null : _fromRow(locale);
    }
  }

  Future<Atleta> createAtleta({
    required String clubId,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppoId,
    String? emailGenitore,
    String? telefonoGenitore,
    bool consensoPrivacyFirmato = false,
    String? note,
    String? numeroTesseraFin,
    DateTime? visitaMedicaScadenza,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'nome': nome,
      'cognome': cognome,
      'data_nascita': formatDateOnly(dataNascita),
      'sesso': ?sesso,
      'sport': sport,
      'gruppo_id': ?gruppoId,
      if (emailGenitore != null && emailGenitore.isNotEmpty)
        'email_genitore': emailGenitore,
      if (telefonoGenitore != null && telefonoGenitore.isNotEmpty)
        'telefono_genitore': telefonoGenitore,
      'consenso_privacy_firmato': consensoPrivacyFirmato,
      if (consensoPrivacyFirmato)
        'consenso_privacy_data': formatDateOnly(DateTime.now()),
      if (note != null && note.isNotEmpty) 'note': note,
      if (numeroTesseraFin != null && numeroTesseraFin.isNotEmpty)
        'numero_tessera_fin': numeroTesseraFin,
      if (visitaMedicaScadenza != null)
        'visita_medica_scadenza': formatDateOnly(visitaMedicaScadenza),
    };
    try {
      final row = await _client
          .from('atleti')
          .insert(payload)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _salvaLocale(payload);
      await enqueueOperation(
        _db,
        tabella: 'atleti',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  /// Manda solo i campi davvero cambiati rispetto a [originale] (sia
  /// online sia nella coda offline): un aggiornamento "a tutto il modulo"
  /// rischierebbe di riportare indietro un campo che un altro dispositivo
  /// ha modificato nel frattempo, anche se qui non è mai stato toccato.
  Future<Atleta> updateAtleta({
    required Atleta originale,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppoId,
    String? emailGenitore,
    String? telefonoGenitore,
    required bool consensoPrivacyFirmato,
    DateTime? consensoPrivacyData,
    String? note,
    String? numeroTesseraFin,
    DateTime? visitaMedicaScadenza,
  }) async {
    final id = originale.id;
    final nuovaConsensoData = consensoPrivacyFirmato
        ? (consensoPrivacyData ??
              originale.consensoPrivacyData ??
              DateTime.now())
        : null;

    final payload = <String, dynamic>{
      if (nome != originale.nome) 'nome': nome,
      if (cognome != originale.cognome) 'cognome': cognome,
      if (dataNascita != originale.dataNascita)
        'data_nascita': formatDateOnly(dataNascita),
      if (sesso != originale.sesso) 'sesso': sesso,
      if (sport != originale.sport) 'sport': sport,
      if (gruppoId != originale.gruppoId) 'gruppo_id': gruppoId,
      if (emailGenitore != originale.emailGenitore)
        'email_genitore': emailGenitore,
      if (telefonoGenitore != originale.telefonoGenitore)
        'telefono_genitore': telefonoGenitore,
      if (consensoPrivacyFirmato != originale.consensoPrivacyFirmato)
        'consenso_privacy_firmato': consensoPrivacyFirmato,
      if (nuovaConsensoData != originale.consensoPrivacyData)
        'consenso_privacy_data': nuovaConsensoData == null
            ? null
            : formatDateOnly(nuovaConsensoData),
      if (note != originale.note) 'note': note,
      if (numeroTesseraFin != originale.numeroTesseraFin)
        'numero_tessera_fin': numeroTesseraFin,
      if (visitaMedicaScadenza != originale.visitaMedicaScadenza)
        'visita_medica_scadenza': visitaMedicaScadenza == null
            ? null
            : formatDateOnly(visitaMedicaScadenza),
    };
    if (payload.isEmpty) return originale;

    try {
      final row = await _client
          .from('atleti')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.atletiTable)..where((t) => t.id.equals(id))).write(
        AtletiTableCompanion(
          nome: payload.containsKey('nome')
              ? Value(nome)
              : const Value.absent(),
          cognome: payload.containsKey('cognome')
              ? Value(cognome)
              : const Value.absent(),
          dataNascita: payload.containsKey('data_nascita')
              ? Value(dataNascita)
              : const Value.absent(),
          sesso: payload.containsKey('sesso')
              ? Value(sesso)
              : const Value.absent(),
          sport: payload.containsKey('sport')
              ? Value(sport)
              : const Value.absent(),
          gruppoId: payload.containsKey('gruppo_id')
              ? Value(gruppoId)
              : const Value.absent(),
          emailGenitore: payload.containsKey('email_genitore')
              ? Value(emailGenitore)
              : const Value.absent(),
          telefonoGenitore: payload.containsKey('telefono_genitore')
              ? Value(telefonoGenitore)
              : const Value.absent(),
          consensoPrivacyFirmato:
              payload.containsKey('consenso_privacy_firmato')
              ? Value(consensoPrivacyFirmato)
              : const Value.absent(),
          consensoPrivacyData: payload.containsKey('consenso_privacy_data')
              ? Value(nuovaConsensoData)
              : const Value.absent(),
          note: payload.containsKey('note')
              ? Value(note)
              : const Value.absent(),
          numeroTesseraFin: payload.containsKey('numero_tessera_fin')
              ? Value(numeroTesseraFin)
              : const Value.absent(),
          visitaMedicaScadenza: payload.containsKey('visita_medica_scadenza')
              ? Value(visitaMedicaScadenza)
              : const Value.absent(),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'atleti',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  /// Scollega l'account atleta da questo record (FASE 9): l'atleta potra'
  /// riscattare un nuovo invito per ricollegarsi. Usa la stessa policy di
  /// update gia' esistente (is_membro_club), nessuna RPC dedicata.
  Future<void> scollegaAccount(String id) async {
    try {
      await _client.from('atleti').update({'user_id': null}).eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'atleti',
        operazione: 'update',
        rigaId: id,
        payload: {'user_id': null},
      );
      _syncEngine.processQueue();
    }
    await (_db.update(_db.atletiTable)..where((t) => t.id.equals(id))).write(
      const AtletiTableCompanion(userId: Value(null)),
    );
  }

  Future<void> setAttivo({required String id, required bool attivo}) async {
    try {
      await _client.from('atleti').update({'attivo': attivo}).eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'atleti',
        operazione: 'update',
        rigaId: id,
        payload: {'attivo': attivo},
      );
      _syncEngine.processQueue();
    }
    await (_db.update(_db.atletiTable)..where((t) => t.id.equals(id))).write(
      AtletiTableCompanion(attivo: Value(attivo)),
    );
  }

  /// Eliminazione definitiva. Sul server la cancellazione a cascata porta
  /// via test, presenze, distinta, personal best, tempi gara e iscrizioni
  /// alle gare dell'atleta, mentre gli eventi di partita restano con
  /// l'atleta azzerato (`on delete set null`): la cache locale segue la
  /// stessa regola, senza aspettare il prossimo aggiornamento dal server.
  Future<void> deleteAtleta(String id) async {
    try {
      await _client.from('atleti').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'atleti',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.personalBestTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.tempiGaraTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.testIngressoTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.tabellePassiTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.presenzeTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.distintaGiocatoriTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.delete(
        _db.garaIscrittiTable,
      )..where((t) => t.atletaId.equals(id))).go();
      await (_db.update(_db.eventiPartitaTable)
            ..where((t) => t.atletaId.equals(id)))
          .write(const EventiPartitaTableCompanion(atletaId: Value(null)));
      await (_db.delete(_db.atletiTable)..where((t) => t.id.equals(id))).go();
    });
  }
}

final atletiRepositoryProvider = Provider<AtletiRepository>((ref) {
  return AtletiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
