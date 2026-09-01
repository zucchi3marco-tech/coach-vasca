import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/generazione_ai_registrata.dart';
import '../domain/parametri_generazione.dart';

const _uuid = Uuid();

/// Storico delle chiamate al modulo "Genera con AI" (FASE 5, punto 6): non
/// e' dato operativo che serve in vasca, quindi niente cache locale Drift,
/// si legge sempre da remoto. Le scritture seguono comunque lo stesso
/// pattern resiliente delle altre feature (in coda se la rete manca), ma il
/// chiamante deve trattare ogni fallimento come non bloccante: uno storico
/// mancato non deve mai impedire una generazione o un salvataggio riusciti.
class GenerazioniAiRepository {
  GenerazioniAiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Future<String> registraGenerazione({
    required String clubId,
    required ParametriGenerazione parametri,
    required String esito,
    Map<String, dynamic>? scheda,
    String? messaggioErrore,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'club_id': clubId,
      'parametri': parametri.toMap(),
      'esito': esito,
      'scheda': ?scheda,
      'messaggio_errore': ?messaggioErrore,
    };
    try {
      await _client.from('generazioni_ai').insert(payload);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'generazioni_ai',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return id;
  }

  Future<void> collegaAllenamento({
    required String generazioneId,
    required String allenamentoId,
  }) async {
    final payload = {'allenamento_id': allenamentoId};
    try {
      await _client
          .from('generazioni_ai')
          .update(payload)
          .eq('id', generazioneId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'generazioni_ai',
        operazione: 'update',
        rigaId: generazioneId,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Future<List<GenerazioneAiRegistrata>> fetchStorico(String clubId) async {
    final rows = await _client
        .from('generazioni_ai')
        .select()
        .eq('club_id', clubId)
        .order('created_at', ascending: false);
    return rows.map(GenerazioneAiRegistrata.fromMap).toList();
  }
}

final generazioniAiRepositoryProvider = Provider<GenerazioniAiRepository>((
  ref,
) {
  return GenerazioniAiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});

final storicoGenerazioniAiProvider =
    FutureProvider.family<List<GenerazioneAiRegistrata>, String>((
      ref,
      clubId,
    ) {
      return ref.watch(generazioniAiRepositoryProvider).fetchStorico(clubId);
    });
