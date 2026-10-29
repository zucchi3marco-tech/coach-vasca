import 'dart:convert';

import 'package:coach_vasca/features/allenamenti/domain/allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/modifica_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/domain/piano_salvataggio_testo.dart';
import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/volume_allenamento.dart';
import 'package:coach_vasca/features/assistente/data/cervello_demo.dart';
import 'package:coach_vasca/features/assistente/domain/motore_assistente.dart';
import 'package:coach_vasca/features/assistente/domain/pseudonimi.dart';
import 'package:coach_vasca/features/assistente/domain/strumenti_assistente.dart';
import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/benessere/domain/scheda_benessere.dart';
import 'package:coach_vasca/features/carico/domain/carico_rpe.dart';
import 'package:coach_vasca/features/impegni/domain/impegno.dart';
import 'package:coach_vasca/features/secco/domain/esercizio_secco.dart';
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
  luogo: 'Piscina comunale',
  ritrovoOra: '15:00',
  ritrovoLuogo: 'al club',
  daPortare: 'calottine e documento',
  noteConvocazione: 'Accompagna Rossi',
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

Serie _serie(
  int ordine,
  String blocco,
  int ripetute,
  int distanzaM, {
  String? zona,
  String esecuzione = 'nuoto',
  Destinatari destinatari = Destinatari.tutti,
  String? esito,
}) => Serie(
  id: 's$ordine',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: ordine,
  blocco: blocco,
  ripetute: ripetute,
  distanzaM: distanzaM,
  stile: 'libero',
  esecuzione: esecuzione,
  zona: zona,
  destinatari: destinatari,
  esito: esito,
);

/// Le serie di a1 (ieri, in acqua): l'8x100 è già segnato «fatta».
final _serieA1 = [
  _serie(1, 'riscaldamento', 1, 400, zona: 'A1'),
  _serie(2, 'principale', 8, 100, zona: 'B1', esito: 'fatta'),
  _serie(
    3,
    'principale',
    4,
    50,
    esecuzione: 'gambe',
    destinatari: const Destinatari.solo(['rossi']),
  ),
  _serie(4, 'defaticamento', 1, 200),
];

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
  Future<List<Serie>> serie(String allenamentoId) async =>
      allenamentoId == 'a1' ? _serieA1 : const [];

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

  @override
  Future<List<Impegno>> impegni() async => [
    Impegno(
      id: 'i1',
      clubId: 'c1',
      gruppoId: 'u14',
      tipo: TipoImpegno.collegiale,
      dal: DateTime(2026, 10, 20),
      al: DateTime(2026, 10, 22),
      nome: 'Collegiale con Rossi',
      luogo: 'Lignano',
    ),
    // Di tutto il club.
    Impegno(
      id: 'i2',
      clubId: 'c1',
      tipo: TipoImpegno.riposo,
      dal: DateTime(2026, 11, 1),
      al: DateTime(2026, 11, 1),
      nome: 'Piscina chiusa',
    ),
    // Di un'altra squadra.
    Impegno(
      id: 'i3',
      clubId: 'c1',
      gruppoId: 'u16',
      tipo: TipoImpegno.trasferta,
      dal: DateTime(2026, 10, 25),
      al: DateTime(2026, 10, 26),
    ),
    // Già passato.
    Impegno(
      id: 'i4',
      clubId: 'c1',
      gruppoId: 'u14',
      tipo: TipoImpegno.torneo,
      dal: DateTime(2026, 10, 1),
      al: DateTime(2026, 10, 3),
    ),
  ];

  @override
  Future<List<EsercizioSecco>> eserciziSecco() async => _eserciziSecco;

  @override
  Future<List<EsercizioSeduta>> eserciziSeduta(String allenamentoId) async =>
      allenamentoId == 'a2' ? _righeA2 : const [];

  @override
  Future<Set<String>> eserciziConMassimale() async => const {'squat'};
}

