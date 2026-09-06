import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../../core/sync/pending_operations.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/evento_partita.dart';

const _uuid = Uuid();

class EventiPartitaRepository {
  EventiPartitaRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  EventoPartita _fromRow(EventiPartitaTableData row) {
    return EventoPartita(
      id: row.id,
      partitaId: row.partitaId,
      clubId: row.clubId,
      tipo: row.tipo,
      squadra: row.squadra,
      atletaId: row.atletaId,
      periodo: row.periodo,
      esito: row.esito,
      contestoTiro: row.contestoTiro,
      posX: row.posX,
      posY: row.posY,
      numeroCalottinaAvversario: row.numeroCalottinaAvversario,
      espulsioneDaRigore: row.espulsioneDaRigore,
      creatoIl: row.creatoIl,
    );
  }

  EventiPartitaTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return EventiPartitaTableCompanion.insert(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      squadra: Value(map['squadra'] as String? ?? 'nostra'),
      atletaId: Value(map['atleta_id'] as String?),
      periodo: Value(map['periodo'] as int?),
      esito: Value(map['esito'] as String?),
      contestoTiro: Value(map['contesto_tiro'] as String? ?? 'azione'),
      posX: Value((map['pos_x'] as num?)?.toDouble()),
      posY: Value((map['pos_y'] as num?)?.toDouble()),
      numeroCalottinaAvversario: Value(
        map['numero_calottina_avversario'] as int?,
      ),
      espulsioneDaRigore: Value(
        map['espulsione_da_rigore'] as bool? ?? false,
      ),
      creatoIl: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Stream<List<EventoPartita>> watchPerPartita(String partitaId) {
    final query = _db.select(_db.eventiPartitaTable)
      ..where((t) => t.partitaId.equals(partitaId))
      ..orderBy([(t) => OrderingTerm.asc(t.creatoIl)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questa partita (non insertOrReplace): un
  /// evento eliminato fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String partitaId) async {
    final rows = await _client
        .from('eventi_partita')
        .select()
        .eq('partita_id', partitaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.eventiPartitaTable,
      )..where((t) => t.partitaId.equals(partitaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.eventiPartitaTable, _companionFromMap(row));
        }
      });
    });
  }

  EventoPartita _fromMap(Map<String, dynamic> map) {
    return EventoPartita(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      clubId: map['club_id'] as String,
      tipo: map['tipo'] as String,
      squadra: map['squadra'] as String? ?? 'nostra',
      atletaId: map['atleta_id'] as String?,
      periodo: map['periodo'] as int?,
      esito: map['esito'] as String?,
      contestoTiro: map['contesto_tiro'] as String? ?? 'azione',
      posX: (map['pos_x'] as num?)?.toDouble(),
      posY: (map['pos_y'] as num?)?.toDouble(),
      numeroCalottinaAvversario: map['numero_calottina_avversario'] as int?,
      espulsioneDaRigore: map['espulsione_da_rigore'] as bool? ?? false,
      creatoIl: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Eventi di un insieme di partite (una stagione), per le statistiche
  /// stagionali "da eventi live".
  Future<List<EventoPartita>> perPartite(List<String> partitaIds) async {
    if (partitaIds.isEmpty) return [];
    try {
      final rows = await _client
          .from('eventi_partita')
          .select()
          .inFilter('partita_id', partitaIds);
      return rows.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe = await (_db.select(
        _db.eventiPartitaTable,
      )..where((t) => t.partitaId.isIn(partitaIds))).get();
      return righe.map(_fromRow).toList();
    }
  }

  /// Tutti i tiri di un atleta, senza filtro di stagione (stesso
  /// perimetro "da sempre" del resto della pagina Carico): usata per la
  /// mappa di calore personale.
  Future<List<EventoPartita>> perAtleta(String atletaId) async {
    try {
      final rows = await _client
          .from('eventi_partita')
          .select()
          .eq('atleta_id', atletaId)
          .eq('tipo', 'tiro');
      return rows.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe = await (_db.select(_db.eventiPartitaTable)
            ..where((t) => t.atletaId.equals(atletaId))
            ..where((t) => t.tipo.equals('tiro')))
          .get();
      return righe.map(_fromRow).toList();
    }
  }

  Future<EventoPartita> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.eventiPartitaTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<EventoPartita> _creaEvento({
    required String partitaId,
    required String tipo,
    String squadra = 'nostra',
    String? atletaId,
    int? periodo,
    String? esito,
    String contestoTiro = 'azione',
    double? posX,
    double? posY,
    int? numeroCalottinaAvversario,
    bool espulsioneDaRigore = false,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'partita_id': partitaId,
      'tipo': tipo,
      'squadra': squadra,
      'atleta_id': ?atletaId,
      'periodo': ?periodo,
      'esito': ?esito,
      'contesto_tiro': contestoTiro,
      'pos_x': ?posX,
      'pos_y': ?posY,
      'numero_calottina_avversario': ?numeroCalottinaAvversario,
      'espulsione_da_rigore': espulsioneDaRigore,
    };
    try {
      final row = await _client
          .from('eventi_partita')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.eventiPartitaTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id e' normalmente ricalcolato dal trigger a partire dalla
      // partita: offline usiamo quello gia' in cache locale.
      final partita = await (_db.select(
        _db.partiteTable,
      )..where((t) => t.id.equals(partitaId))).getSingle();
      final payloadConClub = {...payload, 'club_id': partita.clubId};
      await _db
          .into(_db.eventiPartitaTable)
          .insertOnConflictUpdate(_companionFromMap(payloadConClub));
      await enqueueOperation(
        _db,
        tabella: 'eventi_partita',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  /// [posX]/[posY] sono la posizione toccata sul campo disegnato
  /// (percentuale 0-100): il nuovo flusso di registrazione le fornisce
  /// sempre, ma restano facoltative per non rompere eventuali chiamate
  /// da codice non ancora aggiornato.
  Future<EventoPartita> registraTiro({
    required String partitaId,
    required String atletaId,
    required String esito,
    int? periodo,
    String contestoTiro = 'azione',
    double? posX,
    double? posY,
  }) {
    return _creaEvento(
      partitaId: partitaId,
      tipo: 'tiro',
      atletaId: atletaId,
      periodo: periodo,
      esito: esito,
      contestoTiro: contestoTiro,
      posX: posX,
      posY: posY,
    );
  }

  /// Un'espulsione e' o di un nostro convocato ([atletaId]) o di un
  /// giocatore avversario identificato solo dal numero di calottina
  /// ([numeroCalottinaAvversario]): mai entrambi, mai nessuno dei due.
  Future<EventoPartita> registraEspulsione({
    required String partitaId,
    String? atletaId,
    int? numeroCalottinaAvversario,
    int? periodo,
    bool espulsioneDaRigore = false,
  }) {
    assert(
      (atletaId == null) != (numeroCalottinaAvversario == null),
      'Indica un atleta nostro oppure un numero di calottina avversario, '
      'non entrambi ne nessuno dei due',
    );
    return _creaEvento(
      partitaId: partitaId,
      tipo: 'espulsione',
      squadra: atletaId != null ? 'nostra' : 'avversaria',
      atletaId: atletaId,
      numeroCalottinaAvversario: numeroCalottinaAvversario,
      periodo: periodo,
      espulsioneDaRigore: espulsioneDaRigore,
    );
  }

  /// In modalita' "singolo" [esito] va passato subito; in modalita'
  /// "inizio_fine" si lascia null e si chiama poi [concludiSuperiorita].
  Future<EventoPartita> registraSuperiorita({
    required String partitaId,
    required String squadra,
    String? esito,
    int? periodo,
  }) {
    return _creaEvento(
      partitaId: partitaId,
      tipo: 'superiorita',
      squadra: squadra,
      periodo: periodo,
      esito: esito,
    );
  }

  Future<EventoPartita> concludiSuperiorita({
    required String id,
    required String esito,
  }) async {
    final payload = {'esito': esito};
    try {
      final row = await _client
          .from('eventi_partita')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.eventiPartitaTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.eventiPartitaTable,
      )..where((t) => t.id.equals(id))).write(
        EventiPartitaTableCompanion(esito: Value(esito)),
      );
      await enqueueOperation(
        _db,
        tabella: 'eventi_partita',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<void> eliminaEvento(String id) async {
    try {
      await _client.from('eventi_partita').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'eventi_partita',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.eventiPartitaTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final eventiPartitaRepositoryProvider = Provider<EventiPartitaRepository>((
  ref,
) {
  return EventiPartitaRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
