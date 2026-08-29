import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/date_format.dart';
import '../domain/atleta.dart';

class AtletiRepository {
  AtletiRepository(this._client);

  final SupabaseClient _client;

  Future<List<Atleta>> fetchAtleti({
    required String clubId,
    bool includeInactive = false,
  }) async {
    var query = _client.from('atleti').select().eq('club_id', clubId);
    if (!includeInactive) {
      query = query.eq('attivo', true);
    }
    final rows = await query.order('cognome').order('nome');
    return rows.map(Atleta.fromMap).toList();
  }

  Future<Atleta> createAtleta({
    required String clubId,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppo,
    String? emailGenitore,
    String? telefonoGenitore,
    bool consensoPrivacyFirmato = false,
    String? note,
  }) async {
    final row = await _client
        .from('atleti')
        .insert({
          'club_id': clubId,
          'nome': nome,
          'cognome': cognome,
          'data_nascita': formatDateOnly(dataNascita),
          'sesso': ?sesso,
          'sport': sport,
          if (gruppo != null && gruppo.isNotEmpty) 'gruppo': gruppo,
          if (emailGenitore != null && emailGenitore.isNotEmpty)
            'email_genitore': emailGenitore,
          if (telefonoGenitore != null && telefonoGenitore.isNotEmpty)
            'telefono_genitore': telefonoGenitore,
          'consenso_privacy_firmato': consensoPrivacyFirmato,
          if (consensoPrivacyFirmato)
            'consenso_privacy_data': formatDateOnly(DateTime.now()),
          if (note != null && note.isNotEmpty) 'note': note,
        })
        .select()
        .single();
    return Atleta.fromMap(row);
  }

  Future<Atleta> updateAtleta({
    required String id,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
    String? gruppo,
    String? emailGenitore,
    String? telefonoGenitore,
    required bool consensoPrivacyFirmato,
    DateTime? consensoPrivacyData,
    String? note,
  }) async {
    final row = await _client
        .from('atleti')
        .update({
          'nome': nome,
          'cognome': cognome,
          'data_nascita': formatDateOnly(dataNascita),
          'sesso': sesso,
          'sport': sport,
          'gruppo': gruppo,
          'email_genitore': emailGenitore,
          'telefono_genitore': telefonoGenitore,
          'consenso_privacy_firmato': consensoPrivacyFirmato,
          'consenso_privacy_data': consensoPrivacyFirmato
              ? formatDateOnly(consensoPrivacyData ?? DateTime.now())
              : null,
          'note': note,
        })
        .eq('id', id)
        .select()
        .single();
    return Atleta.fromMap(row);
  }

  Future<void> setAttivo({required String id, required bool attivo}) {
    return _client.from('atleti').update({'attivo': attivo}).eq('id', id);
  }

  Future<void> deleteAtleta(String id) {
    return _client.from('atleti').delete().eq('id', id);
  }
}

final atletiRepositoryProvider = Provider<AtletiRepository>((ref) {
  return AtletiRepository(ref.watch(supabaseClientProvider));
});
