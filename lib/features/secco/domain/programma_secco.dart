import 'dart:math' as math;

import '../../../core/utils/giorni.dart';
import 'esercizio_secco.dart';

/// Un esercizio in una seduta di un programma, con le sue dosi: come una
/// riga di una seduta a secco ([EsercizioSeduta]), senza la seduta.
class DoseEsercizio {
  const DoseEsercizio({
    required this.esercizioId,
    this.serie = 3,
    this.ripetizioni,
    this.durataS,
    this.carico,
    this.recuperoS,
    this.note,
  });

  final String esercizioId;
  final int serie;
  final int? ripetizioni;
  final int? durataS;
  final String? carico;
  final int? recuperoS;

  /// Per l'allenatore: passano nelle note delle sedute, che l'atleta non
  /// legge.
  final String? note;

  factory DoseEsercizio.fromMap(Map<String, dynamic> m) => DoseEsercizio(
    esercizioId: m['esercizio_id'] as String,
    serie: (m['serie'] as num?)?.toInt() ?? 3,
    ripetizioni: (m['ripetizioni'] as num?)?.toInt(),
    durataS: (m['durata_s'] as num?)?.toInt(),
    carico: m['carico'] as String?,
    recuperoS: (m['recupero_s'] as num?)?.toInt(),
    note: m['note'] as String?,
  );

  /// Dalla riga che restituisce il foglio dell'esercizio.
  factory DoseEsercizio.daRiga(EsercizioSeduta r) => DoseEsercizio(
    esercizioId: r.esercizioId,
    serie: r.serie,
    ripetizioni: r.durataS == null ? r.ripetizioni : null,
    durataS: r.durataS,
    carico: _pieno(r.carico),
    recuperoS: r.recuperoS,
    note: _pieno(r.note),
  );

  Map<String, dynamic> toMap() => {
    'esercizio_id': esercizioId,
    'serie': serie,
    'ripetizioni': durataS == null ? ripetizioni : null,
    'durata_s': durataS,
    'carico': _pieno(carico),
    'recupero_s': recuperoS,
    'note': _pieno(note),
  };

  /// Come riga di una seduta: per mostrarla e cambiarla con gli stessi
  /// widget delle sedute, e per scriverla in una seduta vera.
  EsercizioSeduta comeRiga({
    required int ordine,
    String id = '',
    String allenamentoId = '',
    String clubId = '',
  }) => EsercizioSeduta(
    id: id,
    allenamentoId: allenamentoId,
    clubId: clubId,
    esercizioId: esercizioId,
    ordine: ordine,
    serie: serie,
    ripetizioni: ripetizioni,
    durataS: durataS,
    carico: carico,
    recuperoS: recuperoS,
    note: note,
  );

  DoseEsercizio copyWith({int? serie, int? ripetizioni, int? durataS}) =>
      DoseEsercizio(
        esercizioId: esercizioId,
        serie: serie ?? this.serie,
        ripetizioni: ripetizioni ?? this.ripetizioni,
        durataS: durataS ?? this.durataS,
        carico: carico,
        recuperoS: recuperoS,
        note: note,
      );
}

/// Una settimana del programma: le sue sedute (la A, la B...), ognuna con
/// gli esercizi in ordine. Una settimana di scarico ha meno serie.
class SettimanaProgramma {
  const SettimanaProgramma({required this.sedute, this.scarico = false});

  final List<List<DoseEsercizio>> sedute;
  final bool scarico;

  factory SettimanaProgramma.fromMap(Map<String, dynamic> m) =>
      SettimanaProgramma(
        scarico: m['scarico'] as bool? ?? false,
        sedute: [
          for (final s in m['sedute'] as List? ?? const [])
            [
              for (final d in s as List)
                DoseEsercizio.fromMap(d as Map<String, dynamic>),
            ],
        ],
      );

  Map<String, dynamic> toMap() => {
    'scarico': scarico,
    'sedute': [
      for (final s in sedute) [for (final d in s) d.toMap()],
    ],
  };

  SettimanaProgramma copyWith({
    List<List<DoseEsercizio>>? sedute,
    bool? scarico,
  }) => SettimanaProgramma(
    sedute: sedute ?? this.sedute,
    scarico: scarico ?? this.scarico,
  );

