import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/notifica.dart';

/// Avvisi per il coach (FASE 13, punto 1): online-only come lo storico
/// generazioni AI, non e' dato operativo che serve in vasca. Le righe si
/// creano solo dalle funzioni di registrazione atleta lato database, mai
/// da un insert diretto qui.
class NotificheRepository {
  NotificheRepository(this._client);

  final SupabaseClient _client;

  Future<List<Notifica>> fetchNonLette(String clubId) async {
    final righe = await _client
        .from('notifiche')
        .select()
        .eq('club_id', clubId)
        .eq('letta', false)
        .order('created_at', ascending: false);
    return righe.map(Notifica.fromMap).toList();
  }

  Future<void> segnaLetta(String id) async {
    await _client.from('notifiche').update({'letta': true}).eq('id', id);
  }
}

final notificheRepositoryProvider = Provider<NotificheRepository>((ref) {
  return NotificheRepository(ref.watch(supabaseClientProvider));
});

final notificheNonLetteProvider = FutureProvider.autoDispose
    .family<List<Notifica>, String>((ref, clubId) {
      return ref.read(notificheRepositoryProvider).fetchNonLette(clubId);
    });
