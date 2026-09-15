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
import '../domain/partita.dart';

const _uuid = Uuid();

class PartiteRepository {
  PartiteRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Partita _fromRow(PartiteTableData row) {
    return Partita(
      id: row.id,
      clubId: row.clubId,
      data: row.data,
      ora: row.ora,
      luogo: row.luogo,
      campionato: row.campionato,
      coloreCalottina: row.coloreCalottina,
      squadraCasa: row.squadraCasa,
      squadraTrasferta: row.squadraTrasferta,
      numeroMaxConvocati: row.numeroMaxConvocati,
      note: row.note,
      dettaglioTiro: row.dettaglioTiro,
      tracciaTempo: row.tracciaTempo,
      modalitaSuperiorita: row.modalitaSuperiorita,
      nostraSquadra: row.nostraSquadra,
    );
  }

  PartiteTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return PartiteTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      data: DateTime.parse(map['data'] as String),
      ora: Value(map['ora'] as String?),
      luogo: Value(map['luogo'] as String?),
      campionato: Value(map['campionato'] as String?),
      coloreCalottina: Value(map['colore_calottina'] as String?),
      squadraCasa: map['squadra_casa'] as String,
      squadraTrasferta: map['squadra_trasferta'] as String,
      numeroMaxConvocati: Value(map['numero_max_convocati'] as int? ?? 15),
      note: Value(map['note'] as String?),
      dettaglioTiro: Value(map['dettaglio_tiro'] as String? ?? 'semplice'),
      tracciaTempo: Value(map['traccia_tempo'] as bool? ?? true),
      modalitaSuperiorita: Value(
        map['modalita_superiorita'] as String? ?? 'singolo',
      ),
      nostraSquadra: Value(map['nostra_squadra'] as String? ?? 'casa'),
    );
  }

  Stream<List<Partita>> watchPerClub(String clubId) {
    final query = _db.select(_db.partiteTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo club (non insertOrReplace): una
  /// partita eliminata fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client.from('partite').select().eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.partiteTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.partiteTable, _companionFromMap(row));
        }
      });
    });
  }

  /// Ultima partita creata per questo club (per data), usata per
  /// precompilare le impostazioni eventi (dettaglio tiro, traccia tempo,
  /// modalita' superiorita') di una nuova partita.
  Future<Partita?> ultimaPerClub(String clubId) async {
    final rows =
        await (_db.select(_db.partiteTable)
              ..where((t) => t.clubId.equals(clubId))
              ..orderBy([(t) => OrderingTerm.desc(t.data)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Partite del club con data nell'intervallo [dataInizio, dataFine]
  /// (estremi inclusi), per le statistiche stagionali.
  Future<List<Partita>> perClubEPeriodo({
    required String clubId,
    required DateTime dataInizio,
    required DateTime dataFine,
  }) async {
    try {
      final rows = await _client
          .from('partite')
          .select()
          .eq('club_id', clubId)
          .gte('data', formatDateOnly(dataInizio))
          .lte('data', formatDateOnly(dataFine));
      return [for (final r in rows) Partita.fromMap(r)];
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe =
          await (_db.select(_db.partiteTable)
                ..where((t) => t.clubId.equals(clubId))
                ..where((t) => t.data.isBiggerOrEqualValue(dataInizio))
                ..where((t) => t.data.isSmallerOrEqualValue(dataFine)))
              .get();
      return righe.map(_fromRow).toList();
    }
  }

  /// Prossima partita in agenda per il club (FASE 13, punto 3, "prossimo
  /// evento" nella home dell'atleta) — null se non ce ne sono di future.
  Future<Partita?> prossimaPerClub(String clubId) async {
    final oggi = formatDateOnly(DateTime.now());
    try {
      final rows = await _client
          .from('partite')
          .select()
          .eq('club_id', clubId)
          .gte('data', oggi)
          .order('data')
          .limit(1);
      return rows.isEmpty ? null : Partita.fromMap(rows.first);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final rows =
          await (_db.select(_db.partiteTable)
                ..where((t) => t.clubId.equals(clubId))
                ..where((t) => t.data.isBiggerOrEqualValue(DateTime.now()))
                ..orderBy([(t) => OrderingTerm.asc(t.data)])
                ..limit(1))
              .get();
      return rows.isEmpty ? null : _fromRow(rows.first);
    }
  }

  Future<Partita> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.partiteTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<Partita> createPartita({
    required String clubId,
    required DateTime data,
    String? ora,
    String? luogo,
    String? campionato,
    String? coloreCalottina,
    required String squadraCasa,
    required String squadraTrasferta,
    required int numeroMaxConvocati,
    String? note,
    required String dettaglioTiro,
    required bool tracciaTempo,
    required String modalitaSuperiorita,
    required String nostraSquadra,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'data': formatDateOnly(data),
      if (ora != null && ora.isNotEmpty) 'ora': ora,
      if (luogo != null && luogo.isNotEmpty) 'luogo': luogo,
      if (campionato != null && campionato.isNotEmpty) 'campionato': campionato,
      if (coloreCalottina != null && coloreCalottina.isNotEmpty)
        'colore_calottina': coloreCalottina,
      'squadra_casa': squadraCasa,
      'squadra_trasferta': squadraTrasferta,
      'numero_max_convocati': numeroMaxConvocati,
      if (note != null && note.isNotEmpty) 'note': note,
      'dettaglio_tiro': dettaglioTiro,
      'traccia_tempo': tracciaTempo,
      'modalita_superiorita': modalitaSuperiorita,
      'nostra_squadra': nostraSquadra,
    };
    try {
      final row = await _client
          .from('partite')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.partiteTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.partiteTable)
          .insertOnConflictUpdate(_companionFromMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'partite',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<Partita> updatePartita({
    required String id,
    required DateTime data,
    String? ora,
    String? luogo,
    String? campionato,
    String? coloreCalottina,
    required String squadraCasa,
    required String squadraTrasferta,
    required int numeroMaxConvocati,
    String? note,
    required String dettaglioTiro,
    required bool tracciaTempo,
    required String modalitaSuperiorita,
    required String nostraSquadra,
  }) async {
    final payload = {
      'data': formatDateOnly(data),
      'ora': ora,
      'luogo': luogo,
      'campionato': campionato,
      'colore_calottina': coloreCalottina,
      'squadra_casa': squadraCasa,
      'squadra_trasferta': squadraTrasferta,
      'numero_max_convocati': numeroMaxConvocati,
      'note': note,
      'dettaglio_tiro': dettaglioTiro,
      'traccia_tempo': tracciaTempo,
      'modalita_superiorita': modalitaSuperiorita,
      'nostra_squadra': nostraSquadra,
    };
    try {
      final row = await _client
          .from('partite')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.partiteTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.partiteTable)..where((t) => t.id.equals(id))).write(
        PartiteTableCompanion(
          data: Value(data),
          ora: Value(ora),
          luogo: Value(luogo),
          campionato: Value(campionato),
          coloreCalottina: Value(coloreCalottina),
          squadraCasa: Value(squadraCasa),
          squadraTrasferta: Value(squadraTrasferta),
          numeroMaxConvocati: Value(numeroMaxConvocati),
          note: Value(note),
          dettaglioTiro: Value(dettaglioTiro),
          tracciaTempo: Value(tracciaTempo),
          modalitaSuperiorita: Value(modalitaSuperiorita),
          nostraSquadra: Value(nostraSquadra),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'partite',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> deletePartita(String id) async {
    try {
      await _client.from('partite').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'partite',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.partiteTable)..where((t) => t.id.equals(id))).go();
  }
}

final partiteRepositoryProvider = Provider<PartiteRepository>((ref) {
  return PartiteRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
