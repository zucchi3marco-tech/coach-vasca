import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/modifica_allenamento.dart';

/// Le modifiche agli allenamenti da controllare, per il capo della
/// squadra. Online-only: vivono solo sul server, e le regole di accesso
/// (RLS) fanno vedere le righe solo al capo a cui sono destinate.
class ModificheRepository {
  ModificheRepository(this._client);

  final SupabaseClient _client;

  static const _campi = '*, allenamenti(titolo, data, gruppo_id)';

  /// Le modifiche non ancora viste, dalla più recente.
  Future<List<ModificaAllenamento>> daControllare(String clubId) async {
    final righe = await _client
        .from('modifiche_allenamento')
        .select(_campi)
        .eq('club_id', clubId)
        .isFilter('visto_at', null)
        .order('ultima_at', ascending: false);
    return [
      for (final riga in righe)
        ModificaAllenamento.fromMap(Map<String, dynamic>.from(riga)),
    ];
  }

  /// La modifica ancora da vedere di un allenamento, se c'è.
  Future<ModificaAllenamento?> aperta(String allenamentoId) async {
    final riga = await _client
        .from('modifiche_allenamento')
        .select(_campi)
        .eq('allenamento_id', allenamentoId)
        .isFilter('visto_at', null)
        .maybeSingle();
    if (riga == null) return null;
    return ModificaAllenamento.fromMap(Map<String, dynamic>.from(riga));
  }

  Future<void> segnaVista(String id) async {
    await _client.rpc('segna_modifica_vista', params: {'p_id': id});
  }
}

final modificheRepositoryProvider = Provider<ModificheRepository>((ref) {
  return ModificheRepository(ref.watch(supabaseClientProvider));
});
