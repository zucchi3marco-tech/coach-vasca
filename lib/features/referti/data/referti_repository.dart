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
import '../domain/referto_letto.dart';
import '../domain/referto_partita.dart';

const _uuid = Uuid();

/// Chiama la Edge Function `leggi-referto` per la lettura via AI vision, e
/// salva il referto corretto a mano dall'utente collegato a una Partita
/// (un solo referto per partita: salvare di nuovo sovrascrive).
class RefertiRepository {
  RefertiRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  Future<RefertoLetto> leggiReferto({
    required List<int> immagineBytes,
    required String mimeType,
  }) async {
    try {
      final risposta = await _client.functions.invoke(
        'leggi-referto',
        body: {
          'immagineBase64': base64Encode(immagineBytes),
          'mimeType': mimeType,
        },
      );
      final dati = risposta.data;
      if (dati is Map && dati['referto'] is Map) {
        return RefertoLetto.fromMap(dati['referto'] as Map<String, dynamic>);
      }
      throw Exception('Risposta inattesa dalla lettura del referto: $dati');
    } on FunctionException catch (e) {
      throw Exception(_messaggioErrore(e.details));
    }
  }

  /// Traduce il codice d'errore restituito dalla Edge Function in un
  /// messaggio chiaro: un problema di rete/provider e' quasi sempre
  /// transitorio (vale la pena riprovare), una lettura non valida indica
  /// piuttosto una foto poco leggibile.
  String _messaggioErrore(Object? dettagli) {
    final codice = dettagli is Map ? dettagli['codice'] as String? : null;
    switch (codice) {
      case 'chiave_non_configurata':
        return 'Il servizio di lettura non è configurato correttamente. '
            'Contatta l\'assistenza.';
      case 'provider_non_raggiungibile':
      case 'provider_errore':
      case 'risposta_non_valida':
        return 'Il servizio di lettura non ha risposto correttamente. '
            'Riprova tra qualche istante.';
      case 'referto_non_valido':
        return 'Non sono riuscito a leggere bene la foto del referto. '
            'Prova con una foto più nitida o riprova.';
      default:
        final errore = dettagli is Map ? dettagli['error'] as String? : null;
        return errore ?? 'Errore imprevisto nella lettura del referto. Riprova.';
    }
  }

  Map<String, dynamic> _mappaGiocatore(GiocatoreReferto g) => {
    'numeroCalottina': g.numeroCalottina,
    'nome': g.nome,
    'reti': g.reti,
    'espulsioni': g.espulsioni,
    'atletaId': g.atletaId,
  };

  List<Map<String, dynamic>> _asListaMappe(dynamic valore) =>
      (valore as List).cast<Map<String, dynamic>>();

  RefertoPartita _fromRow(RefertiPartitaTableData row) {
    return RefertoPartita(
      id: row.id,
      partitaId: row.partitaId,
      clubId: row.clubId,
      squadraCasa: row.squadraCasa,
      squadraTrasferta: row.squadraTrasferta,
      risultatoCasa: row.risultatoCasa,
      risultatoTrasferta: row.risultatoTrasferta,
      parziali: _asListaMappe(
        jsonDecode(row.parzialiJson),
      ).map(ParzialeReferto.fromMap).toList(),
      giocatoriCasa: _asListaMappe(
        jsonDecode(row.giocatoriCasaJson),
      ).map(GiocatoreReferto.fromMap).toList(),
      giocatoriTrasferta: _asListaMappe(
        jsonDecode(row.giocatoriTrasfertaJson),
      ).map(GiocatoreReferto.fromMap).toList(),
    );
  }

  RefertoPartita _fromMap(Map<String, dynamic> map) {
    return RefertoPartita(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      clubId: map['club_id'] as String,
      squadraCasa: map['squadra_casa'] as String,
      squadraTrasferta: map['squadra_trasferta'] as String,
      risultatoCasa: map['risultato_casa'] as int,
      risultatoTrasferta: map['risultato_trasferta'] as int,
      parziali: _asListaMappe(
        map['parziali'],
      ).map(ParzialeReferto.fromMap).toList(),
      giocatoriCasa: _asListaMappe(
        map['giocatori_casa'],
      ).map(GiocatoreReferto.fromMap).toList(),
      giocatoriTrasferta: _asListaMappe(
        map['giocatori_trasferta'],
      ).map(GiocatoreReferto.fromMap).toList(),
    );
  }

