import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/database_provider.dart';
import '../supabase/supabase_providers.dart';
import 'modifiche_rifiutate.dart';
import 'network_failure.dart';

/// La riga sul server è stata cambiata da qualcun altro dopo la modifica
/// in coda: [aggiornata] (il suo `updated_at`) è dopo [fatta] (quando la
/// modifica è stata fatta, in ora del server) e dopo l'ultima volta che
/// questo telefono l'ha scritta ([scrittaDaMe]).
bool cambiataDaAltri({
  required DateTime aggiornata,
  required DateTime fatta,
  DateTime? scrittaDaMe,
}) {
  final soglia = scrittaDaMe != null && scrittaDaMe.isAfter(fatta)
      ? scrittaDaMe
      : fatta;
  return aggiornata.isAfter(soglia);
}

/// Quando è stata fatta una modifica, in ora del server: [oraServer] è
/// l'ora del server quando sul telefono erano le [adesso]. Così non conta
/// se l'orologio del telefono è avanti o indietro.
DateTime fattaInOraServer({
  required DateTime creataIl,
  required DateTime adesso,
  required DateTime oraServer,
}) {
  final eta = adesso.difference(creataIl);
  return oraServer.subtract(eta.isNegative ? Duration.zero : eta);
}

/// Svuota la coda di scritture in sospeso (vedi [PendingOperationsTable])
/// verso Supabase, un'operazione alla volta e nell'ordine in cui sono
/// state accodate.
///
/// Conflitti (problema 6 del «Piano di WaterTactics», scelta del coach):
/// prima di rimandare una modifica, cambiamento o eliminazione, si guarda
/// la riga sul server. Se intanto qualcun altro l'ha cambiata (il suo
/// `updated_at` è dopo il momento della modifica) o l'ha tolta, la
/// modifica non si manda: resta la versione del collega, la spia lo dice
/// ([ModificaRifiutata.conflitto]) e [suConflitto] fa rileggere le pagine.
/// Le righe nuove non hanno conflitti. Se il server non dice l'ora (la
/// funzione `ora_del_server` non c'è ancora), si manda come prima.
class SyncEngine {
  SyncEngine(this._db, this._client, {this.suRifiuto, this.suConflitto});

  final AppDatabase _db;
  final SupabaseClient _client;

  /// Una modifica che il server ha rifiutato o che ha trovato la riga
  /// cambiata da altri, e che si scarta: la spia nella barra la mostra
  /// (vedi [ModificaRifiutata]).
  final void Function(ModificaRifiutata modifica)? suRifiuto;

  /// La copia del telefono di questa tabella è più vecchia del server (un
  /// conflitto): le pagine che la mostrano vanno rilette.
  final void Function(String tabella)? suConflitto;

  bool _inCorso = false;

  /// Quando questo telefono ha scritto una riga (chiave `tabella|riga`, o
  /// `tabella|*` per una funzione che ne cambia tante), in ora del server:
  /// una modifica successiva in coda sulla stessa riga non è un conflitto
  /// con sé stessa.
  final _scritteDaMe = <String, DateTime>{};

  /// Colonne del conflitto per le tabelle che si sincronizzano tramite
  /// upsert su chiave naturale invece che per id (presenze, tabelle_passi).
  static const _chiaveNaturalePerTabella = {
    'presenze': 'allenamento_id,atleta_id',
    'tabelle_passi': 'test_id,zona',
    'referti_partita': 'partita_id',
    'schede_benessere': 'atleta_id,data',
    'rpe_sedute': 'atleta_id,evento_tipo,evento_id',
    'test_risultati': 'test_id,atleta_id,data',
    'serie_secco_fatte': 'atleta_id,riga_id,serie',
  };

  /// Le funzioni del database in coda e la tabella che cambiano.
  static const _tabellaDellaFunzione = {
    'rinumera_distinta': 'distinta_giocatori',
    'scegli_capitani': 'distinta_giocatori',
  };

  /// Tabelle senza `updated_at`: niente controllo.
  static const _senzaOra = {'generazioni_ai'};

  /// Come si trova la riga sul server: per id, o per la chiave naturale
  /// di un upsert. null = non si controlla (una riga nuova, più righe in
  /// un colpo, una funzione).
  Map<String, Object?>? _filtri(PendingOperationsTableData op) {
    if (_senzaOra.contains(op.tabella)) return null;
    switch (op.operazione) {
      case 'update' || 'delete':
        return {'id': op.rigaId};
      case 'upsert':
        final payload = op.payloadJson == null
            ? null
            : jsonDecode(op.payloadJson!);
        if (payload is! Map<String, dynamic>) return null;
        final chiave = _chiaveNaturalePerTabella[op.tabella];
        if (chiave == null) {
          return payload['id'] == null ? null : {'id': payload['id']};
        }
        final filtri = <String, Object?>{};
        for (final colonna in chiave.split(',')) {
          if (!payload.containsKey(colonna)) return null;
          filtri[colonna] = payload[colonna];
        }
        return filtri;
    }
    return null;
  }

  String _chiave(String tabella, Map<String, Object?> filtri) =>
      '$tabella|${filtri.values.join('|')}';

