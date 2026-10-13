import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/modalita_demo.dart';
import '../../../core/supabase/supabase_providers.dart';
import 'cervello_demo.dart';

/// Il "cervello" dell'assistente: la funzione `assistente` sul server, che
/// passa la conversazione al modello. Riceve solo codici e numeri già
/// calcolati sul telefono (mai nomi, mai dati sulla salute) e restituisce
/// il prossimo messaggio dell'assistente.
class AssistenteRepository {
  AssistenteRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> prossimoMessaggio({
    required String clubId,
    required Map<String, Object?> contesto,
    required List<Map<String, dynamic>> messaggi,
  }) async {
    // Nella demo l'AI non c'è: una traccia fissa per le domande d'esempio.
    if (modalitaDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return cervelloDemo(messaggi);
    }
    try {
      final risposta = await _client.functions.invoke(
        'assistente',
        body: {'club_id': clubId, 'contesto': contesto, 'messaggi': messaggi},
      );
      final dati = risposta.data;
      if (dati is Map && dati['messaggio'] is Map) {
        return (dati['messaggio'] as Map).cast<String, dynamic>();
      }
      throw Exception('Risposta inattesa dall\'assistente.');
    } on FunctionException catch (e) {
      final dettagli = e.details;
      final errore = dettagli is Map ? dettagli['error'] as String? : null;
      throw Exception(
        errore ?? 'L\'assistente non ha risposto. Riprova tra qualche istante.',
      );
    }
  }
}

final assistenteRepositoryProvider = Provider<AssistenteRepository>(
  (ref) => AssistenteRepository(ref.watch(supabaseClientProvider)),
);
