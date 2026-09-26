import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/push/push_tipi.dart';
import '../../../core/supabase/supabase_providers.dart';

/// Salva su Supabase l'iscrizione push di questo browser (una per
/// telefono/browser). Passa da una funzione del database: lo stesso
/// telefono puo' passare da un account all'altro (stesso indirizzo di
/// iscrizione) e un insert diretto verrebbe bloccato dalle regole di
/// accesso.
class PushRepository {
  PushRepository(this._client);

  final SupabaseClient _client;

  Future<void> registra(IscrizionePush iscrizione, {String? userAgent}) async {
    await _client.rpc<void>(
      'registra_push_subscription',
      params: {
        'p_endpoint': iscrizione.endpoint,
        'p_p256dh': iscrizione.p256dh,
        'p_auth_key': iscrizione.authKey,
        'p_user_agent': userAgent,
      },
    );
  }
}

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(ref.watch(supabaseClientProvider));
});
