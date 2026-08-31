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
      gruppo: row.gruppo,
      emailGenitore: row.emailGenitore,
      telefonoGenitore: row.telefonoGenitore,
      consensoPrivacyFirmato: row.consensoPrivacyFirmato,
      consensoPrivacyData: row.consensoPrivacyData,
      note: row.note,
      attivo: row.attivo,
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
      gruppo: Value(map['gruppo'] as String?),
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

  Future<Atleta> createAtleta({
    required String clubId,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppo,
    String? emailGenitore,
    String? telefonoGenitore,
    bool consensoPrivacyFirmato = false,
    String? note,
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
      if (gruppo != null && gruppo.isNotEmpty) 'gruppo': gruppo,
      if (emailGenitore != null && emailGenitore.isNotEmpty)
        'email_genitore': emailGenitore,
      if (telefonoGenitore != null && telefonoGenitore.isNotEmpty)
        'telefono_genitore': telefonoGenitore,
      'consenso_privacy_firmato': consensoPrivacyFirmato,
      if (consensoPrivacyFirmato)
        'consenso_privacy_data': formatDateOnly(DateTime.now()),
      if (note != null && note.isNotEmpty) 'note': note,
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

  Future<Atleta> updateAtleta({
    required String id,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppo,
    String? emailGenitore,
    String? telefonoGenitore,
    required bool consensoPrivacyFirmato,
    DateTime? consensoPrivacyData,
    String? note,
  }) async {
    final payload = {
      'nome': nome,
      'cognome': cognome,
      'data_nascita': formatDateOnly(dataNascita),
      'sesso': sesso,
      'sport': sport,
      'gruppo': gruppo,
      'email_genitore': emailGenitore,
      'telefono_genitore': telefonoGenitore,
      'consenso_privacy_firmato': consensoPrivacyFirmato,
      'consenso_privacy_data': consensoPrivacyFirmato
          ? formatDateOnly(consensoPrivacyData ?? DateTime.now())
          : null,
      'note': note,
    };
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
      await (_db.update(
        _db.atletiTable,
      )..where((t) => t.id.equals(id))).write(
        AtletiTableCompanion(
          nome: Value(nome),
          cognome: Value(cognome),
          dataNascita: Value(dataNascita),
          sesso: Value(sesso),
          sport: Value(sport),
          gruppo: Value(gruppo),
          emailGenitore: Value(emailGenitore),
          telefonoGenitore: Value(telefonoGenitore),
          consensoPrivacyFirmato: Value(consensoPrivacyFirmato),
          consensoPrivacyData: Value(
            consensoPrivacyFirmato
                ? (consensoPrivacyData ?? DateTime.now())
                : null,
          ),
          note: Value(note),
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
    await (_db.delete(_db.atletiTable)..where((t) => t.id.equals(id))).go();
  }
}

final atletiRepositoryProvider = Provider<AtletiRepository>((ref) {
  return AtletiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
