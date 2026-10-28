import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/atleti/data/atleti_repository.dart';
import 'package:coach_vasca/features/atleti/data/codici_gruppo_repository.dart';
import 'package:coach_vasca/features/club/data/club_repository.dart';
import 'package:coach_vasca/features/gruppi/data/gruppi_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// WaterTactics è solo pallanuoto (divisione dal nuoto del 28 ottobre
/// 2026). Il database non è cambiato: club, squadre e atleti hanno ancora
/// la colonna "sport", e per gli atleti, senza valore, il database mette
/// "nuoto". Ogni cosa nuova deve quindi partire con "pallanuoto".
void main() {
  late AppDatabase db;
  late List<http.Request> richieste;
  late SupabaseClient client;

  setUp(() {
    dotenv.loadFromString(envString: 'MODALITA_DEMO=false');
    db = AppDatabase.perTest(NativeDatabase.memory());
    richieste = [];
    client = SupabaseClient(
      'http://supabase.finto',
      'chiave-finta',
      httpClient: MockClient((r) async {
        richieste.add(r);
        final corpo = jsonDecode(r.body) as Map<String, dynamic>;
        // Risponde con la riga "salvata": quello che è arrivato, più i
        // campi che metterebbe il database.
        final riga = switch (r.url.path) {
          '/rest/v1/rpc/create_club' => {
            'id': 'c9',
            'nome': corpo['p_nome'],
            'sport': corpo['p_sport'],
          },
          '/rest/v1/rpc/registra_atleta_da_codice_gruppo' => {
            'id': 'a9',
            'club_id': 'c1',
            'nome': corpo['p_nome'],
            'cognome': corpo['p_cognome'],
            'data_nascita': corpo['p_data_nascita'],
            'sport': corpo['p_sport'],
            'consenso_privacy_firmato': false,
            'attivo': true,
          },
          _ => {...corpo, 'attivo': true},
        };
        return http.Response(
          jsonEncode(riga),
          201,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      }),
    );
  });

  tearDown(() async {
    client.dispose();
    await db.close();
  });

  Map<String, dynamic> corpoDi(String percorso) =>
      jsonDecode(richieste.singleWhere((r) => r.url.path == percorso).body)
          as Map<String, dynamic>;

  test('un atleta nuovo è di pallanuoto', () async {
    final atleta = await AtletiRepository(client, db, SyncEngine(db, client))
        .createAtleta(
          clubId: 'c1',
          nome: 'Marco',
          cognome: 'Rossi',
          dataNascita: DateTime(2012, 3, 1),
        );
    expect(corpoDi('/rest/v1/atleti')['sport'], 'pallanuoto');
    expect(atleta.sport, 'pallanuoto');
  });

  test('chi si registra con il codice della squadra è di pallanuoto', () async {
    await CodiciGruppoRepository(client).registraConCodice(
      codice: 'ABCDE12345',
      nome: 'Luca',
      cognome: 'Bianchi',
      dataNascita: DateTime(2011, 5, 2),
    );
    expect(
      corpoDi('/rest/v1/rpc/registra_atleta_da_codice_gruppo')['p_sport'],
      'pallanuoto',
    );
  });

  test('una squadra nuova è di pallanuoto', () async {
    await GruppiRepository(
      client,
      db,
      SyncEngine(db, client),
    ).createGruppo(clubId: 'c1', nome: 'U16', ordine: 1);
    expect(corpoDi('/rest/v1/gruppi')['sport'], 'pallanuoto');
  });

  test('un club nuovo è di pallanuoto', () async {
    final club = await ClubRepository(client, db).createClub(nome: 'Mako');
    expect(corpoDi('/rest/v1/rpc/create_club')['p_sport'], 'pallanuoto');
    expect(club.sport, 'pallanuoto');
  });
}