  /// La stessa settimana con [seduta] cambiata.
  SettimanaProgramma conSeduta(int seduta, List<DoseEsercizio> esercizi) =>
      copyWith(
        sedute: [
          for (final (i, s) in sedute.indexed) i == seduta ? esercizi : s,
        ],
      );
}

/// Un programma a secco del club: settimane di sedute già scritte, da
/// mettere nel calendario di una squadra (vedi [calendarioProgramma]).
class ProgrammaSecco {
  const ProgrammaSecco({
    required this.id,
    required this.clubId,
    required this.nome,
    this.descrizione,
    this.durataMin = 20,
    this.settimane = const [],
    this.modello,
  });

  final String id;
  final String clubId;
  final String nome;

  /// A cosa serve e come si usa.
  final String? descrizione;

  /// I minuti di ogni seduta (quelli del carico del secco).
  final int durataMin;
  final List<SettimanaProgramma> settimane;

  /// La chiave del programma pronto da cui è nato, null per uno
  /// dell'allenatore.
  final String? modello;

  /// Tutte le settimane hanno le stesse sedute (la A, la B...).
  int get sedutePerSettimana =>
      settimane.isEmpty ? 1 : math.max(1, settimane.first.sedute.length);

  int get numeroSedute => settimane.length * sedutePerSettimana;

  static List<SettimanaProgramma> settimaneDa(Object? json) => [
    for (final s in json as List? ?? const [])
      SettimanaProgramma.fromMap(s as Map<String, dynamic>),
  ];

  Map<String, dynamic> toPayload() => {
    'nome': nome.trim(),
    'descrizione': _pieno(descrizione),
    'durata_min': durataMin,
    'settimane': [for (final s in settimane) s.toMap()],
    'modello': modello,
  };

  ProgrammaSecco copyWith({List<SettimanaProgramma>? settimane}) =>
      ProgrammaSecco(
        id: id,
        clubId: clubId,
        nome: nome,
        descrizione: descrizione,
        durataMin: durataMin,
        settimane: settimane ?? this.settimane,
        modello: modello,
      );

  /// Lo stesso programma con [settimana] (da 0) cambiata.
  ProgrammaSecco conSettimana(int settimana, SettimanaProgramma nuova) =>
      copyWith(
        settimane: [
          for (final (i, s) in settimane.indexed) i == settimana ? nuova : s,
        ],
      );

  /// Lo stesso programma con [quante] sedute a settimana: quelle in più
  /// partono vuote, quelle in meno si tolgono dal fondo in ogni settimana.
  ProgrammaSecco conSedutePerSettimana(int quante) => copyWith(
    settimane: [
      for (final s in settimane)
        s.copyWith(
          sedute: [
            for (var i = 0; i < quante; i++)
              i < s.sedute.length ? s.sedute[i] : const <DoseEsercizio>[],
          ],
        ),
    ],
  );

  /// Se il programma usa l'esercizio [esercizioId] in qualche seduta.
  bool usa(String esercizioId) => settimane.any(
    (s) => s.sedute.any((e) => e.any((d) => d.esercizioId == esercizioId)),
  );
}

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();

/// "A", "B", "C"...
String letteraSeduta(int indice) => String.fromCharCode(65 + indice);

/// "Seduta A", o "La seduta" quando a settimana ce n'è una sola.
String nomeSeduta(int indice, int quante) =>
    quante <= 1 ? 'La seduta' : 'Seduta ${letteraSeduta(indice)}';

/// Il titolo di una seduta messa nel calendario: "Spalla del tiratore ·
/// settimana 2, seduta A".
String titoloSedutaProgramma(
  String nome, {
  required int settimana,
  required int seduta,
  required int sedutePerSettimana,
}) => [
  '${nome.trim()} · settimana $settimana',
  if (sedutePerSettimana > 1) 'seduta ${letteraSeduta(seduta)}',
].join(', ');

/// Quanto durano gli esercizi di una seduta fatti come scritti.
int minutiDosi(List<DoseEsercizio> dosi) => minutiStimati([
  for (final (i, d) in dosi.indexed) d.comeRiga(ordine: i + 1),
]);

