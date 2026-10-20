import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/ai_genera/application/storico_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/carico/data/carico_repository.dart';
import 'package:coach_vasca/features/carico/data/rpe_repository.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/carico/domain/volumi_atleta.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Piano 23, «Com'è andata»: di una serie fatta in parte contano solo i
/// metri o i minuti fatti, nel volume, nel carico e nella media per l'AI.

Serie _serie(
  String id, {
  String allenamentoId = 'a1',
  int ripetute = 1,
  int? distanzaM,
  int? durataS,
  String? zona,
  String esecuzione = 'nuoto',
  double? ripartenzaS,
  String? esito,
  int? metriFatti,
  int? secondiFatti,
}) => Serie(
  id: id,
  allenamentoId: allenamentoId,
  clubId: 'c1',
  ordine: int.parse(id.substring(1)),
  blocco: 'principale',
  ripetute: ripetute,
  distanzaM: distanzaM,
  durataS: durataS,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: zona,
  ripartenzaS: ripartenzaS,
  esito: esito,
  metriFatti: metriFatti,
  secondiFatti: secondiFatti,
);

/// 10x100 in A2 partendo ogni 1'30" (15 minuti).
Serie _dieciPerCento({String? esito, int? metriFatti}) => _serie(
  's1',
  ripetute: 10,
  distanzaM: 100,
  zona: 'A2',
  ripartenzaS: 90,
  esito: esito,
  metriFatti: metriFatti,
);

/// 20' di palleggio, a tempo.
Serie _palleggio({String? esito, int? secondiFatti}) => _serie(
  's2',
  durataS: 1200,
  esecuzione: 'palleggio',
  esito: esito,
  secondiFatti: secondiFatti,
);

