import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/serie.dart';

const _uuid = Uuid();

class SerieRepository {
  SerieRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  Serie _fromRow(SerieTableData row) {
    return Serie(
      id: row.id,
      allenamentoId: row.allenamentoId,
      clubId: row.clubId,
      ordine: row.ordine,
      blocco: row.blocco,
      ripetute: row.ripetute,
      distanzaM: row.distanzaM,
      stile: row.stile,
      esecuzione: row.esecuzione,
      zona: row.zona,
      passoObiettivoS: row.passoObiettivoS,
      recuperoS: row.recuperoS,
      ripartenzaS: row.ripartenzaS,
      attrezzatura: row.attrezzatura,
      note: row.note,
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
      distanzaM: map['distanza_m'] as int,
      stile: map['stile'] as String,
      esecuzione: map['esecuzione'] as String,
      zona: map['zona'] as String?,
      passoObiettivoS: (map['passo_obiettivo_s'] as num?)?.toDouble(),
      recuperoS: map['recupero_s'] as int?,
      ripartenzaS: (map['ripartenza_s'] as num?)?.toDouble(),
      attrezzatura: map['attrezzatura'] as String?,
      note: map['note'] as String?,
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
      distanzaM: map['distanza_m'] as int,
      stile: map['stile'] as String? ?? 'libero',
      esecuzione: map['esecuzione'] as String? ?? 'nuoto',
      zona: Value(map['zona'] as String?),
      passoObiettivoS: Value((map['passo_obiettivo_s'] as num?)?.toDouble()),
      recuperoS: Value(map['recupero_s'] as int?),
      ripartenzaS: Value((map['ripartenza_s'] as num?)?.toDouble()),
      attrezzatura: Value(map['attrezzatura'] as String?),
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<Serie>> watchPerAllenamento(String allenamentoId) {
    final query = _db.select(_db.serieTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordine)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String allenamentoId) async {
    final rows = await _client
        .from('serie')
        .select()
        .eq('allenamento_id', allenamentoId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.serieTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    required int distanzaM,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
  }) async {
    final id = _uuid.v4();
    final row = await _client
        .from('serie')
        .insert({
          'id': id,
          'allenamento_id': allenamentoId,
          'ordine': ordine,
          'blocco': blocco,
          'ripetute': ripetute,
          'distanza_m': distanzaM,
          'stile': stile,
          'esecuzione': esecuzione,
          'zona': zona,
          'passo_obiettivo_s': passoObiettivoS,
          'recupero_s': recuperoS,
          'ripartenza_s': ripartenzaS,
          'attrezzatura': attrezzatura,
          'note': note,
        })
        .select()
        .single();
    await _db.into(_db.serieTable).insertOnConflictUpdate(_companionFromMap(row));
    return _fromMap(row);
  }

  Future<Serie> updateSerie({
    required String id,
    required int ordine,
    required String blocco,
    required int ripetute,
    required int distanzaM,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
  }) async {
    final row = await _client
        .from('serie')
        .update({
          'ordine': ordine,
          'blocco': blocco,
          'ripetute': ripetute,
          'distanza_m': distanzaM,
          'stile': stile,
          'esecuzione': esecuzione,
          'zona': zona,
          'passo_obiettivo_s': passoObiettivoS,
          'recupero_s': recuperoS,
          'ripartenza_s': ripartenzaS,
          'attrezzatura': attrezzatura,
          'note': note,
        })
        .eq('id', id)
        .select()
        .single();
    await _db.into(_db.serieTable).insertOnConflictUpdate(_companionFromMap(row));
    return _fromMap(row);
  }

  Future<void> deleteSerie(String id) async {
    await _client.from('serie').delete().eq('id', id);
    await (_db.delete(_db.serieTable)..where((t) => t.id.equals(id))).go();
  }
}

final serieRepositoryProvider = Provider<SerieRepository>((ref) {
  return SerieRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
