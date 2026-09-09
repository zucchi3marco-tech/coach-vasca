import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/atleta.dart';
import '../domain/codice_gruppo.dart';

/// Gruppo e nome del club a cui appartiene un codice di gruppo, per la
/// conferma prima della registrazione.
typedef GruppoInvitato = ({String gruppoNome, String clubNome});

/// Codici riutilizzabili per registrare più atleti dello stesso gruppo
/// in una volta sola (FASE 9). Online-only, come InvitiAtletaRepository:
/// e' una schermata di amministrazione poco usata, non serve cache
/// locale.
class CodiciGruppoRepository {
  CodiciGruppoRepository(this._client);

  final SupabaseClient _client;

  Future<String> generaCodice({
    required String clubId,
    required String gruppoId,
  }) async {
    final risultato = await _client.rpc(
      'genera_codice_gruppo',
      params: {'p_club_id': clubId, 'p_gruppo_id': gruppoId},
    );
    return risultato as String;
  }

  Future<List<CodiceGruppo>> elencoPerClub(String clubId) async {
    final righe = await _client
        .from('codici_gruppo')
        .select('*, gruppi(nome)')
        .eq('club_id', clubId)
        .order('creato_il', ascending: false);
    return righe.map(CodiceGruppo.fromMap).toList();
  }

  /// Controlla che un codice di gruppo sia valido (esiste, non scaduto)
  /// e ritorna gruppo/club per la conferma. Callable anche prima del
  /// login.
  Future<GruppoInvitato?> validaCodice(String codice) async {
    final righe =
        await _client.rpc(
              'valida_codice_gruppo',
              params: {'p_codice': codice},
            )
            as List;
    if (righe.isEmpty) return null;
    final riga = righe.first as Map<String, dynamic>;
    return (
      gruppoNome: riga['gruppo_nome'] as String,
      clubNome: riga['club_nome'] as String,
    );
  }

  /// Da chiamare subito dopo la signUp(): crea il record atleti (non
  /// esiste ancora) con i dati inseriti dall'atleta stesso.
  Future<Atleta> registraConCodice({
    required String codice,
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    String? sesso,
    required String sport,
  }) async {
    final row =
        await _client.rpc(
              'registra_atleta_da_codice_gruppo',
              params: {
                'p_codice': codice,
                'p_nome': nome,
                'p_cognome': cognome,
                'p_data_nascita': dataNascita.toIso8601String().split('T').first,
                'p_sesso': ?sesso,
                'p_sport': sport,
              },
            )
            as Map<String, dynamic>;
    return Atleta.fromMap(row);
  }
}

final codiciGruppoRepositoryProvider = Provider<CodiciGruppoRepository>((
  ref,
) {
  return CodiciGruppoRepository(ref.watch(supabaseClientProvider));
});