  RefertiPartitaTableCompanion _companionFromMap(Map<String, dynamic> map) {
    return RefertiPartitaTableCompanion.insert(
      id: map['id'] as String,
      partitaId: map['partita_id'] as String,
      clubId: map['club_id'] as String,
      squadraCasa: map['squadra_casa'] as String,
      squadraTrasferta: map['squadra_trasferta'] as String,
      risultatoCasa: map['risultato_casa'] as int,
      risultatoTrasferta: map['risultato_trasferta'] as int,
      parzialiJson: Value(jsonEncode(map['parziali'])),
      giocatoriCasaJson: Value(jsonEncode(map['giocatori_casa'])),
      giocatoriTrasfertaJson: Value(jsonEncode(map['giocatori_trasferta'])),
    );
  }

  /// Referto gia' salvato per questa partita, se esiste (un solo referto
  /// per partita).
  Future<RefertoPartita?> perPartita(String partitaId) async {
    try {
      final righe = await _client
          .from('referti_partita')
          .select()
          .eq('partita_id', partitaId);
      return righe.isEmpty ? null : _fromMap(righe.first);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.refertiPartitaTable,
      )..where((t) => t.partitaId.equals(partitaId))).get();
      return locali.isEmpty ? null : _fromRow(locali.first);
    }
  }

  /// Referti salvati per un insieme di partite (una stagione), per le
  /// statistiche stagionali "da referti".
  Future<List<RefertoPartita>> perPartite(List<String> partitaIds) async {
    if (partitaIds.isEmpty) return [];
    try {
      final righe = await _client
          .from('referti_partita')
          .select()
          .inFilter('partita_id', partitaIds);
      return righe.map(_fromMap).toList();
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locali = await (_db.select(
        _db.refertiPartitaTable,
      )..where((t) => t.partitaId.isIn(partitaIds))).get();
      return locali.map(_fromRow).toList();
    }
  }

  /// Salva (o sovrascrive) il referto corretto a mano dall'utente,
  /// collegandolo alla partita indicata.
  Future<RefertoPartita> salvaReferto({
    required String partitaId,
    required String squadraCasa,
    required String squadraTrasferta,
    required int risultatoCasa,
    required int risultatoTrasferta,
    required List<ParzialeReferto> parziali,
    required List<GiocatoreReferto> giocatoriCasa,
    required List<GiocatoreReferto> giocatoriTrasferta,
  }) async {
    final payload = {
      'partita_id': partitaId,
      'squadra_casa': squadraCasa,
      'squadra_trasferta': squadraTrasferta,
      'risultato_casa': risultatoCasa,
      'risultato_trasferta': risultatoTrasferta,
      'parziali': [
        for (final p in parziali) {'casa': p.casa, 'trasferta': p.trasferta},
      ],
      'giocatori_casa': [for (final g in giocatoriCasa) _mappaGiocatore(g)],
      'giocatori_trasferta': [
        for (final g in giocatoriTrasferta) _mappaGiocatore(g),
      ],
    };
    try {
      final row = await _client
          .from('referti_partita')
          .upsert(payload, onConflict: 'partita_id')
          .select()
          .single();
      await _db
          .into(_db.refertiPartitaTable)
          .insertOnConflictUpdate(_companionFromMap(row));
      return _fromMap(row);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      // club_id e' normalmente ricalcolato dal trigger a partire dalla
      // partita: offline usiamo quello gia' in cache locale. Se esiste
      // gia' un referto locale per questa partita lo riusiamo (stesso id).
      final partita = await (_db.select(
        _db.partiteTable,
      )..where((t) => t.id.equals(partitaId))).getSingle();
      final esistente = await (_db.select(
        _db.refertiPartitaTable,
      )..where((t) => t.partitaId.equals(partitaId))).getSingleOrNull();
      final id = esistente?.id ?? _uuid.v4();
      final payloadCompleto = {
        ...payload,
        'id': id,
        'club_id': partita.clubId,
      };
      await _db
          .into(_db.refertiPartitaTable)
          .insertOnConflictUpdate(_companionFromMap(payloadCompleto));
      await enqueueOperation(
        _db,
        tabella: 'referti_partita',
        operazione: 'upsert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
      return _fromMap(payloadCompleto);
    }
  }
}

final refertiRepositoryProvider = Provider<RefertiRepository>((ref) {
  return RefertiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
