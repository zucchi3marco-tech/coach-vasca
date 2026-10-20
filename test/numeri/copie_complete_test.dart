import 'dart:convert';

import 'package:coach_vasca/core/db/app_database.dart';
import 'package:coach_vasca/core/sync/sync_engine.dart';
import 'package:coach_vasca/features/allenamenti/data/allenamenti_repository.dart';
import 'package:coach_vasca/features/allenamenti/data/copia_serie.dart';
import 'package:coach_vasca/features/allenamenti/data/duplicazione_settimana_service.dart';
import 'package:coach_vasca/features/allenamenti/data/serie_repository.dart';
import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/secco/data/secco_repository.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
import 'package:coach_vasca/features/stagioni/data/duplicazione_stagione_service.dart';
import 'package:coach_vasca/features/stagioni/data/stagioni_repository.dart';
import 'package:coach_vasca/features/stagioni/domain/stagione.dart';
import 'package:drift/drift.dart' show GeneratedColumn;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

/// Famiglia di errori «un campo nuovo si perde in una copia»: capita ogni
/// volta che si aggiunge un campo a una serie (`recuperoDopoS`,
/// `destinatari`, `momentoId`) e una copia non lo sa. Qui ogni colonna
/// delle tabelle copiate ha una decisione scritta (copiata, rifatta dalla
/// copia, lasciata fuori di proposito): una colonna nuova senza decisione
/// fa fallire il test, e dice dove scriverla.

// ---------------------------------------------------------------------------
// Il controllo delle colonne

