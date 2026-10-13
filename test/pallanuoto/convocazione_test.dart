import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/pallanuoto/data/partite_repository.dart';
import 'package:coach_vasca/features/pallanuoto/domain/convocazione.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

Partita _partita({
  String? ora = '16:00',
  String? luogo = 'Piscina Comunale, via Roma 3',
  String? ritrovoOra = '14:15',
  String? ritrovoLuogo = 'al club, si parte in pullman',
  String? rientroOra = '20:00',
  String? daPortare = 'Accappatoio, ciabatte, documento',
  String? note,
  String nostraSquadra = 'trasferta',
}) => Partita(
  id: 'p1',
  clubId: 'c1',
  data: DateTime(2026, 10, 17),
  ora: ora,
  luogo: luogo,
  campionato: 'Under 14 Emilia-Romagna',
  coloreCalottina: nostraSquadra == 'casa' ? 'bianca' : 'blu',
  squadraCasa: 'Rari Nantes Bologna',
  squadraTrasferta: 'Pallanuoto Riviera',
  numeroMaxConvocati: 15,
  nostraSquadra: nostraSquadra,
  ritrovoOra: ritrovoOra,
  ritrovoLuogo: ritrovoLuogo,
  rientroOra: rientroOra,
  daPortare: daPortare,
  noteConvocazione: note,
);

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  group('messaggio per le famiglie', () {
    test('ritrovo, orari, calottina, cosa portare e i convocati in ordine '
        'di numero', () {
      final testo = testoConvocazione(
        partita: _partita(note: 'Quota pullman 10 euro.'),
        squadra: 'Under 14',
        convocati: [
          (numero: 2, cognome: 'Bianchi', nome: 'Luca', portiere: false),
          (numero: 1, cognome: 'Rossi', nome: 'Mario', portiere: true),
        ],
      );
      expect(
        testo,
        '*Convocazione Under 14*\n'
        'Rari Nantes Bologna – Pallanuoto Riviera\n'
        'Sabato 17 ottobre, in trasferta\n'
        'Under 14 Emilia-Romagna\n'
        '\n'
        'Ritrovo: ore 14:15, al club, si parte in pullman\n'
        'Inizio partita: ore 16:00\n'
        'Piscina: Piscina Comunale, via Roma 3\n'
        'Calottina: blu\n'
        'Rientro previsto: ore 20:00\n'
        'Da portare: Accappatoio, ciabatte, documento\n'
        '\n'
        '*Convocati (2)*\n'
        '1 Rossi Mario (portiere)\n'
        '2 Bianchi Luca\n'
        '\n'
        'Quota pullman 10 euro.',
      );
    });

    test('solo le voci compilate, niente squadra né convocati', () {
      final testo = testoConvocazione(
        partita: _partita(
          ora: null,
          luogo: '  ',
          ritrovoOra: null,
          ritrovoLuogo: 'in piscina',
          rientroOra: null,
          daPortare: null,
          nostraSquadra: 'casa',
        ),
        convocati: const [],
      );
      expect(
        testo,
        '*Convocazione*\n'
        'Rari Nantes Bologna – Pallanuoto Riviera\n'
        'Sabato 17 ottobre, in casa\n'
        'Under 14 Emilia-Romagna\n'
        '\n'
        'Ritrovo: in piscina\n'
        'Calottina: bianca',
      );
    });

    test("nella home dell'atleta solo ritrovo, rientro, da portare e note", () {
      final voci = vociConvocazioneAtleta(_partita(note: 'Puntuali.'));
      expect(
        [for (final v in voci) v.etichetta],
        ['Ritrovo', 'Rientro previsto', 'Da portare', 'Note'],
      );
    });

    test('ritrovo proposto prima della partita', () {
      expect(oraMeno('16:00', 60), '15:00');
      expect(oraMeno('9.30', 45), '08:45');
      expect(oraMeno('00:30', 60), isNull);
      expect(oraMeno(null, 60), isNull);
      expect(oraMeno('pomeriggio', 60), isNull);
    });
  });

  group('salvataggio', () {
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
              data: DateTime(2026, 10, 17),
              ora: const Value('16:00'),
              squadraCasa: 'Noi',
              squadraTrasferta: 'Loro',
            ),
          );
    });

    tearDown(() async {
      await db.close();
      await client.dispose();
    });

    test('senza rete la convocazione resta sul telefono e l\'invio parte '
        'dopo, con l\'ora dell\'invio', () async {
      final repository = PartiteRepository(client, db, sync);

      final bozza = await repository.salvaConvocazione(
        id: 'p1',
        ora: '16:00',
        ritrovoOra: '15:00',
        ritrovoLuogo: '  in piscina ',
        daPortare: 'Accappatoio',
      );
      expect(bozza.ritrovoOra, '15:00');
      expect(bozza.ritrovoLuogo, 'in piscina');
      expect(bozza.convocazioneInviata, isFalse);

      final prima = DateTime.now();
      final inviata = await repository.salvaConvocazione(
        id: 'p1',
        ora: '16:00',
        ritrovoOra: '15:00',
        ritrovoLuogo: 'in piscina',
        daPortare: 'Accappatoio',
        invia: true,
      );
      expect(inviata.convocazioneInviata, isTrue);
      // Drift tiene le date al secondo.
      expect(
        inviata.convocazioneInviataIl!.difference(prima).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );

      final coda = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          (
            o.operazione,
            jsonDecode(o.payloadJson ?? '{}') as Map<String, dynamic>,
          ),
      ];
      expect(coda, hasLength(2));
      expect(coda.first.$1, 'update');
      expect(coda.first.$2.containsKey('convocazione_inviata_at'), isFalse);
      expect(coda.first.$2['ritrovo_luogo'], 'in piscina');
      expect(coda.first.$2['rientro_ora'], isNull);
      expect(coda.last.$2['convocazione_inviata_at'], isA<String>());

      // Il "da portare" si ripropone alla convocazione dopo.
      expect(await repository.ultimoDaPortare('c1'), 'Accappatoio');
      expect(await repository.ultimoDaPortare('altro'), isNull);
    });
  });
}
