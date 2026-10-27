import 'dart:convert';
import 'dart:math' as math;

import 'package:coach_vasca/features/club/domain/ruolo_club.dart';
import 'package:coach_vasca/features/export/data/dati_club_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

const _club = 'club-1';

/// Una riga per tabella, come le manda Supabase. Le funzioni (rpc) hanno
/// la chiave `rpc/nome`.
Map<String, List<Map<String, dynamic>>> _tabelle() => {
  'gruppi': [
    {
      'id': 'gruppo-1',
      'club_id': _club,
      'nome': 'Under 14',
      'ordine': 1,
      'sport': 'pallanuoto',
      'capo_user_id': 'utente-2',
    },
  ],
  'rpc/membri_del_club': [
    {
      'user_id': 'utente-1',
      'nome': 'Marco Rossi',
      'ruolo': 'owner',
      'email': 'marco@example.com',
      'sono_io': true,
    },
    {
      'user_id': 'utente-2',
      'nome': 'Luca Bianchi',
      'ruolo': 'coach',
      'email': 'luca@example.com',
      'sono_io': false,
    },
  ],
  'atleti': [
    {
      'id': 'atleta-1',
      'club_id': _club,
      'nome': 'Mario',
      'cognome': 'Rossi',
      'data_nascita': '2012-03-12',
      'sesso': 'M',
      'sport': 'pallanuoto',
      'gruppo_id': 'gruppo-1',
      'email_genitore': 'genitore@example.com',
      'telefono_genitore': null,
      'consenso_privacy_firmato': true,
      'consenso_privacy_data': '2026-09-05',
      'note': null,
      'attivo': true,
      'numero_tessera_fin': '12345',
      'user_id': null,
      'visita_medica_scadenza': '2027-01-31',
      'ruolo': 'portiere',
      'altro_gruppo_id': null,
      'giorni_altro_gruppo': [2, 4],
    },
  ],
  'stagioni': [
    {
      'id': 'stagione-1',
      'club_id': _club,
      'nome': 'Campionato U14',
      'data_inizio': '2026-09-01',
      'data_fine': '2027-06-30',
      'obiettivo': 'Salvezza',
      'gruppo_id': 'gruppo-1',
      'campionato': 'Serie C',
      'fasi': [
        {
          'nome': 'Preparazione',
          'data_inizio': '2026-09-01',
          'data_fine': '2026-10-31',
          'obiettivo_metri': 12000,
        },
      ],
    },
  ],
  'allenamenti': [
    {
      'id': 'allenamento-1',
      'club_id': _club,
      'data': '2026-10-10',
      'titolo': 'Resistenza',
      'gruppo_id': 'gruppo-1',
      'note': null,
      'tipo': 'acqua',
      'durata_min': null,
    },
  ],
  'serie': [
    {
      'id': 'serie-1',
      'allenamento_id': 'allenamento-1',
      'club_id': _club,
      'ordine': 1,
      'blocco': 'principale',
      'ripetute': 4,
      'distanza_m': 100,
      'durata_s': null,
      'stile': 'libero',
      'esecuzione': 'nuoto',
      'zona': 'A1',
      'passo_obiettivo_s': 92.5,
      'recupero_s': 20,
      'per_ruolo': 'portiere',
    },
  ],
  'presenze': [
    {
      'id': 'presenza-1',
      'allenamento_id': 'allenamento-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'stato': 'presente',
      'note': null,
    },
  ],
  'esercizi_secco': [
    {
      'id': 'esercizio-1',
      'club_id': _club,
      'nome': 'Rotazioni esterne',
      'categoria': 'spalla',
      'misura': 'ripetizioni',
      'archiviato': false,
    },
  ],
  'esercizi_seduta': [
    {
      'id': 'riga-1',
      'allenamento_id': 'allenamento-secco',
      'club_id': _club,
      'esercizio_id': 'esercizio-1',
      'ordine': 1,
      'serie': 3,
      'ripetizioni': 12,
      'carico': 'elastico rosso',
    },
  ],
  'serie_secco_fatte': [
    {
      'id': 'fatta-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'allenamento_id': 'allenamento-secco',
      'riga_id': 'riga-1',
      'esercizio_id': 'esercizio-1',
      'serie': 1,
      'ripetizioni': 12,
      'carico': 'elastico rosso',
      'fatta_il': '2026-10-12T16:05:00+00:00',
    },
  ],
  'partite': [
    {
      'id': 'partita-1',
      'club_id': _club,
      'gruppo_id': 'gruppo-1',
      'data': '2026-10-17',
      'ora': '15:30',
      'squadra_casa': 'Canottieri Milano',
      'squadra_trasferta': 'Pro Recco',
      'numero_max_convocati': 14,
    },
  ],
  'distinta_giocatori': [
    {
      'id': 'distinta-1',
      'partita_id': 'partita-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'numero_calottina': 1,
      'capitano': true,
      'vice_capitano': false,
      'portiere': true,
      'fuoriquota': false,
    },
  ],
  'eventi_partita': [
    {
      'id': 'evento-1',
      'partita_id': 'partita-1',
      'club_id': _club,
      'tipo': 'tiro',
      'squadra': 'nostra',
      'atleta_id': 'atleta-1',
      'esito': 'gol',
      'created_at': '2026-10-17T14:00:00+00:00',
    },
  ],
  'referti_partita': [
    {
      'id': 'referto-1',
      'partita_id': 'partita-1',
      'club_id': _club,
      'squadra_casa': 'Canottieri Milano',
      'squadra_trasferta': 'Pro Recco',
      'risultato_casa': 2,
      'risultato_trasferta': 1,
      'parziali': [
        {'casa': 1, 'trasferta': 0},
      ],
      'giocatori_casa': [
        {
          'numeroCalottina': 1,
          'nome': 'M. Rossi',
          'reti': 2,
          'espulsioni': 0,
          'atletaId': 'atleta-1',
        },
      ],
      'giocatori_trasferta': [],
    },
  ],
  'gare': [
    {
      'id': 'gara-1',
      'club_id': _club,
      'data': '2026-11-08',
      'nome': 'Trofeo Città',
      'gruppo_id': null,
    },
  ],
  'impegni': [
    {
      'id': 'impegno-1',
      'club_id': _club,
      'gruppo_id': null,
      'tipo': 'collegiale',
      'dal': '2026-12-27',
      'al': '2026-12-29',
      'nome': 'Collegiale a Lignano',
      'luogo': null,
      'note': null,
    },
  ],
  'gara_iscritti': [
    {
      'id': 'iscritto-1',
      'gara_id': 'gara-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
    },
  ],
  'tempi_gara': [
    {
      'id': 'tempo-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'stile': 'libero',
      'distanza_m': 100,
      'vasca_m': 25,
      'tempo_s': 65.2,
      'data': '2026-10-05',
      'note': null,
      'gara_id': 'gara-1',
    },
  ],
  'personal_best': [
    {
      'id': 'pb-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'stile': 'rana',
      'distanza_m': 100,
      'tempo_s': 80.55,
      'data': null,
      'note': null,
    },
  ],
  'test_ingresso': [
    {
      'id': 'ingresso-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'tipo': 'BVS',
      'data_test': '2026-09-20',
      'distanza_totale_m': 400,
      'tempo_totale_s': 360,
      'passo_medio_100_s': 90,
    },
  ],
  'tabelle_passi': [
    {
      'id': 'passo-1',
      'test_id': 'ingresso-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'zona': 'A1',
      'passo_100_s': 110,
      'percentuale_riferimento': 80,
    },
  ],
  'test_club': [
    {
      'id': 'test-1',
      'club_id': _club,
      'nome': 'Sprint 15 m',
      'unita': 'secondi',
      'migliore': 'minore',
      'prove': 2,
      'punteggio': 'migliore',
    },
  ],
  'test_risultati': [
    {
      'id': 'risultato-1',
      'test_id': 'test-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'data': '2026-10-01',
      'valori': [8.9, 8.62],
    },
  ],
  'rpe_sedute': [
    {
      'id': 'rpe-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'evento_tipo': 'allenamento',
      'evento_id': 'allenamento-1',
      'data': '2026-10-10',
      'rpe': 7,
    },
  ],
  'schede_benessere': [
    {
      'id': 'scheda-1',
      'atleta_id': 'atleta-1',
      'club_id': _club,
      'data': '2026-10-09',
      'evento_tipo': 'allenamento',
      'evento_id': 'allenamento-1',
      'dolori': true,
      'zone_dolore': ['spalla'],
      'intensita_dolore': 4,
      'ore_sonno': 7.5,
      'qualita_sonno': 4,
      'energia': 3,
      'muscoli': 2,
      'stress': 4,
      'umore': 5,
      'sintomi': ['raffreddore'],
      'created_at': '2026-10-09T05:00:00+00:00',
      'updated_at': '2026-10-09T05:30:00+00:00',
    },
  ],
  'club': [
    {'created_at': '2024-11-03T10:00:00+00:00'},
  ],
};

