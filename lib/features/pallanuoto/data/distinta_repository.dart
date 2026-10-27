import 'dart:convert';

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
import '../../../core/utils/date_format.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/numeri_distinta.dart';

const _uuid = Uuid();

String? _tempiJson(Object? valore) {
  final tempi = tempiDaLista(valore);
  return tempi.isEmpty ? null : jsonEncode(tempi);
}

/// Chi entra in distinta dalla pagina "Scegli i convocati", con il numero
/// già deciso (vedi `numeriProposti`).
typedef NuovoConvocato = ({
  String atletaId,
  int numero,
  bool portiere,
  bool capitano,
  bool viceCapitano,
});

class DistintaRepository {
  DistintaRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  DistintaGiocatore _fromRow(DistintaGiocatoriTableData row) {
    return DistintaGiocatore(
      id: row.id,
      partitaId: row.partitaId,
      atletaId: row.atletaId,
      clubId: row.clubId,
      numeroCalottina: row.numeroCalottina,
      capitano: row.capitano,
      viceCapitano: row.viceCapitano,
      portiere: row.portiere,
      fuoriquota: row.fuoriquota,
      tempiInPorta: tempiDaLista(row.tempiInPortaJson),
    );
  }

  DistintaGiocatoriTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return DistintaGiocatoriTableCompanion.insert(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      atletaId: map['atleta_id'] as String,
      clubId: map['club_id'] as String,
      numeroCalottina: map['numero_calottina'] as int,
      capitano: Value(map['capitano'] as bool? ?? false),
      viceCapitano: Value(map['vice_capitano'] as bool? ?? false),
      portiere: Value(map['portiere'] as bool? ?? false),
      fuoriquota: Value(map['fuoriquota'] as bool? ?? false),
      tempiInPortaJson: Value(_tempiJson(map['tempi_in_porta'])),
    );
  }

  Stream<List<DistintaGiocatore>> watchPerPartita(String partitaId) {
    final query = _db.select(_db.distintaGiocatoriTable)
      ..where((t) => t.partitaId.equals(partitaId))
      ..orderBy([(t) => OrderingTerm.asc(t.numeroCalottina)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Sostituzione totale per questa partita (non insertOrReplace): un
  /// convocato rimosso fuori dall'app resterebbe altrimenti in cache a
  /// tempo indeterminato.
  Future<void> refreshFromRemote(String partitaId) async {
    final rows = await _client
        .from('distinta_giocatori')
        .select()
        .eq('partita_id', partitaId);
    await _db.transaction(() async {
      await (_db.delete(
        _db.distintaGiocatoriTable,
      )..where((t) => t.partitaId.equals(partitaId))).go();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(_db.distintaGiocatoriTable, _companionFromMap(row));
        }
      });
    });
  }

  Future<DistintaGiocatore> _rileggiLocale(String id) async {
    return _fromRow(
      await (_db.select(
        _db.distintaGiocatoriTable,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  }

  Future<DistintaGiocatore> aggiungiConvocato({
    required String partitaId,
    required String atletaId,
    required int numeroCalottina,

    /// Di solito dal ruolo nella scheda dell'atleta: si cambia per la
    /// singola partita dalla riga del convocato.
    bool portiere = false,
  }) async {
    final id = _uuid.v4();
    final payload = {
      'id': id,
      'partita_id': partitaId,
      'atleta_id': atletaId,
      'numero_calottina': numeroCalottina,
      if (portiere) 'portiere': true,
    };
    try {
      final row = await _client
          .from('distinta_giocatori')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.distintaGiocatoriTable)
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
          .into(_db.distintaGiocatoriTable)
          .insertOnConflictUpdate(_companionFromMap(payloadConClub));
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  Future<DistintaGiocatore> aggiornaConvocato({
    required String id,
    required int numeroCalottina,
    required bool capitano,
    required bool viceCapitano,
    required bool portiere,
    required bool fuoriquota,
  }) async {
    final payload = {
      'numero_calottina': numeroCalottina,
      'capitano': capitano,
      'vice_capitano': viceCapitano,
      'portiere': portiere,
      'fuoriquota': fuoriquota,
    };
    try {
      final row = await _client
          .from('distinta_giocatori')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      await _db
          .into(_db.distintaGiocatoriTable)
          .insertOnConflictUpdate(_companionFromMap(row));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await (_db.update(
        _db.distintaGiocatoriTable,
      )..where((t) => t.id.equals(id))).write(
        DistintaGiocatoriTableCompanion(
          numeroCalottina: Value(numeroCalottina),
          capitano: Value(capitano),
          viceCapitano: Value(viceCapitano),
          portiere: Value(portiere),
          fuoriquota: Value(fuoriquota),
        ),
      );
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiLocale(id);
  }

  /// Salva la scelta della pagina "Scegli i convocati": prima toglie chi
  /// non c'è più (così i suoi numeri si liberano), poi aggiunge tutti i
  /// nuovi con una chiamata sola. Senza rete resta tutto in coda, nello
  /// stesso ordine.
  Future<void> salvaConvocati({
    required String partitaId,
    List<NuovoConvocato> aggiungi = const [],
    List<String> togli = const [],
  }) async {
    if (togli.isNotEmpty) {
      try {
        await _client.from('distinta_giocatori').delete().inFilter('id', togli);
      } catch (e) {
        if (!isNetworkFailure(e)) rethrow;
        for (final id in togli) {
          await enqueueOperation(
            _db,
            tabella: 'distinta_giocatori',
            operazione: 'delete',
            rigaId: id,
          );
        }
        _syncEngine.processQueue();
      }
      await (_db.delete(
        _db.distintaGiocatoriTable,
      )..where((t) => t.id.isIn(togli))).go();
    }
    if (aggiungi.isEmpty) return;
    final payloads = [
      for (final n in aggiungi)
        {
          'id': _uuid.v4(),
          'partita_id': partitaId,
          'atleta_id': n.atletaId,
          'numero_calottina': n.numero,
          if (n.portiere) 'portiere': true,
          if (n.capitano) 'capitano': true,
          if (n.viceCapitano) 'vice_capitano': true,
        },
    ];
    try {
      final rows = await _client
          .from('distinta_giocatori')
          .insert(payloads)
          .select();
      await _db.batch((batch) {
        for (final row in rows) {
          batch.insert(
            _db.distintaGiocatoriTable,
            _companionFromMap(row),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id lo mette il trigger dalla partita: offline usiamo quello
      // della partita in cache.
      final partita = await (_db.select(
        _db.partiteTable,
      )..where((t) => t.id.equals(partitaId))).getSingle();
      await _db.batch((batch) {
        for (final p in payloads) {
          batch.insert(
            _db.distintaGiocatoriTable,
            _companionFromMap({...p, 'club_id': partita.clubId}),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      for (final p in payloads) {
        await enqueueOperation(
          _db,
          tabella: 'distinta_giocatori',
          operazione: 'insert',
          rigaId: p['id']! as String,
          payload: p,
        );
      }
      _syncEngine.processQueue();
    }
  }

  /// Nuovi numeri a più convocati insieme (Riordina, o due numeri
  /// scambiati): una funzione del database, perché il vincolo "un numero
  /// per partita" non li lascia cambiare una riga alla volta.
  /// [numeri]: id della riga della distinta → numero.
  Future<void> rinumera(String partitaId, Map<String, int> numeri) async {
    if (numeri.isEmpty) return;
    final params = {
      'p_partita_id': partitaId,
      'p_numeri': [
        for (final e in numeri.entries) {'id': e.key, 'numero': e.value},
      ],
    };
    try {
      await _client.rpc('rinumera_distinta', params: params);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'rinumera_distinta',
        operazione: 'rpc',
        rigaId: partitaId,
        payload: params,
      );
      _syncEngine.processQueue();
    }
    await _db.batch((batch) {
      for (final e in numeri.entries) {
        batch.update(
          _db.distintaGiocatoriTable,
          DistintaGiocatoriTableCompanion(numeroCalottina: Value(e.value)),
          where: (t) => t.id.equals(e.key),
        );
      }
    });
  }

  /// Capitano e vice della partita in un colpo solo (null = nessuno): chi
  /// lo era torna giocatore. Con gli id delle righe della distinta.
  Future<void> scegliCapitani(
    String partitaId, {
    String? capitanoId,
    String? viceId,
  }) async {
    if (capitanoId != null && capitanoId == viceId) {
      throw StateError('Capitano e vice devono essere due atleti diversi.');
    }
    final params = {
      'p_partita_id': partitaId,
      'p_capitano_id': capitanoId,
      'p_vice_id': viceId,
    };
    try {
      await _client.rpc('scegli_capitani', params: params);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'scegli_capitani',
        operazione: 'rpc',
        rigaId: partitaId,
        payload: params,
      );
      _syncEngine.processQueue();
    }
    await _db.transaction(() async {
      await (_db.update(
        _db.distintaGiocatoriTable,
      )..where((t) => t.partitaId.equals(partitaId))).write(
        const DistintaGiocatoriTableCompanion(
          capitano: Value(false),
          viceCapitano: Value(false),
        ),
      );
      if (capitanoId != null) {
        await (_db.update(
          _db.distintaGiocatoriTable,
        )..where((t) => t.id.equals(capitanoId))).write(
          const DistintaGiocatoriTableCompanion(capitano: Value(true)),
        );
      }
      if (viceId != null) {
        await (_db.update(
          _db.distintaGiocatoriTable,
        )..where((t) => t.id.equals(viceId))).write(
          const DistintaGiocatoriTableCompanion(viceCapitano: Value(true)),
        );
      }
    });
  }

  /// L'ultima partita della stessa squadra, fino al giorno di questa, con
  /// dei convocati: da lì i numeri, "Come l'ultima partita", capitano e
  /// vice. Null se non ce n'è.
  Future<UltimaDistinta?> ultimaDellaSquadra(
    ChiavePartitaDistinta chiave,
  ) async {
    try {
      var query = _client
          .from('partite')
          .select(
            'id, data, squadra_casa, squadra_trasferta, nostra_squadra, '
            'distinta_giocatori(atleta_id, numero_calottina, capitano, '
            'vice_capitano)',
          )
          .eq('club_id', chiave.clubId)
          .neq('id', chiave.partitaId)
          .lte('data', formatDateOnly(chiave.data));
      query = chiave.gruppoId == null
          ? query.isFilter('gruppo_id', null)
          : query.eq('gruppo_id', chiave.gruppoId!);
      final rows = await query.order('data', ascending: false).limit(10);
      for (final r in rows) {
        final righe = (r['distinta_giocatori'] as List?) ?? const [];
        if (righe.isEmpty) continue;
        final inCasa = r['nostra_squadra'] != 'trasferta';
        return UltimaDistinta(
          partitaId: r['id'] as String,
          data: DateTime.parse(r['data'] as String),
          avversario:
              (inCasa ? r['squadra_trasferta'] : r['squadra_casa']) as String,
          perAtleta: {
            for (final g in righe.cast<Map<String, dynamic>>())
              g['atleta_id'] as String: (
                numero: g['numero_calottina'] as int,
                capitano: g['capitano'] as bool? ?? false,
                viceCapitano: g['vice_capitano'] as bool? ?? false,
              ),
          },
        );
      }
      return null;
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
    }
    final partite =
        await (_db.select(_db.partiteTable)
              ..where(
                (t) =>
                    t.clubId.equals(chiave.clubId) &
                    t.id.equals(chiave.partitaId).not() &
                    t.data.isSmallerOrEqualValue(chiave.data) &
                    (chiave.gruppoId == null
                        ? t.gruppoId.isNull()
                        : t.gruppoId.equals(chiave.gruppoId!)),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.data)])
              ..limit(10))
            .get();
    for (final p in partite) {
      final righe = await (_db.select(
        _db.distintaGiocatoriTable,
      )..where((t) => t.partitaId.equals(p.id))).get();
      if (righe.isEmpty) continue;
      return UltimaDistinta(
        partitaId: p.id,
        data: p.data,
        avversario: p.nostraSquadra == 'trasferta'
            ? p.squadraCasa
            : p.squadraTrasferta,
        perAtleta: {
          for (final g in righe)
            g.atletaId: (
              numero: g.numeroCalottina,
              capitano: g.capitano,
              viceCapitano: g.viceCapitano,
            ),
        },
      );
    }
    return null;
  }

  /// I tempi in cui il convocato [id] è stato in porta (sostituisce i
  /// precedenti; lista vuota = nessuno).
  Future<void> impostaTempiInPorta(String id, List<int> tempi) async {
    final ordinati = tempiDaLista(tempi);
    final payload = {'tempi_in_porta': ordinati};
    final locale = DistintaGiocatoriTableCompanion(
      tempiInPortaJson: Value(ordinati.isEmpty ? null : jsonEncode(ordinati)),
    );
    try {
      await _client.from('distinta_giocatori').update(payload).eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'update',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    await (_db.update(
      _db.distintaGiocatoriTable,
    )..where((t) => t.id.equals(id))).write(locale);
  }

  /// Le partite in cui l'atleta era nella distinta: per il suo report.
  /// Senza rete, dalla cache locale.
  Future<Set<String>> partiteDellAtleta(String atletaId) async {
    try {
      final rows = await _client
          .from('distinta_giocatori')
          .select('partita_id')
          .eq('atleta_id', atletaId);
      return {for (final r in rows) r['partita_id'] as String};
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe = await (_db.select(
        _db.distintaGiocatoriTable,
      )..where((t) => t.atletaId.equals(atletaId))).get();
      return {for (final r in righe) r.partitaId};
    }
  }

  /// Le partite in cui l'atleta è stato in porta, con i suoi tempi: per
  /// le statistiche da portiere. Senza rete, dalla cache locale.
  Future<Map<String, List<int>>> tempiInPortaDellAtleta(String atletaId) async {
    try {
      final rows = await _client
          .from('distinta_giocatori')
          .select('partita_id, tempi_in_porta')
          .eq('atleta_id', atletaId)
          .neq('tempi_in_porta', '{}');
      return {
        for (final r in rows)
          r['partita_id'] as String: tempiDaLista(r['tempi_in_porta']),
      };
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final righe =
          await (_db.select(_db.distintaGiocatoriTable)
                ..where((t) => t.atletaId.equals(atletaId))
                ..where((t) => t.tempiInPortaJson.isNotNull()))
              .get();
      return {
        for (final r in righe)
          if (tempiDaLista(r.tempiInPortaJson).isNotEmpty)
            r.partitaId: tempiDaLista(r.tempiInPortaJson),
      };
    }
  }

  Future<void> rimuoviConvocato(String id) async {
    try {
      await _client.from('distinta_giocatori').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'distinta_giocatori',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(
      _db.distintaGiocatoriTable,
    )..where((t) => t.id.equals(id))).go();
  }
}

final distintaRepositoryProvider = Provider<DistintaRepository>((ref) {
  return DistintaRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
