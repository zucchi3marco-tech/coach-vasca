import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/serie.dart';

class SerieRepository {
  SerieRepository(this._client);

  final SupabaseClient _client;

  Future<List<Serie>> fetchPerAllenamento(String allenamentoId) async {
    final rows = await _client
        .from('serie')
        .select()
        .eq('allenamento_id', allenamentoId)
        .order('ordine');
    return rows.map(Serie.fromMap).toList();
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
    final row = await _client
        .from('serie')
        .insert({
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
    return Serie.fromMap(row);
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
    return Serie.fromMap(row);
  }

  Future<void> deleteSerie(String id) {
    return _client.from('serie').delete().eq('id', id);
  }
}

final serieRepositoryProvider = Provider<SerieRepository>((ref) {
  return SerieRepository(ref.watch(supabaseClientProvider));
});
