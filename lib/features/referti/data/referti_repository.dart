import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/referto_letto.dart';

/// Chiama la Edge Function `leggi-referto`, che tiene la chiave del
/// provider AI lato server e la inoltra a Gemini in modalita' visione.
class RefertiRepository {
  RefertiRepository(this._client);

  final SupabaseClient _client;

  Future<RefertoLetto> leggiReferto({
    required List<int> immagineBytes,
    required String mimeType,
  }) async {
    try {
      final risposta = await _client.functions.invoke(
        'leggi-referto',
        body: {
          'immagineBase64': base64Encode(immagineBytes),
          'mimeType': mimeType,
        },
      );
      final dati = risposta.data;
      if (dati is Map && dati['referto'] is Map) {
        return RefertoLetto.fromMap(dati['referto'] as Map<String, dynamic>);
      }
      throw Exception('Risposta inattesa dalla lettura del referto: $dati');
    } on FunctionException catch (e) {
      throw Exception(_messaggioErrore(e.details));
    }
  }

  /// Traduce il codice d'errore restituito dalla Edge Function in un
  /// messaggio chiaro: un problema di rete/provider e' quasi sempre
  /// transitorio (vale la pena riprovare), una lettura non valida indica
  /// piuttosto una foto poco leggibile.
  String _messaggioErrore(Object? dettagli) {
    final codice = dettagli is Map ? dettagli['codice'] as String? : null;
    switch (codice) {
      case 'chiave_non_configurata':
        return 'Il servizio di lettura non è configurato correttamente. '
            'Contatta l\'assistenza.';
      case 'provider_non_raggiungibile':
      case 'provider_errore':
      case 'risposta_non_valida':
        return 'Il servizio di lettura non ha risposto correttamente. '
            'Riprova tra qualche istante.';
      case 'referto_non_valido':
        return 'Non sono riuscito a leggere bene la foto del referto. '
            'Prova con una foto più nitida o riprova.';
      default:
        final errore = dettagli is Map ? dettagli['error'] as String? : null;
        return errore ?? 'Errore imprevisto nella lettura del referto. Riprova.';
    }
  }
}

final refertiRepositoryProvider = Provider<RefertiRepository>((ref) {
  return RefertiRepository(ref.watch(supabaseClientProvider));
});
