import 'dart:convert';

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

  Club _fromRow(ClubTableData row) => Club(
    id: row.id,
    nome: row.nome,
    citta: row.citta,
    sport: row.sport,
    categorie: (jsonDecode(row.categorieJson) as List)
        .map((c) => c as String)
        .toList(),
  );

  /// Legge dalla cache locale: disponibile anche offline.
  Future<List<Club>> fetchMyClubsLocal() async {
    final rows = await _db.select(_db.clubTable).get();
    final clubs = rows.map(_fromRow).toList();
    clubs.sort((a, b) => a.nome.compareTo(b.nome));
    return clubs;
  }

  /// Legge un club specifico dalla cache locale, per id — usato
  /// dall'atleta per il proprio club (gia' noto da `atleta.clubId`),
  /// invece di [fetchMyClubsLocal] (pensato per "i club di cui il coach
  /// e' membro": non ha senso per un atleta, che ne ha sempre esattamente
  /// uno e non e' detto compaia lì).
  Future<Club?> fetchByIdLocal(String clubId) async {
    final row = await (_db.select(
      _db.clubTable,
    )..where((t) => t.id.equals(clubId))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Aggiorna la cache locale per un solo club — non una sostituzione
  /// totale come [refreshFromRemote]: un atleta non deve svuotare la
  /// cache degli altri club che il coach di questo stesso device
  /// potrebbe avere.
  Future<void> refreshFromRemoteById(String clubId) async {
    final row = await _client
        .from('club')
        .select('id, nome, citta, sport, categorie')
        .eq('id', clubId)
        .maybeSingle();
    if (row == null) return;
    await _db
        .into(_db.clubTable)
        .insertOnConflictUpdate(
          ClubTableCompanion.insert(
            id: row['id'] as String,
            nome: row['nome'] as String,
            citta: Value(row['citta'] as String?),
            sport: Value(row['sport'] as String?),
            categorieJson: Value(jsonEncode(row['categorie'] ?? const [])),
          ),
        );
  }

  /// Aggiorna la cache locale con i club remoti di cui l'utente e' membro
  /// (la RLS su `club` filtra automaticamente in base a `club_membri`).
  /// Sostituzione totale (non insertOrReplace): se un club viene
  /// eliminato direttamente su Supabase (fuori dall'app, es. da SQL
  /// Editor), la sola insertOrReplace non lo toglierebbe mai dalla cache
  /// locale, che continuerebbe a proporlo come "fantasma" a tempo
  /// indeterminato.
  Future<void> refreshFromRemote() async {
    final rows = await _client
        .from('club')
        .select('id, nome, citta, sport, categorie')
        .order('nome');
    await _db.transaction(() async {
      await _db.delete(_db.clubTable).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(
            _db.clubTable,
            ClubTableCompanion.insert(
              id: row['id'] as String,
              nome: row['nome'] as String,
              citta: Value(row['citta'] as String?),
              sport: Value(row['sport'] as String?),
              categorieJson: Value(jsonEncode(row['categorie'] ?? const [])),
            ),
          );
        }
      });
    });
  }

  /// La creazione richiede una connessione (passa da una funzione RPC
  /// Supabase, vedi supabase/migrations/20260829000900_create_club_rpc.sql):
  /// creare un club offline e farlo comparire come "esistente" prima che il
  /// server lo confermi non avrebbe senso, dato che l'ownership dipende dal
  /// trigger lato DB.
  Future<Club> createClub({
    required String nome,
    String? citta,
    String? sport,
    List<String> categorie = const [],
  }) async {
    final row = await _client.rpc(
      'create_club',
      params: {
        'p_nome': nome,
        if (citta != null && citta.isNotEmpty) 'p_citta': citta,
        'p_sport': ?sport,
        'p_categorie': categorie,
      },
    ) as Map<String, dynamic>;
    final club = Club.fromMap(row);
    await _db
        .into(_db.clubTable)
        .insertOnConflictUpdate(
          ClubTableCompanion.insert(
            id: club.id,
            nome: club.nome,
            citta: Value(club.citta),
            sport: Value(club.sport),
            categorieJson: Value(jsonEncode(club.categorie)),
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
