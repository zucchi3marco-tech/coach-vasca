import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/core/video/lettore_youtube.dart';
import 'package:coach_vasca/core/video/link_youtube.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/presentation/esercizio_secco_form_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

/// Il server finto del modulo: annota l'esercizio salvato.
class _SeccoFinto implements SeccoRepository {
  EsercizioSecco? creato;

  @override
  Future<EsercizioSecco> creaEsercizio(EsercizioSecco e) async => creato = e;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('i link di YouTube', () {
    test('il punto di partenza: t=90, t=1m30s, start=, niente', () {
      expect(inizioYoutubeDa('https://youtu.be/dQw4w9WgXcQ?t=90'), 90);
      expect(
        inizioYoutubeDa(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1m30s&si=abc',
        ),
        90,
      );
      expect(inizioYoutubeDa('youtu.be/dQw4w9WgXcQ?t=45s'), 45);
      expect(inizioYoutubeDa('https://youtu.be/dQw4w9WgXcQ?t=1h2m3s'), 3723);
      expect(
        inizioYoutubeDa('https://www.youtube.com/embed/dQw4w9WgXcQ?start=12'),
        12,
      );
      expect(inizioYoutubeDa('https://youtu.be/dQw4w9WgXcQ'), isNull);
      expect(inizioYoutubeDa('https://youtu.be/dQw4w9WgXcQ?t=0'), isNull);
      expect(inizioYoutubeDa('https://youtu.be/dQw4w9WgXcQ?t=dopo'), isNull);
      expect(inizioYoutubeDa('dQw4w9WgXcQ'), isNull);
    });

    test('il link breve, avanti e indietro', () {
      expect(linkYoutube('dQw4w9WgXcQ'), 'https://youtu.be/dQw4w9WgXcQ');
      final link = linkYoutube('dQw4w9WgXcQ', da: 75);
      expect(link, 'https://youtu.be/dQw4w9WgXcQ?t=75');
      expect(idYoutubeDa(link), 'dQw4w9WgXcQ');
      expect(inizioYoutubeDa(link), 75);
      expect(
        idYoutubeDa('https://youtube.com/shorts/dQw4w9WgXcQ?si=x'),
        'dQw4w9WgXcQ',
      );
    });
  });

  group("il video dell'esercizio", () {
    test('si salva l\'id e il secondo, e arriva all\'atleta', () {
      const e = EsercizioSecco(
        id: 'e1',
        clubId: 'c1',
        nome: 'Face pull',
        categoria: CategoriaEsercizio.scapole,
        videoYoutube: 'dQw4w9WgXcQ',
        videoDaS: 30,
      );
      expect(e.toPayload()['video_youtube'], 'dQw4w9WgXcQ');
      expect(e.toPayload()['video_da_s'], 30);
      // Senza video, niente secondo.
      const senza = EsercizioSecco(
        id: 'e2',
        clubId: 'c1',
        nome: 'Plank',
        categoria: CategoriaEsercizio.core,
        videoDaS: 30,
      );
      expect(senza.toPayload()['video_youtube'], isNull);
      expect(senza.toPayload()['video_da_s'], isNull);
      expect(e.copyWith(archiviato: true).videoYoutube, 'dQw4w9WgXcQ');

      final perAtleta = EsercizioSedutaAtleta.fromMap({
        'id': 'r1',
        'allenamento_id': 's1',
        'esercizio_id': 'e1',
        'ordine': 1,
        'nome': 'Face pull',
        'categoria': 'scapole',
        'misura': 'ripetizioni',
        'video_youtube': 'dQw4w9WgXcQ',
        'video_da_s': 30,
        'serie': 3,
        'ripetizioni': 12,
      });
      expect(perAtleta.esercizio.videoYoutube, 'dQw4w9WgXcQ');
      expect(perAtleta.esercizio.videoDaS, 30);
    });

    test('senza rete resta sul telefono e parte dopo', () async {
      final client = _senzaRete();
      final db = AppDatabase.perTest(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        await client.dispose();
      });
      final secco = SeccoRepository(client, db, SyncEngine(db, client));
      final creato = await secco.creaEsercizio(
        const EsercizioSecco(
          id: '',
          clubId: 'c1',
          nome: 'Face pull',
          categoria: CategoriaEsercizio.scapole,
          videoYoutube: 'dQw4w9WgXcQ',
          videoDaS: 30,
        ),
      );
      expect(creato.videoYoutube, 'dQw4w9WgXcQ');
      expect(creato.videoDaS, 30);
      final tolto = await secco.aggiornaEsercizio(
        EsercizioSecco(
          id: creato.id,
          clubId: 'c1',
          nome: 'Face pull',
          categoria: CategoriaEsercizio.scapole,
        ),
      );
      expect(tolto.videoYoutube, isNull);
      final coda = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          jsonDecode(o.payloadJson!) as Map<String, dynamic>,
      ];
      expect(coda.first['video_youtube'], 'dQw4w9WgXcQ');
      expect(coda.first['video_da_s'], 30);
      expect(coda.last.containsKey('video_youtube'), isTrue);
      expect(coda.last['video_youtube'], isNull);
    });
  });

  testWidgets(
    'nel modulo: il link, la ricerca, l\'anteprima e il salvataggio',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final finto = _SeccoFinto();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [seccoRepositoryProvider.overrideWithValue(finto)],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const EsercizioSeccoFormScreen(clubId: 'c1'),
                  ),
                ),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();

      Finder campo(String etichetta) => find.descendant(
        of: find
            .ancestor(of: find.text(etichetta), matching: find.byType(Column))
            .first,
        matching: find.byType(TextField),
      );

      await tester.enterText(campo('Nome'), 'Face pull');
      expect(find.text('Cerca su YouTube'), findsOneWidget);
      expect(find.text('Guarda il video'), findsNothing);

      // Un link che non è di YouTube non si salva.
      await tester.enterText(
        campo('Video su YouTube (facoltativo)'),
        'https://vimeo.com/123',
      );
      await tester.pump();
      await tester.tap(find.text('Salva esercizio'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Non è un link di YouTube'), findsOneWidget);
      expect(finto.creato, isNull);

      // Uno giusto: l'anteprima, poi il salvataggio con id e secondo.
      await tester.enterText(
        campo('Video su YouTube (facoltativo)'),
        'https://youtu.be/dQw4w9WgXcQ?si=abc&t=42',
      );
      await tester.pump();
      expect(find.text('Guarda il video'), findsOneWidget);
      await tester.tap(find.text('Guarda il video'));
      await tester.pumpAndSettle();
      expect(find.byType(LettoreYoutube), findsOneWidget);
      expect(
        tester.widget<LettoreYoutube>(find.byType(LettoreYoutube)).inizio,
        42,
      );
      await tester.tap(find.text('Salva esercizio'));
      await tester.pumpAndSettle();
      expect(finto.creato?.videoYoutube, 'dQw4w9WgXcQ');
      expect(finto.creato?.videoDaS, 42);
    },
  );
}
