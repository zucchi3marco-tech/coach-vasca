import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/modifiche_rifiutate.dart';
import 'package:coach_vasca/core/sync/pending_operations.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, SupabaseClient;

const _rifiutoRls = {
  'code': '42501',
  'message': 'new row violates row-level security policy for table "presenze"',
  'details': 'Failing row contains (p1, Luca Bianchi, presente)',
  'hint': null,
};

void main() {
  group('una modifica rifiutata', () {
    test('dice cosa era e perché, a parole', () {
      final m = ModificaRifiutata.daErrore(
        tabella: 'presenze',
        operazione: 'upsert',
        errore: PostgrestException(
          message: _rifiutoRls['message']!,
          code: '42501',
          details: _rifiutoRls['details'],
        ),
        quando: DateTime(2026, 10, 19, 18, 42),
      );
      expect(m.cosa, 'Presenze');
      expect(m.tipo, 'modifica');
      expect(m.perche, 'Permesso negato: questo account non può farlo.');
      expect(m.codice, '42501');
    });

    test('non tiene mai i dettagli, che possono avere i dati degli atleti', () {
      final m = ModificaRifiutata.daErrore(
        tabella: 'presenze',
        operazione: 'insert',
        errore: const PostgrestException(
          message: 'violates check constraint',
          code: '23514',
          details: 'Failing row contains (p1, Luca Bianchi)',
        ),
      );
      expect(jsonEncode(m.aMappa()), isNot(contains('Luca')));
      expect(m.perche, 'Il server ha trovato dati non validi.');
      expect(m.tipo, 'nuova');
    });

    test('una tabella senza nome scritto si legge comunque', () {
      final m = ModificaRifiutata(
        tabella: 'righe_programma',
        operazione: 'delete',
        quando: DateTime(2026),
      );
      expect(m.cosa, 'Righe programma');
      expect(m.tipo, 'eliminazione');
      expect(m.perche, 'Il server non l\'ha accettata.');
    });

    test('si salva e si rilegge uguale', () {
      final m = ModificaRifiutata(
        tabella: 'gare',
        operazione: 'update',
        quando: DateTime(2026, 10, 19, 18, 42),
        codice: '23505',
        messaggio: 'duplicate key',
      );
      final riletta = ModificaRifiutata.daMappa(
        jsonDecode(jsonEncode(m.aMappa())) as Map<String, dynamic>,
      );
      expect(riletta.aMappa(), m.aMappa());
    });
  });

  group('l\'elenco sul telefono', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'aggiunge in cima, resta dopo il riavvio, «Ho capito» lo svuota',
      () async {
        final primo = ProviderContainer();
        addTearDown(primo.dispose);
        final elenco = primo.read(modificheRifiutateProvider.notifier);
        await elenco.aggiungi(
          ModificaRifiutata(
            tabella: 'gare',
            operazione: 'update',
            quando: DateTime(2026, 10, 18),
          ),
        );
        await elenco.aggiungi(
          ModificaRifiutata(
            tabella: 'presenze',
            operazione: 'upsert',
            quando: DateTime(2026, 10, 19),
          ),
        );
        expect(
          [for (final m in primo.read(modificheRifiutateProvider)) m.tabella],
          ['presenze', 'gare'],
        );

        // Come dopo aver riaperto l'app.
        final secondo = ProviderContainer();
        addTearDown(secondo.dispose);
        secondo.read(modificheRifiutateProvider);
        await pumpEventQueue();
        expect(secondo.read(modificheRifiutateProvider), hasLength(2));

        await secondo.read(modificheRifiutateProvider.notifier).svuota();
        expect(secondo.read(modificheRifiutateProvider), isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(jsonDecode(prefs.getString('modifiche_rifiutate')!), isEmpty);
      },
    );

    test('ne tiene al massimo 20', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final elenco = container.read(modificheRifiutateProvider.notifier);
      for (var i = 0; i < 25; i++) {
        await elenco.aggiungi(
          ModificaRifiutata(
            tabella: 'gare',
            operazione: 'update',
            quando: DateTime(2026, 1, 1 + i),
          ),
        );
      }
      final rimaste = container.read(modificheRifiutateProvider);
      expect(rimaste, hasLength(20));
      expect(rimaste.first.quando, DateTime(2026, 1, 25));
    });
  });

  group('la sincronizzazione', () {
    late AppDatabase db;
    setUp(() async {
      db = AppDatabase.perTest(NativeDatabase.memory());
      await enqueueOperation(
        db,
        tabella: 'presenze',
        operazione: 'upsert',
        rigaId: 'p1',
        payload: {'id': 'p1', 'atleta_id': 'a1', 'stato': 'presente'},
      );
    });
    tearDown(() => db.close());

    Future<int> inCoda() async =>
        (await db.select(db.pendingOperationsTable).get()).length;

    test(
      'una modifica rifiutata dal server esce dalla coda e si segnala',
      () async {
        final client = SupabaseClient(
          'http://supabase.finto',
          'chiave-finta',
          httpClient: MockClient(
            (r) async => http.Response(
              jsonEncode(_rifiutoRls),
              403,
              headers: {'content-type': 'application/json'},
              request: r,
            ),
          ),
        );
        addTearDown(client.dispose);
        final rifiutate = <ModificaRifiutata>[];

        await SyncEngine(db, client, suRifiuto: rifiutate.add).processQueue();

        expect(await inCoda(), 0);
        final m = rifiutate.single;
        expect(
          (m.tabella, m.operazione, m.codice),
          ('presenze', 'upsert', '42501'),
        );
        expect(jsonEncode(m.aMappa()), isNot(contains('Luca')));
      },
    );

    test('senza rete resta in coda e non è un rifiuto', () async {
      final client = SupabaseClient(
        'http://supabase.finto',
        'chiave-finta',
        httpClient: MockClient(
          (_) async => throw http.RequestAbortedException(),
        ),
      );
      addTearDown(client.dispose);
      final rifiutate = <ModificaRifiutata>[];

      await SyncEngine(db, client, suRifiuto: rifiutate.add).processQueue();

      expect(await inCoda(), 1);
      expect(rifiutate, isEmpty);
    });
  });
}
