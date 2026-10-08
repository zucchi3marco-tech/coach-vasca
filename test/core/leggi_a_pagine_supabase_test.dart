import 'dart:convert';
import 'dart:math' as math;

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/supabase/leggi_a_pagine.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/presenze/data/presenze_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Un Supabase finto con [righe] righe in ogni tabella e funzione, che
/// come quello vero ne restituisce al massimo 1000 per richiesta (oltre
/// tronca, senza errore). Annota le richieste in [richieste].
MockClient _server(List<Map<String, dynamic>> righe, List<Uri> richieste) =>
    MockClient((richiesta) async {
      richieste.add(richiesta.url);
      final q = richiesta.url.queryParameters;
      final da = int.parse(q['offset'] ?? '0');
      final quante = math.min(int.parse(q['limit'] ?? '1000'), 1000);
      final pagina = righe.skip(da).take(quante).toList();
      return http.Response(
        jsonEncode(pagina),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
        // Il client legge il metodo dalla richiesta della risposta.
        request: richiesta,
      );
    });

Map<String, dynamic> _presenza(int i) => {
  'id': 'p${i.toString().padLeft(5, '0')}',
  'allenamento_id': 'a$i',
  'atleta_id': 'at${i % 30}',
  'club_id': 'c1',
  'stato': 'presente',
  'note': null,
};

void main() {
  test('2500 presenze del club arrivano tutte sul telefono', () async {
    final richieste = <Uri>[];
    final client = SupabaseClient(
      'http://supabase.finto',
      'chiave-finta',
      httpClient: _server([
        for (var i = 0; i < 2500; i++) _presenza(i),
      ], richieste),
    );
    final db = AppDatabase.perTest(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await client.dispose();
    });

    await PresenzeRepository(
      client,
      db,
      SyncEngine(db, client),
    ).refreshFromRemotePerClub('c1');

    final locali = await db.select(db.presenzeTable).get();
    expect(locali, hasLength(2500));
    // Tre pagine, sempre nello stesso ordine.
    expect(
      [for (final r in richieste) r.queryParameters['offset']],
      ['0', '1000', '2000'],
    );
    expect(richieste.first.queryParameters['order'], startsWith('id'));
  });

  test('anche le funzioni (rpc) si leggono a pagine', () async {
    final richieste = <Uri>[];
    final client = SupabaseClient(
      'http://supabase.finto',
      'chiave-finta',
      httpClient: _server([
        for (var i = 0; i < 1500; i++) {'id': 's$i', 'ripetute': 1},
      ], richieste),
    );
    addTearDown(client.dispose);

    final righe = await leggiAPagine(
      (da, a) => client
          .rpc('serie_per_carico', params: {'p_club_id': 'c1'})
          .order('id')
          .range(da, a),
    );
    expect(righe, hasLength(1500));
    expect(richieste, hasLength(2));
    expect(richieste.first.path, endsWith('/rpc/serie_per_carico'));
  });
}
