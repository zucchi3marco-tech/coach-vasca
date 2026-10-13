import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/leggi_a_pagine.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../domain/carico_rpe.dart';
import '../domain/rpe_seduta.dart';
import '../domain/volumi_atleta.dart';
import 'rpe_repository.dart';

/// Il carico degli atleti seduta per seduta: RPE × minuti (il metodo di
/// Foster), per acqua, secco e partita — vedi [seduteDiAtleta]. Base del
/// modello Banister (fitness/fatica/forma) e dell'ACWR.
///
/// Prima il carico contava solo i metri pesati per zona: una partita e il
/// lavoro a secco valevano zero (analisi "Il Mako della pallanuoto",
/// proposta 1).
class CaricoRepository {
  CaricoRepository(this._client, this._db, this._rpe);

  final SupabaseClient _client;
  final AppDatabase _db;
  final RpeRepository _rpe;

  /// Data, tipo e durata (per il secco) di ogni allenamento del club
  /// (chiave: id). Legge da `allenamenti_per_carico` (RPC): l'atleta
  /// collegato non legge la tabella degli allenamenti.
  Future<Map<String, ({DateTime data, String tipo, int? durataMin})>>
  _allenamenti(String clubId) async {
    List<Map<String, dynamic>> righe;
    try {
      righe = await leggiAPagine(
        (da, a) => _client
            .rpc('allenamenti_per_carico', params: {'p_club_id': clubId})
            .order('id')
            .range(da, a),
      );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.allenamentiTable,
      )..where((t) => t.clubId.equals(clubId))).get();
      righe = [
        for (final r in locali)
          {
            'id': r.id,
            'data': r.data.toIso8601String(),
            'tipo': r.tipo,
            'durata_min': r.durataMin,
          },
      ];
    }
    return {
      for (final r in righe)
        r['id'] as String: (
          data: DateTime.parse(r['data'] as String),
          tipo: r['tipo'] as String? ?? 'acqua',
          durataMin: (r['durata_min'] as num?)?.toInt(),
        ),
    };
  }

  /// Mappa partitaId -> data, per tutte le partite del club.
  Future<Map<String, DateTime>> _dataPerPartita(String clubId) async {
    List<Map<String, dynamic>> righe;
    try {
      righe = await leggiAPagine(
        (da, a) => _client
            .from('partite')
            .select('id, data')
            .eq('club_id', clubId)
            .order('id')
            .range(da, a),
      );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.partiteTable,
      )..where((t) => t.clubId.equals(clubId))).get();
      righe = [
        for (final r in locali) {'id': r.id, 'data': r.data.toIso8601String()},
      ];
    }
    return {
      for (final r in righe)
        r['id'] as String: DateTime.parse(r['data'] as String),
    };
  }

  /// Le presenze (allenamento_id, atleta_id, stato) di un atleta o, con
  /// [atletaId] null, di tutto il club.
  Future<List<Map<String, dynamic>>> _presenze({
    required String clubId,
    String? atletaId,
  }) async {
    try {
      return await leggiAPagine((da, a) {
        final q = _client
            .from('presenze')
            .select('id, allenamento_id, atleta_id, stato');
        return (atletaId == null
                ? q.eq('club_id', clubId)
                : q.eq('atleta_id', atletaId))
            .order('id')
            .range(da, a);
      });
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final q = _db.select(_db.presenzeTable)
        ..where(
          (t) => atletaId == null
              ? t.clubId.equals(clubId)
              : t.atletaId.equals(atletaId),
        );
      return [
        for (final r in await q.get())
          {
            'allenamento_id': r.allenamentoId,
            'atleta_id': r.atletaId,
            'stato': r.stato,
          },
      ];
    }
  }

  /// Le convocazioni (partita_id, atleta_id) di un atleta o, con
  /// [atletaId] null, di tutto il club.
  Future<List<Map<String, dynamic>>> _convocazioni({
    required String clubId,
    String? atletaId,
  }) async {
    try {
      return await leggiAPagine((da, a) {
        final q = _client
            .from('distinta_giocatori')
            .select('id, partita_id, atleta_id');
        return (atletaId == null
                ? q.eq('club_id', clubId)
                : q.eq('atleta_id', atletaId))
            .order('id')
            .range(da, a);
      });
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final q = _db.select(_db.distintaGiocatoriTable)
        ..where(
          (t) => atletaId == null
              ? t.clubId.equals(clubId)
              : t.atletaId.equals(atletaId),
        );
      return [
        for (final r in await q.get())
          {'partita_id': r.partitaId, 'atleta_id': r.atletaId},
      ];
    }
  }

  /// Il ruolo di ogni atleta del club che ne ha uno (chiave: id): per
  /// contare a ognuno solo le sue serie. All'atleta collegato arriva solo
  /// il suo.
  Future<Map<String, String>> _ruoli(String clubId) async {
    List<Map<String, dynamic>> righe;
    try {
      righe = await leggiAPagine(
        (da, a) => _client
            .from('atleti')
            .select('id, ruolo')
            .eq('club_id', clubId)
            .not('ruolo', 'is', null)
            .order('id')
            .range(da, a),
      );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.atletiTable,
      )..where((t) => t.clubId.equals(clubId) & t.ruolo.isNotNull())).get();
      righe = [
        for (final r in locali) {'id': r.id, 'ruolo': r.ruolo},
      ];
    }
    return {for (final r in righe) r['id'] as String: r['ruolo'] as String};
  }

  /// Le sedute di ogni atleta (chiave: id atleta) a partire da
  /// [presenze], [convocazioni] e risposte [rpe]: un atleta senza
  /// nessuna di queste non compare.
  Future<Map<String, List<CaricoSeduta>>> _sedute({
    required String clubId,
    required List<Map<String, dynamic>> presenze,
    required List<Map<String, dynamic>> convocazioni,
    required List<RpeSeduta> rpe,
  }) async {
    final allenamenti = await _allenamenti(clubId);
    final dataAllenamenti = {
      for (final MapEntry(:key, :value) in allenamenti.entries) key: value.data,
    };
    // Le sedute a secco valgono i loro minuti, tutti nel secco.
    final minutiSecco = {
      for (final MapEntry(:key, :value) in allenamenti.entries)
        if (value.tipo == 'secco')
          key: value.durataMin ?? minutiSeccoPredefiniti,
    };
    final dataPartite = await _dataPerPartita(clubId);
    final ruoli = await _ruoli(clubId);
    final seriePerAllenamento = <String, List<SerieCarico>>{};
    for (final r in await _serieDelClub(clubId)) {
      final s = SerieCarico.fromMap(r);
      (seriePerAllenamento[s.allenamentoId] ??= []).add(s);
    }

    final presenzePerAtleta = <String, Map<String, String>>{};
    for (final p in presenze) {
      (presenzePerAtleta[p['atleta_id'] as String] ??= {})[p['allenamento_id']
              as String] =
          p['stato'] as String;
    }
    final convocazioniPerAtleta = <String, Set<String>>{};
    for (final c in convocazioni) {
      (convocazioniPerAtleta[c['atleta_id'] as String] ??= {}).add(
        c['partita_id'] as String,
      );
    }
    final rpePerAtleta = <String, Map<(String, String), int>>{};
    for (final r in rpe) {
      (rpePerAtleta[r.atletaId] ??= {})[(r.eventoTipo, r.eventoId)] = r.rpe;
    }

    final atleti = {
      ...presenzePerAtleta.keys,
      ...convocazioniPerAtleta.keys,
      ...rpePerAtleta.keys,
    };
    return {
      for (final atletaId in atleti)
        atletaId: seduteDiAtleta(
          dataAllenamenti: dataAllenamenti,
          seriePerAllenamento: seriePerAllenamento,
          minutiSecco: minutiSecco,
          statoPresenze: presenzePerAtleta[atletaId] ?? const {},
          dataPartite: dataPartite,
          partiteConvocato: convocazioniPerAtleta[atletaId] ?? const {},
          rpe: rpePerAtleta[atletaId] ?? const {},
          atletaId: atletaId,
          ruolo: ruoli[atletaId],
        ),
    };
  }

  /// Le sedute di un atleta, ognuna con il suo carico, dalla più vecchia.
  Future<List<CaricoSeduta>> sedutePerAtleta({
    required String atletaId,
    required String clubId,
  }) async {
    final sedute = await _sedute(
      clubId: clubId,
      presenze: await _presenze(clubId: clubId, atletaId: atletaId),
      convocazioni: await _convocazioni(clubId: clubId, atletaId: atletaId),
      rpe: await _rpe.perAtleta(atletaId),
    );
    return sedute[atletaId] ?? const [];
  }

  /// Le sedute di tutti gli atleti del club (vista dell'allenatore), con
  /// una lettura sola per tabella.
  Future<Map<String, List<CaricoSeduta>>> sedutePerClub(String clubId) async =>
      _sedute(
        clubId: clubId,
        presenze: await _presenze(clubId: clubId),
        convocazioni: await _convocazioni(clubId: clubId),
        rpe: await _rpe.perClub(clubId),
      );

  /// Righe di tutte le serie del club non saltate (distanza o durata,
  /// zona, esecuzione, recupero, ripartenza, passo obiettivo).
  ///
  /// Legge da `serie_per_carico` (RPC, non dalla tabella `serie`
  /// direttamente): un atleta collegato può calcolare il proprio carico
  /// senza poter leggere note/attrezzatura delle serie di altri atleti
  /// (audit 12/09) — vedi migrazione `20260912000100_carico_atleta_rpc.sql`.
  Future<List<Map<String, dynamic>>> _serieDelClub(String clubId) async {
    try {
      // A pagine: il club supera presto le 1000 serie, il massimo di righe
      // per richiesta, e oltre il carico si calcolava su una parte sola.
      return await leggiAPagine(
        (da, a) => _client
            .rpc('serie_per_carico', params: {'p_club_id': clubId})
            .order('id')
            .range(da, a),
      );
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // Come la RPC: le serie saltate a bordo vasca non contano.
      final locali =
          await (_db.select(_db.serieTable)
                ..where((t) => t.clubId.equals(clubId))
                ..where(
                  (t) => t.esito.isNull() | t.esito.isNotValue('saltata'),
                ))
              .get();
      return [
        for (final r in locali)
          {
            'allenamento_id': r.allenamentoId,
            'ripetute': r.ripetute,
            'distanza_m': r.distanzaM,
            'durata_s': r.durataS,
            'zona': r.zona,
            'esecuzione': r.esecuzione,
            'recupero_s': r.recuperoS,
            'ripartenza_s': r.ripartenzaS,
            'passo_obiettivo_s': r.passoObiettivoS,
            'recupero_dopo_s': r.recuperoDopoS,
            'per_ruolo': r.perRuolo,
            'solo_atleti': r.soloAtletiJson,
            'tranne_atleti': r.tranneAtletiJson,
          },
      ];
    }
  }

  /// Volume (metri e lavoro a tempo) di un atleta scomposto per zona e
  /// per tipo di lavoro, contato solo negli allenamenti a cui risulta
  /// presente e solo con le serie che fa lui.
  Future<VolumiAtleta> volumiPerAtleta({
    required String atletaId,
    required String clubId,
  }) async => VolumiAtleta.daSerie(
    await _serieDelClub(clubId),
    {
      for (final p in await _presenze(clubId: clubId, atletaId: atletaId))
        if (p['stato'] == 'presente') p['allenamento_id'] as String,
    },
    atletaId: atletaId,
    ruolo: (await _ruoli(clubId))[atletaId],
  );
}

final caricoRepositoryProvider = Provider<CaricoRepository>((ref) {
  return CaricoRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(rpeRepositoryProvider),
  );
});
