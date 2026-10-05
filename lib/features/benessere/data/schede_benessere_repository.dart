import 'dart:convert';

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
import '../domain/scheda_benessere.dart';

const _uuid = Uuid();

/// Schede benessere: scritte dall'atleta (RLS: solo le proprie), lette
/// anche dall'allenatore del club. Una per atleta al giorno, salvata con
/// upsert sulla chiave naturale (atleta_id, data), come le presenze.
class SchedeBenessereRepository {
  SchedeBenessereRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  SchedaBenessere _fromRow(SchedeBenessereTableData r) => SchedaBenessere(
    id: r.id,
    atletaId: r.atletaId,
    clubId: r.clubId,
    data: r.data,
    eventoTipo: r.eventoTipo,
    eventoId: r.eventoId,
    dolori: r.dolori,
    zoneDolore: (jsonDecode(r.zoneDoloreJson) as List).cast<String>(),
    intensitaDolore: r.intensitaDolore,
    oreSonno: r.oreSonno,
    compilataIl: r.compilataIl,
    qualitaSonno: r.qualitaSonno,
    energia: r.energia,
    muscoli: r.muscoli,
    stress: r.stress,
    umore: r.umore,
    sintomi: (jsonDecode(r.sintomiJson) as List).cast<String>(),
  );

  SchedeBenessereTableCompanion _companionFromMap(Map<String, dynamic> m) =>
      SchedeBenessereTableCompanion.insert(
        id: m['id'] as String,
        atletaId: m['atleta_id'] as String,
        clubId: m['club_id'] as String,
        data: DateTime.parse(m['data'] as String),
        eventoTipo: Value(m['evento_tipo'] as String?),
        eventoId: Value(m['evento_id'] as String?),
        dolori: m['dolori'] as bool,
        zoneDoloreJson: Value(jsonEncode(m['zone_dolore'] ?? const [])),
        intensitaDolore: Value(m['intensita_dolore'] as int?),
        oreSonno: (m['ore_sonno'] as num).toDouble(),
        qualitaSonno: Value(m['qualita_sonno'] as int?),
        energia: Value(m['energia'] as int?),
        muscoli: Value(m['muscoli'] as int?),
        stress: Value(m['stress'] as int?),
        umore: Value(m['umore'] as int?),
        sintomiJson: Value(jsonEncode(m['sintomi'] ?? const [])),
        compilataIl: DateTime.parse(
          (m['updated_at'] ??
                  m['created_at'] ??
                  DateTime.now().toIso8601String())
              as String,
        ),
      );

  /// Le schede di un atleta, dalla piu' recente.
  Stream<List<SchedaBenessere>> watchPerAtleta(String atletaId) {
    final q = _db.select(_db.schedeBenessereTable)
      ..where((t) => t.atletaId.equals(atletaId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return q.watch().map((righe) => righe.map(_fromRow).toList());
  }

  /// Le schede di tutto il club (vista squadra dell'allenatore).
  Stream<List<SchedaBenessere>> watchPerClub(String clubId) {
    final q = _db.select(_db.schedeBenessereTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.data)]);
    return q.watch().map((righe) => righe.map(_fromRow).toList());
  }

  /// Sostituzione totale per il club (solo l'allenatore la vede tutta).
  Future<void> refreshFromRemoteClub(String clubId) async {
    final righe = await _client
        .from('schede_benessere')
        .select()
        .eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.schedeBenessereTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.schedeBenessereTable, _companionFromMap(r));
        }
      });
    });
  }

  /// Sostituzione totale per l'atleta: una scheda cancellata fuori
  /// dall'app non resta "fantasma" in cache.
  Future<void> refreshFromRemote(String atletaId) async {
    final righe = await _client
        .from('schede_benessere')
        .select()
        .eq('atleta_id', atletaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.schedeBenessereTable,
      )..where((t) => t.atletaId.equals(atletaId))).go();
      await _db.batch((b) {
        for (final r in righe) {
          b.insert(_db.schedeBenessereTable, _companionFromMap(r));
        }
      });
    });
  }

  /// Salva (o aggiorna) la scheda del giorno [data]. Offline va in locale
  /// e in coda, e parte appena torna la rete.
  Future<void> salva({
    required String atletaId,
    required String clubId,
    required DateTime data,
    required bool dolori,
    required List<String> zoneDolore,
    required int? intensitaDolore,
    required double oreSonno,
    int? qualitaSonno,
    int? energia,
    int? muscoli,
    int? stress,
    int? umore,
    List<String> sintomi = const [],
    String? eventoTipo,
    String? eventoId,
  }) async {
    final giorno = DateTime(data.year, data.month, data.day);
    final esistente =
        await (_db.select(_db.schedeBenessereTable)..where(
              (t) => t.atletaId.equals(atletaId) & t.data.equals(giorno),
            ))
            .getSingleOrNull();
    final payload = {
      'id': esistente?.id ?? _uuid.v4(),
      'atleta_id': atletaId,
      'club_id': clubId,
      'data': formatDateOnly(giorno),
      'evento_tipo': eventoTipo,
      'evento_id': eventoId,
      'dolori': dolori,
      'zone_dolore': dolori ? zoneDolore : const <String>[],
      'intensita_dolore': dolori ? intensitaDolore : null,
      'ore_sonno': oreSonno,
      'qualita_sonno': qualitaSonno,
      'energia': energia,
      'muscoli': muscoli,
      'stress': stress,
      'umore': umore,
      'sintomi': sintomi,
    };
    try {
      final riga = await _client
          .from('schede_benessere')
          .upsert(payload, onConflict: 'atleta_id,data')
          .select()
          .single();
      await _db
          .into(_db.schedeBenessereTable)
          .insertOnConflictUpdate(_companionFromMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.schedeBenessereTable)
          .insertOnConflictUpdate(
            _companionFromMap({
              ...payload,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );
      await enqueueOperation(
        _db,
        tabella: 'schede_benessere',
        operazione: 'upsert',
        rigaId: payload['id']! as String,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }
}

final schedeBenessereRepositoryProvider = Provider<SchedeBenessereRepository>(
  (ref) => SchedeBenessereRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  ),
);
