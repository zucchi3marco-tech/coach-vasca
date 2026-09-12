import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/sync/network_failure.dart';
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

/// Calcola, per un atleta, il carico di allenamento giorno per giorno a
/// partire dallo storico di serie e presenze: base per il modello
/// Banister (fitness/fatica/forma) usato per pianificare lo scarico
/// pre-gara.
class CaricoRepository {
  CaricoRepository(this._client, this._db);

  final SupabaseClient _client;
  final AppDatabase _db;

  /// Mappa allenamentoId -> carico totale (somma delle serie pesate per
  /// zona) per tutti gli allenamenti del club.
  ///
  /// Legge da `serie_per_carico` (RPC, non dalla tabella `serie`
  /// direttamente): un atleta collegato può calcolare il proprio carico
  /// senza poter leggere note/attrezzatura delle serie di altri atleti
  /// (audit 12/09) — vedi migrazione `20260912000100_carico_atleta_rpc.sql`.
  Future<Map<String, double>> _caricoPerAllenamento(String clubId) async {
    List<Map<String, dynamic>> righe;
    try {
      final risposta = await _client.rpc(
        'serie_per_carico',
        params: {'p_club_id': clubId},
      );
      righe = (risposta as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.serieTable,
      )..where((t) => t.clubId.equals(clubId))).get();
      righe = [
        for (final r in locali)
          {
            'allenamento_id': r.allenamentoId,
            'ripetute': r.ripetute,
            'distanza_m': r.distanzaM,
            'zona': r.zona,
          },
      ];
    }
    final carico = <String, double>{};
    for (final r in righe) {
      final allenamentoId = r['allenamento_id'] as String;
      final ripetute = r['ripetute'] as int;
      final distanzaM = r['distanza_m'] as int;
      final peso = _pesoPerZona(r['zona'] as String?);
      carico[allenamentoId] =
          (carico[allenamentoId] ?? 0.0) + ripetute * distanzaM * peso;
    }
    return carico;
  }

  /// Mappa allenamentoId -> data, per tutti gli allenamenti del club.
  /// Legge da `allenamenti_per_carico` (RPC), stesso motivo di
  /// [_caricoPerAllenamento].
  Future<Map<String, DateTime>> _dataPerAllenamento(String clubId) async {
    List<Map<String, dynamic>> righe;
    try {
      final risposta = await _client.rpc(
        'allenamenti_per_carico',
        params: {'p_club_id': clubId},
      );
      righe = (risposta as List).cast<Map<String, dynamic>>();
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

  /// Righe di tutte le serie del club (zona ed esecuzione incluse),
  /// stesso schema try/fallback-locale di [_caricoPerAllenamento].
  Future<List<Map<String, dynamic>>> _serieDelClub(String clubId) async {
    try {
      final risposta = await _client.rpc(
        'serie_per_carico',
        params: {'p_club_id': clubId},
      );
      return (risposta as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.serieTable,
      )..where((t) => t.clubId.equals(clubId))).get();
      return [
        for (final r in locali)
          {
            'allenamento_id': r.allenamentoId,
            'ripetute': r.ripetute,
            'distanza_m': r.distanzaM,
            'zona': r.zona,
            'esecuzione': r.esecuzione,
          },
      ];
    }
  }

  /// Volume (metri) di un atleta scomposto per zona e per tipo di
  /// lavoro, contato solo negli allenamenti a cui risulta presente
  /// (stesso perimetro di [caricoGiornalieroPerAtleta]).
  Future<VolumiAtleta> volumiPerAtleta({
    required String atletaId,
    required String clubId,
  }) async {
    final serie = await _serieDelClub(clubId);
    final presenti = await _allenamentiPresenti(atletaId);

    var totale = 0;
    final perZona = <String, int>{};
    final perEsecuzione = <String, int>{};
    for (final r in serie) {
      if (!presenti.contains(r['allenamento_id'] as String)) continue;
      final volume = (r['ripetute'] as int) * (r['distanza_m'] as int);
      totale += volume;
      final zona = r['zona'] as String?;
      if (zona != null) {
        perZona[zona] = (perZona[zona] ?? 0) + volume;
      }
      final esecuzione = r['esecuzione'] as String;
      perEsecuzione[esecuzione] = (perEsecuzione[esecuzione] ?? 0) + volume;
    }
    return VolumiAtleta(
      volumeTotaleM: totale,
      perZona: perZona,
      perEsecuzione: perEsecuzione,
    );
  }
}

final caricoRepositoryProvider = Provider<CaricoRepository>((ref) {
  return CaricoRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
  );
});