/// Ogni colonna di [colonne] deve avere una decisione in [decise] (e ogni
/// decisione una colonna): se no il test fallisce con il punto in cui
/// scriverla.
void _controllaColonne(
  String tabella,
  Iterable<GeneratedColumn> colonne,
  Set<String> decise, {
  required String doveCopiare,
}) {
  final nomi = {for (final c in colonne) c.name};
  for (final nome in nomi) {
    if (!decise.contains(nome)) {
      fail(
        'Colonna nuova in $tabella: «$nome». Decidi se la copia la porta '
        '($doveCopiare) e scrivila qui.',
      );
    }
  }
  for (final nome in decise) {
    if (!nomi.contains(nome)) {
      fail(
        'In $tabella non c\'è più la colonna «$nome»: toglila dalle '
        'decisioni di questo test.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Un Supabase finto che si ricorda le righe

/// Un server finto con le tabelle in memoria: salva ciò che gli arriva
/// (aggiungendo `club_id`, come fa il trigger vero), lo restituisce e
/// applica le modifiche. Con [senzaRete] ogni richiesta fallisce come
/// quando il telefono è offline.
class _ServerFinto {
  final tabelle = <String, List<Map<String, dynamic>>>{};
  bool senzaRete = false;

  SupabaseClient client() => SupabaseClient(
    'http://supabase.finto',
    'chiave-finta',
    httpClient: MockClient(_rispondi),
  );

  Future<http.Response> _rispondi(http.Request r) async {
    if (senzaRete) throw http.ClientException('offline');
    final righe = tabelle.putIfAbsent(r.url.pathSegments.last, () => []);
    final filtri = {
      for (final e in r.url.queryParameters.entries)
        if (e.value.startsWith('eq.')) e.key: e.value.substring(3),
    };
    List<Map<String, dynamic>> trovate() => [
      for (final riga in righe)
        if (filtri.entries.every((f) => '${riga[f.key]}' == f.value)) riga,
    ];

    var stato = 200;
    late List<Map<String, dynamic>> risposta;
    switch (r.method) {
      case 'POST':
        final nuova = {
          'club_id': 'c1',
          ...jsonDecode(r.body) as Map<String, dynamic>,
        };
        righe.add(nuova);
        risposta = [nuova];
        stato = 201;
      case 'PATCH':
        risposta = trovate();
        for (final riga in risposta) {
          riga.addAll(jsonDecode(r.body) as Map<String, dynamic>);
        }
      default:
        risposta = trovate()
          ..sort(
            (a, b) => ((a['ordine'] ?? 0) as num).compareTo(
              (b['ordine'] ?? 0) as num,
            ),
          );
    }
    final unaSola = r.headers.entries.any(
      (h) =>
          h.key.toLowerCase() == 'accept' &&
          h.value.contains('vnd.pgrst.object'),
    );
    return http.Response(
      jsonEncode(unaSola ? risposta.single : risposta),
      stato,
      headers: {'content-type': 'application/json; charset=utf-8'},
      // Il client legge il metodo dalla richiesta della risposta.
      request: r,
    );
  }
}

// ---------------------------------------------------------------------------
// Le serie

/// Ogni colonna della tabella locale delle serie, con il suo valore in una
/// [Serie]. Gli elenchi dei destinatari sono liste, qui e nell'originale.
final Map<String, Object? Function(Serie)> _valoriSerie = {
  'id': (s) => s.id,
  'allenamento_id': (s) => s.allenamentoId,
  'club_id': (s) => s.clubId,
  'ordine': (s) => s.ordine,
  'blocco': (s) => s.blocco,
  'ripetute': (s) => s.ripetute,
  'distanza_m': (s) => s.distanzaM,
  'durata_s': (s) => s.durataS,
  'stile': (s) => s.stile,
  'esecuzione': (s) => s.esecuzione,
  'zona': (s) => s.zona,
  'passo_obiettivo_s': (s) => s.passoObiettivoS,
  'recupero_s': (s) => s.recuperoS,
  'ripartenza_s': (s) => s.ripartenzaS,
  'attrezzatura': (s) => s.attrezzatura,
  'note': (s) => s.note,
  'piramide_id': (s) => s.piramideId,
  'esito': (s) => s.esito,
  'recupero_dopo_s': (s) => s.recuperoDopoS,
  'per_ruolo': (s) => s.destinatari.ruolo,
  'solo_atleti_json': (s) => s.destinatari.soloAtleti,
  'tranne_atleti_json': (s) => s.destinatari.tranneAtleti,
  'momento_id': (s) => s.momentoId,
};

/// Le colonne che `copiaSerie` porta com'è dall'originale.
const _serieCopiate = {
  'blocco',
  'ripetute',
  'distanza_m',
  'durata_s',
  'stile',
  'esecuzione',
  'zona',
  'passo_obiettivo_s',
  'recupero_s',
  'ripartenza_s',
  'attrezzatura',
  'note',
  'recupero_dopo_s',
  'per_ruolo',
  'solo_atleti_json',
  'tranne_atleti_json',
};

/// Quelle che la copia rifà: le sceglie chi copia (id nuovo, allenamento
/// di arrivo, posizione, id del gruppo e del momento in parallelo).
const _serieRifatte = {
  'id',
  'allenamento_id',
  'ordine',
  'piramide_id',
  'momento_id',
};

/// Quelle che la copia lascia fuori di proposito: `club_id` lo mette il
/// trigger del server a partire dall'allenamento; `esito` (fatta/saltata)
/// no, perché una copia non è ancora fatta.
const _serieLasciate = {'club_id', 'esito'};

/// Una serie con TUTTI i campi pieni e diversi da quelli di partenza. Ha
/// sia la durata sia la distanza (la app non le fa insieme, ma qui serve
/// vedere che entrambe viaggiano). [destinatari] di default: i portieri,
/// tranne Rossi.
Serie _serieCompleta({
  String id = 's1',
  int ordine = 4,
  Destinatari destinatari = const Destinatari(
    ruolo: 'portiere',
    tranneAtleti: ['rossi'],
  ),
}) => Serie(
  id: id,
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: 'defaticamento',
  ripetute: 4,
  distanzaM: 150,
  durataS: 45,
  stile: 'rana',
  esecuzione: 'gambe',
  zona: 'B2',
  passoObiettivoS: 32.5,
  recuperoS: 20,
  ripartenzaS: 90.5,
  attrezzatura: 'pinne',
  note: 'testa bassa, spinta lunga',
  piramideId: 'g-vecchio',
  esito: 'saltata',
  recuperoDopoS: 120,
  destinatari: destinatari,
  momentoId: 'm-vecchio',
);

/// La stessa serie, ma per alcuni atleti: così anche `solo_atleti_json`
/// ha un valore (con i nomi non c'è né ruolo né esclusi).
Serie _serieSoloAtleti({String id = 's2', int ordine = 5}) => _serieCompleta(
  id: id,
  ordine: ordine,
  destinatari: const Destinatari(soloAtleti: ['rossi', 'bianchi']),
);

/// Il valore di una colonna è "pieno": non nullo e, se è un elenco, non
/// vuoto.
bool _pieno(Object? v) => v != null && !(v is List && v.isEmpty);

/// Il fondo di [letta] confrontato con [atteso], colonna per colonna.
void _stesseColonne(
  Serie letta,
  Serie atteso, {
  Map<String, Object?> diverse = const {},
}) {
  for (final e in _valoriSerie.entries) {
    expect(
      e.value(letta),
      diverse.containsKey(e.key) ? diverse[e.key] : e.value(atteso),
      reason: 'colonna «${e.key}» della serie',
    );
  }
}

/// Crea [s] con il repository vero, passando ogni campo (scritti a mano
/// qui apposta: è il modo con cui il resto dell'app scrive una serie).
Future<Serie> _crea(SerieRepository repo, Serie s) => repo.createSerie(
  allenamentoId: s.allenamentoId,
  ordine: s.ordine,
  blocco: s.blocco,
  ripetute: s.ripetute,
  distanzaM: s.distanzaM,
  durataS: s.durataS,
  stile: s.stile,
  esecuzione: s.esecuzione,
  zona: s.zona,
  passoObiettivoS: s.passoObiettivoS,
  recuperoS: s.recuperoS,
  ripartenzaS: s.ripartenzaS,
  attrezzatura: s.attrezzatura,
  note: s.note,
  piramideId: s.piramideId,
  recuperoDopoS: s.recuperoDopoS,
  destinatari: s.destinatari,
  momentoId: s.momentoId,
);

/// Un repository di serie che annota cosa riceve `createSerie`, con le
/// stesse chiavi delle colonne: la copia vera (`copiaSerie`) gira contro
/// questo.
class _SerieChePrende implements SerieRepository {
  final ricevute = <Map<String, Object?>>[];

  @override
  Future<Serie> createSerie({
    required String allenamentoId,
    required int ordine,
    required String blocco,
    required int ripetute,
    int? distanzaM,
    int? durataS,
    required String stile,
    required String esecuzione,
    String? zona,
    double? passoObiettivoS,
    int? recuperoS,
    double? ripartenzaS,
    String? attrezzatura,
    String? note,
    String? piramideId,
    int? recuperoDopoS,
    Destinatari destinatari = Destinatari.tutti,
    String? momentoId,
  }) async {
    ricevute.add({
      'allenamento_id': allenamentoId,
      'ordine': ordine,
      'blocco': blocco,
      'ripetute': ripetute,
      'distanza_m': distanzaM,
      'durata_s': durataS,
      'stile': stile,
      'esecuzione': esecuzione,
      'zona': zona,
      'passo_obiettivo_s': passoObiettivoS,
      'recupero_s': recuperoS,
      'ripartenza_s': ripartenzaS,
      'attrezzatura': attrezzatura,
      'note': note,
      'piramide_id': piramideId,
      'recupero_dopo_s': recuperoDopoS,
      'per_ruolo': destinatari.ruolo,
      'solo_atleti_json': destinatari.soloAtleti,
      'tranne_atleti_json': destinatari.tranneAtleti,
      'momento_id': momentoId,
    });
    return _serieCompleta();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Gli allenamenti

final Map<String, Object? Function(Allenamento)> _valoriAllenamento = {
  'id': (a) => a.id,
  'club_id': (a) => a.clubId,
  'data': (a) => a.data,
  'titolo': (a) => a.titolo,
  'gruppo_id': (a) => a.gruppoId,
  'note': (a) => a.note,
  'tipo': (a) => a.tipo,
  'durata_min': (a) => a.durataMin,
  'programma_id': (a) => a.programmaId,
  'programma_settimana': (a) => a.programmaSettimana,
};

/// Colonne che `copiaAllenamento` porta com'è.
const _allenamentoCopiate = {'titolo', 'note', 'tipo', 'durata_min'};

/// Quelle che la copia rifà: id nuovo, la data e la squadra le sceglie chi
/// copia (anche un'altra squadra).
const _allenamentoRifatte = {'id', 'data', 'gruppo_id'};

/// Lasciate fuori di proposito. Decisione del coach, 2026-10-20: la copia
/// di una seduta a secco nata da un programma diventa una seduta libera,
/// fuori dal programma (non ne fa parte né ne occupa la settimana).
/// `club_id` resta quello dell'originale.
const _allenamentoLasciate = {'programma_id', 'programma_settimana'};
const _allenamentoUguali = {'club_id'};

class _SerieVuote implements SerieRepository {
  @override
  Future<List<Serie>> fetchPerAllenamento(String allenamentoId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Gli esercizi a secco: annota le sedute copiate.
class _SeccoChePrende implements SeccoRepository {
  final copie = <({String da, String a, String clubId})>[];

  @override
  Future<void> copiaSeduta({
    required String daAllenamentoId,
    required String aAllenamentoId,
    required String clubId,
  }) async =>
      copie.add((da: daAllenamentoId, a: aAllenamentoId, clubId: clubId));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Gli esercizi di una seduta a secco

final Map<String, Object? Function(EsercizioSeduta)> _valoriEsercizio = {
  'id': (r) => r.id,
  'allenamento_id': (r) => r.allenamentoId,
  'club_id': (r) => r.clubId,
  'esercizio_id': (r) => r.esercizioId,
  'ordine': (r) => r.ordine,
  'serie': (r) => r.serie,
  'ripetizioni': (r) => r.ripetizioni,
  'durata_s': (r) => r.durataS,
  'carico': (r) => r.carico,
  'recupero_s': (r) => r.recuperoS,
  'note': (r) => r.note,
};

const _esercizioCopiate = {
  'esercizio_id',
  'serie',
  'ripetizioni',
  'durata_s',
  'carico',
  'recupero_s',
  'note',
};

/// Rifatte: id nuovo, la seduta di arrivo, la posizione (da 1, nell'ordine
/// di partenza) e `club_id`, che `copiaSeduta` riceve dal chiamante.
const _esercizioRifatte = {'id', 'allenamento_id', 'ordine', 'club_id'};

// ---------------------------------------------------------------------------
// Le stagioni

class _StagioniChePrendono implements StagioniRepository {
  final ricevute = <Map<String, Object?>>[];

  @override
  Future<Stagione> createStagione({
    required String clubId,
    required String nome,
    required DateTime dataInizio,
    required DateTime dataFine,
    String? obiettivo,
    String? gruppoId,
    String? campionato,
    List<FaseStagione> fasi = const [],
  }) async {
    ricevute.add({
      'club_id': clubId,
      'nome': nome,
      'data_inizio': dataInizio,
      'data_fine': dataFine,
      'obiettivo': obiettivo,
      'gruppo_id': gruppoId,
      'campionato': campionato,
      'fasi_json': fasi,
    });
    return Stagione(
      id: 'nuova',
      clubId: clubId,
      nome: nome,
      dataInizio: dataInizio,
      dataFine: dataFine,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.perTest(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('copia di una serie', () {
    test('ogni colonna della tabella ha una decisione scritta', () {
      _controllaColonne('serie', db.serieTable.$columns, {
        ..._serieCopiate,
        ..._serieRifatte,
        ..._serieLasciate,
      }, doveCopiare: 'copia_serie.dart');
      // E ogni colonna si sa leggere da una Serie (serve ai test sotto).
      _controllaColonne(
        'serie',
        db.serieTable.$columns,
        _valoriSerie.keys.toSet(),
        doveCopiare: 'copia_serie.dart',
      );
    });

    test('le due serie di prova hanno ogni campo pieno', () {
      // Se una colonna copiata fosse vuota nella serie di prova, il test
      // sotto passerebbe anche perdendola.
      final prove = [_serieCompleta(), _serieSoloAtleti()];
      for (final nome in {..._serieCopiate, ..._serieRifatte, 'esito'}) {
        expect(
          prove.any((s) => _pieno(_valoriSerie[nome]!(s))),
          isTrue,
          reason: 'la colonna «$nome» è vuota in entrambe le serie di prova',
        );
      }
    });

    for (final (nome, originale) in [
      ('per un ruolo, con gli esclusi', _serieCompleta()),
      ('per alcuni atleti', _serieSoloAtleti()),
    ]) {
      test('copiaSerie porta ogni campo ($nome)', () async {
        final repo = _SerieChePrende();
        await repo.copiaSerie(
          originale,
          allenamentoId: 'a-nuovo',
          ordine: 9,
          piramideId: 'g-nuovo',
          momentoId: 'm-nuovo',
        );

        final ricevuta = repo.ricevute.single;
        for (final colonna in _serieCopiate) {
          expect(
            ricevuta[colonna],
            _valoriSerie[colonna]!(originale),
            reason: 'colonna «$colonna» persa nella copia',
          );
        }
        // Quelle rifatte arrivano come le ha scelte chi copia.
        expect(ricevuta['allenamento_id'], 'a-nuovo');
        expect(ricevuta['ordine'], 9);
        expect(ricevuta['piramide_id'], 'g-nuovo');
        expect(ricevuta['momento_id'], 'm-nuovo');
        // Mai quelle lasciate fuori: createSerie non le riceve nemmeno.
        for (final colonna in _serieLasciate) {
          expect(ricevuta.containsKey(colonna), isFalse, reason: colonna);
        }
      });
    }

    test('per un\'altra squadra la copia prende i destinatari dati', () async {
      final repo = _SerieChePrende();
      await repo.copiaSerie(
        _serieSoloAtleti(),
        allenamentoId: 'a-nuovo',
        ordine: 1,
        piramideId: null,
        momentoId: null,
        destinatari: const Destinatari(ruolo: 'portiere'),
      );
      final ricevuta = repo.ricevute.single;
      expect(ricevuta['per_ruolo'], 'portiere');
      expect(ricevuta['solo_atleti_json'], isEmpty);
      expect(ricevuta['tranne_atleti_json'], isEmpty);
      expect(ricevuta['piramide_id'], isNull);
      expect(ricevuta['momento_id'], isNull);
    });
  });

  group('una serie sul server e sul telefono', () {
    late _ServerFinto server;
    late SupabaseClient client;
    late SerieRepository repo;

    setUp(() {
      server = _ServerFinto();
      client = server.client();
      repo = SerieRepository(client, db, SyncEngine(db, client));
    });

    tearDown(() async {
      await client.dispose();
    });

    /// Il telefono sa già dell'allenamento (serve per le serie create
    /// senza rete: il club lo prendono da lì).
    Future<void> allenamentoInCache() async {
      await db
          .into(db.allenamentiTable)
          .insert(
            AllenamentiTableCompanion.insert(
              id: 'a1',
              clubId: 'c1',
              data: DateTime(2026, 10, 20),
            ),
          );
    }

    test(
      'dal server, poi dal telefono senza rete: nessun campo si perde',
      () async {
        final attese = [_serieCompleta(), _serieSoloAtleti()];
        final create = [for (final s in attese) await _crea(repo, s)];
        for (final (i, s) in attese.indexed) {
          await repo.segnaEsito(create[i].id, s.esito);
        }

        void controlla(List<Serie> lette, {required String da}) {
          expect(lette, hasLength(2), reason: da);
          for (final (i, s) in attese.indexed) {
            // L'id lo dà la creazione; il club lo mette il server.
            _stesseColonne(
              lette[i],
              s,
              diverse: {'id': create[i].id, 'club_id': 'c1'},
            );
          }
        }

        controlla(await repo.fetchPerAllenamento('a1'), da: 'letto dal server');

        // Quello che la creazione e l'esito hanno scritto sul telefono.
        server.senzaRete = true;
        controlla(
          await repo.fetchPerAllenamento('a1'),
          da: 'scritto sul telefono',
        );

        // E quello che il telefono si porta giù dal server.
        server.senzaRete = false;
        await repo.refreshFromRemote('a1');
        server.senzaRete = true;
        controlla(
          await repo.fetchPerAllenamento('a1'),
          da: 'riletto dal server',
        );
      },
    );

    test('creata senza rete: sul telefono e in coda c\'è ogni campo', () async {
      await allenamentoInCache();
      server.senzaRete = true;
      final attese = [_serieCompleta(), _serieSoloAtleti()];
      final create = [for (final s in attese) await _crea(repo, s)];
      for (final (i, s) in attese.indexed) {
        await repo.segnaEsito(create[i].id, s.esito);
      }

      final lette = await repo.fetchPerAllenamento('a1');
      expect(lette, hasLength(2));
      for (final (i, s) in attese.indexed) {
        _stesseColonne(
          lette[i],
          s,
          diverse: {'id': create[i].id, 'club_id': 'c1'},
        );
      }

      // Quello che parte quando torna la rete: ogni colonna dell'originale
      // (con il nome del server), senza esito, che si segna a parte.
      final coda = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          if (o.tabella == 'serie' && o.operazione == 'insert')
            jsonDecode(o.payloadJson!) as Map<String, dynamic>,
      ];
      expect(coda, hasLength(2));
      final attesi = {
        for (final nome in {..._serieCopiate, ..._serieRifatte})
          nome.replaceFirst(RegExp(r'_json$'), ''),
      };
      for (final payload in coda) {
        expect(payload.keys, containsAll(attesi));
        expect(payload.containsKey('esito'), isFalse);
      }
    });

    test('spostarla offline non le toglie il gruppo, il per chi, il '
        'recupero, il momento', () async {
      await allenamentoInCache();
      server.senzaRete = true;
      final originale = _serieCompleta();
      final creata = await _crea(repo, originale);
      await repo.segnaEsito(creata.id, originale.esito);

      // Come lo spostamento di una riga: solo i campi della riga.
      final dopo = await repo.updateSerie(
        id: creata.id,
        ordine: 1,
        blocco: originale.blocco,
        ripetute: originale.ripetute,
        distanzaM: originale.distanzaM,
        durataS: originale.durataS,
        stile: originale.stile,
        esecuzione: originale.esecuzione,
        zona: originale.zona,
        passoObiettivoS: originale.passoObiettivoS,
        recuperoS: originale.recuperoS,
        ripartenzaS: originale.ripartenzaS,
        attrezzatura: originale.attrezzatura,
        note: originale.note,
      );

      _stesseColonne(
        dopo,
        originale,
        diverse: {'id': creata.id, 'club_id': 'c1', 'ordine': 1},
      );
      final riletta = (await repo.fetchPerAllenamento('a1')).single;
      _stesseColonne(
        riletta,
        originale,
        diverse: {'id': creata.id, 'club_id': 'c1', 'ordine': 1},
      );

      // E alla ripresa della rete non parte nemmeno l'ordine di quei campi.
      final modifica = [
        for (final o in await db.select(db.pendingOperationsTable).get())
          if (o.tabella == 'serie' &&
              o.operazione == 'update' &&
              (jsonDecode(o.payloadJson!) as Map).containsKey('ordine'))
            jsonDecode(o.payloadJson!) as Map<String, dynamic>,
      ].single;
      for (final chiave in [
        'piramide_id',
        'recupero_dopo_s',
        'per_ruolo',
        'solo_atleti',
        'tranne_atleti',
        'momento_id',
        'esito',
      ]) {
        expect(modifica.containsKey(chiave), isFalse, reason: chiave);
      }
    });

    test(
      'la copia con il repository vero porta tutto tranne l\'esito',
      () async {
        final attese = [_serieCompleta(), _serieSoloAtleti()];
        final create = [for (final s in attese) await _crea(repo, s)];
        for (final (i, s) in attese.indexed) {
          await repo.segnaEsito(create[i].id, s.esito);
        }

        for (final (i, s) in attese.indexed) {
          final originale = (await repo.fetchPerAllenamento('a1'))
              .firstWhere((x) => x.id == create[i].id);
          expect(originale.esito, 'saltata');
          await repo.copiaSerie(
            originale,
            allenamentoId: 'a2',
            ordine: 7 + i,
            piramideId: 'g-nuovo',
            momentoId: 'm-nuovo',
          );
          final copia = (await repo.fetchPerAllenamento('a2'))
              .firstWhere((x) => x.ordine == 7 + i);
          _stesseColonne(
            copia,
            s,
            diverse: {
              'id': copia.id,
              'club_id': 'c1',
              'allenamento_id': 'a2',
              'ordine': 7 + i,
              'piramide_id': 'g-nuovo',
              'momento_id': 'm-nuovo',
              // Una copia non è ancora fatta.
              'esito': null,
            },
          );
          expect(copia.id, isNot(originale.id));
        }
      },
    );
  });

  group('copia di un allenamento', () {
    test('ogni colonna della tabella ha una decisione scritta', () {
      _controllaColonne('allenamenti', db.allenamentiTable.$columns, {
        ..._allenamentoCopiate,
        ..._allenamentoRifatte,
        ..._allenamentoLasciate,
        ..._allenamentoUguali,
      }, doveCopiare: 'DuplicazioneSettimanaService.copiaAllenamento');
      _controllaColonne(
        'allenamenti',
        db.allenamentiTable.$columns,
        _valoriAllenamento.keys.toSet(),
        doveCopiare: 'DuplicazioneSettimanaService.copiaAllenamento',
      );
    });

    for (final senzaRete in [false, true]) {
      test('una seduta piena si copia con ogni campo '
          '(${senzaRete ? 'senza rete' : 'con rete'})', () async {
        final server = _ServerFinto()..senzaRete = senzaRete;
        final client = server.client();
        addTearDown(client.dispose);
        final secco = _SeccoChePrende();
        final servizio = DuplicazioneSettimanaService(
          AllenamentiRepository(client, db, SyncEngine(db, client)),
          _SerieVuote(),
          secco,
        );
        // Nata da un programma a secco, con tutto pieno.
        final sorgente = Allenamento(
          id: 'a1',
          clubId: 'c1',
          data: DateTime(2026, 10, 20, 18),
          titolo: 'Spalla del tiratore',
          gruppoId: 'u14',
          note: 'portare gli elastici',
          tipo: 'secco',
          durataMin: 40,
          programmaId: 'p1',
          programmaSettimana: 3,
        );
        for (final nome in {..._allenamentoCopiate, ..._allenamentoLasciate}) {
          expect(
            _pieno(_valoriAllenamento[nome]!(sorgente)),
            isTrue,
            reason: nome,
          );
        }

        final copia = await servizio.copiaAllenamento(
          sorgente,
          data: DateTime(2026, 10, 27, 18),
          gruppoId: 'u16',
        );

        for (final nome in _allenamentoCopiate) {
          expect(
            _valoriAllenamento[nome]!(copia),
            _valoriAllenamento[nome]!(sorgente),
            reason: 'colonna «$nome» persa nella copia',
          );
        }
        expect(copia.id, isNot(sorgente.id));
        expect(copia.gruppoId, 'u16');
        // La colonna `data` ha solo il giorno, non l'ora.
        expect(
          [copia.data.year, copia.data.month, copia.data.day],
          [2026, 10, 27],
        );
        expect(copia.clubId, 'c1');
        // Decisione del coach (2026-10-20): fuori dal programma.
        expect(copia.programmaId, isNull);
        expect(copia.programmaSettimana, isNull);
        // Una seduta a secco porta anche i suoi esercizi.
        expect(secco.copie.single.da, 'a1');
        expect(secco.copie.single.a, copia.id);
        expect(secco.copie.single.clubId, 'c1');
      });
    }
  });

  group('copia di una seduta a secco', () {
    test('ogni colonna degli esercizi ha una decisione scritta', () {
      _controllaColonne('esercizi_seduta', db.eserciziSedutaTable.$columns, {
        ..._esercizioCopiate,
        ..._esercizioRifatte,
      }, doveCopiare: 'SeccoRepository.copiaSeduta');
      _controllaColonne(
        'esercizi_seduta',
        db.eserciziSedutaTable.$columns,
        _valoriEsercizio.keys.toSet(),
        doveCopiare: 'SeccoRepository.copiaSeduta',
      );
    });

    for (final senzaRete in [false, true]) {
      test('ogni campo di un esercizio arriva nella copia '
          '(${senzaRete ? 'senza rete' : 'con rete'})', () async {
        final server = _ServerFinto()..senzaRete = senzaRete;
        final client = server.client();
        addTearDown(client.dispose);
        final secco = SeccoRepository(client, db, SyncEngine(db, client));

        // Uno a ripetizioni e uno a tempo: una riga a tempo non ha
        // ripetizioni (`toPayload`), quindi servono entrambi per vedere
        // tutte le colonne.
        final righe = [
          const EsercizioSeduta(
            id: '',
            allenamentoId: 'seduta',
            clubId: 'c1',
            esercizioId: 'face-pull',
            ordine: 1,
            serie: 4,
            ripetizioni: 12,
            carico: 'elastico rosso',
            recuperoS: 45,
            note: 'spalle basse',
          ),
          const EsercizioSeduta(
            id: '',
            allenamentoId: 'seduta',
            clubId: 'c1',
            esercizioId: 'plank',
            ordine: 2,
            serie: 5,
            durataS: 30,
            carico: '4 kg',
            recuperoS: 20,
            note: 'bacino in linea',
          ),
        ];
        for (final r in righe) {
          await secco.aggiungiAllaSeduta(r);
        }
        final originali = await secco.watchSeduta('seduta').first;
        expect(originali, hasLength(2));
        for (final nome in _esercizioCopiate) {
          expect(
            originali.any((r) => _pieno(_valoriEsercizio[nome]!(r))),
            isTrue,
            reason: 'la colonna «$nome» è vuota negli esercizi di prova',
          );
        }

        await secco.copiaSeduta(
          daAllenamentoId: 'seduta',
          aAllenamentoId: 'copia',
          clubId: 'c1',
        );

        final copie = await secco.watchSeduta('copia').first;
        expect(copie, hasLength(2));
        for (final (i, copia) in copie.indexed) {
          for (final nome in _esercizioCopiate) {
            expect(
              _valoriEsercizio[nome]!(copia),
              _valoriEsercizio[nome]!(originali[i]),
              reason:
                  'colonna «$nome» persa nella copia dell\'esercizio ${i + 1}',
            );
          }
          expect(copia.id, isNot(originali[i].id));
          expect(copia.allenamentoId, 'copia');
          expect(copia.clubId, 'c1');
          expect(copia.ordine, i + 1);
        }
      });
    }
  });

  group('copia di una stagione', () {
    final fase = FaseStagione(
      nome: 'Andata',
      dataInizio: DateTime(2025, 10, 27),
      dataFine: DateTime(2025, 12, 21),
      obiettivoMetri: 18000,
      obiettivoCarico: 2400,
    );

    test('ogni campo di una fase ha una decisione scritta', () {
      // Ciò che la fase scrive nel database (`fasi_json`) è tutto ciò che
      // ha: un campo nuovo entra qui e va deciso.
      const copiati = {'nome', 'obiettivo_metri', 'obiettivo_carico'};
      const spostati = {'data_inizio', 'data_fine'};
      final campi = fase.toMap().keys.toSet();
      for (final campo in campi) {
        if (!{...copiati, ...spostati}.contains(campo)) {
          fail(
            'Campo nuovo in FaseStagione: «$campo». Decidi se '
            '`spostata` lo porta (stagione.dart) e scrivilo qui.',
          );
        }
      }
      expect(campi, {
        ...copiati,
        ...spostati,
      }, reason: 'la fase di prova ha ogni campo pieno');
    });

    test('spostata porta ogni campo e sposta solo le date', () {
      // 364 giorni: attraversa il cambio dell'ora, i giorni restano quelli.
      final spostata = fase.spostata(364);
      expect(spostata.toMap(), {
        ...fase.toMap(),
        'data_inizio': '2026-10-26',
        'data_fine': '2026-12-20',
      });
    });

    test('ogni colonna della stagione ha una decisione scritta', () {
      const copiate = {
        'club_id',
        'nome',
        'obiettivo',
        'gruppo_id',
        'campionato',
        'fasi_json',
      };
      const spostate = {'data_inizio', 'data_fine'};
      const rifatte = {'id'};
      _controllaColonne('stagioni', db.stagioniTable.$columns, {
        ...copiate,
        ...spostate,
        ...rifatte,
      }, doveCopiare: 'DuplicazioneStagioneService.duplica');
    });

    test('duplicare una stagione porta ogni campo, fasi comprese', () async {
      final repo = _StagioniChePrendono();
      await DuplicazioneStagioneService(repo).duplica(
        Stagione(
          id: 's1',
          clubId: 'c1',
          nome: 'Campionato U14',
          dataInizio: DateTime(2025, 9, 1),
          dataFine: DateTime(2026, 6, 30),
          obiettivo: 'Arrivare ai playoff',
          gruppoId: 'u14',
          campionato: 'Under 14 Lombardia',
          fasi: [fase],
        ),
        DateTime(2026, 9, 1),
      );

      final r = repo.ricevute.single;
      expect(r['club_id'], 'c1');
      expect(r['nome'], 'Campionato U14');
      expect(r['obiettivo'], 'Arrivare ai playoff');
      expect(r['gruppo_id'], 'u14');
      expect(r['campionato'], 'Under 14 Lombardia');
      expect(r['data_inizio'], DateTime(2026, 9, 1));
      expect(r['data_fine'], DateTime(2027, 6, 30));
      final fasi = r['fasi_json'] as List<FaseStagione>;
      expect(fasi.single.toMap(), {
        ...fase.toMap(),
        'data_inizio': '2026-10-27',
        'data_fine': '2026-12-21',
      });
    });
  });
}
