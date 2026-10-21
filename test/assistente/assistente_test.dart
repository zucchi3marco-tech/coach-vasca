import 'dart:convert';

import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/assistente/data/cervello_demo.dart';
import 'package:coach_vasca/features/assistente/domain/motore_assistente.dart';
import 'package:coach_vasca/features/assistente/domain/pseudonimi.dart';
import 'package:coach_vasca/features/assistente/domain/strumenti_assistente.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/pallanuoto/domain/distinta_giocatore.dart';
import 'package:coach_vasca/features/pallanuoto/domain/evento_partita.dart';
import 'package:coach_vasca/features/pallanuoto/domain/partita.dart';
import 'package:coach_vasca/features/presenze/domain/presenza.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 13, 18);

Atleta _atleta(
  String id,
  String nome,
  String cognome, {
  String? ruolo,
  String gruppo = 'u14',
}) => Atleta(
  id: id,
  clubId: 'c1',
  nome: nome,
  cognome: cognome,
  dataNascita: DateTime(2012),
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: gruppo,
  ruolo: ruolo,
);

final _atleti = [
  _atleta('rossi', 'Marco', 'Rossi', ruolo: 'portiere'),
  _atleta('bianchi', 'Luca', 'Bianchi'),
  _atleta('verdi', 'Sara', 'Verdi'),
  _atleta('neri', 'Paolo', 'Neri', gruppo: 'u16'),
];

final _prossima = Partita(
  id: 'p-futura',
  clubId: 'c1',
  gruppoId: 'u14',
  data: DateTime(2026, 10, 17),
  ora: '16:00',
  squadraCasa: 'Noi',
  squadraTrasferta: 'Recco',
  numeroMaxConvocati: 3,
);

final _giocata = Partita(
  id: 'p-giocata',
  clubId: 'c1',
  gruppoId: 'u14',
  data: DateTime(2026, 10, 10),
  squadraCasa: 'Noi',
  squadraTrasferta: 'Posillipo',
  numeroMaxConvocati: 15,
);

EventoPartita _tiro(
  String atletaId, {
  String esito = 'gol',
  String? contesto,
}) => EventoPartita(
  id: '$atletaId-$esito-$contesto-${DateTime.now().microsecondsSinceEpoch}',
  partitaId: 'p-giocata',
  clubId: 'c1',
  tipo: 'tiro',
  squadra: 'nostra',
  atletaId: atletaId,
  esito: esito,
  contestoTiro: contesto ?? 'azione',
  creatoIl: DateTime.utc(2026, 10, 10, 15),
);

SchedaBenessere _scheda(
  String atletaId, {
  List<String> zone = const [],
  List<String> sintomi = const [],
}) => SchedaBenessere(
  id: 's-$atletaId',
  atletaId: atletaId,
  clubId: 'c1',
  data: DateTime(2026, 10, 13),
  dolori: zone.isNotEmpty,
  zoneDolore: zone,
  intensitaDolore: zone.isEmpty ? null : 6,
  oreSonno: 8,
  sintomi: sintomi,
  compilataIl: DateTime(2026, 10, 13, 8),
);

class _Fonte implements FonteDatiAssistente {
  @override
  String? get gruppoId => 'u14';

  @override
  Future<List<Atleta>> atleti() async => _atleti;

  @override
  Future<List<Partita>> partite() async => [_prossima, _giocata];

  @override
  Future<List<EventoPartita>> eventi(String partitaId) async =>
      partitaId == 'p-giocata'
      ? [
          _tiro('bianchi'),
          _tiro('bianchi', contesto: 'superiorita'),
          _tiro('verdi', esito: 'parato'),
        ]
      : const [];

  @override
  Future<List<DistintaGiocatore>> distinta(String partitaId) async =>
      partitaId == 'p-futura'
      ? const [
          DistintaGiocatore(
            id: 'd1',
            partitaId: 'p-futura',
            atletaId: 'verdi',
            clubId: 'c1',
            numeroCalottina: 1,
            capitano: false,
            viceCapitano: false,
            portiere: false,
            fuoriquota: false,
          ),
        ]
      : const [];

