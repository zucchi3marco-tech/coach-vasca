import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/pallanuoto/data/eventi_partita_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/data/video_partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/video_partita.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  late SupabaseClient client;
  late AppDatabase db;
  late SyncEngine sync;

  setUp(() async {
    client = _senzaRete();
    db = AppDatabase.perTest(NativeDatabase.memory());
    sync = SyncEngine(db, client);
    await db
        .into(db.partiteTable)
        .insert(
          PartiteTableCompanion.insert(
            id: 'p1',
            clubId: 'c1',
            data: DateTime(2026, 10, 12),
            squadraCasa: 'Noi',
            squadraTrasferta: 'Loro',
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await client.dispose();
  });

  Future<List<(String, String, Map<String, dynamic>)>> coda() async => [
    for (final o in await db.select(db.pendingOperationsTable).get())
      (
        o.tabella,
        o.operazione,
        jsonDecode(o.payloadJson ?? '{}') as Map<String, dynamic>,
      ),
  ];

  test('senza rete video, allineamento e note restano sul telefono e '
      'partono dopo', () async {
    final repository = VideoPartiteRepository(client, db, sync);

    final video = await repository.collegaVideo(
      partitaId: 'p1',
      clubId: 'c1',
      youtubeId: 'dQw4w9WgXcQ',
    );
    expect(video.allineato, isFalse);
    expect((await repository.watchVideo('p1').first)?.youtubeId, 'dQw4w9WgXcQ');

    final punto = Allineamento(
      secondo: 312.456,
      momento: DateTime.utc(2026, 10, 12, 15, 10),
      periodo: 1,
      eventoId: 'gol1',
    );
    final allineato = await repository.salvaAllineamenti(video.id, [punto]);
    expect(allineato.allineamenti.single.secondo, closeTo(312.46, 0.001));
    expect(allineato.allineamenti.single.eventoId, 'gol1');

    await repository.salvaNota(
      video: allineato,
      secondo: 312.4,
      eventoId: 'gol1',
      atletaId: 'rossi',
      testo: '  Qui resta largo  ',
      disegno: const [
        SegnoVideo(
          forma: FormaSegno.freccia,
          colore: 'rosso',
          da: (0.1, 0.1),
          a: (0.5, 0.5),
        ),
      ],
    );
    var note = await repository.watchNote(video.id).first;
    expect(note.single.testo, 'Qui resta largo');
    expect(note.single.atletaId, 'rossi');
    expect(note.single.disegno.single.colore, 'rosso');
    expect(note.single.clubId, 'c1');

    // Modificata: diventa per tutta la squadra, senza disegno.
    await repository.salvaNota(
      id: note.single.id,
      video: allineato,
      secondo: 312.4,
      testo: 'Tutti larghi',
      disegno: const [],
    );
    note = await repository.watchNote(video.id).first;
    expect(note.single.atletaId, isNull);
    expect(note.single.disegno, isEmpty);
    expect(note.single.secondo, closeTo(312.4, 0.001));

    final operazioni = await coda();
    expect(operazioni.map((o) => (o.$1, o.$2)), [
      ('video_partite', 'insert'),
      ('video_partite', 'update'),
      ('note_video', 'insert'),
      ('note_video', 'update'),
    ]);
    expect(operazioni[0].$3['youtube_id'], 'dQw4w9WgXcQ');
    expect(
      (operazioni[1].$3['allineamenti'] as List).single['momento'],
      '2026-10-12T15:10:00.000Z',
    );
    expect(operazioni[2].$3['partita_id'], 'p1');
    expect(operazioni[2].$3['disegno'], hasLength(1));
    // La modifica non sposta la nota né la cambia di video.
    expect(operazioni[3].$3.containsKey('secondo'), isFalse);
    expect(operazioni[3].$3['atleta_id'], isNull);

    // Scollegando il video spariscono anche le sue note.
    await repository.scollegaVideo(video.id);
    expect(await repository.watchVideo('p1').first, isNull);
    expect(await db.select(db.noteVideoTable).get(), isEmpty);
  });

  test('eliminando la partita se ne vanno anche video e note', () async {
    final repository = VideoPartiteRepository(client, db, sync);
    final video = await repository.collegaVideo(
      partitaId: 'p1',
      clubId: 'c1',
      youtubeId: 'dQw4w9WgXcQ',
    );
    await repository.salvaNota(
      video: video,
      secondo: 10,
      testo: 'Bene',
      disegno: const [],
    );
    await PartiteRepository(client, db, sync).deletePartita('p1');
    expect(await db.select(db.videoPartiteTable).get(), isEmpty);
    expect(await db.select(db.noteVideoTable).get(), isEmpty);
  });

  test('un evento registrato senza rete tiene l\'orario del tocco, non '
      'quello dell\'arrivo al server', () async {
    final repository = EventiPartitaRepository(client, db, sync);
    final prima = DateTime.now().toUtc();
    final gol = await repository.registraTiro(
      partitaId: 'p1',
      atletaId: 'rossi',
      esito: 'gol',
    );
    final inviato = DateTime.parse(
      (await coda()).single.$3['created_at'] as String,
    );
    expect(
      inviato.isBefore(prima.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(inviato.isAfter(DateTime.now().toUtc()), isFalse);
    // Sul telefono lo stesso orario che partirà con la coda (la copia
    // locale lo tiene al secondo).
    expect(
      gol.creatoIl.difference(inviato).inMilliseconds.abs(),
      lessThan(1000),
    );
  });
}