  /// null = si manda; altrimenti il conflitto da segnalare.
  Future<ModificaRifiutata?> _conflitto(
    PendingOperationsTableData op,
    DateTime fatta,
  ) async {
    final filtri = _filtri(op);
    if (filtri == null) return null;
    Map<String, dynamic>? riga;
    try {
      var query = _client.from(op.tabella).select('updated_at');
      for (final MapEntry(:key, :value) in filtri.entries) {
        query = value == null
            ? query.isFilter(key, null)
            : query.eq(key, value);
      }
      riga = await query.maybeSingle();
    } catch (e) {
      if (isNetworkFailure(e)) rethrow;
      // Non si riesce a guardare (una colonna che manca, più righe):
      // si manda come prima.
      return null;
    }
    if (riga == null) {
      // Cambiare una riga che un altro ha tolto non la fa tornare.
      return op.operazione == 'update'
          ? ModificaRifiutata.conflitto(
              tabella: op.tabella,
              operazione: op.operazione,
              tolta: true,
            )
          : null;
    }
    final ora = riga['updated_at'];
    if (ora is! String) return null;
    final mia =
        [
          _scritteDaMe[_chiave(op.tabella, filtri)],
          _scritteDaMe['${op.tabella}|*'],
        ].whereType<DateTime>().fold<DateTime?>(
          null,
          (m, d) => m == null || d.isAfter(m) ? d : m,
        );
    return cambiataDaAltri(
          aggiornata: DateTime.parse(ora),
          fatta: fatta,
          scrittaDaMe: mia,
        )
        ? ModificaRifiutata.conflitto(
            tabella: op.tabella,
            operazione: op.operazione,
          )
        : null;
  }

  /// L'ora del server, o null se non la sa dire (la funzione non c'è).
  /// Senza rete lancia l'errore di rete.
  Future<DateTime?> _oraDelServer() async {
    try {
      final ora = await _client.rpc('ora_del_server');
      return ora is String ? DateTime.parse(ora) : null;
    } catch (e) {
      if (isNetworkFailure(e)) rethrow;
      return null;
    }
  }

  void _segnaScritta(PendingOperationsTableData op, DateTime adessoServer) {
    // Un margine: l'updated_at del server è un attimo dopo.
    final quando = adessoServer.add(const Duration(seconds: 5));
    if (op.operazione == 'rpc') {
      final tabella = _tabellaDellaFunzione[op.tabella];
      if (tabella != null) _scritteDaMe['$tabella|*'] = quando;
      return;
    }
    final filtri =
        _filtri(op) ?? (op.operazione == 'insert' ? {'id': op.rigaId} : null);
    if (filtri != null) _scritteDaMe[_chiave(op.tabella, filtri)] = quando;
  }

  Future<void> processQueue() async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final operazioni = await (_db.select(
        _db.pendingOperationsTable,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      if (operazioni.isEmpty) return;

      final DateTime? oraServer;
      try {
        oraServer = await _oraDelServer();
      } catch (_) {
        // Ancora offline: si riprova al prossimo giro.
        return;
      }
      final adesso = DateTime.now();
      final orologio = Stopwatch()..start();
      DateTime? adessoServer() => oraServer?.add(orologio.elapsed);

      for (final op in operazioni) {
        try {
          if (oraServer != null) {
            final conflitto = await _conflitto(
              op,
              fattaInOraServer(
                creataIl: op.creatoIl,
                adesso: adesso,
                oraServer: oraServer,
              ),
            );
            if (conflitto != null) {
              await (_db.delete(
                _db.pendingOperationsTable,
              )..where((t) => t.id.equals(op.id))).go();
              suRifiuto?.call(conflitto);
              suConflitto?.call(op.tabella);
              continue;
            }
          }
          switch (op.operazione) {
            case 'insert':
              await _client
                  .from(op.tabella)
                  .insert(jsonDecode(op.payloadJson!) as Map<String, dynamic>);
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
            case 'rpc':
              // Una funzione del database che cambia più righe in un colpo
              // solo (es. i numeri della distinta): qui "tabella" è il
              // nome della funzione, il payload i suoi parametri.
              await _client.rpc(
                op.tabella,
                params: jsonDecode(op.payloadJson!) as Map<String, dynamic>,
              );
          }
          if (adessoServer() case final ora?) _segnaScritta(op, ora);
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
          // resta com'e', l'utente puo' comunque modificarla di nuovo; la
          // spia nella barra gli dice che non e' partita.
          await (_db.delete(
            _db.pendingOperationsTable,
          )..where((t) => t.id.equals(op.id))).go();
          suRifiuto?.call(
            ModificaRifiutata.daErrore(
              tabella: op.tabella,
              operazione: op.operazione,
              errore: e,
            ),
          );
        }
      }
    } finally {
      _inCorso = false;
    }
  }
}

/// L'ultima tabella con un conflitto (e quante volte è successo, così ogni
/// conflitto si sente anche sulla stessa tabella): chi mostra le pagine
/// la ascolta e le fa rileggere.
final ultimoConflittoProvider =
    NotifierProvider<UltimoConflitto, ({String tabella, int volte})?>(
      UltimoConflitto.new,
    );

class UltimoConflitto extends Notifier<({String tabella, int volte})?> {
  @override
  ({String tabella, int volte})? build() => null;

  void segna(String tabella) =>
      state = (tabella: tabella, volte: (state?.volte ?? 0) + 1);
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
    suRifiuto: (modifica) =>
        ref.read(modificheRifiutateProvider.notifier).aggiungi(modifica),
    suConflitto: (tabella) =>
        ref.read(ultimoConflittoProvider.notifier).segna(tabella),
  );
});

/// Numero di scritture in sospeso, per l'indicatore "sincronizzato / in
/// coda" in UI.
final pendingOperationsCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.pendingOperationsTable)
      .watch()
      .map((rows) => rows.length);
});