/// Un po' di più della settimana prima: una serie in più fino a 4, poi
/// qualche ripetizione (+2) o qualche secondo (+5''). La mobilità resta
/// com'è: uno stretching non cresce.
DoseEsercizio unPoDiPiu(DoseEsercizio d, {CategoriaEsercizio? categoria}) {
  if (categoria == CategoriaEsercizio.mobilita) return d;
  if (d.serie < 4) return d.copyWith(serie: d.serie + 1);
  if (d.durataS != null) {
    return d.copyWith(durataS: math.min(d.durataS! + 5, 3600));
  }
  return d.copyWith(ripetizioni: math.min((d.ripetizioni ?? 0) + 2, 500));
}

/// Per lo scarico: una serie in meno, almeno una.
DoseEsercizio unaSerieInMeno(DoseEsercizio d) =>
    d.copyWith(serie: math.max(1, d.serie - 1));

/// La settimana da aggiungere in fondo: l'ultima che non è di scarico (se
/// no l'ultima), con un po' di più a ogni esercizio. [esercizi] dice la
/// categoria di ogni esercizio, per lasciare com'è la mobilità.
SettimanaProgramma settimanaSuccessiva(
  List<SettimanaProgramma> settimane, {
  Map<String, EsercizioSecco> esercizi = const {},
}) {
  final base = settimane.lastWhere(
    (s) => !s.scarico,
    orElse: () => settimane.last,
  );
  return SettimanaProgramma(
    sedute: [
      for (final seduta in base.sedute)
        [
          for (final d in seduta)
            unPoDiPiu(d, categoria: esercizi[d.esercizioId]?.categoria),
        ],
    ],
  );
}

/// Una seduta del programma nel calendario: il giorno, la settimana (da 1)
/// e quale seduta di quella settimana (da 0: la A).
typedef SedutaInCalendario = ({DateTime data, int settimana, int seduta});

/// I giorni delle sedute di un programma di [settimane] settimane: dal
/// [primoGiorno] ogni 7 giorni comincia una settimana, e dentro quei 7
/// giorni le sedute cadono nei [giorni] della settimana scelti (1 = lunedì,
/// 7 = domenica), la A nel primo che arriva.
List<SedutaInCalendario> calendarioProgramma({
  required DateTime primoGiorno,
  required int settimane,
  required Iterable<int> giorni,
}) {
  final scelti = giorni.toSet();
  final inizio = soloData(primoGiorno);
  final calendario = <SedutaInCalendario>[];
  for (var s = 0; s < settimane; s++) {
    var seduta = 0;
    for (var g = 0; g < 7; g++) {
      final data = aggiungiGiorni(inizio, s * 7 + g);
      if (scelti.contains(data.weekday)) {
        calendario.add((data: data, settimana: s + 1, seduta: seduta++));
      }
    }
  }
  return calendario;
}

/// I giorni proposti per [quante] sedute a settimana: martedì; martedì e
/// giovedì; lunedì, mercoledì e venerdì; lunedì, martedì, giovedì e
/// venerdì.
List<int> giorniProposti(int quante) => switch (quante) {
  <= 1 => const [2],
  2 => const [2, 4],
  3 => const [1, 3, 5],
  _ => const [1, 2, 4, 5],
};

/// Il primo lunedì da [oggi] in poi (oggi, se è lunedì): un programma parte
/// di solito con la settimana.
DateTime prossimoLunedi(DateTime oggi) =>
    aggiungiGiorni(soloData(oggi), (8 - oggi.weekday) % 7);

// ---------------------------------------------------------------------------
// I programmi pronti

/// Un esercizio di un programma pronto (la chiave di [modelliEsercizi]) con
/// le dosi di ogni settimana, scritte come "3x12" o "3x30s" (a tempo) e il
/// carico dopo uno spazio ("3x12 elastico più duro").
class RigaPronta {
  const RigaPronta(this.esercizio, this.dosi, {this.recuperoS = 45});

  final String esercizio;
  final List<String> dosi;
  final int recuperoS;
}

final _dose = RegExp(r'^(\d+)x(\d+)(s?)(?:\s+(.+))?$');

