import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/leggi_a_pagine.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
import '../../allenamenti/domain/durata_serie.dart';
import '../domain/volumi_atleta.dart';

/// Peso relativo di ogni zona di intensita' nel calcolo del carico: una
/// stima approssimativa (non un fattore TRIMP validato scientificamente,
/// che richiederebbe la frequenza cardiaca), pensata solo per dare più
/// peso alle serie più intense a parità di volume. Da ritoccare se l'uso
/// reale mostra che non riflette bene lo sforzo percepito.
// 'C' resta per pesare correttamente le serie storiche create prima
// dello split in C1/C2/C3 (mai piu' assegnata a serie nuove).
const _pesoZona = {
  'A1': 1.0,
  'A2': 1.2,
  'B1': 1.6,
  'B2': 2.0,
  'C': 2.8,
  'C1': 2.4,
  'C2': 2.8,
  'C3': 3.2,
  'D': 3.5,
};

double _pesoPerZona(String? zona) => _pesoZona[zona] ?? 1.0;

/// Il carico di una serie: i metri pesati per zona. Una serie a tempo
/// (palleggio, tattica, a secco...) vale i metri che si nuotano in quel
/// tempo al passo medio ([passoMedioS], 1'50" ogni 100 m), pesati allo
/// stesso modo: prima valeva zero (segnalazione del coach 2026-10-08).
double caricoSerie({
  required int ripetute,
  int? distanzaM,
  int? durataS,
  String? zona,
}) {
  final metri = distanzaM ?? (durataS ?? 0) * 100 / passoMedioS;
  return ripetute * metri * _pesoPerZona(zona);
}

/// Calcola, per un atleta, il carico di allenamento giorno per giorno a
/// partire dallo storico di serie e presenze: base per il modello
/// Banister (fitness/fatica/forma) usato per pianificare lo scarico
/// pre-gara.
class CaricoRepository {
  CaricoRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  /// Mappa allenamentoId -> carico totale (somma di [caricoSerie]) per
  /// tutti gli allenamenti del club.
  Future<Map<String, double>> _caricoPerAllenamento(String clubId) async {
    final carico = <String, double>{};
    for (final r in await _serieDelClub(clubId)) {
      final allenamentoId = r['allenamento_id'] as String;
      carico[allenamentoId] =
          (carico[allenamentoId] ?? 0.0) +
          caricoSerie(
            ripetute: r['ripetute'] as int,
            distanzaM: r['distanza_m'] as int?,
            durataS: r['durata_s'] as int?,
            zona: r['zona'] as String?,
          );
    }
    return carico;
  }

  /// Mappa allenamentoId -> data, per tutti gli allenamenti del club.
  /// Legge da `allenamenti_per_carico` (RPC), stesso motivo di
  /// [_caricoPerAllenamento].
  Future<Map<String, DateTime>> _dataPerAllenamento(String clubId) async {
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
        for (final r in locali) {'id': r.id, 'data': r.data.toIso8601String()},
      ];
    }
    return {
      for (final r in righe)
        r['id'] as String: DateTime.parse(r['data'] as String),
    };
  }

  /// Id di tutti gli allenamenti a cui l'atleta risulta presente.
  Future<Set<String>> _allenamentiPresenti(String atletaId) async {
    List<Map<String, dynamic>> righe;
    try {
      righe = await _client
          .from('presenze')
          .select('allenamento_id')
          .eq('atleta_id', atletaId)
          .eq('stato', 'presente');
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali =
          await (_db.select(_db.presenzeTable)
                ..where((t) => t.atletaId.equals(atletaId))
                ..where((t) => t.stato.equals('presente')))
              .get();
      righe = [
        for (final r in locali) {'allenamento_id': r.allenamentoId},
      ];
    }
    return {for (final r in righe) r['allenamento_id'] as String};
  }

  /// Carico totale per giorno (normalizzato a mezzanotte), sommando gli
  /// allenamenti a cui l'atleta era presente. Un giorno con piu'
  /// allenamenti presenti somma i rispettivi carichi.
  Future<Map<DateTime, double>> caricoGiornalieroPerAtleta({
    required String atletaId,
    required String clubId,
  }) async {
    final dataPerAllenamento = await _dataPerAllenamento(clubId);
    final caricoPerAllenamento = await _caricoPerAllenamento(clubId);
    final presenti = await _allenamentiPresenti(atletaId);

    final risultato = <DateTime, double>{};
    for (final allenamentoId in presenti) {
      final data = dataPerAllenamento[allenamentoId];
      if (data == null) continue;
      final giorno = DateTime(data.year, data.month, data.day);
      final carico = caricoPerAllenamento[allenamentoId] ?? 0.0;
      risultato[giorno] = (risultato[giorno] ?? 0.0) + carico;
    }
    return risultato;
  }

  /// Righe di tutte le serie del club (distanza o durata, zona,
  /// esecuzione).
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
          },
      ];
    }
  }

  /// Volume (metri e lavoro a tempo) di un atleta scomposto per zona e
  /// per tipo di lavoro, contato solo negli allenamenti a cui risulta
  /// presente (stesso perimetro di [caricoGiornalieroPerAtleta]).
  Future<VolumiAtleta> volumiPerAtleta({
    required String atletaId,
    required String clubId,
  }) async => VolumiAtleta.daSerie(
    await _serieDelClub(clubId),
    await _allenamentiPresenti(atletaId),
  );
}

final caricoRepositoryProvider = Provider<CaricoRepository>((ref) {
  return CaricoRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