/// Un Supabase finto che risponde a ogni tabella (e funzione) con le sue
/// righe, al massimo 1000 per richiesta come quello vero, e annota le
/// richieste.
MockClient _server(
  Map<String, List<Map<String, dynamic>>> tabelle,
  List<Uri> richieste,
) => MockClient((richiesta) async {
  richieste.add(richiesta.url);
  // .../rest/v1/atleti, oppure .../rest/v1/rpc/membri_del_club
  final segmenti = richiesta.url.pathSegments;
  final chiave = segmenti[segmenti.length - 2] == 'rpc'
      ? 'rpc/${segmenti.last}'
      : segmenti.last;
  final righe = tabelle[chiave];
  if (righe == null) {
    return http.Response(
      jsonEncode({'message': 'Tabella ignota: $chiave'}),
      404,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: richiesta,
    );
  }
  final q = richiesta.url.queryParameters;
  final da = int.parse(q['offset'] ?? '0');
  final quante = math.min(int.parse(q['limit'] ?? '1000'), 1000);
  return http.Response(
    jsonEncode(righe.skip(da).take(quante).toList()),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
    request: richiesta,
  );
});

String _tabella(Uri url) {
  final segmenti = url.pathSegments;
  return segmenti[segmenti.length - 2] == 'rpc'
      ? 'rpc/${segmenti.last}'
      : segmenti.last;
}

