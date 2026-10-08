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
import '../domain/serie.dart';

const _uuid = Uuid();

class SerieRepository {
  SerieRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Serie _fromRow(SerieTableData row) {
    return Serie(
      id: row.id,
      allenamentoId: row.allenamentoId,
      clubId: row.clubId,
      ordine: row.ordine,
      blocco: row.blocco,
      ripetute: row.ripetute,
      distanzaM: row.distanzaM,
      durataS: row.durataS,
      stile: row.stile,
      esecuzione: row.esecuzione,
      zona: row.zona,
      passoObiettivoS: row.passoObiettivoS,
      recuperoS: row.recuperoS,
      ripartenzaS: row.ripartenzaS,
      attrezzatura: row.attrezzatura,
      note: row.note,
      piramideId: row.piramideId,
    );
  }

  Serie _fromMap(Map<String, dynamic> map) {
    return Serie(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      clubId: map['club_id'] as String,
      ordine: map['ordine'] as int,
      blocco: map['blocco'] as String,
      ripetute: map['ripetute'] as int,
      distanzaM: map['distanza_m'] as int?,
      durataS: map['durata_s'] as int?,
      stile: map['stile'] as String,
      esecuzione: map['esecuzione'] as String,
      zona: map['zona'] as String?,
      passoObiettivoS: (map['passo_obiettivo_s'] as num?)?.toDouble(),
      recuperoS: map['recupero_s'] as int?,
      ripartenzaS: (map['ripartenza_s'] as num?)?.toDouble(),
      attrezzatura: map['attrezzatura'] as String?,
      note: map['note'] as String?,
      piramideId: map['piramide_id'] as String?,
    );
  }

  SerieTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return SerieTableCompanion.insert(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      clubId: map['club_id'] as String,
      ordine: map['ordine'] as int? ?? 1,
      blocco: map['blocco'] as String? ?? 'principale',
      ripetute: map['ripetute'] as int? ?? 1,
      distanzaM: Value(map['distanza_m'] as int?),
      durataS: Value(map['durata_s'] as int?),
      stile: map['stile'] as String? ?? 'libero',
      esecuzione: map['esecuzione'] as String? ?? 'nuoto',
      zona: Value(map['zona'] as String?),
      passoObiettivoS: Value((map['passo_obiettivo_s'] as num?)?.toDouble()),
      recuperoS: Value(map['recupero_s'] as int?),
      ripartenzaS: Value((map['ripartenza_s'] as num?)?.toDouble()),
      attrezzatura: Value(map['attrezzatura'] as String?),
      note: Value(map['note'] as String?),
      piramideId: Value(map['piramide_id'] as String?),
    );
  }

  Stream<List<Serie>> watchPerAllenamento(String allenamentoId) {
    final query = _db.select(_db.serieTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questo allenamento (non insertOrReplace): una
  /// serie eliminata fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String allenamentoId) async {
    final rows = await _client
        .from('serie')
        .select()
        .eq('allenamento_id', allenamentoId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.serieTable,
      )..where((t) => t.allenamentoId.equals(allenamentoId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.serieTable, _companionFromMap(row));
        }
      });
    });
  }

  /// Per l'atleta collegato: le serie di UN allenamento, senza il campo
  /// libero `note` (l'atleta non legge la tabella `serie`, vedi la
  /// funzione `serie_allenamento_atleta`). Solo da rete: l'atleta non ha
  /// una cache locale delle serie.
  Future<List<Serie>> fetchPerAtleta(String allenamentoId) async {
    final risposta = await _client.rpc(
      'serie_allenamento_atleta',
      params: {'p_allenamento_id': allenamentoId},
    );
    return (risposta as List)
        .cast<Map<String, dynamic>>()
        .map(Serie.fromMap)
        .toList();
  }

  /// Letto da remoto quando possibile (dati sempre freschi per la
  /// duplicazione settimana), con fallback sulla cache locale se offline.
  Future<List<Serie>> fetchPerAllenamento(String allenamentoId) async {
    try {
      final rows = await _client
          .from('serie')
          .select()
          .eq('allenamento_id', allenamentoId)
          .order('ordine');
      return rows.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final rows =
          await (_db.select(_db.serieTable)
                ..where((t) => t.allenamentoId.equals(allenamentoId))
                ..orderBy([(t) => OrderingTerm.asc(t.ordine)]))
              .get();
      return rows.map(_fromRow).toList();
    }
  }

  /// Le serie di più allenamenti in un colpo solo, per analizzare come
  /// il gruppo è stato allenato finora (generatore settimana AI — vedi
  /// `storico_settimana_service.dart`): senza questa, occorrerebbe una
  /// chiamata per allenamento.
  Future<List<Serie>> fetchPerAllenamenti(List<String> allenamentoIds) async {
    if (allenamentoIds.isEmpty) return [];
    try {
      final rows = await _client
          .from('serie')
          .select()
          .inFilter('allenamento_id', allenamentoIds);
      return rows.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final rows = await (_db.select(
        _db.serieTable,
      )..where((t) => t.allenamentoId.isIn(allenamentoIds))).get();
      return rows.map(_fromRow).toList();
    }
  }

  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
    String? piramideId,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'allenamento_id': allenamentoId,
      'ordine': ordine,
      'blocco': blocco,
      'ripetute': ripetute,
      'distanza_m': distanzaM,
      'durata_s': durataS,
      'stile': stile,
      'esecuzione': esecuzione,
      'zona': zona,
      'passo_obiettivo_s': passoObiettivoS,
      'recupero_s': recuperoS,
      'ripartenza_s': ripartenzaS,
      'attrezzatura': attrezzatura,
      'note': note,
      'piramide_id': piramideId,
    };
    try {
      final row = await _client.from('serie').insert(payload).select().single();
      await _db
          .into(_db.serieTable)
          .insertOnConflictUpdate(_companionFromMap(row));
      return _fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id e' normalmente ricalcolato dal trigger a partire
      // dall'allenamento: offline usiamo quello gia' in cache locale.
      final allenamento = await (_db.select(
        _db.allenamentiTable,
      )..where((t) => t.id.equals(allenamentoId))).getSingle();
      final payloadConClub = {...payload, 'club_id': allenamento.clubId};
      await _db
          .into(_db.serieTable)
          .insertOnConflictUpdate(_companionFromMap(payloadConClub));
      await enqueueOperation(
        _db,
        tabella: 'serie',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
      return _fromMap(payloadConClub);
    }
  }

  Future<Serie> updateSerie({
    required String id,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,

    /// Solo dalla scrittura a testo, che rifà anche i gruppi: senza, il
    /// gruppo della serie resta com'è.
    ({String? id})? piramide,
  }) async {
    final payload = {
      'ordine': ordine,
      'blocco': blocco,
      'ripetute': ripetute,
      'distanza_m': distanzaM,
      'durata_s': durataS,
      'stile': stile,
      'esecuzione': esecuzione,
      'zona': zona,
      'passo_obiettivo_s': passoObiettivoS,
      'recupero_s': recuperoS,
      'ripartenza_s': ripartenzaS,
      'attrezzatura': attrezzatura,
      'note': note,
      if (piramide != null) 'piramide_id': piramide.id,
    };
    try {
      final row = await _client
          .from('serie')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.serieTable)
          .insertOnConflictUpdate(_companionFromMap(row));
      return _fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(_db.serieTable)..where((t) => t.id.equals(id))).write(
        SerieTableCompanion(
          ordine: Value(ordine),
          blocco: Value(blocco),
          ripetute: Value(ripetute),
          distanzaM: Value(distanzaM),
          durataS: Value(durataS),
          stile: Value(stile),
          esecuzione: Value(esecuzione),
          zona: Value(zona),
          passoObiettivoS: Value(passoObiettivoS),
          recuperoS: Value(recuperoS),
          ripartenzaS: Value(ripartenzaS),
          attrezzatura: Value(attrezzatura),
          note: Value(note),
          piramideId: piramide == null
              ? const Value.absent()
              : Value(piramide.id),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'serie',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
      final aggiornata = await (_db.select(
        _db.serieTable,
      )..where((t) => t.id.equals(id))).getSingle();
      return _fromRow(aggiornata);
    }
  }

  Future<void> deleteSerie(String id) async {
    try {
      await _client.from('serie').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'serie',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.serieTable)..where((t) => t.id.equals(id))).go();
  }
}

final serieRepositoryProvider = Provider<SerieRepository>((ref) {
  return SerieRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
