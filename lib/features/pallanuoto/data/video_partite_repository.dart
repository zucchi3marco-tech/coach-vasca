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
import '../domain/video_partita.dart';

const _uuid = Uuid();

/// Il video di una partita e le note sui suoi fotogrammi. Come il resto
/// dell'app ogni scrittura prova prima il server e senza rete finisce
/// nella copia locale e in coda (vedi `SyncEngine`): il video va visto
/// in rete, ma un allineamento o una nota non si perdono se la rete cade
/// mentre si salvano.
class VideoPartiteRepository {
  VideoPartiteRepository(this._client, this._db, this._syncEngine);

  final SupabaseClient _client;
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  VideoPartita _videoDaRiga(VideoPartiteTableData r) => VideoPartita(
    id: r.id,
    clubId: r.clubId,
    partitaId: r.partitaId,
    youtubeId: r.youtubeId,
    allineamenti: allineamentiDa(r.allineamentiJson),
  );

  VideoPartiteTableCompanion _videoDaMap(Map<String, dynamic> m) =>
      VideoPartiteTableCompanion.insert(
        id: m['id'] as String,
        clubId: m['club_id'] as String,
        partitaId: m['partita_id'] as String,
        youtubeId: m['youtube_id'] as String,
        allineamentiJson: Value(
          jsonEncode([
            for (final a in allineamentiDa(m['allineamenti'])) a.toJson(),
          ]),
        ),
      );

  NotaVideo _notaDaRiga(NoteVideoTableData r) => NotaVideo(
    id: r.id,
    videoId: r.videoId,
    partitaId: r.partitaId,
    clubId: r.clubId,
    secondo: r.secondo,
    eventoId: r.eventoId,
    atletaId: r.atletaId,
    testo: r.testo,
    disegno: segniDa(r.disegnoJson),
    creataIl: r.creatoIl,
  );

  NoteVideoTableCompanion _notaDaMap(Map<String, dynamic> m) =>
      NoteVideoTableCompanion.insert(
        id: m['id'] as String,
        videoId: m['video_id'] as String,
        partitaId: m['partita_id'] as String,
        clubId: m['club_id'] as String,
        secondo: (m['secondo'] as num).toDouble(),
        eventoId: Value(m['evento_id'] as String?),
        atletaId: Value(m['atleta_id'] as String?),
        testo: Value(m['testo'] as String?),
        disegnoJson: Value(
          jsonEncode([for (final s in segniDa(m['disegno'])) s.toJson()]),
        ),
        creatoIl: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
      );

  Stream<VideoPartita?> watchVideo(String partitaId) {
    final q = _db.select(_db.videoPartiteTable)
      ..where((t) => t.partitaId.equals(partitaId));
    return q.watch().map(
      (righe) => righe.isEmpty ? null : _videoDaRiga(righe.first),
    );
  }

  Stream<List<NotaVideo>> watchNote(String videoId) {
    final q = _db.select(_db.noteVideoTable)
      ..where((t) => t.videoId.equals(videoId))
      ..orderBy([(t) => OrderingTerm.asc(t.secondo)]);
    return q.watch().map((righe) => righe.map(_notaDaRiga).toList());
  }