  @override
  Future<List<Presenza>> presenze() async => const [
    Presenza(
      id: 'pr1',
      allenamentoId: 'a1',
      atletaId: 'rossi',
      clubId: 'c1',
      stato: 'presente',
    ),
    Presenza(
      id: 'pr2',
      allenamentoId: 'a1',
      atletaId: 'bianchi',
      clubId: 'c1',
      stato: 'assente',
    ),
    Presenza(
      id: 'pr3',
      allenamentoId: 'a2',
      atletaId: 'rossi',
      clubId: 'c1',
      stato: 'presente',
    ),
    // Arrivata in ritardo: conta come presente, ma si dice a parte.
    Presenza(
      id: 'pr4',
      allenamentoId: 'a2',
      atletaId: 'verdi',
      clubId: 'c1',
      stato: 'ritardo',
    ),
  ];

  @override
  Future<List<Allenamento>> allenamenti() async => [
    Allenamento(
      id: 'a1',
      clubId: 'c1',
      gruppoId: 'u14',
      data: DateTime(2026, 10, 12),
      titolo: 'Lavoro per Rossi e superiorità',
    ),
    Allenamento(
      id: 'a2',
      clubId: 'c1',
      gruppoId: 'u14',
      data: DateTime(2026, 10, 13),
      tipo: 'secco',
      durataMin: 40,
    ),
  ];

  @override
  Future<Map<String, VolumeAllenamento>> volumi() async => const {
    'a1': VolumeAllenamento(metri: 2400, secondi: 600),
  };

  @override
  Future<List<SchedaBenessere>> schedeBenessere() async => [
    _scheda('rossi', zone: const ['spalla']),
    _scheda('bianchi', sintomi: const ['febbre']),
    _scheda('verdi'),
  ];

  @override
  Future<Map<String, List<CaricoSeduta>>> sedutePerAtleta() async => const {};
}

