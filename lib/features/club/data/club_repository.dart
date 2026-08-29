import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/club.dart';

class ClubRepository {
  ClubRepository(this._client);

  final SupabaseClient _client;

  /// I club di cui l'utente corrente e' membro: la RLS su `club` filtra
  /// automaticamente in base a `club_membri`, nessun filtro esplicito qui.
  Future<List<Club>> fetchMyClubs() async {
    final rows = await _client
        .from('club')
        .select('id, nome, citta')
        .order('nome');
    return rows.map(Club.fromMap).toList();
  }

  /// Passa dalla funzione RPC `create_club` (SECURITY DEFINER) invece di un
  /// insert diretto: un insert diretto con RETURNING fallisce per RLS,
  /// perche' la policy di SELECT su `club` viene valutata sulla riga
  /// restituita prima che il trigger che crea la membership owner sia
  /// passato. Vedi supabase/migrations/20260829000900_create_club_rpc.sql.
  Future<Club> createClub({required String nome, String? citta}) async {
    final row = await _client.rpc(
      'create_club',
      params: {
        'p_nome': nome,
        if (citta != null && citta.isNotEmpty) 'p_citta': citta,
      },
    );
    return Club.fromMap(row as Map<String, dynamic>);
  }
}

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(ref.watch(supabaseClientProvider));
});