/// L'elenco del club: i codici vanno per categoria e nome (E1 extra, E2
/// dead bug, E3 plank, E4 squat); l'archiviato non c'è.
const _eserciziSecco = [
  EsercizioSecco(
    id: 'squat',
    clubId: 'c1',
    nome: 'Squat',
    categoria: CategoriaEsercizio.forza,
  ),
  EsercizioSecco(
    id: 'plank',
    clubId: 'c1',
    nome: 'Plank',
    categoria: CategoriaEsercizio.core,
    misura: MisuraEsercizio.tempo,
  ),
  EsercizioSecco(
    id: 'deadbug',
    clubId: 'c1',
    nome: 'Dead bug',
    categoria: CategoriaEsercizio.core,
  ),
  EsercizioSecco(
    id: 'extra',
    clubId: 'c1',
    nome: 'Extrarotazione con elastico',
    categoria: CategoriaEsercizio.spalla,
    attrezzo: 'Elastico',
  ),
  EsercizioSecco(
    id: 'vecchio',
    clubId: 'c1',
    nome: 'Crunch',
    categoria: CategoriaEsercizio.core,
    archiviato: true,
  ),
];

EsercizioSeduta _riga(
  String id,
  String esercizio,
  int ordine, {
  int serie = 3,
  int? ripetizioni,
  int? durataS,
  String? carico,
  int? recuperoS = 45,
  String? varianteDi,
  Destinatari destinatari = Destinatari.tutti,
}) => EsercizioSeduta(
  id: id,
  allenamentoId: 'a2',
  clubId: 'c1',
  esercizioId: esercizio,
  ordine: ordine,
  serie: serie,
  ripetizioni: ripetizioni,
  durataS: durataS,
  carico: carico,
  recuperoS: recuperoS,
  varianteDi: varianteDi,
  destinatari: destinatari,
);

/// La seduta a secco di oggi (a2): Rossi ha una variante dello squat.
final _righeA2 = [
  _riga('r1', 'extra', 1, ripetizioni: 15),
  _riga('r2', 'plank', 2, durataS: 30),
  _riga(
    'r3',
    'squat',
    3,
    serie: 4,
    ripetizioni: 6,
    carico: '70%',
    recuperoS: 90,
  ),
  _riga(
    'v1',
    'squat',
    3,
    serie: 3,
    ripetizioni: 6,
    carico: '50%',
    varianteDi: 'r3',
    destinatari: const Destinatari.solo(['rossi']),
  ),
];

/// Oggi due sedute della squadra: l'appello non sa quale.
class _FonteDueSedute extends _Fonte {
  @override
  Future<List<Allenamento>> allenamenti() async => [
    ...await super.allenamenti(),
    Allenamento(
      id: 'a3',
      clubId: 'c1',
      gruppoId: 'u14',
      data: DateTime(2026, 10, 13, 19),
      titolo: 'Tiri con Verdi',
    ),
  ];
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
        'ritrovo': 'ore 15:00, al club',
        'piscina': 'Piscina comunale',
        'da portare': 'calottine e documento',
        'note_per_le_famiglie': 'Accompagna G3',
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