void main() {
  final pseudonimi = Pseudonimi(_atleti);
  final strumenti = StrumentiAssistente(
    fonte: _Fonte(),
    pseudonimi: pseudonimi,
    oggi: _oggi,
  );

  /// Quello che uscirebbe dal telefono: mai un nome, mai la salute.
  void senzaNomiNeSalute(Object? json) {
    final testo = jsonEncode(json).toLowerCase();
    for (final parola in [
      'rossi',
      'bianchi',
      'verdi',
      'marco',
      'luca',
      'sara',
      'spalla',
      'febbre',
      'dolore',
    ]) {
      expect(testo, isNot(contains(parola)), reason: parola);
    }
  }

  group('codici al posto dei nomi', () {
    test('ogni atleta ha il suo codice, per cognome', () {
      // Bianchi, Neri, Rossi, Verdi.
      expect(pseudonimi.codice('bianchi'), 'G1');
      expect(pseudonimi.codice('neri'), 'G2');
      expect(pseudonimi.codice('rossi'), 'G3');
      expect(pseudonimi.codice('verdi'), 'G4');
      expect(pseudonimi.atleta('g3')?.id, 'rossi');
    });

    test('i nomi spariscono dalla domanda, le zone restano', () {
      expect(
        pseudonimi.anonimizza(
          'Rossi Marco e luca Bianchi in A1, poi Sara 8x100 B1',
        ),
        'G3 e G1 in A1, poi G4 8x100 B1',
      );
      expect(pseudonimi.anonimizza('Rossi M. ha male?'), 'G3 ha male?');
    });

    test('con due Rossi il cognome da solo non dice chi è', () {
      final due = Pseudonimi([
        _atleta('r1', 'Marco', 'Rossi'),
        _atleta('r2', 'Luca', 'Rossi'),
      ]);
      expect(due.anonimizza('Rossi Luca e Rossi'), 'G1 e un atleta');
    });

    test('nella risposta tornano i nomi', () {
      expect(
        pseudonimi.conNomi('Convoca G3 e G1, non G99.'),
        'Convoca Rossi e Bianchi, non G99.',
      );
    });
  });

  group('strumenti', () {
    test('la squadra: codici e ruoli, solo il gruppo scelto', () async {
      final esito = await strumenti.esegui('squadra', const {});
      expect(esito.perModello['atleti'], [
        {'codice': 'G1', 'ruolo': 'movimento'},
        {'codice': 'G3', 'ruolo': 'portiere'},
        {'codice': 'G4', 'ruolo': 'movimento'},
      ]);
      senzaNomiNeSalute(esito.perModello);
    });

    test(
      'scegli_atleti applica la salute sul telefono e dà solo codici',
      () async {
        final esito = await strumenti.esegui('scegli_atleti', const {
          'escludi_dolore_spalla': true,
          'escludi_sintomi': true,
        });
        expect(esito.perModello['atleti'], ['G4']);
        senzaNomiNeSalute(esito.perModello);
      },
    );

    test(
      'mostra_benessere: la scheda all\'allenatore, niente al modello',
      () async {
        final esito = await strumenti.esegui('mostra_benessere', const {
          'cosa': 'tutto',
          'giorni': 1,
        });
        senzaNomiNeSalute(esito.perModello);
        final scheda = esito.scheda! as SchedaSalute;
        expect([for (final r in scheda.righe) r.atleta.id], hasLength(3));
        expect(scheda.righe.first.scheda.sintomi, ['febbre']);
      },
    );

    test('partite e statistiche, con i codici', () async {
      final prossime = await strumenti.esegui('partite', const {
        'quali': 'prossime',
      });
      expect((prossime.perModello['partite'] as List).single, {
        'id': 'p-futura',
        'data': '2026-10-17',
        'giorno': 'sabato',
        'ora': '16:00',
        'avversario': 'Recco',
        'in_casa': true,
        'convocati': 1,
        'massimo_convocati': 3,
        'convocazione_inviata': false,
      });
      final st = await strumenti.esegui('statistiche_partite', const {
        'ultime': 5,
      });
      final squadra = st.perModello['squadra'] as Map;
      expect(squadra['gol'], 2);
      expect(squadra['tiri'], 3);
      expect(squadra['gol_in_superiorita'], 1);
      final perAtleta = st.perModello['per_atleta'] as List;
      expect(
        perAtleta.firstWhere((a) => (a as Map)['codice'] == 'G1')['gol'],
        2,
      );
      senzaNomiNeSalute(st.perModello);
    });

    test('presenze e allenamenti, con i titoli senza nomi', () async {
      final presenze = await strumenti.esegui('presenze', const {'giorni': 7});
      final rossi = (presenze.perModello['per_atleta'] as List).firstWhere(
        (a) => (a as Map)['codice'] == 'G3',
      );
      expect(rossi['presente'], 2);
      expect(rossi['percentuale'], 100);
      final sedute = await strumenti.esegui('allenamenti', const {
        'da': '2026-10-12',
        'a': '2026-10-13',
      });
      expect(sedute.perModello['sedute'], [
        {
          'id': 'a1',
          'data': '2026-10-12',
          'giorno': 'lunedì',
          'tipo': 'acqua',
          'titolo': 'Lavoro per G3 e superiorità',
          'metri': 2400,
          'minuti_a_tempo': 10,
          'presenti': 1,
        },
        {
          'id': 'a2',
          'data': '2026-10-13',
          'giorno': 'martedì',
          'tipo': 'secco',
          'titolo': 'Seduta a secco',
          'durata_minuti': 40,
          // Rossi presente e Verdi in ritardo.
          'presenti': 2,
        },
      ]);
      senzaNomiNeSalute(sedute.perModello);
    });

    test('chi è in ritardo conta come presente, e se ne dice quanti', () async {
      final presenze = await strumenti.esegui('presenze', const {'giorni': 7});
      final verdi = (presenze.perModello['per_atleta'] as List).firstWhere(
        (a) => (a as Map)['codice'] == 'G4',
      );
      expect(verdi['presente'], 1);
      expect(verdi['di_cui_in_ritardo'], 1);
      expect(verdi['assente'], 0);
      expect(verdi['percentuale'], 100);
      // Chi non è mai in ritardo ha zero, non niente.
      final rossi = (presenze.perModello['per_atleta'] as List).firstWhere(
        (a) => (a as Map)['codice'] == 'G3',
      );
      expect(rossi['di_cui_in_ritardo'], 0);
    });

    test(
      'proponi_convocazione: numeri liberi, chi c\'è già, il massimo',
      () async {
        final esito = await strumenti.esegui('proponi_convocazione', const {
          'partita_id': 'p-futura',
          'atleti': ['G1', 'G3', 'G4', 'G42'],
        });
        final p = esito.scheda! as PropostaConvocazione;
        expect(
          [for (final n in p.nuovi) (n.atleta.id, n.numero)],
          // Rossi è portiere: l'1 è già preso, prende il 13.
          [('bianchi', 2), ('rossi', 13)],
        );
        expect(p.giaConvocati, 1);
        expect(p.oltreIlMassimo, isFalse);
        expect(esito.perModello['codici_sconosciuti'], ['G42']);
        senzaNomiNeSalute(esito.perModello);
      },
    );

    test('proponi_seduta: i codici diventano nomi e "per chi"', () async {
      final esito = await strumenti.esegui('proponi_seduta', const {
        'data': '2026-10-16',
        'titolo': 'Superiorità',
        'testo': 'Riscaldamento\n400 mix A1\n\nPrincipale\nG3: 10\' tiri\n8x50 sl B1 r15',
      });
      final p = esito.scheda! as PropostaSeduta;
      expect(p.testo, contains('Rossi: 10\' tiri'));
      expect(p.scritto.serie, hasLength(3));
      expect(p.scritto.serie[1].destinatari.soloAtleti, ['rossi']);
      expect(esito.perModello['righe_non_capite'], 0);
      senzaNomiNeSalute(esito.perModello);
    });
  });

  group('conversazione', () {
    test('la domanda parte senza nomi, gli strumenti girano sul telefono, '
        'la risposta torna con i nomi', () async {
      final mandate = <List<Map<String, dynamic>>>[];
      var giro = 0;
      final motore = MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: strumenti,
        chiama: (messaggi) async {
          mandate.add(messaggi);
          giro++;
          if (giro == 1) {
            return {
              'role': 'assistant',
              'content': null,
              'tool_calls': [
                {
                  'id': 't1',
                  'type': 'function',
                  'function': {
                    'name': 'scegli_atleti',
                    'arguments': '{"escludi_dolore_spalla": true}',
                  },
                },
                {
                  'id': 't2',
                  'type': 'function',
                  'function': {
                    'name': 'proponi_convocazione',
                    'arguments': '{"partita_id": "p-futura", "atleti": ["G1"]}',
                  },
                },
              ],
            };
          }
          return {
            'role': 'assistant',
            'content': 'Ho proposto G1: G3 resta fuori.',
          };
        },
      );

      final voci = await motore.chiedi(
        'Convoca per sabato escludendo chi ha male alla spalla, non Rossi',
      );
      expect(
        voci.whereType<VoceScheda>().single.scheda,
        isA<PropostaConvocazione>(),
      );
      final risposta = voci.whereType<RispostaAssistente>().single;
      expect(risposta.testo, 'Ho proposto Bianchi: Rossi resta fuori.');
      expect(risposta.datiLetti, ['benessere (sul telefono)', 'distinta']);

      // Tutto quello che è uscito: domanda e risultati, senza nomi.
      expect(mandate, hasLength(2));
      // La domanda senza il nome (le parole dell'allenatore restano), i
      // risultati degli strumenti senza nomi né salute.
      final domanda = '${mandate.first.single['content']}';
      expect(domanda, contains('non G3'));
      expect(domanda.toLowerCase(), isNot(contains('rossi')));
      senzaNomiNeSalute([
        for (final m in mandate.last)
          if (m['role'] == 'tool') m,
      ]);
    });

    test('con un errore la storia torna com\'era', () async {
      final motore = MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: strumenti,
        chiama: (_) async => throw Exception('rete'),
      );
      await expectLater(motore.chiedi('Ciao'), throwsException);
      expect(motore.storia, isEmpty);
    });
  });

  group('demo', () {
    MotoreAssistente motoreDemo() => MotoreAssistente(
      pseudonimi: pseudonimi,
      strumenti: strumenti,
      chiama: (messaggi) async => cervelloDemo(messaggi, oggi: _oggi),
    );

    test('la convocazione: partita, scelta sul telefono, proposta', () async {
      final voci = await motoreDemo().chiedi(
        'Convoca per la prossima partita, escludendo chi ha male alla spalla',
      );
      final proposta =
          voci.whereType<VoceScheda>().single.scheda as PropostaConvocazione;
      // Rossi (spalla) resta fuori; Verdi era già in distinta.
      expect([for (final n in proposta.nuovi) n.atleta.id], ['bianchi']);
      expect(
        voci.whereType<RispostaAssistente>().single.testo,
        contains('sabato con Recco'),
      );
    });

    test('superiorità e dolori', () async {
      final motore = motoreDemo();
      final sup = await motore.chiedi(
        'Com\'è andata la superiorità nelle ultime 5 partite?',
      );
      expect(sup.whereType<RispostaAssistente>().single.testo, isNotEmpty);
      final dolori = await motore.chiedi('Chi ha segnato dolori?');
      expect(dolori.whereType<VoceScheda>().single.scheda, isA<SchedaSalute>());
    });

    test('la seduta di giovedì', () async {
      final voci = await motoreDemo().chiedi('Prepara la seduta di giovedì');
      final p = voci.whereType<VoceScheda>().single.scheda as PropostaSeduta;
      expect(p.data, DateTime(2026, 10, 15));
      expect(p.scritto.righeNonCapite, 0);
    });
  });
}