/// La dose di [testo] ("3x12", "3x30s", "3x12 elastico più duro").
DoseEsercizio doseDaTesto(
  String esercizioId,
  String testo, {
  required int recuperoS,
}) {
  final m = _dose.firstMatch(testo.trim());
  if (m == null) throw FormatException('Dose non valida: $testo');
  final quanto = int.parse(m.group(2)!);
  final aTempo = m.group(3) == 's';
  return DoseEsercizio(
    esercizioId: esercizioId,
    serie: int.parse(m.group(1)!),
    ripetizioni: aTempo ? null : quanto,
    durataS: aTempo ? quanto : null,
    carico: m.group(4),
    recuperoS: recuperoS,
  );
}

/// Un programma pronto: settimane uguali nella forma (le stesse sedute con
/// gli stessi esercizi), dosi che crescono, le settimane di [scarico] (da
/// 1) con meno serie.
class ProgrammaPronto {
  const ProgrammaPronto({
    required this.chiave,
    required this.nome,
    required this.descrizione,
    required this.durataMin,
    required this.sedute,
    this.scarico = const {},
  });

  final String chiave;
  final String nome;
  final String descrizione;
  final int durataMin;
  final List<List<RigaPronta>> sedute;
  final Set<int> scarico;

  int get settimane => sedute.first.first.dosi.length;

  /// Le chiavi degli esercizi pronti che usa.
  Set<String> get esercizi => {
    for (final s in sedute)
      for (final r in s) r.esercizio,
  };

  /// Le settimane con gli esercizi del club: [idPerModello] dà l'id
  /// dell'esercizio del club nato da ogni esercizio pronto.
  List<SettimanaProgramma> settimaneCon(Map<String, String> idPerModello) => [
    for (var w = 0; w < settimane; w++)
      SettimanaProgramma(
        scarico: scarico.contains(w + 1),
        sedute: [
          for (final s in sedute)
            [
              for (final r in s)
                doseDaTesto(
                  idPerModello[r.esercizio]!,
                  r.dosi[w],
                  recuperoS: r.recuperoS,
                ),
            ],
        ],
      ),
  ];
}

