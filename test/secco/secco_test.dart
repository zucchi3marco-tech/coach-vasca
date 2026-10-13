import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

EsercizioSeduta _riga({
  int serie = 3,
  int? ripetizioni = 12,
  int? durataS,
  String? carico,
  int? recuperoS = 60,
}) => EsercizioSeduta(
  id: 'r',
  allenamentoId: 'a',
  clubId: 'c',
  esercizioId: 'e',
  ordine: 1,
  serie: serie,
  ripetizioni: durataS == null ? ripetizioni : null,
  durataS: durataS,
  carico: carico,
  recuperoS: recuperoS,
);

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

void main() {
  group('come si scrive un esercizio', () {
    test('serie per ripetizioni o tempo, carico e recupero', () {
      expect(
        prescrizioneEsercizio(_riga(carico: 'elastico rosso')),
        "3 × 12, elastico rosso · recupero 1'",
      );
      expect(
        prescrizioneEsercizio(_riga(durataS: 45, recuperoS: 30)),
        "3 × 45'' · recupero 30''",
      );
      expect(prescrizioneEsercizio(_riga(recuperoS: null)), '3 × 12');
      expect(formattaSecondi(90), "1'30''");
      expect(formattaSecondi(120), "2'");
    });

    test('la durata stimata: lavoro, recuperi fra le serie, cambio', () {
      // 3 × 12 a 3'' = 108'' + 2 recuperi da 60'' + 30'' = 258''.
      // 3 × 40'' = 120'' + 2 da 30'' + 30'' = 210''. Totale 468'' → 8'.
      expect(minutiStimati([_riga(), _riga(durataS: 40, recuperoS: 30)]), 8);
      expect(minutiStimati(const []), 0);
    });

    test("la prescrizione proposta: l'ultima volta, se no quella pronta", () {
      const pronto = EsercizioSecco(
        id: 'e',
        clubId: 'c',
        nome: 'Plank frontale',
        categoria: CategoriaEsercizio.core,
        misura: MisuraEsercizio.tempo,
        modello: 'plank_frontale',
      );
      expect(prescrizioneProposta(pronto), (
        serie: 3,
        ripetizioni: null,
        durataS: 40,
        recuperoS: 30,
        carico: null,
      ));
      expect(
        prescrizioneProposta(
          pronto,
          ultima: _riga(serie: 4, durataS: 60, recuperoS: 45),
        ),
        (serie: 4, ripetizioni: null, durataS: 60, recuperoS: 45, carico: null),
      );
      const mio = EsercizioSecco(
        id: 'x',
        clubId: 'c',
        nome: 'Lanci con la palla medica',
        categoria: CategoriaEsercizio.forza,
      );
      expect(prescrizioneProposta(mio), (
        serie: 3,
        ripetizioni: 12,
        durataS: null,
        recuperoS: 60,
        carico: null,
      ));
    });

    test("l'elenco pronto: chiavi uniche, per tutte le categorie utili", () {
      final chiavi = {for (final m in modelliEsercizi) m.chiave};
      expect(chiavi, hasLength(modelliEsercizi.length));
      final categorie = {for (final m in modelliEsercizi) m.categoria};
      expect(
        categorie,
        containsAll(<CategoriaEsercizio>[
          CategoriaEsercizio.spalla,
          CategoriaEsercizio.scapole,
          CategoriaEsercizio.core,
          CategoriaEsercizio.gambe,
          CategoriaEsercizio.mobilita,
          CategoriaEsercizio.forza,
        ]),
      );
      for (final m in modelliEsercizi) {
        expect(
          (m.ripetizioni == null) != (m.durataS == null),
          isTrue,
          reason: m.chiave,
        );
        expect(m.descrizione.length, lessThanOrEqualTo(1000));
      }
    });
  });

  group('carico', () {
    test('una seduta a secco vale RPE × i suoi minuti, tutta nel secco', () {
      final sedute = seduteDiAtleta(
        dataAllenamenti: {
          'acqua': DateTime(2026, 10, 12),
          'secco': DateTime(2026, 10, 13),
          'secco2': DateTime(2026, 10, 14),
        },
        seriePerAllenamento: const {},
        minutiSecco: const {'secco': 40, 'secco2': 45},
        statoPresenze: const {
          'acqua': 'presente',
          'secco': 'presente',
          'secco2': 'presente',
        },
        dataPartite: const {},
        partiteConvocato: const {},
        rpe: const {('allenamento', 'secco'): 7},
      );
      expect(sedute, hasLength(3));
      final secco = sedute.firstWhere((s) => s.eventoId == 'secco');
      expect(secco.minuti, 40);
      expect(secco.secco, 280);
      expect(secco.acqua, 0);
      expect(secco.stimato, isFalse);
      // Senza risposta: RPE stimato 5.
      final stimata = sedute.firstWhere((s) => s.eventoId == 'secco2');
      expect(stimata.secco, 45 * rpeStimatoSecco);
      expect(stimata.stimato, isTrue);
      // L'acqua senza serie resta come prima.
      final acqua = sedute.firstWhere((s) => s.eventoId == 'acqua');
      expect(acqua.secco, 0);
      expect(acqua.minuti, minutiAllenamentoSenzaSerie);
    });
  });

  group('senza rete', () {
    late SupabaseClient client;
    late AppDatabase db;
    late SyncEngine sync;

    setUp(() {
      client = _senzaRete();
      db = AppDatabase.perTest(NativeDatabase.memory());
      sync = SyncEngine(db, client);
    });

    tearDown(() async {
      await db.close();
      await client.dispose();
    });

    test('seduta, esercizi pronti e righe restano sul telefono e partono '
        'dopo; la prescrizione si ricorda', () async {
      final allenamenti = AllenamentiRepository(client, db, sync);
      final secco = SeccoRepository(client, db, sync);

      final seduta = await allenamenti.createAllenamento(
        clubId: 'c1',
        data: DateTime(2026, 10, 14),
        titolo: 'Prevenzione spalla',
        tipo: 'secco',
        durataMin: 40,
      );
      expect(seduta.secco, isTrue);
      expect(seduta.durataMin, 40);
      expect(seduta.titoloMostrato, 'Prevenzione spalla');

      await secco.aggiungiModelli('c1', modelliEsercizi.take(2));
      // Già aggiunti: la seconda volta non si duplicano.
      await secco.aggiungiModelli('c1', modelliEsercizi.take(3));
      final esercizi = await secco.watchEsercizi('c1').first;
      expect(esercizi, hasLength(3));
      final extra = esercizi.firstWhere(
        (e) => e.modello == 'extrarotazione_elastico',
      );
      expect(extra.categoria, CategoriaEsercizio.spalla);

      await secco.aggiungiAllaSeduta(
        EsercizioSeduta(
          id: '',
          allenamentoId: seduta.id,
          clubId: 'c1',
          esercizioId: extra.id,
          ordine: 1,
          ripetizioni: 15,
          carico: 'elastico rosso',
          recuperoS: 45,
        ),
      );
      final altro = esercizi.firstWhere((e) => e.id != extra.id);
      await secco.aggiungiAllaSeduta(
        EsercizioSeduta(
          id: '',
          allenamentoId: seduta.id,
          clubId: 'c1',
          esercizioId: altro.id,
          ordine: 2,
          ripetizioni: 12,
        ),
      );
      var righe = await secco.watchSeduta(seduta.id).first;
      expect([for (final r in righe) r.esercizioId], [extra.id, altro.id]);

      await secco.riordina(righe.reversed.toList());
      righe = await secco.watchSeduta(seduta.id).first;
      expect([for (final r in righe) r.esercizioId], [altro.id, extra.id]);

      final ultima = await secco.ultimaVolta(extra.id);
      expect(ultima?.carico, 'elastico rosso');
      expect(await secco.inUso(extra.id), isTrue);

      // La copia della seduta (Duplica) porta gli esercizi.
      final copia = await allenamenti.createAllenamento(
        clubId: 'c1',
        data: DateTime(2026, 10, 21),
        tipo: 'secco',
        durataMin: 40,
      );
      await secco.copiaSeduta(
        daAllenamentoId: seduta.id,
        aAllenamentoId: copia.id,
        clubId: 'c1',
      );
      final copiate = await secco.watchSeduta(copia.id).first;
      expect([for (final r in copiate) r.esercizioId], [altro.id, extra.id]);
      expect([for (final r in copiate) r.ordine], [1, 2]);

      final coda = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          (
            o.tabella,
            o.operazione,
            jsonDecode(o.payloadJson ?? '{}') as Map<String, dynamic>,
          ),
      ];
      final sedute = [
        for (final o in coda)
          if (o.$1 == 'allenamenti') o.$3,
      ];
      expect(sedute.first['tipo'], 'secco');
      expect(sedute.first['durata_min'], 40);
      expect(
        coda.where((o) => o.$1 == 'esercizi_secco' && o.$2 == 'insert'),
        hasLength(3),
      );
      expect(
        coda.where((o) => o.$1 == 'esercizi_seduta' && o.$2 == 'insert'),
        hasLength(4),
      );

      // Eliminando la seduta se ne vanno anche i suoi esercizi.
      await allenamenti.deleteAllenamento(seduta.id);
      expect(await secco.watchSeduta(seduta.id).first, isEmpty);
    });
  });
}
