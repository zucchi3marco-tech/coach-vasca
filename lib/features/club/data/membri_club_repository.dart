import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/ruolo_club.dart';

/// Un messaggio scritto apposta per chi usa l'app, arrivato da una funzione
/// del database ("Codice non trovato"): `messaggioErrore` lo mostra così
/// com'è, senza il prefisso tecnico "Errore dal server".
class MessaggioClub implements Exception {
  const MessaggioClub(this.messaggio);

  final String messaggio;

  @override
  String toString() => messaggio;
}

/// Chi lavora nel club e gli inviti per allenatori e assistenti. Online-only:
/// vive tutto sul server (funzioni della migrazione `ruoli_club`).
class MembriClubRepository {
  MembriClubRepository(this._client);

  final SupabaseClient _client;

  /// Le funzioni del database sollevano eccezioni con un testo in italiano
  /// (codice P0001): si mostra quello. Il resto (rete, permessi) lo lascia
  /// a `messaggioErrore`.
  Future<T> _chiama<T>(String funzione, Map<String, dynamic> params) async {
    try {
      return await _client.rpc(funzione, params: params) as T;
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' && e.message.isNotEmpty) {
        throw MessaggioClub(e.message);
      }
      rethrow;
    }
  }

  /// Il mio ruolo nel club, null se non ne faccio parte.
  Future<RuoloClub?> mioRuolo(String clubId) async {
    final utente = _client.auth.currentUser;
    if (utente == null) return null;
    final riga = await _client
        .from('club_membri')
        .select('ruolo')
        .eq('club_id', clubId)
        .eq('user_id', utente.id)
        .maybeSingle();
    if (riga == null) return null;
    return RuoloClub.fromDb(riga['ruolo'] as String);
  }

  Future<List<MembroClub>> membri(String clubId) async {
    final righe = await _chiama<List<dynamic>>('membri_del_club', {
      'p_club_id': clubId,
    });
    return [
      for (final riga in righe)
        MembroClub.fromMap(Map<String, dynamic>.from(riga as Map)),
    ];
  }

  /// Un codice nuovo per un allenatore o un assistente (solo il
  /// responsabile). Vale 7 giorni, una volta sola.
  Future<String> generaInvito(String clubId, RuoloClub ruolo) {
    return _chiama<String>('genera_invito_staff', {
      'p_club_id': clubId,
      'p_ruolo': ruolo.db,
    });
  }

  /// Di che club è il codice e con che ruolo si entra; null se non vale più.
  Future<InvitoStaff?> validaInvito(String codice) async {
    final righe = await _chiama<List<dynamic>>('valida_invito_staff', {
      'p_codice': codice,
    });
    if (righe.isEmpty) return null;
    final riga = Map<String, dynamic>.from(righe.first as Map);
    return InvitoStaff(
      clubNome: riga['club_nome'] as String,
      ruolo: RuoloClub.fromDb(riga['ruolo'] as String),
    );
  }

  /// Entra nel club del codice con il proprio nome. Torna l'id del club.
  Future<String> entraConInvito(String codice, String nome) {
    return _chiama<String>('entra_con_invito_staff', {
      'p_codice': codice,
      'p_nome': nome,
    });
  }

  Future<void> cambiaRuolo(String clubId, String userId, RuoloClub ruolo) {
    return _chiama<dynamic>('cambia_ruolo_membro', {
      'p_club_id': clubId,
      'p_user_id': userId,
      'p_ruolo': ruolo.db,
    });
  }

  Future<void> togliMembro(String clubId, String userId) {
    return _chiama<dynamic>('togli_membro', {
      'p_club_id': clubId,
      'p_user_id': userId,
    });
  }

  Future<void> scriviMioNome(String clubId, String nome) {
    return _chiama<dynamic>('mio_nome_nel_club', {
      'p_club_id': clubId,
      'p_nome': nome,
    });
  }
}

final membriClubRepositoryProvider = Provider<MembriClubRepository>((ref) {
  return MembriClubRepository(ref.watch(supabaseClientProvider));
});