/// I programmi pronti: prevenzione della spalla del tiratore, scapole e
/// core, gambe per la bicicletta, i portieri. Dosi comuni nella
/// prevenzione degli sport di lancio, tre settimane in crescita e una di
/// scarico, da adattare all'età e al livello.
const modelliProgrammi = <ProgrammaPronto>[
  ProgrammaPronto(
    chiave: 'spalla_tiratore',
    nome: 'Spalla del tiratore',
    descrizione:
        'Cuffia dei rotatori e scapole del braccio che tira: 15 minuti '
        'prima dell\'acqua, con gli elastici, due volte a settimana. La '
        'quarta settimana è di scarico; dalla quinta un elastico più duro.',
    durataMin: 15,
    scarico: {4},
    sedute: [
      [
        RigaPronta('extrarotazione_elastico', [
          '2x12',
          '3x12',
          '3x15',
          '2x10',
          '3x12 elastico più duro',
          '3x15 elastico più duro',
        ]),
        RigaPronta('intrarotazione_elastico', [
          '2x12',
          '3x12',
          '3x15',
          '2x10',
          '3x12 elastico più duro',
          '3x15 elastico più duro',
        ]),
        RigaPronta('ytw_prono', ['2x6', '3x6', '3x8', '2x6', '3x8', '3x10']),
        RigaPronta('sleeper_stretch', [
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
        ], recuperoS: 15),
      ],
      [
        RigaPronta('extrarotazione_90', [
          '2x10',
          '3x10',
          '3x12',
          '2x8',
          '3x10 elastico più duro',
          '3x12 elastico più duro',
        ], recuperoS: 60),
        RigaPronta('face_pull', [
          '2x12',
          '3x12',
          '3x15',
          '2x10',
          '3x12 elastico più duro',
          '3x15 elastico più duro',
        ]),
        RigaPronta('extrarotazione_prono', [
          '2x10',
          '3x10',
          '3x12',
          '2x8',
          '3x10 mezzo kg in più',
          '3x12 mezzo kg in più',
        ], recuperoS: 60),
        RigaPronta('stretching_pettorali', [
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
          '2x30s',
        ], recuperoS: 15),
      ],
    ],
  ),
  ProgrammaPronto(
    chiave: 'scapole_core',
    nome: 'Scapole e core',
    descrizione:
        'Scapole stabili e un tronco che regge i contatti: 20 minuti, due '
        'volte a settimana. Tre settimane in crescita e una di scarico.',
    durataMin: 20,
    scarico: {4},
    sedute: [
      [
        RigaPronta('push_up_plus', ['2x10', '3x10', '3x12', '2x10']),
        RigaPronta('rematore_elastico', ['2x12', '3x12', '3x15', '2x12']),
        RigaPronta('plank_frontale', [
          '3x30s',
          '3x40s',
          '3x45s',
          '2x30s',
        ], recuperoS: 30),
        RigaPronta('dead_bug', ['2x8', '3x8', '3x10', '2x8']),
      ],
      [
        RigaPronta('face_pull', ['2x12', '3x12', '3x15', '2x12']),
        RigaPronta('plank_laterale', [
          '3x20s',
          '3x25s',
          '3x30s',
          '2x20s',
        ], recuperoS: 30),
        RigaPronta('pallof_press', ['2x8', '3x8', '3x10', '2x8']),
        RigaPronta('hollow_hold', [
          '3x20s',
          '3x25s',
          '3x30s',
          '2x20s',
        ], recuperoS: 35),
      ],
    ],
  ),
  ProgrammaPronto(
    chiave: 'gambe_bicicletta',
    nome: 'Gambe per la bicicletta',
    descrizione:
        'La resistenza e l\'esplosività delle gambe che servono alla '
        'bicicletta e allo stacco: 20 minuti a corpo libero, due volte a '
        'settimana. Tre settimane in crescita e una di scarico.',
    durataMin: 20,
    scarico: {4},
    sedute: [
      [
        RigaPronta('squat', ['3x12', '3x15', '4x15', '2x12'], recuperoS: 60),
        RigaPronta('affondi', ['2x8', '3x8', '3x10', '2x8'], recuperoS: 60),
        RigaPronta('squat_muro', [
          '3x30s',
          '3x40s',
          '3x45s',
          '2x30s',
        ], recuperoS: 60),
        RigaPronta('fire_hydrant', [
          '2x10',
          '2x10',
          '2x10',
          '2x10',
        ], recuperoS: 30),
      ],
      [
        RigaPronta('squat_jump', ['3x5', '4x5', '4x6', '2x5'], recuperoS: 90),
        RigaPronta('ponte_glutei', ['3x12', '3x15', '4x15', '2x12']),
        RigaPronta('squat_muro', [
          '3x30s',
          '3x40s',
          '3x45s',
          '2x30s',
        ], recuperoS: 60),
        RigaPronta('fire_hydrant', [
          '2x10',
          '2x10',
          '2x10',
          '2x10',
        ], recuperoS: 30),
      ],
    ],
  ),
  ProgrammaPronto(
    chiave: 'portieri',
    nome: 'Portieri',
    descrizione:
        'Per chi sta in porta: le gambe della bicicletta e dello stacco, la '
        'spalla che para in alto, il core. 20 minuti, due volte a '
        'settimana; la quarta settimana è di scarico.',
    durataMin: 20,
    scarico: {4},
    sedute: [
      [
        RigaPronta('squat_jump', ['3x5', '4x5', '4x6', '2x5'], recuperoS: 90),
        RigaPronta('squat_muro', [
          '3x30s',
          '3x40s',
          '3x45s',
          '2x30s',
        ], recuperoS: 60),
        RigaPronta('extrarotazione_90', [
          '2x10',
          '3x10',
          '3x12',
          '2x8',
        ], recuperoS: 60),
        RigaPronta('plank_laterale', [
          '3x20s',
          '3x25s',
          '3x30s',
          '2x20s',
        ], recuperoS: 30),
      ],
      [
        RigaPronta('affondi', ['2x8', '3x8', '3x10', '2x8'], recuperoS: 60),
        RigaPronta('fire_hydrant', [
          '2x10',
          '2x10',
          '2x10',
          '2x10',
        ], recuperoS: 30),
        RigaPronta('face_pull', ['2x12', '3x12', '3x15', '2x12']),
        RigaPronta('dead_bug', ['2x8', '3x8', '3x10', '2x8']),
      ],
    ],
  ),
];
