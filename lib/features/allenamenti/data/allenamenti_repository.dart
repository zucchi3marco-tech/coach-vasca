import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/date_format.dart';
import '../domain/allenamento.dart';

class AllenamentiRepository {
  AllenamentiRepository(this._client);

  final SupabaseClient _client;

  Future<List<Allenamento>> fetchPerClub(String clubId) async {
    final rows = await _client
        .from('allenamenti')
        .select()
        .eq('club_id', clubId)
        .order('data', ascending: false);
    return rows.map(Allenamento.fromMap).toList();
  }

  Future<Allenamento> createAllenamento({
    required String clubId,
    required DateTime data,
    String? titolo,
    String? gruppo,
    String? note,
  }) async {
    final row = await _client
        .from('allenamenti')
        .insert({
          'club_id': clubId,
          'data': formatDateOnly(data),
          if (titolo != null && titolo.isNotEmpty) 'titolo': titolo,
          if (gruppo != null && gruppo.isNotEmpty) 'gruppo': gruppo,
          if (note != null && note.isNotEmpty) 'note': note,
        })
        .select()
        .single();
    return Allenamento.fromMap(row);
  }

  Future<Allenamento> updateAllenamento({
    required String id,
    required DateTime data,
    String? titolo,
    String? gruppo,
    String? note,
  }) async {
    final row = await _client
        .from('allenamenti')
        .update({
          'data': formatDateOnly(data),
          'titolo': titolo,
          'gruppo': gruppo,
          'note': note,
        })
        .eq('id', id)
        .select()
        .single();
    return Allenamento.fromMap(row);
  }

  Future<void> deleteAllenamento(String id) {
    return _client.from('allenamenti').delete().eq('id', id);
  }
}

final allenamentiRepositoryProvider = Provider<AllenamentiRepository>((ref) {
  return AllenamentiRepository(ref.watch(supabaseClientProvider));
});