void main() {
  group('quanto si è fatto di una serie', () {
    test('non segnata o fatta tutta: vale com\'è scritta', () {
      for (final s in [_dieciPerCento(), _dieciPerCento(esito: 'fatta')]) {
        expect(volumeFatto(s).metri, 1000);
        expect(quotaFatta(s), 1);
      }
    });

    test('saltata: niente', () {
      final s = _dieciPerCento(esito: 'saltata');
      expect(volumeFatto(s).vuoto, isTrue);
      expect(quotaFatta(s), 0);
    });

    test('in parte, a metri: 6 ripetute di 10', () {
      final s = _dieciPerCento(esito: 'fatta', metriFatti: 600);
      expect(volumeFatto(s).metri, 600);
      expect(quotaFatta(s), closeTo(0.6, 1e-9));
      // Il volume scritto resta quello: è il totale in testa al dettaglio.
      expect(volumeSerie(s).metri, 1000);
    });

    test('in parte, a tempo: 12 minuti di 20', () {
      final s = _palleggio(esito: 'fatta', secondiFatti: 720);
      expect(volumeFatto(s).secondi, 720);
      expect(volumeFatto(s).metri, 0);
      expect(quotaFatta(s), closeTo(0.6, 1e-9));
    });

    test('mai più di quanto è scritto', () {
      final s = _dieciPerCento(esito: 'fatta', metriFatti: 1500);
      expect(volumeFatto(s).metri, 1000);
      expect(quotaFatta(s), 1);
    });

    test('il volume fatto di un allenamento, solo quello del gruppo', () {
      final serie = [
        _dieciPerCento(esito: 'fatta', metriFatti: 600),
        _serie('s3', ripetute: 4, distanzaM: 200, esito: 'saltata'),
        _serie('s4', distanzaM: 400),
        _palleggio(esito: 'fatta', secondiFatti: 720),
      ];
      final scritto = volumiPerAllenamento(serie)['a1']!;
      final fatto = volumiPerAllenamento(serie, fatto: true)['a1']!;
      expect(scritto.metri, 1000 + 800 + 400);
      expect(scritto.secondi, 1200);
      expect(fatto.metri, 600 + 0 + 400);
      expect(fatto.secondi, 720);
    });
  });

  group('il carico conta i minuti fatti', () {
    test('6 ripetute di 10: il 60% dei minuti di quella serie', () {
      final tutta = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 20),
        serie: [_dieciPerCento(), _palleggio()],
        rpe: 6,
      );
      // 15 minuti di 10x100 e 20 di palleggio.
      expect(tutta.minuti, 35);
      expect(tutta.totale, 6 * 35);

      final inParte = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 20),
        serie: [
          _dieciPerCento(esito: 'fatta', metriFatti: 600),
          _palleggio(esito: 'fatta', secondiFatti: 600),
        ],
        rpe: 6,
      );
      // 9 minuti di nuoto e 10 di palleggio.
      expect(inParte.minuti, 19);
      expect(inParte.totale, 6 * 19);
    });

    test('tutto segnato fatto per zero: nessun minuto, nessun carico', () {
      final niente = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 20),
        serie: [
          _dieciPerCento(esito: 'fatta', metriFatti: 0),
          _palleggio(esito: 'fatta', secondiFatti: 0),
        ],
      );
      expect(niente.minuti, 0);
      expect(niente.totale, 0);
      expect(niente.rpe.isFinite, isTrue);
    });

    test('senza serie restano i minuti tipici di una seduta', () {
      final vuota = caricoAllenamento(
        id: 'a1',
        giorno: DateTime(2026, 10, 20),
        serie: const [],
      );
      expect(vuota.minuti, minutiAllenamentoSenzaSerie);
    });
  });

  group('i volumi di un atleta', () {
    test('per zona, solo i metri fatti', () {
      final volumi = VolumiAtleta.daSerie(
        [
          {
            'allenamento_id': 'a1',
            'ripetute': 10,
            'distanza_m': 100,
            'zona': 'A2',
            'esecuzione': 'nuoto',
            'metri_fatti': 600,
          },
          {
            'allenamento_id': 'a1',
            'ripetute': 4,
            'distanza_m': 200,
            'zona': 'B1',
            'esecuzione': 'nuoto',
          },
          {
            'allenamento_id': 'a1',
            'ripetute': 1,
            'durata_s': 1200,
            'esecuzione': 'palleggio',
            'secondi_fatti': 720,
          },
        ],
        {'a1'},
      );
      expect(volumi.volumeTotaleM, 600 + 800);
      expect(volumi.perZona, {'A2': 600, 'B1': 800});
      expect(volumi.tempoTotaleS, 720);
      expect(volumi.tempoPerEsecuzione, {'palleggio': 720});
    });
  });

  test('Genera settimana con AI: la media conta i metri fatti', () {
    final media = mediaMetriSettimanali([
      _dieciPerCento(esito: 'fatta', metriFatti: 600),
      _serie('s3', ripetute: 4, distanzaM: 200),
      _serie('s4', distanzaM: 400, esito: 'saltata'),
    ]);
    expect(media, (600 + 800) / 4);
  });

  group('senza rete', () {
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
      for (final s in [
        _dieciPerCento(esito: 'fatta', metriFatti: 600),
        _serie('s3', ripetute: 4, distanzaM: 200, esito: 'saltata'),
        _serie('s4', distanzaM: 400),
      ]) {
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
                zona: Value(s.zona),
                ripartenzaS: Value(s.ripartenzaS),
                esito: Value(s.esito),
                metriFatti: Value(s.metriFatti),
              ),
            );
      }
      await db
          .into(db.atletiTable)
          .insert(
            AtletiTableCompanion.insert(
              id: 'rossi',
              clubId: 'c1',
              nome: 'Mario',
              cognome: 'Rossi',
              dataNascita: DateTime(2010),
              sport: 'pallanuoto',
            ),
          );
      await db
          .into(db.presenzeTable)
          .insert(
            PresenzeTableCompanion.insert(
              id: 'p-rossi',
              allenamentoId: 'a1',
              atletaId: 'rossi',
              clubId: 'c1',
              stato: 'presente',
            ),
          );
    });

    tearDown(() async {
      await db.close();
      await client.dispose();
    });

    test('il telefono conta solo la parte fatta', () async {
      final volumi = await carico.volumiPerAtleta(
        atletaId: 'rossi',
        clubId: 'c1',
      );
      // 600 dei 10x100, niente della saltata, il 400 non segnato.
      expect(volumi.volumeTotaleM, 600 + 400);
      expect(volumi.perZona['A2'], 600);
    });
  });
}