  /// Sostituzione totale per la partita: un video scollegato o una nota
  /// eliminata altrove non restano. L'atleta riceve solo quello che può
  /// vedere (il video se è convocato, le note per tutti e le sue).
  Future<void> refresh(String partitaId) async {
    final video = await _client
        .from('video_partite')
        .select()
        .eq('partita_id', partitaId);
    final note = await _client
        .from('note_video')
        .select()
        .eq('partita_id', partitaId)
        .order('secondo', ascending: true);
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteVideoTable,
      )..where((t) => t.partitaId.equals(partitaId))).go();
      await (_db.delete(
        _db.videoPartiteTable,
      )..where((t) => t.partitaId.equals(partitaId))).go();
      await _db.batch((b) {
        for (final r in video) {
          b.insert(_db.videoPartiteTable, _videoDaMap(r));
        }
        for (final r in note) {
          b.insert(_db.noteVideoTable, _notaDaMap(r));
        }
      });
    });
  }

  Future<VideoPartita> _rileggiVideo(String id) async => _videoDaRiga(
    await (_db.select(
      _db.videoPartiteTable,
    )..where((t) => t.id.equals(id))).getSingle(),
  );

  /// Collega il video YouTube [youtubeId] alla partita (ancora da
  /// allineare).
  Future<VideoPartita> collegaVideo({
    required String partitaId,
    required String clubId,
    required String youtubeId,
  }) async {
    final payload = {
      'id': _uuid.v4(),
      'partita_id': partitaId,
      'club_id': clubId,
      'youtube_id': youtubeId,
    };
    final id = payload['id']!;
    try {
      final riga = await _client
          .from('video_partite')
          .insert(payload)
          .select()
          .single();
      await _db
          .into(_db.videoPartiteTable)
          .insertOnConflictUpdate(_videoDaMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await _db
          .into(_db.videoPartiteTable)
          .insertOnConflictUpdate(_videoDaMap(payload));
      await enqueueOperation(
        _db,
        tabella: 'video_partite',
        operazione: 'insert',
        rigaId: id,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    return _rileggiVideo(id);
  }

  /// Sostituisce i punti di allineamento (aggiungerne uno, ricominciare).
  Future<VideoPartita> salvaAllineamenti(
    String videoId,
    List<Allineamento> allineamenti,
  ) async {
    final lista = [for (final a in allineamenti) a.toJson()];
    final payload = {'allineamenti': lista};
    try {
      await _client.from('video_partite').update(payload).eq('id', videoId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'video_partite',
        operazione: 'update',
        rigaId: videoId,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
    await (_db.update(
      _db.videoPartiteTable,
    )..where((t) => t.id.equals(videoId))).write(
      VideoPartiteTableCompanion(allineamentiJson: Value(jsonEncode(lista))),
    );
    return _rileggiVideo(videoId);
  }

  /// Scollega il video: sul server a cascata anche le sue note.
  Future<void> scollegaVideo(String videoId) async {
    try {
      await _client.from('video_partite').delete().eq('id', videoId);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'video_partite',
        operazione: 'delete',
        rigaId: videoId,
      );
      _syncEngine.processQueue();
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteVideoTable,
      )..where((t) => t.videoId.equals(videoId))).go();
      await (_db.delete(
        _db.videoPartiteTable,
      )..where((t) => t.id.equals(videoId))).go();
    });
  }

  /// Crea una nota ([id] null) o la modifica.
  Future<void> salvaNota({
    String? id,
    required VideoPartita video,
    required double secondo,
    String? eventoId,
    String? atletaId,
    String? testo,
    required List<SegnoVideo> disegno,
  }) async {
    final nuova = id == null;
    final idNota = id ?? _uuid.v4();
    final testoPulito = testo?.trim();
    final payload = {
      'id': idNota,
      if (nuova) ...{
        'video_id': video.id,
        'partita_id': video.partitaId,
        'club_id': video.clubId,
        'secondo': double.parse(secondo.toStringAsFixed(2)),
        'evento_id': eventoId,
      },
      'atleta_id': atletaId,
      'testo': testoPulito == null || testoPulito.isEmpty ? null : testoPulito,
      'disegno': [for (final s in disegno) s.toJson()],
    };
    try {
      final riga = nuova
          ? await _client.from('note_video').insert(payload).select().single()
          : await _client
                .from('note_video')
                .update(payload)
                .eq('id', idNota)
                .select()
                .single();
      await _db
          .into(_db.noteVideoTable)
          .insertOnConflictUpdate(_notaDaMap(riga));
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      final locale = nuova
          ? payload
          : {
              ..._mapDaRiga(
                await (_db.select(
                  _db.noteVideoTable,
                )..where((t) => t.id.equals(idNota))).getSingle(),
              ),
              ...payload,
            };
      await _db
          .into(_db.noteVideoTable)
          .insertOnConflictUpdate(_notaDaMap(locale));
      await enqueueOperation(
        _db,
        tabella: 'note_video',
        operazione: nuova ? 'insert' : 'update',
        rigaId: idNota,
        payload: payload,
      );
      _syncEngine.processQueue();
    }
  }

  Map<String, dynamic> _mapDaRiga(NoteVideoTableData r) => {
    'id': r.id,
    'video_id': r.videoId,
    'partita_id': r.partitaId,
    'club_id': r.clubId,
    'secondo': r.secondo,
    'evento_id': r.eventoId,
    'created_at': r.creatoIl.toUtc().toIso8601String(),
  };

  Future<void> eliminaNota(String id) async {
    try {
      await _client.from('note_video').delete().eq('id', id);
    } catch (e) {
      if (!isNetworkFailure(e)) rethrow;
      await enqueueOperation(
        _db,
        tabella: 'note_video',
        operazione: 'delete',
        rigaId: id,
      );
      _syncEngine.processQueue();
    }
    await (_db.delete(_db.noteVideoTable)..where((t) => t.id.equals(id))).go();
  }
}

final videoPartiteRepositoryProvider = Provider<VideoPartiteRepository>((ref) {
  return VideoPartiteRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(syncEngineProvider),
  );
});