  group('proponi_appello', () {
    // Oggi c'è il secco degli U14 (a2): Rossi è già presente, Verdi già in
    // ritardo, Bianchi non è segnato, Neri è degli U16.
    test('chi non è nominato è presente, chi era già segnato resta', () async {
      final esito = await strumenti.esegui('proponi_appello', const {
        'assenti': ['G1'],
      });
      final p = esito.scheda! as PropostaAppello;
      expect(p.allenamento.id, 'a2');
      expect(
        [for (final r in p.righe) (r.atleta.id, r.attuale, r.proposto)],
        [
          ('bianchi', null, 'assente'),
          ('rossi', 'presente', 'presente'),
          ('verdi', 'ritardo', 'ritardo'),
        ],
      );
      expect(esito.perModello['presenti'], 2);
      expect(esito.perModello['di_cui_in_ritardo'], 1);
      expect(esito.perModello['assenti'], 1);
      expect(esito.perModello['gia_segnati_e_non_nominati'], 2);
      senzaNomiNeSalute(esito.perModello);
    });

    test('chi è nominato cambia anche se era già segnato', () async {
      final esito = await strumenti.esegui('proponi_appello', const {
        'giustificati': ['G3'],
        'presenti': ['G4'],
      });
      final p = esito.scheda! as PropostaAppello;
      final rossi = p.righe.firstWhere((r) => r.atleta.id == 'rossi');
      expect(
        (rossi.attuale, rossi.proposto, rossi.nominato),
        ('presente', 'giustificato', true),
      );
      expect(
        p.righe.firstWhere((r) => r.atleta.id == 'verdi').proposto,
        'presente',
      );
    });

    test('un atleta di un\'altra squadra entra se nominato; codici sconosciuti '
        'detti al modello', () async {
      final esito = await strumenti.esegui('proponi_appello', const {
        'in_ritardo': ['G2', 'G42'],
      });
      final p = esito.scheda! as PropostaAppello;
      final neri = p.righe.firstWhere((r) => r.atleta.id == 'neri');
      expect((neri.proposto, neri.daFuori), ('ritardo', true));
      expect(esito.perModello['da_altre_squadre'], ['G2']);
      expect(esito.perModello['codici_sconosciuti'], ['G42']);
    });

    test('una seduta indicata per id, anche di ieri', () async {
      final esito = await strumenti.esegui('proponi_appello', const {
        'allenamento_id': 'a1',
      });
      final p = esito.scheda! as PropostaAppello;
      expect(p.allenamento.id, 'a1');
      // Bianchi era assente ieri: resta assente.
      expect(
        p.righe.firstWhere((r) => r.atleta.id == 'bianchi').proposto,
        'assente',
      );
    });

    test('senza una seduta, nel futuro o con più sedute: un errore per il '
        'modello, nessuna scheda', () async {
      for (final args in const [
        {'data': '2026-10-11'},
        {'data': '2026-10-20'},
        {'allenamento_id': 'non-c-e'},
        {'data': 'ieri'},
      ]) {
        final esito = await strumenti.esegui('proponi_appello', args);
        expect(esito.scheda, isNull, reason: '$args');
        expect(esito.perModello['errore'], isNotNull, reason: '$args');
      }

      final dueSedute = StrumentiAssistente(
        fonte: _FonteDueSedute(),
        pseudonimi: pseudonimi,
        oggi: _oggi,
      );
      final esito = await dueSedute.esegui('proponi_appello', const {});
      expect(esito.scheda, isNull);
      expect(
        [for (final s in esito.perModello['sedute']! as List) (s as Map)['id']],
        ['a2', 'a3'],
      );
      // Il titolo arriva senza nomi.
      senzaNomiNeSalute(esito.perModello);
    });
  });

