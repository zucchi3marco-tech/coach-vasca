import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/tempi_da_foto.dart';

/// Chiama la Edge Function `leggi-tempi`: la foto del foglio dei tempi
/// diventa una riga per atleta. Non salva niente: le righe le controlla
/// l'allenatore e le salva nei tempi o nei test.
class TempiFotoRepository {
  TempiFotoRepository(this._client);

  final SupabaseClient _client;

  Future<List<RigaTempiLetta>> leggi({
    required List<int> immagineBytes,
    required String mimeType,
  }) async {
    try {
      final risposta = await _client.functions.invoke(
        'leggi-tempi',
        body: {
          'immagineBase64': base64Encode(immagineBytes),
          'mimeType': mimeType,
        },
      );
      final dati = risposta.data;
      if (dati is Map && dati['righe'] is List) {
        return [
          for (final r in dati['righe'] as List)
            RigaTempiLetta.fromMap(r as Map<String, dynamic>),
        ];
      }
      throw Exception('Risposta inattesa dalla lettura del foglio: $dati');
    } on FunctionException catch (e) {
      throw Exception(_messaggioErrore(e.details));
    }
  }

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
      case 'foglio_non_valido':
        return 'Sulla foto non ho trovato nomi con dei tempi. Prova con '
            'una foto più nitida, con il foglio dritto e ben illuminato.';
      default:
        final errore = dettagli is Map ? dettagli['error'] as String? : null;
        return errore ?? 'Errore imprevisto nella lettura del foglio. Riprova.';
    }
  }
}

final tempiFotoRepositoryProvider = Provider<TempiFotoRepository>(
  (ref) => TempiFotoRepository(ref.watch(supabaseClientProvider)),
);
