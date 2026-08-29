import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/presenza.dart';

class PresenzeRepository {
  PresenzeRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  Presenza _fromRow(PresenzeTableData row) {
    return Presenza(
      id: row.id,
      allenamentoId: row.allenamentoId,
      atletaId: row.atletaId,
      clubId: row.clubId,
      stato: row.stato,
      note: row.note,
    );
  }

  PresenzeTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return PresenzeTableCompanion.insert(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: Value(map['note'] as String?),
    );
  }

  Stream<List<Presenza>> watchPerAllenamento(String allenamentoId) {
    final query = _db.select(_db.presenzeTable)
      ..where((t) => t.allenamentoId.equals(allenamentoId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> refreshFromRemote(String allenamentoId) async {
    final rows = await _client
        .from('presenze')
        .select()
        .eq('allenamento_id', allenamentoId);
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.presenzeTable,
          _companionFromMap(row),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// club_id e' ricalcolato dal trigger `imposta_e_valida_presenza()` a
  /// partire da allenamento_id/atleta_id, con validazione incrociata che
  /// appartengano allo stesso club. Nessun id generato lato client: e' un
  /// upsert sulla chiave naturale (allenamento_id, atleta_id), l'id lo
  /// assegna il DB come sempre.
  Future<Presenza> segnaPresenza({
    required String allenamentoId,
    required String atletaId,
    required String stato,
  }) async {
    final row = await _client
        .from('presenze')
        .upsert(
          {
            'allenamento_id': allenamentoId,
            'atleta_id': atletaId,
            'stato': stato,
          },
          onConflict: 'allenamento_id,atleta_id',
        )
        .select()
        .single();
    await _db
        .into(_db.presenzeTable)
        .insertOnConflictUpdate(_companionFromMap(row));
    return _fromMap(row);
  }

  Presenza _fromMap(Map<String, dynamic> map) {
    return Presenza(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      stato: map['stato'] as String,
      note: map['note'] as String?,
    );
  }
}

final presenzeRepositoryProvider = Provider<PresenzeRepository>((ref) {
  return PresenzeRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