  group('cambiare una seduta', () {
    Future<String> testoDiA1() async {
      final letta = await strumenti.esegui('leggi_seduta', const {
        'allenamento_id': 'a1',
      });
      return letta.perModello['testo']! as String;
    }

    test(
      'leggi_seduta: il testo delle serie con i codici, mai i nomi',
      () async {
        final esito = await strumenti.esegui('leggi_seduta', const {
          'allenamento_id': 'a1',
        });
        final m = esito.perModello;
        expect(esito.scheda, isNull);
        expect((m['seduta']! as Map)['titolo'], 'Lavoro per G3 e superiorità');
        expect(m['serie'], 4);
        expect(m['testo'], contains('G3'));
        expect(m['testo'], contains('8x100'));
        senzaNomiNeSalute(m);
      },
    );

    test('il secco si legge dalla data: oggi c\'è solo a2', () async {
      final esito = await strumenti.esegui('leggi_seduta', const {
        'data': '2026-10-13',
      });
      expect((esito.perModello['seduta']! as Map)['tipo'], 'secco');
      expect(esito.perModello['esercizi'], hasLength(3));
    });

    test('una serie aggiunta: il resto uguale, la «fatta» resta sua', () async {
      final testo = (await testoDiA1()).replaceFirst(
        '400 sl A1',
        '400 sl A1\n4x50 sl gambe A2',
      );
      final esito = await strumenti.esegui('proponi_modifica_seduta', {
        'allenamento_id': 'a1',
        'testo': testo,
      });
      final p = esito.scheda! as PropostaModificaSeduta;
      expect(p.cambiaSerie, isTrue);
      expect((p.cambiaTitolo, p.cambiaNote), (false, false));
      expect(
        [
          for (final r in p.righe)
            if (r.stato != StatoRiga.uguale) r.toString(),
        ],
        ['aggiunta: 4x50 sl gambe A2'],
      );
      // La variante torna di Rossi.
      expect(
        p.scritto.serie
            .where((s) => s.destinatari.soloAtleti.isNotEmpty)
            .single
            .destinatari
            .soloAtleti,
        ['rossi'],
      );
      final piano = pianoSalvataggio(
        vecchie: p.serie,
        nuove: p.scritto.serie,
        nuovoId: () => 'nuovo',
      );
      expect(piano.crea, hasLength(1));
      expect(piano.elimina, isEmpty);
      // L'8x100 (fatta) è riusato, solo con l'ordine nuovo.
      expect(
        piano.aggiorna.where((a) => a.vecchia.id == 's2').single.ordine,
        3,
      );
      expect(esito.perModello['serie_prima'], 4);
      expect(esito.perModello['serie_dopo'], 5);
      expect(esito.perModello['righe_tolte'], isEmpty);
      expect(esito.perModello['righe_aggiunte'], ['4x50 sl gambe A2']);
      senzaNomiNeSalute(esito.perModello);
    });

    test('«togli 2x100»: al modello la riga tolta e quella nuova, con i '
        'codici', () async {
      final esito = await strumenti.esegui('proponi_modifica_seduta', {
        'allenamento_id': 'a1',
        'testo': (await testoDiA1()).replaceFirst('8x100', '6x100'),
      });
      final m = esito.perModello;
      expect(m['righe_tolte'], [contains('8x100')]);
      expect(m['righe_aggiunte'], [contains('6x100')]);
      expect(m['metri_prima'], isNot(m['metri_dopo']));
      senzaNomiNeSalute(m);
    });

    test('solo il titolo, con i codici che tornano nomi', () async {
      final esito = await strumenti.esegui('proponi_modifica_seduta', const {
        'allenamento_id': 'a1',
        'titolo': 'Tiri per G3',
      });
      final p = esito.scheda! as PropostaModificaSeduta;
      expect(p.cambiaSerie, isFalse);
      expect(p.titolo, 'Tiri per Rossi');
      expect(p.righe.every((r) => r.stato == StatoRiga.uguale), isTrue);
      expect(esito.perModello['cambia_titolo'], isTrue);
      senzaNomiNeSalute(esito.perModello);
    });

    test(
      'niente di diverso o niente di capito: un errore, nessuna scheda',
      () async {
        final testo = await testoDiA1();
        for (final args in [
          {'allenamento_id': 'a1', 'testo': testo},
          // Il titolo riscritto con i codici è lo stesso.
          {'allenamento_id': 'a1', 'titolo': 'Lavoro per G3 e superiorità'},
          {'allenamento_id': 'a1', 'testo': 'bla bla'},
          {'allenamento_id': 'non-c-e', 'titolo': 'X'},
        ]) {
          final esito = await strumenti.esegui('proponi_modifica_seduta', args);
          expect(esito.scheda, isNull, reason: '$args');
          expect(esito.perModello['errore'], isNotNull, reason: '$args');
        }
      },
    );

    test('stesseSerie: la proposta è vecchia se le serie sono cambiate', () {
      expect(stesseSerie(_serieA1, [..._serieA1]), isTrue);
      expect(stesseSerie(_serieA1, _serieA1.sublist(1)), isFalse);
      expect(stesseSerie(_serieA1, [..._serieA1.reversed]), isFalse);
      expect(
        stesseSerie(_serieA1, [
          _serie(1, 'riscaldamento', 1, 300, zona: 'A1'),
          ..._serieA1.skip(1),
        ]),
        isFalse,
      );
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

    test('l\'appello: assenti e in ritardo dalla frase', () async {
      final voci = await motoreDemo().chiedi(
        'Appello: assenti Bianchi, Verdi in ritardo',
      );
      final p = voci.whereType<VoceScheda>().single.scheda as PropostaAppello;
      expect(
        {for (final r in p.righe) r.atleta.id: r.proposto},
        {'bianchi': 'assente', 'rossi': 'presente', 'verdi': 'ritardo'},
      );
      expect(
        voci.whereType<RispostaAssistente>().single.testo,
        contains('2 presenti, 1 assente.'),
      );
    });

    test(
      'dalla pagina della seduta: aggiungi alla fine del riscaldamento',
      () async {
        final voci = await MotoreAssistente(
          pseudonimi: pseudonimi,
          strumenti: strumenti,
          chiama: (messaggi) async =>
              cervelloDemo(messaggi, oggi: _oggi, sedutaAperta: 'a1'),
        ).chiedi('Aggiungi 4x50 gambe alla fine del riscaldamento');
        final p =
            voci.whereType<VoceScheda>().single.scheda
                as PropostaModificaSeduta;
        expect(p.allenamento.id, 'a1');
        expect(
          [
            for (final r in p.righe)
              if (r.stato != StatoRiga.uguale) r.toString(),
          ],
          ['aggiunta: 4x50 sl gambe'],
        );
        expect(p.scritto.serie[1].blocco, 'riscaldamento');
        expect(
          voci.whereType<RispostaAssistente>().single.testo,
          contains('controllale e salvale'),
        );
      },
    );

    test('dalla pagina della seduta: togli l\'ultima del principale', () async {
      final voci = await MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: strumenti,
        chiama: (messaggi) async =>
            cervelloDemo(messaggi, oggi: _oggi, sedutaAperta: 'a1'),
      ).chiedi('Togli l\'ultima serie del principale');
      final p =
          voci.whereType<VoceScheda>().single.scheda as PropostaModificaSeduta;
      expect(p.scritto.serie, hasLength(3));
      expect(
        p.scritto.serie.every((s) => s.destinatari.soloAtleti.isEmpty),
        isTrue,
      );
    });

    test('la seduta di giovedì', () async {
      final voci = await motoreDemo().chiedi('Prepara la seduta di giovedì');
      final p = voci.whereType<VoceScheda>().single.scheda as PropostaSeduta;
      expect(p.data, DateTime(2026, 10, 15));
      expect(p.scritto.righeNonCapite, 0);
    });

    test('il messaggio ai genitori: il prossimo giovedì', () async {
      final voci = await motoreDemo().chiedi(
        'Scrivi ai genitori che giovedì non c\'è allenamento',
      );
      final p =
          voci.whereType<VoceScheda>().single.scheda
              as PropostaMessaggioFamiglie;
      expect(p.testo, startsWith('*Niente allenamento giovedì 15 ottobre*'));
      expect(
        voci.whereType<RispostaAssistente>().single.testo,
        contains('Condividi'),
      );
    });

    test('il messaggio ai genitori sulla partita: ritrovo e piscina', () async {
      final voci = await motoreDemo().chiedi(
        'Ricorda alle famiglie la partita di sabato',
      );
      final p =
          voci.whereType<VoceScheda>().single.scheda
              as PropostaMessaggioFamiglie;
      expect(p.testo, contains('Sabato 17 ottobre contro Recco'));
      expect(p.testo, contains('Ritrovo: ore 15:00, al club'));
      expect(p.testo, contains('Piscina: Piscina comunale'));
    });
  });

  group('messaggi alle famiglie', () {
    test(
      'impegni: della squadra e del club, nel periodo, senza nomi',
      () async {
        final esito = await strumenti.esegui('impegni', const {});
        final elenco = (esito.perModello['impegni']! as List)
            .cast<Map<String, Object?>>();
        expect([for (final i in elenco) i['tipo']], ['collegiale', 'riposo']);
        final collegiale = elenco.first;
        expect(collegiale['nome'], 'Collegiale con G3');
        expect(collegiale['luogo'], 'Lignano');
        expect(collegiale['dal'], '2026-10-20');
        expect(collegiale['giorni'], 3);
        expect(collegiale['di_tutto_il_club'], isFalse);
        expect(elenco.last['di_tutto_il_club'], isTrue);
        senzaNomiNeSalute(esito.perModello);
      },
    );

    test('impegni: un periodo chiesto', () async {
      final esito = await strumenti.esegui('impegni', const {
        'da': '2026-10-25',
        'a': '2026-11-30',
      });
      final elenco = esito.perModello['impegni']! as List;
      expect(elenco, hasLength(1));
      expect((elenco.single as Map)['nome'], 'Piscina chiusa');
    });

    test('partite prossime: i dettagli per le famiglie, senza nomi', () async {
      final esito = await strumenti.esegui('partite', const {
        'quali': 'prossime',
      });
      final p = (esito.perModello['partite']! as List).single as Map;
      expect(p['ritrovo'], 'ore 15:00, al club');
      expect(p['piscina'], 'Piscina comunale');
      expect(p['da portare'], 'calottine e documento');
      expect(p['note_per_le_famiglie'], 'Accompagna G3');
      expect(p.containsKey('inizio partita'), isFalse);
      senzaNomiNeSalute(esito.perModello);

      final giocate = await strumenti.esegui('partite', const {
        'quali': 'giocate',
      });
      expect(
        ((giocate.perModello['partite']! as List).single as Map).containsKey(
          'ritrovo',
        ),
        isFalse,
      );
    });

    test('proponi_messaggio_famiglie: cognome e nome al posto dei codici', () async {
      final esito = await strumenti.esegui('proponi_messaggio_famiglie', const {
        'testo': '*Documenti*\nG3 e G1 portino il documento sabato.',
      });
      final p = esito.scheda! as PropostaMessaggioFamiglie;
      expect(
        p.testo,
        '*Documenti*\nRossi Marco e Bianchi Luca portino il documento sabato.',
      );
      expect(esito.perModello['stato'], contains('Non è ancora inviato'));
      senzaNomiNeSalute(esito.perModello);
    });

    test(
      'proponi_messaggio_famiglie: codici sconosciuti o testo vuoto',
      () async {
        final sconosciuto = await strumenti.esegui(
          'proponi_messaggio_famiglie',
          const {'testo': 'G9 porti il pallone'},
        );
        expect(sconosciuto.scheda, isNull);
        expect(sconosciuto.perModello['errore'], contains('G9'));

        final vuoto = await strumenti.esegui(
          'proponi_messaggio_famiglie',
          const {'testo': '  '},
        );
        expect(vuoto.scheda, isNull);
        expect(vuoto.perModello['errore'], contains('vuoto'));
      },
    );
  });

  group('il secco', () {
    // Ogni prova con una conversazione nuova: i codici E1... partono da capo.
    StrumentiAssistente nuovi() => StrumentiAssistente(
      fonte: _Fonte(),
      pseudonimi: pseudonimi,
      oggi: _oggi,
    );

    test(
      'esercizi_secco: i codici per categoria e nome, senza archiviati',
      () async {
        final esito = await nuovi().esegui('esercizi_secco', const {});
        final elenco = (esito.perModello['esercizi']! as List)
            .cast<Map<String, Object?>>();
        expect(
          [for (final e in elenco) '${e['codice']} ${e['nome']}'],
          [
            'E1 Extrarotazione con elastico',
            'E2 Dead bug',
            'E3 Plank',
            'E4 Squat',
          ],
        );
        expect(elenco[2]['misura'], 'tempo');
        expect(elenco[0]['attrezzo'], 'Elastico');
        expect(elenco[3]['massimale'], isTrue);
        expect(elenco[0].containsKey('massimale'), isFalse);
        // «Spalla» qui è la categoria dell'esercizio: si guardano i nomi.
        expect(
          jsonEncode(esito.perModello).toLowerCase(),
          isNot(
            anyOf(contains('rossi'), contains('bianchi'), contains('verdi')),
          ),
        );
      },
    );

    test('proponi_seduta_secco: dosi controllate, la percentuale solo con il '
        'massimale', () async {
      final s = nuovi();
      final esito = await s.esegui('proponi_seduta_secco', const {
        'data': '2026-10-16',
        'titolo': 'Core e spalla',
        'esercizi': [
          {'esercizio': 'E1', 'serie': 3, 'ripetizioni': 15, 'carico': '60%'},
          // A tempo: le ripetizioni diventano secondi.
          {'esercizio': 'e3', 'serie': 3, 'ripetizioni': 40},
          {'esercizio': 'E4', 'serie': 30, 'ripetizioni': 6, 'carico': '70%'},
        ],
      });
      final p = esito.scheda! as PropostaSedutaSecco;
      expect(p.data, DateTime(2026, 10, 16));
      expect(p.titolo, 'Core e spalla');
      expect(
        [for (final d in p.dosi) d.esercizioId],
        ['extra', 'plank', 'squat'],
      );
      expect(p.dosi[0].carico, isNull);
      expect((p.dosi[1].durataS, p.dosi[1].ripetizioni), (40, null));
      expect((p.dosi[2].serie, p.dosi[2].carico), (10, '70%'));
      expect(p.dosi[0].recuperoS, 45);
      expect(esito.perModello['carichi_tolti'], contains('E1'));
      expect(
        p.durataMin,
        esito.perModello['minuti_stimati_fatti_come_scritto'],
      );

      final sconosciuto = await s.esegui('proponi_seduta_secco', const {
        'data': '2026-10-16',
        'esercizi': [
          {'esercizio': 'E9'},
        ],
      });
      expect(sconosciuto.scheda, isNull);
      expect(sconosciuto.perModello['errore'], contains('E9'));
    });

    test('proponi_programma_secco: la prima settimana dal modello, le altre '
        'crescono, lo scarico ha una serie in meno', () async {
      final esito = await nuovi().esegui('proponi_programma_secco', const {
        'nome': 'Spalla del tiratore',
        'minuti': 20,
        'settimane': 5,
        'scarico': [4, 9],
        'sedute': [
          [
            {'esercizio': 'E1', 'serie': 3, 'ripetizioni': 12},
            {'esercizio': 'E3', 'serie': 4, 'secondi': 30},
          ],
          [
            {'esercizio': 'E2', 'serie': 2, 'ripetizioni': 10},
          ],
        ],
      });
      final p = (esito.scheda! as PropostaProgrammaSecco).programma;
      expect(p.settimane, hasLength(5));
      expect(p.sedutePerSettimana, 2);
      expect(
        [for (final s in p.settimane) s.scarico],
        [false, false, false, true, false],
      );
      String extra(int w) {
        final d = p.settimane[w].sedute[0][0];
        return '${d.serie}x${d.ripetizioni}';
      }

      // 3x12, 4x12, 4x14, scarico 3x14, poi 4x16.
      expect(
        [for (var w = 0; w < 5; w++) extra(w)],
        ['3x12', '4x12', '4x14', '3x14', '4x16'],
      );
      // A tempo: +5 secondi.
      expect(p.settimane[1].sedute[0][1].durataS, 35);
      expect(esito.perModello['settimane_di_scarico'], [4]);
      senzaNomiNeSalute(esito.perModello);
    });

    test('leggi_seduta a secco: gli esercizi di tutti, con le varianti '
        'contate', () async {
      final esito = await nuovi().esegui('leggi_seduta', const {
        'allenamento_id': 'a2',
      });
      final m = esito.perModello;
      expect((m['seduta']! as Map)['minuti'], 40);
      final esercizi = (m['esercizi']! as List).cast<Map<String, Object?>>();
      expect([for (final e in esercizi) e['esercizio']], ['E1', 'E3', 'E4']);
      expect(esercizi[1]['secondi'], 30);
      expect(esercizi[2]['carico'], '70%');
      expect(esercizi[2]['varianti_per_atleti'], 1);
      senzaNomiNeSalute(m);
    });

    test(
      'una serie in più di squat: cambia solo lo squat, la variante resta',
      () async {
        final s = nuovi();
        await s.esegui('esercizi_secco', const {});
        final esito = await s.esegui('proponi_modifica_seduta', const {
          'allenamento_id': 'a2',
          'esercizi': [
            {'esercizio': 'E1'},
            {'esercizio': 'E3'},
            {'esercizio': 'E4', 'serie': 5},
          ],
        });
        final p = esito.scheda! as PropostaModificaSecco;
        expect(p.cambiaEsercizi, isTrue);
        expect(esito.perModello['righe_tolte'], [contains('4 × 6')]);
        expect(esito.perModello['righe_aggiunte'], [contains('5 × 6')]);
        final piano = pianoSecco(
          righe: _righeA2,
          dosi: p.dosi,
          allenamentoId: 'a2',
          clubId: 'c1',
          nuovoId: () => 'nuovo',
        );
        expect(piano.elimina, isEmpty);
        expect(piano.crea, isEmpty);
        expect(piano.aggiorna.single.id, 'r3');
        expect(piano.aggiorna.single.serie, 5);
        expect(piano.aggiorna.single.carico, '70%');
        senzaNomiNeSalute(esito.perModello);
      },
    );

    test(
      'togli il plank: si toglie, lo squat e la sua variante salgono',
      () async {
        final s = nuovi();
        await s.esegui('esercizi_secco', const {});
        final esito = await s.esegui('proponi_modifica_seduta', const {
          'allenamento_id': 'a2',
          'esercizi': [
            {'esercizio': 'E1'},
            {'esercizio': 'E4'},
          ],
        });
        final p = esito.scheda! as PropostaModificaSecco;
        final piano = pianoSecco(
          righe: _righeA2,
          dosi: p.dosi,
          allenamentoId: 'a2',
          clubId: 'c1',
          nuovoId: () => 'nuovo',
        );
        expect(piano.elimina, ['r2']);
        expect([
          for (final r in piano.aggiorna) '${r.id} ${r.ordine}',
        ], unorderedEquals(['r3 2', 'v1 2']));
        expect(piano.crea, isEmpty);
      },
    );

    test('un esercizio nuovo in fondo si crea; niente di diverso è un '
        'errore', () async {
      final s = nuovi();
      await s.esegui('esercizi_secco', const {});
      final esito = await s.esegui('proponi_modifica_seduta', const {
        'allenamento_id': 'a2',
        'esercizi': [
          {'esercizio': 'E1'},
          {'esercizio': 'E3'},
          {'esercizio': 'E4'},
          {'esercizio': 'E2', 'serie': 2, 'ripetizioni': 10},
        ],
      });
      final p = esito.scheda! as PropostaModificaSecco;
      final piano = pianoSecco(
        righe: _righeA2,
        dosi: p.dosi,
        allenamentoId: 'a2',
        clubId: 'c1',
        nuovoId: () => 'nuovo',
      );
      expect(piano.aggiorna, isEmpty);
      expect(
        [for (final r in piano.crea) '${r.esercizioId} ${r.ordine} ${r.serie}'],
        ['deadbug 4 2'],
      );

      final uguale = await s.esegui('proponi_modifica_seduta', const {
        'allenamento_id': 'a2',
        'esercizi': [
          {'esercizio': 'E1'},
          {'esercizio': 'E3'},
          {'esercizio': 'E4'},
        ],
      });
      expect(uguale.scheda, isNull);
      expect(uguale.perModello['errore'], contains('Niente di diverso'));
    });

    test('stessiEsercizi: la proposta è vecchia se una riga è cambiata', () {
      expect(stessiEsercizi([..._righeA2.reversed], _righeA2), isTrue);
      expect(
        stessiEsercizi([
          ..._righeA2.take(3),
          _righeA2[3].copyWith(ordine: 9),
        ], _righeA2),
        isFalse,
      );
      expect(stessiEsercizi(_righeA2.take(3).toList(), _righeA2), isFalse);
    });

    test('demo: la seduta a secco di venerdì con core e spalla', () async {
      final voci = await MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: nuovi(),
        chiama: (messaggi) async => cervelloDemo(messaggi, oggi: _oggi),
      ).chiedi('Prepara 20\' di core e spalla a secco per venerdì');
      final p =
          voci.whereType<VoceScheda>().single.scheda as PropostaSedutaSecco;
      expect(p.data, DateTime(2026, 10, 16));
      expect(
        [for (final d in p.dosi) d.esercizioId],
        ['extra', 'deadbug', 'plank'],
      );
      expect(
        voci.whereType<RispostaAssistente>().single.testo,
        contains('creala'),
      );
    });

    test('demo: il programma di 4 settimane, scarico la quarta', () async {
      final voci = await MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: nuovi(),
        chiama: (messaggi) async => cervelloDemo(messaggi, oggi: _oggi),
      ).chiedi('Un programma a secco di 4 settimane per la spalla');
      final p =
          voci.whereType<VoceScheda>().single.scheda as PropostaProgrammaSecco;
      expect(p.programma.settimane, hasLength(4));
      expect(p.scarico, [4]);
    });

    test('demo: dalla seduta a secco, una serie in più a tutti', () async {
      final voci = await MotoreAssistente(
        pseudonimi: pseudonimi,
        strumenti: nuovi(),
        chiama: (messaggi) async =>
            cervelloDemo(messaggi, oggi: _oggi, sedutaAperta: 'a2'),
      ).chiedi('Una serie in più a tutti gli esercizi');
      final p =
          voci.whereType<VoceScheda>().single.scheda as PropostaModificaSecco;
      expect([for (final d in p.dosi) d.serie], [4, 4, 5]);
    });
  });
}
