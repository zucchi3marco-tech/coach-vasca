import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/libreria_blocchi/data/training_blocks_repository.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Le serie, gli esercizi della seduta e le parti dei blocchi letti dal
/// server vanno chiesti dalla prima all'ultima: senza `ascending`
/// Supabase li dà dalla più alta, e "Duplica settimana" e l'esportazione
/// uscivano al contrario (coach, 2026-10-17).
void main() {
  late List<Uri> richieste;
  late SupabaseClient client;
  late AppDatabase db;

  setUp(() {
    richieste = [];
    client = SupabaseClient(
      'http://supabase.finto',
      'chiave-finta',
      httpClient: MockClient((richiesta) async {
        richieste.add(richiesta.url);
        return http.Response(
          jsonEncode(<Object>[]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
          request: richiesta,
        );
      }),
    );
    db = AppDatabase.perTest(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await client.dispose();
  });

  String ordine() => richieste.single.queryParameters['order']!;

  test('le serie di un allenamento (esporta, duplica)', () async {
    await SerieRepository(
      client,
      db,
      SyncEngine(db, client),
    ).fetchPerAllenamento('a1');
    expect(ordine(), startsWith('ordine.asc'));
  });

  test('gli esercizi di una seduta a secco (duplica)', () async {
    await SeccoRepository(client, db, SyncEngine(db, client)).fetchSeduta('a1');
    expect(ordine(), startsWith('ordine.asc'));
  });

  test('le parti di un blocco della libreria', () async {
    await TrainingBlocksRepository(
      client,
      db,
      SyncEngine(db, client),
    ).fetchParti('b1');
    expect(ordine(), startsWith('ordine.asc'));
  });
}