({DatiClubRepository repository, List<Uri> richieste}) _repository(
  Map<String, List<Map<String, dynamic>>> tabelle,
) {
  final richieste = <Uri>[];
  final client = SupabaseClient(
    'http://supabase.finto',
    'chiave-finta',
    httpClient: _server(tabelle, richieste),
  );
  addTearDown(client.dispose);
  return (repository: DatiClubRepository(client), richieste: richieste);
}

void main() {
  test('le righe diventano i dati del club', () async {
    final (:repository, :richieste) = _repository(_tabelle());

    final dati = await repository.leggi(_club, conBenessere: true);

    expect(dati.squadre.single.nome, 'Under 14');
    expect(dati.squadre.single.sport, 'pallanuoto');
    expect(dati.squadreConCapo.single.capoUserId, 'utente-2');
    expect(dati.membri, hasLength(2));
    expect(dati.membri.first.ruolo, RuoloClub.responsabile);
    expect(dati.membri.first.email, 'marco@example.com');
    expect(dati.atleti.single.cognome, 'Rossi');
    expect(dati.atleti.single.giorniAltroGruppo, [2, 4]);
    expect(dati.stagioni.single.campionato, 'Serie C');
    expect(dati.stagioni.single.fasi.single.obiettivoMetri, 12000);
    expect(dati.allenamenti.single.data, DateTime(2026, 10, 10));
    expect(dati.serie.single.passoObiettivoS, 92.5);
    expect(dati.serie.single.destinatari.ruolo, 'portiere');
    expect(dati.presenze.single.stato, 'presente');
    expect(dati.eserciziSecco.single.nome, 'Rotazioni esterne');
    expect(dati.eserciziSeduta.single.carico, 'elastico rosso');
    expect(dati.serieSeccoFatte.single.ripetizioni, 12);
    expect(dati.partite.single.squadraTrasferta, 'Pro Recco');
    expect(dati.distinte.single.portiere, isTrue);
    expect(dati.eventiPartita.single.esito, 'gol');
    expect(dati.referti.single.risultatoCasa, 2);
    expect(dati.referti.single.parziali.single.casa, 1);
    expect(dati.referti.single.giocatoriCasa.single.atletaId, 'atleta-1');
    expect(dati.gare.single.nome, 'Trofeo Città');
    expect(dati.iscrittiGare.single.atletaId, 'atleta-1');
    expect(dati.tempiGara.single.tempoS, 65.2);
    expect(dati.tempiGara.single.garaId, 'gara-1');
    expect(dati.personalBest.single.data, isNull);
    expect(dati.personalBest.single.tempoS, 80.55);
    expect(dati.testIngresso.single.passoMedio100S, 90);
    expect(dati.tabellePassi.single.percentualeRiferimento, 80);
    expect(dati.testClub.single.piuBassoMeglio, isTrue);
    expect(dati.risultatiTest.single.valori, [8.9, 8.62]);
    expect(dati.rpeSedute.single.rpe, 7);

    final scheda = dati.schedeBenessere!.single;
    expect(scheda.zoneDolore, ['spalla']);
    expect(scheda.sintomi, ['raffreddore']);
    expect(scheda.oreSonno, 7.5);
    expect(scheda.umore, 5);
    expect(scheda.compilataIl, DateTime.utc(2026, 10, 9, 5, 30).toLocal());
    expect(richieste, isNotEmpty);
  });

  test(
    'senza benessere la tabella delle schede non viene nemmeno chiesta',
    () async {
      final (:repository, :richieste) = _repository(_tabelle());
      final frasi = <String>[];

      final dati = await repository.leggi(
        _club,
        conBenessere: false,
        avanzamento: frasi.add,
      );

      expect(dati.schedeBenessere, isNull);
      expect([
        for (final r in richieste) _tabella(r),
      ], isNot(contains('schede_benessere')));
      expect(
        richieste.map((r) => r.toString()),
        everyElement(isNot(contains('benessere'))),
      );
      expect(frasi, isNot(contains('Leggo il benessere')));
      // Il resto c'è.
      expect(dati.atleti, hasLength(1));
      expect(dati.rpeSedute, hasLength(1));
    },
  );

  test('con il benessere la tabella delle schede viene chiesta', () async {
    final (:repository, :richieste) = _repository(_tabelle());
    final frasi = <String>[];

    final dati = await repository.leggi(
      _club,
      conBenessere: true,
      avanzamento: frasi.add,
    );

    expect(dati.schedeBenessere, hasLength(1));
    expect([
      for (final r in richieste) _tabella(r),
    ], contains('schede_benessere'));
    expect(frasi.last, 'Leggo il benessere');
  });

  test(
    'ogni tabella si legge per club, a pagine, in un ordine stabile',
    () async {
      final (:repository, :richieste) = _repository(_tabelle());

      await repository.leggi(_club, conBenessere: true);

      // Membri e capi delle squadre passano da MembriClubRepository (la
      // sua lettura delle squadre ha le sue colonne e il suo ordine).
      final dalClub = [
        for (final r in richieste)
          if (_tabella(r) != 'rpc/membri_del_club' &&
              r.queryParameters['select'] != 'id,nome,capo_user_id')
            r,
      ];
      expect(dalClub, isNotEmpty);
      for (final r in dalClub) {
        expect(r.queryParameters['club_id'], 'eq.$_club', reason: '$r');
        expect(r.queryParameters['order'], startsWith('id'), reason: '$r');
        expect(r.queryParameters['offset'], isNotNull, reason: '$r');
      }
      expect([
        for (final r in richieste) _tabella(r),
      ], contains('rpc/membri_del_club'));
      final capi = richieste.where(
        (r) => r.queryParameters['select'] == 'id,nome,capo_user_id',
      );
      expect(capi, hasLength(1));
      expect(capi.single.queryParameters['club_id'], 'eq.$_club');
    },
  );

  test('oltre 1000 righe le legge tutte, a pagine', () async {
    final tabelle = _tabelle();
    tabelle['presenze'] = [
      for (var i = 0; i < 2500; i++)
        {
          'id': 'presenza-${i.toString().padLeft(5, '0')}',
          'allenamento_id': 'allenamento-1',
          'atleta_id': 'atleta-1',
          'club_id': _club,
          'stato': 'presente',
          'note': null,
        },
    ];
    final (:repository, :richieste) = _repository(tabelle);

    final dati = await repository.leggi(_club, conBenessere: false);

    expect(dati.presenze, hasLength(2500));
    expect(
      [
        for (final r in richieste)
          if (_tabella(r) == 'presenze') r.queryParameters['offset'],
      ],
      ['0', '1000', '2000'],
    );
  });

  test(
    'l\'avanzamento dice quale tabella si legge, prima di leggerla',
    () async {
      final (:repository, :richieste) = _repository(_tabelle());
      final frasi = <String>[];
      // Per ogni frase: quante richieste erano già partite.
      final giaPartite = <int>[];

      await repository.leggi(
        _club,
        conBenessere: false,
        avanzamento: (cosa) {
          frasi.add(cosa);
          giaPartite.add(richieste.length);
        },
      );

      expect(frasi.first, 'Leggo le squadre');
      expect(frasi, contains('Leggo le presenze'));
      expect(frasi, contains('Leggo gli atleti'));
      expect(frasi.toSet(), hasLength(frasi.length));
      // Le frasi arrivano prima delle richieste: crescono di pari passo.
      expect(giaPartite, orderedEquals([...giaPartite]..sort()));
      final presenze = frasi.indexOf('Leggo le presenze');
      expect(
        richieste.skip(giaPartite[presenze]).map(_tabella).first,
        'presenze',
      );
    },
  );

  test('quando è nato il club', () async {
    final (:repository, richieste: _) = _repository(_tabelle());
    expect(
      await repository.creatoIl(_club),
      DateTime.utc(2024, 11, 3, 10).toLocal(),
    );
  });

  test('se il server non mostra il club, la data manca', () async {
    final tabelle = _tabelle()..['club'] = [];
    final (:repository, richieste: _) = _repository(tabelle);
    expect(await repository.creatoIl(_club), isNull);
  });
}
