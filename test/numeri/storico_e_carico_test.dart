import 'dart:convert';
import 'dart:math' as math;

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/ai_genera/application/storico_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/carico/data/carico_repository.dart';
import 'package:coach_vasca/features/carico/data/rpe_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Piano 15, «Prove sui numeri»: tre errori che davano numeri credibili e
/// sbagliati, trovati il 2026-10-20.

Serie _serie(
  String id, {
  String allenamentoId = 'a1',
  int ripetute = 1,
  required int distanzaM,
  Destinatari destinatari = Destinatari.tutti,
  String? momentoId,
}) => Serie(
  id: id,
  allenamentoId: allenamentoId,
  clubId: 'c1',
  ordine: int.parse(id.substring(1)),
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: 'nuoto',
  destinatari: destinatari,
  momentoId: momentoId,
);

/// Una seduta con un lavoro in parallelo: tutti 8x100 (800 m) mentre i
/// portieri fanno 6x50 (300 m), poi una variante solo per Rossi (200 m) e
/// un 400 per tutti. Il gruppo fa 1200 m, un portiere 700.
List<Serie> _seduta(String allenamentoId, String prefisso) => [
  _serie(
    '${prefisso}1',
    allenamentoId: allenamentoId,
    ripetute: 8,
    distanzaM: 100,
    momentoId: 'm-$allenamentoId',
  ),
  _serie(
    '${prefisso}2',
    allenamentoId: allenamentoId,
    ripetute: 6,
    distanzaM: 50,
    destinatari: Destinatari.portieri,
    momentoId: 'm-$allenamentoId',
  ),
  _serie(
    '${prefisso}3',
    allenamentoId: allenamentoId,
    ripetute: 4,
    distanzaM: 50,
    destinatari: const Destinatari(soloAtleti: ['rossi']),
  ),
  _serie('${prefisso}4', allenamentoId: allenamentoId, distanzaM: 400),
];

/// Un Supabase finto che, come quello vero, filtra per `allenamento_id`
/// (`in.(…)`) e restituisce al massimo 1000 righe per richiesta, oltre le
/// quali tronca senza errore. Annota quanti id chiede ogni richiesta.
MockClient _server(List<Map<String, dynamic>> righe, List<int> idChiesti) =>
    MockClient((richiesta) async {
      final q = richiesta.url.queryParameters;
      final filtro = q['allenamento_id']!;
      final ids = filtro
          .substring('in.('.length, filtro.length - 1)
          .split(',')
          .map((id) => id.replaceAll('"', ''))
          .toSet();
      idChiesti.add(ids.length);
      final da = int.parse(q['offset'] ?? '0');
      final quante = math.min(int.parse(q['limit'] ?? '1000'), 1000);
      final pagina = righe
          .where((r) => ids.contains(r['allenamento_id']))
          .skip(da)
          .take(quante)
          .toList();
      return http.Response(
        jsonEncode(pagina),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: richiesta,
      );
    });

Map<String, dynamic> _rigaSerie(int i) => {
  'id': 's${i.toString().padLeft(5, '0')}',
  'allenamento_id': 'a${i ~/ 10}',
  'club_id': 'c1',
  'ordine': i % 10 + 1,
  'blocco': 'principale',
  'ripetute': 1,
  'distanza_m': 100,
  'stile': 'libero',
  'esecuzione': 'nuoto',
};

void main() {
  group('Genera settimana con AI: la media delle ultime 4 settimane', () {
    test('conta i metri del gruppo, come la testata dell\'allenamento', () {
      final serie = [for (var i = 0; i < 4; i++) ..._seduta('a$i', 's$i')];
      // 4 sedute da 1200 m in 4 settimane. Sommando tutte le serie (800 +
      // 300 + 200 + 400 a seduta) usciva 1700 e l'avviso di carico
      // eccessivo poteva non comparire.
      expect(mediaMetriSettimanali(serie), 1200);
    });

    test('senza storico la media è zero', () {
      expect(mediaMetriSettimanali(const []), 0);
    });
  });

  group('lo storico per l\'AI si legge tutto', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.perTest(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('oltre le 1000 righe e oltre i 100 allenamenti', () async {
      // 150 allenamenti da 10 serie: 1500 righe.
      final righe = [for (var i = 0; i < 1500; i++) _rigaSerie(i)];
      final idChiesti = <int>[];
      final client = SupabaseClient(
        'http://supabase.finto',
        'chiave-finta',
        httpClient: _server(righe, idChiesti),
      );
      addTearDown(client.dispose);

      final serie = await SerieRepository(
        client,
        db,
        SyncEngine(db, client),
      ).fetchPerAllenamenti([for (var a = 0; a < 150; a++) 'a$a']);

      expect(serie, hasLength(1500));
      expect(serie.map((s) => s.id).toSet(), hasLength(1500));
      // Un indirizzo corto per ogni richiesta.
      expect(idChiesti.every((n) => n <= 100), isTrue, reason: '$idChiesti');
    });
  });

  group('il carico senza rete', () {
    late AppDatabase db;
    late SupabaseClient client;
    late CaricoRepository carico;

    setUp(() async {
      db = AppDatabase.perTest(NativeDatabase.memory());
      client = SupabaseClient(
        'http://supabase.finto',
        'chiave-finta',
        httpClient: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
      );
      carico = CaricoRepository(
        client,
        db,
        RpeRepository(client, db, SyncEngine(db, client)),
      );
      for (final s in _seduta('a1', 's')) {
        await db
            .into(db.serieTable)
            .insert(
              SerieTableCompanion.insert(
                id: s.id,
                allenamentoId: s.allenamentoId,
                clubId: s.clubId,
                ordine: s.ordine,
                blocco: s.blocco,
                ripetute: s.ripetute,
                distanzaM: Value(s.distanzaM),
                stile: s.stile,
                esecuzione: s.esecuzione,
                perRuolo: Value(s.destinatari.campi['per_ruolo'] as String?),
                soloAtletiJson: Value(s.destinatari.soloAtletiJson),
                tranneAtletiJson: Value(s.destinatari.tranneAtletiJson),
                momentoId: Value(s.momentoId),
              ),
            );
      }
      for (final (id, ruolo) in [('ve', 'portiere'), ('rossi', null)]) {
        await db
            .into(db.atletiTable)
            .insert(
              AtletiTableCompanion.insert(
                id: id,
                clubId: 'c1',
                nome: id,
                cognome: id,
                dataNascita: DateTime(2010),
                sport: 'pallanuoto',
                ruolo: Value(ruolo),
              ),
            );
        await db
            .into(db.presenzeTable)
            .insert(
              PresenzeTableCompanion.insert(
                id: 'p-$id',
                allenamentoId: 'a1',
                atletaId: id,
                clubId: 'c1',
                stato: 'presente',
              ),
            );
      }
    });

    tearDown(() async {
      await db.close();
      await client.dispose();
    });

    test(
      'un portiere conta solo la sua colonna del lavoro in parallelo',
      () async {
        final volumi = await carico.volumiPerAtleta(
          atletaId: 've',
          clubId: 'c1',
        );
        // 300 dei portieri + 400 di tutti: senza il momento letto dal
        // telefono contava anche gli 800 di tutti.
        expect(volumi.volumeTotaleM, 700);
      },
    );

    test(
      'un giocatore di movimento la colonna di tutti, più la sua variante',
      () async {
        final volumi = await carico.volumiPerAtleta(
          atletaId: 'rossi',
          clubId: 'c1',
        );
        expect(volumi.volumeTotaleM, 800 + 200 + 400);
      },
    );
  });
}
