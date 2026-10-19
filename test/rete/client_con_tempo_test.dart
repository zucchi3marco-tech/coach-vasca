import 'dart:async';
import 'dart:convert';

import 'package:coach_vasca/core/rete/client_con_tempo.dart';
import 'package:coach_vasca/core/rete/stato_rete.dart';
import 'package:coach_vasca/core/sync/network_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

const _breve = Duration(milliseconds: 60);

/// Un server che non risponde mai: si ferma solo se la richiesta viene
/// interrotta.
class _ServerFermo extends http.BaseClient {
  var richieste = 0;
  var interrotte = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    richieste++;
    final risposta = Completer<http.StreamedResponse>();
    if (request is http.Abortable) {
      request.abortTrigger?.then((_) {
        interrotte++;
        if (!risposta.isCompleted) {
          risposta.completeError(http.RequestAbortedException(request.url));
        }
      });
    }
    return risposta.future;
  }
}

/// Manda le intestazioni subito, poi un pezzo del corpo, poi più niente.
class _CorpoAMeta extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final corpo = StreamController<List<int>>()..add(utf8.encode('[{"id"'));
    return http.StreamedResponse(corpo.stream, 200, request: request);
  }
}

ClientConTempoMassimo _client(http.Client interno, StatoRete stato) =>
    ClientConTempoMassimo(interno, stato: stato, tempoPer: (_) => _breve);

void main() {
  late StatoRete stato;
  setUp(() => stato = StatoRete());

  test('i tempi massimi: dati, file e funzioni sul server', () {
    Duration per(String percorso) =>
        tempoMassimoPer(Uri.parse('https://x.supabase.co$percorso'));
    expect(per('/rest/v1/atleti'), const Duration(seconds: 8));
    expect(per('/auth/v1/token'), const Duration(seconds: 8));
    expect(
      per('/storage/v1/object/segnalazioni/a.png'),
      const Duration(seconds: 30),
    );
    expect(
      per('/functions/v1/genera-allenamento'),
      const Duration(seconds: 90),
    );
  });

  test('una risposta in tempo passa intera e riporta in rete', () async {
    stato.chiamataFallita(DateTime(2026, 10, 19, 18, 42));
    final client = _client(
      MockClient((richiesta) async {
        expect(richiesta.method, 'POST');
        expect(richiesta.headers['apikey'], 'chiave');
        expect(richiesta.body, '{"nome":"Luca"}');
        return http.Response('{"ok":true}', 201, request: richiesta);
      }),
      stato,
    );

    final risposta = await client.post(
      Uri.parse('https://x.supabase.co/rest/v1/atleti'),
      headers: {'apikey': 'chiave'},
      body: '{"nome":"Luca"}',
    );

    expect(risposta.statusCode, 201);
    expect(risposta.body, '{"ok":true}');
    expect(stato.inRete, isTrue);
  });

  test('anche una risposta di errore del server vuol dire «in rete»', () async {
    stato.chiamataFallita();
    final client = _client(
      MockClient((r) async => http.Response('no', 403, request: r)),
      stato,
    );
    final risposta = await client.get(
      Uri.parse('https://x.supabase.co/rest/v1/a'),
    );
    expect(risposta.statusCode, 403);
    expect(stato.inRete, isTrue);
  });

  test('un server che non risponde: allo scadere la richiesta si interrompe '
      'davvero e vale come senza rete', () async {
    final server = _ServerFermo();
    final client = _client(server, stato);

    await expectLater(
      client.get(Uri.parse('https://x.supabase.co/rest/v1/atleti')),
      throwsA(isA<http.RequestAbortedException>()),
    );
    expect(server.interrotte, 1);
    expect(stato.inRete, isFalse);
    expect(stato.senzaReteDa, isNotNull);
  });

  test(
    'un errore di rete esce come interruzione, e l\'ora resta la prima',
    () async {
      final prima = DateTime(2026, 10, 19, 18, 42);
      stato.chiamataFallita(prima);
      final client = _client(
        MockClient((_) async => throw http.ClientException('rete assente')),
        stato,
      );

      Object? errore;
      try {
        await client.get(Uri.parse('https://x.supabase.co/rest/v1/atleti'));
      } catch (e) {
        errore = e;
      }
      expect(errore, isA<http.RequestAbortedException>());
      expect(isNetworkFailure(errore!), isTrue);
      expect(stato.senzaReteDa, prima);
    },
  );

  test('un corpo che si ferma a metà si interrompe allo scadere', () async {
    final client = _client(_CorpoAMeta(), stato);
    await expectLater(
      client.get(Uri.parse('https://x.supabase.co/rest/v1/atleti')),
      throwsA(isA<http.RequestAbortedException>()),
    );
    expect(stato.inRete, isFalse);
  });

  test('un\'interruzione chiesta da chi chiama non è «senza rete»', () async {
    final server = _ServerFermo();
    final client = ClientConTempoMassimo(
      server,
      stato: stato,
      tempoPer: (_) => const Duration(seconds: 30),
    );
    final basta = Completer<void>();
    final richiesta = http.AbortableRequest(
      'GET',
      Uri.parse('https://x.supabase.co/rest/v1/atleti'),
      abortTrigger: basta.future,
    );

    final invio = client.send(richiesta);
    basta.complete();
    await expectLater(invio, throwsA(isA<http.RequestAbortedException>()));
    expect(server.interrotte, 1);
    expect(stato.inRete, isTrue);
  });

  group('con il client di Supabase', () {
    test(
      'una lettura senza rete non riprova tre volte: un tentativo solo',
      () async {
        var tentativi = 0;
        final supabase = SupabaseClient(
          'https://x.supabase.co',
          'chiave-finta',
          httpClient: _client(
            MockClient((_) async {
              tentativi++;
              throw http.ClientException('rete assente');
            }),
            stato,
          ),
        );
        addTearDown(supabase.dispose);

        final orologio = Stopwatch()..start();
        Object? errore;
        try {
          await supabase.from('atleti').select();
        } catch (e) {
          errore = e;
        }
        expect(isNetworkFailure(errore!), isTrue);
        expect(tentativi, 1);
        // Senza: 1 + 2 + 4 secondi di attese fra i tentativi.
        expect(orologio.elapsed, lessThan(const Duration(seconds: 1)));
      },
    );

    test('un server che non risponde: la lettura finisce allo scadere, come '
        'senza rete', () async {
      final server = _ServerFermo();
      final supabase = SupabaseClient(
        'https://x.supabase.co',
        'chiave-finta',
        httpClient: _client(server, stato),
      );
      addTearDown(supabase.dispose);

      Object? errore;
      try {
        await supabase.from('atleti').select();
      } catch (e) {
        errore = e;
      }
      expect(isNetworkFailure(errore!), isTrue);
      expect(server.richieste, 1);
      expect(stato.inRete, isFalse);
    });
  });
}
