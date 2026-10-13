import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/secco/domain/programma_secco.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

SupabaseClient _senzaRete() => SupabaseClient(
  'http://supabase.finto',
  'chiave-finta',
  httpClient: MockClient((_) async => throw http.ClientException('offline')),
);

ProgrammaPronto _pronto(String chiave) =>
    modelliProgrammi.firstWhere((m) => m.chiave == chiave);

/// Gli id degli esercizi del club, uguali alle chiavi di quelli pronti.
final _idUguali = {for (final m in modelliEsercizi) m.chiave: m.chiave};

void main() {
  group('i programmi pronti', () {
    test('chiavi uniche, esercizi pronti veri, settimane tutte uguali', () {
      expect(
        modelliProgrammi.map((m) => m.chiave).toSet(),
        hasLength(modelliProgrammi.length),
      );
      expect(modelliProgrammi.map((m) => m.chiave), [
        'spalla_tiratore',
        'scapole_core',
        'gambe_bicicletta',
        'portieri',
      ]);
      final pronti = {for (final m in modelliEsercizi) m.chiave: m};
      for (final p in modelliProgrammi) {
        expect(p.sedute, hasLength(2), reason: p.nome);
        for (final s in p.sedute) {
          for (final r in s) {
            final esercizio = pronti[r.esercizio];
            expect(esercizio, isNotNull, reason: '${p.nome}: ${r.esercizio}');
            expect(r.dosi, hasLength(p.settimane), reason: r.esercizio);
            for (final d in r.dosi) {
              final dose = doseDaTesto('x', d, recuperoS: r.recuperoS);
              // "3x30s" solo per gli esercizi a tempo.
              expect(
                dose.durataS != null,
                esercizio!.aTempo,
                reason: '${r.esercizio}: $d',
              );
            }
          }
        }
        for (final w in p.scarico) {
          expect(w, inInclusiveRange(1, p.settimane));
        }
      }
    });

    test('le sedute stanno nei minuti scritti, lo scarico ha meno serie', () {
      for (final p in modelliProgrammi) {
        final settimane = p.settimaneCon(_idUguali);
        for (final (w, s) in settimane.indexed) {
          for (final dosi in s.sedute) {
            expect(
              minutiDosi(dosi),
              lessThanOrEqualTo(p.durataMin + 2),
              reason: '${p.nome}, settimana ${w + 1}',
            );
          }
          if (s.scarico) {
            final prima = settimane[w - 1];
            for (final (j, dosi) in s.sedute.indexed) {
              for (final (i, d) in dosi.indexed) {
                expect(
                  d.serie,
                  lessThanOrEqualTo(prima.sedute[j][i].serie),
                  reason: '${p.nome}, settimana ${w + 1}',
                );
              }
            }
          }
        }
      }
    });

    test('dalle dosi scritte alle dosi del programma', () {
      final spalla = _pronto('spalla_tiratore');
      expect(spalla.settimane, 6);
      expect(spalla.scarico, {4});
      final settimane = spalla.settimaneCon(_idUguali);
      expect(settimane, hasLength(6));
      expect(settimane[3].scarico, isTrue);
      expect(settimane[0].scarico, isFalse);
      final extra = settimane[4].sedute[0][0];
      expect(extra.esercizioId, 'extrarotazione_elastico');
      expect((extra.serie, extra.ripetizioni), (3, 12));
      expect(extra.carico, 'elastico più duro');
      expect(extra.recuperoS, 45);
      final sleeper = settimane[0].sedute[0][3];
      expect(
        (sleeper.serie, sleeper.durataS, sleeper.ripetizioni),
        (2, 30, null),
      );
      expect(sleeper.recuperoS, 15);
      expect(
        () => doseDaTesto('x', '3 per 12', recuperoS: 45),
        throwsFormatException,
      );
    });
  });

  group('settimana dopo settimana', () {
    const elastico = DoseEsercizio(esercizioId: 'e', serie: 2, ripetizioni: 12);

    test('un po\' di più: una serie fino a 4, poi ripetizioni o secondi', () {
      final tre = unPoDiPiu(elastico);
      expect((tre.serie, tre.ripetizioni), (3, 12));
      final quattro = unPoDiPiu(unPoDiPiu(tre));
      expect((quattro.serie, quattro.ripetizioni), (4, 14));
      final plank = unPoDiPiu(
        const DoseEsercizio(esercizioId: 'p', serie: 4, durataS: 30),
      );
      expect((plank.serie, plank.durataS), (4, 35));
      // La mobilità resta com'è.
      expect(
        unPoDiPiu(elastico, categoria: CategoriaEsercizio.mobilita).serie,
        2,
      );
      expect(unaSerieInMeno(elastico).serie, 1);
      expect(unaSerieInMeno(unaSerieInMeno(elastico)).serie, 1);
    });

    test('la settimana nuova parte dall\'ultima che non è di scarico', () {
      const settimane = [
        SettimanaProgramma(
          sedute: [
            [DoseEsercizio(esercizioId: 'e', serie: 3, ripetizioni: 15)],
            [DoseEsercizio(esercizioId: 's', serie: 2, durataS: 30)],
          ],
        ),
        SettimanaProgramma(
          scarico: true,
          sedute: [
            [DoseEsercizio(esercizioId: 'e', serie: 2, ripetizioni: 10)],
            [DoseEsercizio(esercizioId: 's', serie: 2, durataS: 30)],
          ],
        ),
      ];
      final nuova = settimanaSuccessiva(
        settimane,
        esercizi: {
          's': const EsercizioSecco(
            id: 's',
            clubId: 'c',
            nome: 'Sleeper stretch',
            categoria: CategoriaEsercizio.mobilita,
            misura: MisuraEsercizio.tempo,
          ),
        },
      );
      expect(nuova.scarico, isFalse);
      expect(
        (nuova.sedute[0][0].serie, nuova.sedute[0][0].ripetizioni),
        (4, 15),
      );
      expect(nuova.sedute[1][0].serie, 2);
    });

    test('sedute a settimana in più o in meno, per tutte le settimane', () {
      const p = ProgrammaSecco(
        id: 'p',
        clubId: 'c',
        nome: 'Prova',
        settimane: [
          SettimanaProgramma(
            sedute: [
              [DoseEsercizio(esercizioId: 'a')],
              [DoseEsercizio(esercizioId: 'b')],
            ],
          ),
          SettimanaProgramma(
            sedute: [
              [DoseEsercizio(esercizioId: 'a')],
              [DoseEsercizio(esercizioId: 'b')],
            ],
          ),
        ],
      );
      expect(p.sedutePerSettimana, 2);
      expect(p.numeroSedute, 4);
      expect(p.usa('b'), isTrue);
      final tre = p.conSedutePerSettimana(3);
      expect(tre.sedutePerSettimana, 3);
      expect(tre.settimane[1].sedute[2], isEmpty);
      final una = p.conSedutePerSettimana(1);
      expect(una.numeroSedute, 2);
      expect(una.usa('b'), isFalse);
      // Il JSON del database avanti e indietro.
      final riletto = ProgrammaSecco.settimaneDa(
        jsonDecode(jsonEncode(p.toPayload()['settimane'])),
      );
      expect(riletto[1].sedute[1].single.esercizioId, 'b');
      expect(riletto[1].sedute[1].single.serie, 3);
    });

    test('nomi e titoli delle sedute', () {
      expect(nomeSeduta(0, 2), 'Seduta A');
      expect(nomeSeduta(1, 2), 'Seduta B');
      expect(nomeSeduta(0, 1), 'La seduta');
      expect(
        titoloSedutaProgramma(
          'Spalla del tiratore',
          settimana: 2,
          seduta: 1,
          sedutePerSettimana: 2,
        ),
        'Spalla del tiratore · settimana 2, seduta B',
      );
      expect(
        titoloSedutaProgramma(
          'Core',
          settimana: 3,
          seduta: 0,
          sedutePerSettimana: 1,
        ),
        'Core · settimana 3',
      );
    });
  });

  group('nel calendario', () {
    test('ogni 7 giorni una settimana, la A nel primo giorno scelto', () {
      // Lunedì 19 ottobre 2026; domenica 25 finisce l'ora legale.
      final calendario = calendarioProgramma(
        primoGiorno: DateTime(2026, 10, 19),
        settimane: 2,
        giorni: const [4, 2],
      );
      expect(
        [for (final c in calendario) (c.data, c.settimana, c.seduta)],
        [
          (DateTime(2026, 10, 20), 1, 0),
          (DateTime(2026, 10, 22), 1, 1),
          (DateTime(2026, 10, 27), 2, 0),
          (DateTime(2026, 10, 29), 2, 1),
        ],
      );
      // Partendo di giovedì la A è il giovedì, la B il martedì dopo.
      final daGiovedi = calendarioProgramma(
        primoGiorno: DateTime(2026, 10, 22, 18),
        settimane: 2,
        giorni: const [2, 4],
      );
      expect(
        [for (final c in daGiovedi) (c.data, c.settimana, c.seduta)],
        [
          (DateTime(2026, 10, 22), 1, 0),
          (DateTime(2026, 10, 27), 1, 1),
          (DateTime(2026, 10, 29), 2, 0),
          (DateTime(2026, 11, 3), 2, 1),
        ],
      );
    });

    test('il primo lunedì e i giorni proposti', () {
      expect(prossimoLunedi(DateTime(2026, 10, 13, 9)), DateTime(2026, 10, 19));
      expect(prossimoLunedi(DateTime(2026, 10, 19, 9)), DateTime(2026, 10, 19));
      expect(prossimoLunedi(DateTime(2026, 10, 25)), DateTime(2026, 10, 26));
      expect(giorniProposti(1), [2]);
      expect(giorniProposti(2), [2, 4]);
      expect(giorniProposti(3), [1, 3, 5]);
      expect(giorniProposti(4), [1, 2, 4, 5]);
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

    test('un programma pronto entra nel club e nel calendario, poi si '
        'toglie', () async {
      final secco = SeccoRepository(client, db, sync);
      final allenamenti = AllenamentiRepository(client, db, sync);

      // Uno degli esercizi c'è già: non si duplica.
      await secco.aggiungiModelli('c1', [
        modelliEsercizi.firstWhere((m) => m.chiave == 'face_pull'),
      ]);
      final programma = await secco.aggiungiProgrammaPronto(
        'c1',
        _pronto('spalla_tiratore'),
      );
      expect(programma.nome, 'Spalla del tiratore');
      expect(programma.modello, 'spalla_tiratore');
      expect(programma.settimane, hasLength(6));
      expect(programma.sedutePerSettimana, 2);
      expect(programma.durataMin, 15);
      final esercizi = await secco.watchEsercizi('c1').first;
      expect(esercizi, hasLength(8));
      final perModello = {for (final e in esercizi) e.modello: e.id};
      expect(
        programma.settimane[0].sedute[1][1].esercizioId,
        perModello['face_pull'],
      );
      expect(
        (await secco.watchProgrammi('c1').first).single.settimane[3].scarico,
        isTrue,
      );
      // Usato solo nel programma: non si elimina.
      expect(await secco.inUso(perModello['sleeper_stretch']!), isTrue);

      final calendario = calendarioProgramma(
        primoGiorno: DateTime(2026, 10, 19),
        settimane: programma.settimane.length,
        giorni: const [2, 4],
      );
      final quante = await secco.mettiNelCalendario(
        programma: programma,
        gruppoId: 'u14',
        calendario: calendario,
        durataMin: 15,
      );
      expect(quante, 12);
      final sedute = [
        for (final a in await allenamenti.watchPerClub('c1').first)
          if (a.programmaId == programma.id) a,
      ]..sort((a, b) => a.data.compareTo(b.data));
      expect(sedute, hasLength(12));
      expect(sedute.first.data, DateTime(2026, 10, 20));
      expect(sedute.first.secco, isTrue);
      expect(sedute.first.gruppoId, 'u14');
      expect(sedute.first.durataMin, 15);
      expect(sedute.first.programmaSettimana, 1);
      expect(
        sedute.first.titolo,
        'Spalla del tiratore · settimana 1, seduta A',
      );
      expect(sedute[7].programmaSettimana, 4);
      final righe = await secco.watchSeduta(sedute[9].id).first;
      // Settimana 5, seduta B: extrarotazione a 90° con l'elastico più duro.
      expect(sedute[9].titolo, 'Spalla del tiratore · settimana 5, seduta B');
      expect(righe, hasLength(4));
      expect(righe.first.esercizioId, perModello['extrarotazione_90']);
      expect((righe.first.serie, righe.first.ripetizioni), (3, 10));
      expect(righe.first.carico, 'elastico più duro');
      expect([for (final r in righe) r.ordine], [1, 2, 3, 4]);

      // In coda nell'ordine giusto: prima esercizi e programma, poi le
      // sedute, poi le loro righe.
      final coda = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          (o.tabella, o.operazione),
      ];
      expect(coda.where((o) => o.$1 == 'allenamenti'), hasLength(12));
      expect(coda.where((o) => o.$1 == 'esercizi_seduta'), hasLength(48));
      expect(
        coda.indexWhere((o) => o.$1 == 'programmi_secco'),
        lessThan(coda.indexWhere((o) => o.$1 == 'allenamenti')),
      );
      expect(
        coda.lastIndexWhere((o) => o.$1 == 'allenamenti'),
        lessThan(coda.indexWhere((o) => o.$1 == 'esercizi_seduta')),
      );
      final primaSeduta = jsonDecode(
        (await db.select(db.pendingOperationsTable).get())
            .firstWhere((o) => o.tabella == 'allenamenti')
            .payloadJson!,
      ) as Map<String, dynamic>;
      expect(primaSeduta['programma_id'], programma.id);
      expect(primaSeduta['programma_settimana'], 1);
      expect(primaSeduta['tipo'], 'secco');

      // Da togliere: da mercoledì 28 in poi, senza la seduta con le
      // presenze.
      await db
          .into(db.presenzeTable)
          .insert(
            PresenzeTableCompanion.insert(
              id: 'pr1',
              allenamentoId: sedute[3].id,
              atletaId: 'a1',
              clubId: 'c1',
              stato: 'presente',
            ),
          );
      final daTogliere = await secco.seduteDaTogliere(
        programmaId: programma.id,
        gruppoId: 'u14',
        daGiorno: DateTime(2026, 10, 28, 15),
      );
      expect(daTogliere, hasLength(8));
      expect(daTogliere, isNot(contains(sedute[3].id)));
      expect(
        await secco.seduteDaTogliere(
          programmaId: programma.id,
          gruppoId: null,
          daGiorno: DateTime(2026, 10, 28),
        ),
        isEmpty,
      );

      // Eliminando il programma le sedute restano, staccate.
      await secco.eliminaProgramma(programma.id);
      expect(await secco.watchProgrammi('c1').first, isEmpty);
      final rimaste = await allenamenti.watchPerClub('c1').first;
      expect(rimaste, hasLength(12));
      expect(rimaste.every((a) => a.programmaId == null), isTrue);
    });

    test('un programma nuovo si crea, si cambia e si rilegge', () async {
      final secco = SeccoRepository(client, db, sync);
      final creato = await secco.creaProgramma(
        const ProgrammaSecco(
          id: '',
          clubId: 'c1',
          nome: 'Core del lunedì',
          durataMin: 10,
          settimane: [
            SettimanaProgramma(sedute: [[]]),
          ],
        ),
      );
      expect(creato.id, isNotEmpty);
      expect(creato.sedutePerSettimana, 1);
      final cambiato = await secco.aggiornaProgramma(
        creato.copyWith(
          settimane: [
            const SettimanaProgramma(
              sedute: [
                [
                  DoseEsercizio(
                    esercizioId: 'e1',
                    serie: 3,
                    durataS: 40,
                    note: '  ',
                  ),
                ],
              ],
            ),
          ],
        ),
      );
      final dose = cambiato.settimane.single.sedute.single.single;
      expect((dose.serie, dose.durataS, dose.ripetizioni), (3, 40, null));
      expect(dose.note, isNull);
      final riga = await (db.select(
        db.programmiSeccoTable,
      )..where((t) => t.id.equals(creato.id))).getSingle();
      expect(riga.durataMin, 10);
      expect(riga.settimaneJson, contains('"durata_s":40'));
      await db
          .update(db.programmiSeccoTable)
          .write(const ProgrammiSeccoTableCompanion(nome: Value('Core')));
      expect((await secco.watchProgrammi('c1').first).single.nome, 'Core');
    });
  });
}
