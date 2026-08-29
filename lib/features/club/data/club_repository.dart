import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/club.dart';

class ClubRepository {
  ClubRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  Club _fromRow(ClubTableData row) =>
      Club(id: row.id, nome: row.nome, citta: row.citta);

  /// Legge dalla cache locale: disponibile anche offline.
  Future<List<Club>> fetchMyClubsLocal() async {
    final rows = await _db.select(_db.clubTable).get();
    final clubs = rows.map(_fromRow).toList();
    clubs.sort((a, b) => a.nome.compareTo(b.nome));
    return clubs;
  }

  /// Aggiorna la cache locale con i club remoti di cui l'utente e' membro
  /// (la RLS su `club` filtra automaticamente in base a `club_membri`).
  Future<void> refreshFromRemote() async {
    final rows = await _client
        .from('club')
        .select('id, nome, citta')
        .order('nome');
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _db.clubTable,
          ClubTableCompanion.insert(
            id: row['id'] as String,
            nome: row['nome'] as String,
            citta: Value(row['citta'] as String?),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// La creazione richiede una connessione (passa da una funzione RPC
  /// Supabase, vedi supabase/migrations/20260829000900_create_club_rpc.sql):
  /// creare un club offline e farlo comparire come "esistente" prima che il
  /// server lo confermi non avrebbe senso, dato che l'ownership dipende dal
  /// trigger lato DB.
  Future<Club> createClub({required String nome, String? citta}) async {
    final row =
        await _client.rpc(
              'create_club',
              params: {
                'p_nome': nome,
                if (citta != null && citta.isNotEmpty) 'p_citta': citta,
              },
            )
            as Map<String, dynamic>;
    final club = Club(
      id: row['id'] as String,
      nome: row['nome'] as String,
      citta: row['citta'] as String?,
    );
    await _db
        .into(_db.clubTable)
        .insertOnConflictUpdate(
          ClubTableCompanion.insert(
            id: club.id,
            nome: club.nome,
            citta: Value(club.citta),
          ),
        );
    return club;
  }
}

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
