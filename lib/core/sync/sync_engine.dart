import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/database_provider.dart';
import '../supabase/supabase_providers.dart';
import 'network_failure.dart';

/// Svuota la coda di scritture in sospeso (vedi [PendingOperationsTable])
/// verso Supabase, un'operazione alla volta e nell'ordine in cui sono
/// state accodate.
///
/// Regola di conflitto (last-write-wins su `updated_at`): non viene fatto
/// nessun confronto esplicito di timestamp lato client. Le operazioni
/// vengono semplicemente rigiocate in ordine verso il server; l'ultima
/// scrittura che arriva fisicamente a destinazione e' quella che vince,
/// e il trigger `set_updated_at()' gia' presente su ogni tabella aggiorna
/// `updated_at` di conseguenza. Se un'altra postazione ha modificato la
/// stessa riga nel frattempo, la sua modifica viene sovrascritta da questa
/// sincronizzazione: e' la stessa regola gia' documentata in ROADMAP.md.
class SyncEngine {
  SyncEngine(this._db, this._client);

  final AppDatabase _db;
  final SupabaseClient _client;

  bool _inCorso = false;

  /// Colonne del conflitto per le tabelle che si sincronizzano tramite
  /// upsert su chiave naturale invece che per id (presenze, tabelle_passi).
  static const _chiaveNaturalePerTabella = {
    'presenze': 'allenamento_id,atleta_id',
    'tabelle_passi': 'test_id,zona',
    'referti_partita': 'partita_id',
  };

  Future<void> processQueue() async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final operazioni = await (_db.select(
        _db.pendingOperationsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

      for (final op in operazioni) {
        try {
          switch (op.operazione) {
            case 'insert':
              await _client
                  .from(op.tabella)
                  .insert(
                    jsonDecode(op.payloadJson!) as Map<String, dynamic>,
                  );
            case 'update':
              await _client
                  .from(op.tabella)
                  .update(jsonDecode(op.payloadJson!) as Map<String, dynamic>)
                  .eq('id', op.rigaId);
            case 'upsert':
              // Il payload puo' essere una singola riga (Map) o piu' righe
              // in blocco (List), come per la rigenerazione delle 6 zone
              // di una tabella passi in un'unica chiamata.
              await _client
                  .from(op.tabella)
                  .upsert(
                    jsonDecode(op.payloadJson!),
                    onConflict: _chiaveNaturalePerTabella[op.tabella],
                  );
            case 'delete':
              await _client.from(op.tabella).delete().eq('id', op.rigaId);
          }
          await (_db.delete(
            _db.pendingOperationsTable,
          )..where((t) => t.id.equals(op.id))).go();
        } catch (e) {
          if (isNetworkFailure(e)) {
            // Ancora offline: interrompo qui, ritento al prossimo giro
            // (non ha senso saltare questa e provare le successive fuori
            // ordine sulla stessa riga).
            return;
          }
          // Errore reale del server (es. RLS, vincolo violato): scarto
          // l'operazione per non ritentarla all'infinito. La riga locale
          // resta com'e', l'utente puo' comunque modificarla di nuovo.
          await (_db.delete(
            _db.pendingOperationsTable,
          )..where((t) => t.id.equals(op.id))).go();
        }
      }
    } finally {
      _inCorso = false;
    }
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
  );
});

/// Numero di scritture in sospeso, per l'indicatore "sincronizzato / in
/// coda" in UI.
final pendingOperationsCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.pendingOperationsTable).watch().map((rows) => rows.length);
});
