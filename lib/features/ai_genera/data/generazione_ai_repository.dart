import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/parametri_generazione.dart';
import '../domain/scheda_generata.dart';

/// Chiama la Edge Function `genera-allenamento`, che tiene la chiave del
/// provider AI lato server e la inoltra a Gemini. Così il provider si può
/// cambiare in futuro riscrivendo solo la Edge Function, senza toccare
/// l'app. La Edge Function valida già la scheda contro i valori noti
/// (blocco/stile/esecuzione/zona): qui ci si fida della forma dei dati.
class GenerazioneAiRepository {
  GenerazioneAiRepository(this._client);

  final SupabaseClient _client;

  Future<SchedaGenerata> generaAllenamento(
    ParametriGenerazione parametri,
  ) async {
    try {
      final risposta = await _client.functions.invoke(
        'genera-allenamento',
        body: {
          'gruppo': parametri.gruppo,
          'livello': parametri.livello,
          'volumeMetri': parametri.volumeMetri,
          'focus': parametri.focus,
          'regimiAmmessi': parametri.regimiAmmessi,
          'vincoli': parametri.vincoli,
          'corsie': parametri.corsie.map((c) => c.toMap()).toList(),
        },
      );
      final dati = risposta.data;
      if (dati is Map && dati['scheda'] is Map) {
        return SchedaGenerata.fromMap(dati['scheda'] as Map<String, dynamic>);
      }
      throw Exception('Risposta inattesa dalla generazione AI: $dati');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      if (dettagli is Map && dettagli['error'] is String) {
        throw Exception(dettagli['error'] as String);
      }
      rethrow;
    }
  }
}

final generazioneAiRepositoryProvider = Provider<GenerazioneAiRepository>((
  ref,
) {
  return GenerazioneAiRepository(ref.watch(supabaseClientProvider));
});
