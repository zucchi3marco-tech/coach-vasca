import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/atleta.dart';

/// Nome e cognome dell'atleta a cui appartiene un codice invito, per
/// mostrare una conferma prima di completare la registrazione.
typedef AtletaInvitato = ({String nome, String cognome});

/// Collegamento account atleta ↔ record in rubrica (FASE 9), tramite
/// codice di invito monouso. Richiede sempre connessione (le RPC sotto
/// non hanno un fallback offline, come create_club).
class InvitiAtletaRepository {
  InvitiAtletaRepository(this._client);

  final SupabaseClient _client;

  /// Genera un nuovo codice invito per un atleta (solo coach del club).
  Future<String> generaInvito(String atletaId) async {
    final risultato = await _client.rpc(
      'genera_invito_atleta',
      params: {'p_atleta_id': atletaId},
    );
    return risultato as String;
  }

  /// Controlla che un codice sia valido (esiste, non scaduto, non usato)
  /// e ritorna nome/cognome dell'atleta per la conferma. Callable anche
  /// prima del login.
  Future<AtletaInvitato?> validaCodice(String codice) async {
    final righe = await _client.rpc(
      'valida_codice_invito',
      params: {'p_codice': codice},
    ) as List;
    if (righe.isEmpty) return null;
    final riga = righe.first as Map<String, dynamic>;
    return (nome: riga['nome'] as String, cognome: riga['cognome'] as String);
  }

  /// Da chiamare subito dopo la signUp(): collega l'utente appena
  /// autenticato all'atleta del codice.
  Future<Atleta> collegaConCodice(String codice) async {
    final row =
        await _client.rpc(
              'collega_atleta_da_invito',
              params: {'p_codice': codice},
            )
            as Map<String, dynamic>;
    return Atleta.fromMap(row);
  }
}

final invitiAtletaRepositoryProvider = Provider<InvitiAtletaRepository>((
  ref,
) {
  return InvitiAtletaRepository(ref.watch(supabaseClientProvider));
});
