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
import '../domain/schema_tattico.dart';

const _uuid = Uuid();

PuntoSchema _puntoDaLista(List lista) =>
    ((lista[0] as num).toDouble(), (lista[1] as num).toDouble());

List<GiocatoreSchema> _giocatoriFromDati(Map<String, dynamic> dati) {
  final lista = dati['giocatori'] as List? ?? const [];
  return [
    for (final g in lista)
      (
        punto: _puntoDaLista(g['punto'] as List),
        // Fallback prudente: schemi salvati prima dell'introduzione dei
        // colori (nessuno, in pratica) non hanno questo campo.
        colore: g['colore'] as String? ?? 'blu',
      ),
  ];
}

List<FrecciaSchema> _frecceFromDati(Map<String, dynamic> dati) {
  final lista = dati['frecce'] as List? ?? const [];
  return [
    for (final f in lista)
      (
        inizio: _puntoDaLista(f['inizio'] as List),
        fine: _puntoDaLista(f['fine'] as List),
        colore: f['colore'] as String? ?? 'blu',
      ),
  ];
}

Map<String, dynamic> _passoToMap(PassoSchema passo) => {
  'giocatori': [
    for (final g in passo.giocatori)
      {
        'punto': [g.punto.$1, g.punto.$2],
        'colore': g.colore,
      },
  ],
  'frecce': [
    for (final f in passo.frecce)
      {
        'inizio': [f.inizio.$1, f.inizio.$2],
        'fine': [f.fine.$1, f.fine.$2],
        'colore': f.colore,
      },
  ],
};

PassoSchema _passoFromMap(Map<String, dynamic> map) =>
    (giocatori: _giocatoriFromDati(map), frecce: _frecceFromDati(map));

Map<String, dynamic> _datiToMap(List<PassoSchema> passi) => {
  'passi': [for (final p in passi) _passoToMap(p)],
};

List<PassoSchema> _passiFromDati(Map<String, dynamic> dati) {
  final passiRaw = dati['passi'] as List?;
  if (passiRaw == null) {
    // Compatibilita' con gli schemi salvati prima dell'introduzione dei
    // passi (un solo passo implicito, i dati stavano direttamente qui).
    return [_passoFromMap(dati)];
  }
  return [for (final p in passiRaw) _passoFromMap(p as Map<String, dynamic>)];
}

/// Schemi tattici salvati dall'allenatore (pallanuoto): a differenza
/// della lavagna libera di prima (solo locale), qui ogni schema si
/// salva e diventa sfogliabile dagli atleti (RLS lato server: il coach
/// legge e scrive, l'atleta collegato solo legge).
class SchemiTatticiRepository {
  SchemiTatticiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  SchemaTattico _fromRow(SchemiTatticiTableData row) {
    final dati = jsonDecode(row.dati) as Map<String, dynamic>;
    return SchemaTattico(
      id: row.id,
      clubId: row.clubId,
      titolo: row.titolo,
      categoria: row.categoria,
      campo: row.campo,
      passi: _passiFromDati(dati),
      aggiornatoIl: row.aggiornatoIl,
    );
  }

  SchemiTatticiTableCompanion _companionFromMap(Map<String, dynamic> map) {
    final dati = map['dati'] as Map<String, dynamic>;
    return SchemiTatticiTableCompanion.insert(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      titolo: map['titolo'] as String,
      categoria: Value(map['categoria'] as String? ?? ''),
      campo: Value(map['campo'] as String? ?? 'intero'),
      dati: jsonEncode(dati),
      aggiornatoIl: DateTime.parse(map['updated_at'] as String),
    );
  }

  Future<void> _salvaLocale(Map<String, dynamic> row) {
    return _db
        .into(_db.schemiTatticiTable)
        .insertOnConflictUpdate(_companionFromMap(row));
  }

  Stream<List<SchemaTattico>> watchPerClub(String clubId) {
    final query = _db.select(_db.schemiTatticiTable)
      ..where((t) => t.clubId.equals(clubId))
      ..orderBy([(t) => OrderingTerm.desc(t.aggiornatoIl)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per il club (non insertOrReplace): uno schema
  /// eliminato fuori dall'app resterebbe altrimenti "fantasma" in cache.
  Future<void> refreshFromRemote(String clubId) async {
    final rows = await _client
        .from('schemi_tattici')
        .select()
        .eq('club_id', clubId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.schemiTatticiTable,
      )..where((t) => t.clubId.equals(clubId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.schemiTatticiTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<void> creaSchema({
    required String clubId,
    required String titolo,
    required String categoria,
    required String campo,
    required List<PassoSchema> passi,
  }) async {
    final id = _uuid.v4();
    final ora = DateTime.now();
    final payload = {
      'id': id,
      'club_id': clubId,
      'titolo': titolo,
      'categoria': categoria,
      'campo': campo,
      'dati': _datiToMap(passi),
    };
    try {
      final row = await _client
          .from('schemi_tattici')
          .insert(payload)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _salvaLocale({...payload, 'updated_at': ora.toIso8601String()});
      await enqueueOperation(
        _db,
        tabella: 'schemi_tattici',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> aggiornaSchema({
    required String id,
    required String titolo,
    required String categoria,
    required String campo,
    required List<PassoSchema> passi,
  }) async {
    final ora = DateTime.now();
    final payload = {
      'titolo': titolo,
      'categoria': categoria,
      'campo': campo,
      'dati': _datiToMap(passi),
    };
    try {
      final row = await _client
          .from('schemi_tattici')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _salvaLocale(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.schemiTatticiTable,
      )..where((t) => t.id.equals(id))).write(
        SchemiTatticiTableCompanion(
          titolo: Value(titolo),
          categoria: Value(categoria),
          campo: Value(campo),
          dati: Value(jsonEncode(_datiToMap(passi))),
          aggiornatoIl: Value(ora),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'schemi_tattici',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<void> eliminaSchema(String id) async {
    try {
      await _client.from('schemi_tattici').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'schemi_tattici',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.schemiTatticiTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final schemiTatticiRepositoryProvider = Provider<SchemiTatticiRepository>((
  ref,
) {
  return SchemiTatticiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
