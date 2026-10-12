import 'dart:convert';
import 'dart:math' as math;

import '../../atleti/domain/atleta.dart';

/// Cosa misura un test del club e in che unità si scrive ogni prova.
enum UnitaTest {
  secondi('Tempo', 's'),
  metri('Metri', 'm'),
  centimetri('Centimetri', 'cm'),
  chili('Chili', 'kg'),
  kmh('Velocità', 'km/h'),
  punti('Punti', 'punti'),
  ripetizioni('Ripetizioni', 'rip.');

  const UnitaTest(this.etichetta, this.sigla);

  final String etichetta;
  final String sigla;

  static UnitaTest daNome(String nome) =>
      UnitaTest.values.firstWhere((u) => u.name == nome);

  /// Un tempo è migliore se più basso; il resto se più alto.
  bool get piuBassoMeglioDiSolito => this == secondi;

  /// Le unità che si contano a numeri interi.
  bool get intera => this == punti || this == ripetizioni;

  /// Le unità con la virgola (chili, km/h); i tempi la mette l'app.
  bool get conDecimali => this == chili || this == kmh;
}

/// Con più prove, il valore che va in classifica.
enum PunteggioTest {
  migliore('La migliore'),
  media('La media'),
  somma('La somma');

  const PunteggioTest(this.etichetta);

  final String etichetta;

  static PunteggioTest daNome(String nome) =>
      PunteggioTest.values.firstWhere((p) => p.name == nome);
}

/// Un test del club (fase 2 del "Mako della pallanuoto", proposta 3):
/// uno sprint, uno sprint ripetuto, la verticale, il tiro... Lo inventa
/// l'allenatore o parte da uno pronto ([modelliTest]).
class TestClub {
  const TestClub({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.unita,
    required this.piuBassoMeglio,
    this.descrizione,
    this.prove = 1,
    this.punteggio = PunteggioTest.migliore,
    this.modello,
    this.archiviato = false,
  });

  factory TestClub.fromMap(Map<String, dynamic> m) => TestClub(
    id: m['id'] as String,
    clubId: m['club_id'] as String,
    nome: m['nome'] as String,
    descrizione: m['descrizione'] as String?,
    unita: UnitaTest.daNome(m['unita'] as String),
    piuBassoMeglio: m['migliore'] == 'minore',
    prove: (m['prove'] as num?)?.toInt() ?? 1,
    punteggio: PunteggioTest.daNome(m['punteggio'] as String? ?? 'migliore'),
    modello: m['modello'] as String?,
    archiviato: m['archiviato'] as bool? ?? false,
  );

  final String id;
  final String clubId;
  final String nome;
  final String? descrizione;
  final UnitaTest unita;

  /// Il valore migliore è il più basso (un tempo) o il più alto.
  final bool piuBassoMeglio;

  /// Quante prove fa ogni atleta (6 in un 6 × 15 m).
  final int prove;
  final PunteggioTest punteggio;

  /// La chiave del test pronto da cui è nato, null se inventato.
  final String? modello;
  final bool archiviato;

  /// Il primo dei due valori è migliore del secondo?
  bool meglio(double a, double b) => piuBassoMeglio ? a < b : a > b;

  /// Il valore in classifica di un risultato con questi [valori].
  double punteggioDi(List<double> valori) {
    if (valori.length == 1 || prove == 1) return valori.first;
    return switch (punteggio) {
      PunteggioTest.migliore => valori.reduce((a, b) => meglio(a, b) ? a : b),
      PunteggioTest.media => valori.reduce((a, b) => a + b) / valori.length,
      PunteggioTest.somma => valori.reduce((a, b) => a + b),
    };
  }

  /// "Migliore di 3 prove", "Media di 6 prove", "1 prova".
  String get comeSiLegge {
    if (prove == 1) return '1 prova';
    return switch (punteggio) {
      PunteggioTest.migliore => 'Migliore di $prove prove',
      PunteggioTest.media => 'Media di $prove prove',
      PunteggioTest.somma => 'Somma di $prove prove',
    };
  }

  Map<String, Object?> toPayload() => {
    'nome': nome.trim(),
    'descrizione': descrizione == null || descrizione!.trim().isEmpty
        ? null
        : descrizione!.trim(),
    'unita': unita.name,
    'migliore': piuBassoMeglio ? 'minore' : 'maggiore',
    'prove': prove,
    'punteggio': punteggio.name,
    'modello': modello,
    'archiviato': archiviato,
  };
}

/// Un risultato: un atleta, un giorno, il valore di ogni prova.
class RisultatoTest {
  const RisultatoTest({
    required this.id,
    required this.testId,
    required this.atletaId,
    required this.clubId,
    required this.data,
    required this.valori,
    this.note,
  });

  factory RisultatoTest.fromMap(Map<String, dynamic> m) => RisultatoTest(
    id: m['id'] as String,
    testId: m['test_id'] as String,
    atletaId: m['atleta_id'] as String,
    clubId: m['club_id'] as String,
    data: DateTime.parse(m['data'] as String),
    valori: valoriDa(m['valori']),
    note: m['note'] as String?,
  );

  final String id;
  final String testId;
  final String atletaId;
  final String clubId;
  final DateTime data;
  final List<double> valori;
  final String? note;
}

/// I valori di un risultato: lista dal database, testo JSON dalla copia
/// locale.
List<double> valoriDa(Object? valore) => switch (valore) {
  final String json => [
    for (final v in jsonDecode(json) as List) (v as num).toDouble(),
  ],
  final List<dynamic> lista => [for (final v in lista) (v as num).toDouble()],
  _ => const [],
};

/// L'indice di affaticamento di più prove (decremento percentuale, come
/// nei test di sprint ripetuti): quanto la serie è lontana dal fare
/// sempre la prova migliore. 0 = tutte uguali alla migliore. null con
/// meno di due prove.
double? indiceAffaticamento(TestClub test, List<double> valori) {
  if (valori.length < 2) return null;
  final migliore = valori.reduce((a, b) => test.meglio(a, b) ? a : b);
  if (migliore <= 0) return null;
  final somma = valori.reduce((a, b) => a + b);
  final ideale = migliore * valori.length;
  final indice = test.piuBassoMeglio
      ? (somma / ideale - 1) * 100
      : (1 - somma / ideale) * 100;
  return math.max(0, indice);
}

/// "8,62 s", "1:05,20", "1.250 m", "58,4 km/h", "7 punti".
String formattaValore(UnitaTest unita, double valore, {bool sigla = true}) {
  final numero = switch (unita) {
    UnitaTest.secondi => _tempo(valore),
    UnitaTest.metri || UnitaTest.centimetri => _intero(valore),
    UnitaTest.punti || UnitaTest.ripetizioni => _intero(valore),
    UnitaTest.chili || UnitaTest.kmh => _decimale(valore, 1),
  };
  if (!sigla) return numero;
  // Sopra il minuto il tempo si legge da sé ("1:05,20").
  if (unita == UnitaTest.secondi && valore >= 60) return numero;
  return '$numero ${unita.sigla}';
}

String _tempo(double secondi) {
  final centesimi = (secondi * 100).round();
  final minuti = centesimi ~/ 6000;
  final resto = (centesimi % 6000) / 100;
  // I tempi tengono i centesimi anche se zero ("8,60").
  final testo = _decimale(resto, 2, tieniZeri: true);
  if (minuti == 0) return testo;
  return '$minuti:${resto < 10 ? '0' : ''}$testo';
}

/// Con la virgola; senza [tieniZeri] gli zeri in fondo si tolgono ("58",
/// "58,4").
String _decimale(double v, int cifre, {bool tieniZeri = false}) {
  var testo = v.toStringAsFixed(cifre);
  if (!tieniZeri && testo.contains('.')) {
    testo = testo
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return testo.replaceAll('.', ',');
}

String _intero(double v) {
  final cifre = v.round().abs().toString();
  final gruppi = <String>[];
  for (var fine = cifre.length; fine > 0; fine -= 3) {
    gruppi.insert(0, cifre.substring(math.max(0, fine - 3), fine));
  }
  return '${v < 0 ? '-' : ''}${gruppi.join('.')}';
}

/// "6,2%".
String formattaPercentuale(double v) =>
    '${v.toStringAsFixed(1).replaceAll('.', ',')}%';

/// La differenza fra due valori, con il segno: "−0,12 s", "+3 cm".
String formattaDifferenza(UnitaTest unita, double differenza) {
  final segno = differenza > 0
      ? '+'
      : differenza < 0
      ? '−'
      : '';
  return '$segno${formattaValore(unita, differenza.abs())}';
}

/// Una riga di classifica.
class PostoClassifica {
  const PostoClassifica({
    required this.posizione,
    required this.atleta,
    required this.risultato,
    required this.punteggio,
    this.precedente,
  });

  /// 1 per il migliore; a pari merito la stessa.
  final int posizione;
  final Atleta atleta;

  /// Il risultato che conta (l'ultimo o il migliore, vedi [classifica]).
  final RisultatoTest risultato;
  final double punteggio;

  /// Il punteggio del risultato prima di [risultato], per vedere se è
  /// migliorato.
  final double? precedente;
}

/// Quale risultato di ogni atleta va in classifica.
enum ModoClassifica {
  ultima('Ultima prova'),
  migliore('Migliore');

  const ModoClassifica(this.etichetta);

  final String etichetta;
}

/// La classifica di un [test] fra gli [atleti] con un risultato in
/// [risultati]: per ognuno l'ultimo risultato o il migliore ([modo]), dal
/// più bravo; dal giorno [dal] in poi se c'è.
List<PostoClassifica> classifica(
  TestClub test,
  Iterable<RisultatoTest> risultati,
  List<Atleta> atleti, {
  ModoClassifica modo = ModoClassifica.ultima,
  DateTime? dal,
}) {
  final perAtleta = <String, List<RisultatoTest>>{};
  for (final r in risultati) {
    if (r.testId != test.id || r.valori.isEmpty) continue;
    if (dal != null && r.data.isBefore(dal)) continue;
    (perAtleta[r.atletaId] ??= []).add(r);
  }
  final righe = <({Atleta atleta, RisultatoTest r, double p, double? prima})>[];
  for (final atleta in atleti) {
    final suoi = perAtleta[atleta.id];
    if (suoi == null || suoi.isEmpty) continue;
    suoi.sort((a, b) => a.data.compareTo(b.data));
    final RisultatoTest scelto;
    if (modo == ModoClassifica.ultima) {
      scelto = suoi.last;
    } else {
      scelto = suoi.reduce(
        (a, b) =>
            test.meglio(test.punteggioDi(b.valori), test.punteggioDi(a.valori))
            ? b
            : a,
      );
    }
    final indice = suoi.indexOf(scelto);
    righe.add((
      atleta: atleta,
      r: scelto,
      p: test.punteggioDi(scelto.valori),
      prima: indice > 0 ? test.punteggioDi(suoi[indice - 1].valori) : null,
    ));
  }
  righe.sort((a, b) {
    if (a.p == b.p) {
      return a.atleta.nomeCompleto.compareTo(b.atleta.nomeCompleto);
    }
    return test.meglio(a.p, b.p) ? -1 : 1;
  });
  final posti = <PostoClassifica>[];
  for (var i = 0; i < righe.length; i++) {
    final r = righe[i];
    final pariMerito = i > 0 && righe[i - 1].p == r.p;
    posti.add(
      PostoClassifica(
        posizione: pariMerito ? posti.last.posizione : i + 1,
        atleta: r.atleta,
        risultato: r.r,
        punteggio: r.p,
        precedente: r.prima,
      ),
    );
  }
  return posti;
}

/// I risultati di un atleta in un test, dal più vecchio: per l'andamento.
List<RisultatoTest> storicoAtleta(
  TestClub test,
  Iterable<RisultatoTest> risultati,
  String atletaId,
) => [
  for (final r in risultati)
    if (r.testId == test.id && r.atletaId == atletaId && r.valori.isNotEmpty) r,
]..sort((a, b) => a.data.compareTo(b.data));

/// La classifica in CSV, con il punto e virgola e la virgola nei
/// decimali: Excel in italiano la apre già divisa in colonne.
String csvClassifica(TestClub test, List<PostoClassifica> posti) {
  String cella(String v) =>
      v.contains(';') || v.contains('"') || v.contains('\n')
      ? '"${v.replaceAll('"', '""')}"'
      : v;
  final conAffaticamento = test.prove > 1;
  final righe = [
    [
      'Posizione',
      'Atleta',
      'Anno di nascita',
      'Data',
      '${test.nome} (${test.unita.sigla})',
      for (var i = 1; i <= test.prove; i++) 'Prova $i',
      if (conAffaticamento) 'Affaticamento %',
    ],
    for (final p in posti)
      [
        '${p.posizione}',
        p.atleta.nomeCompleto,
        '${p.atleta.dataNascita.year}',
        '${p.risultato.data.day.toString().padLeft(2, '0')}/'
            '${p.risultato.data.month.toString().padLeft(2, '0')}/'
            '${p.risultato.data.year}',
        formattaValore(test.unita, p.punteggio, sigla: false),
        for (var i = 0; i < test.prove; i++)
          i < p.risultato.valori.length
              ? formattaValore(test.unita, p.risultato.valori[i], sigla: false)
              : '',
        if (conAffaticamento)
          switch (indiceAffaticamento(test, p.risultato.valori)) {
            final v? => v.toStringAsFixed(1).replaceAll('.', ','),
            null => '',
          },
      ],
  ];
  return righe.map((r) => r.map(cella).join(';')).join('\r\n');
}

/// Un test pronto da aggiungere al club.
typedef ModelloTest = ({
  String chiave,
  String nome,
  String descrizione,
  UnitaTest unita,
  bool piuBassoMeglio,
  int prove,
  PunteggioTest punteggio,
});

/// I test di pallanuoto pronti: gli sprint (con e senza palla e ripetuti,
/// con l'indice di affaticamento), la navetta intermittente, la
/// verticale, il salto, la velocità e la precisione del tiro. Le misure
/// sono quelle più usate; il protocollo lo dice la descrizione, che
/// l'allenatore può cambiare.
const modelliTest = <ModelloTest>[
  (
    chiave: 'sprint_10',
    nome: 'Sprint 10 m',
    descrizione: 'Partenza da fermi in acqua, al fischio. Due prove.',
    unita: UnitaTest.secondi,
    piuBassoMeglio: true,
    prove: 2,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'sprint_15',
    nome: 'Sprint 15 m senza palla',
    descrizione: 'Partenza da fermi in acqua, al fischio. Due prove.',
    unita: UnitaTest.secondi,
    piuBassoMeglio: true,
    prove: 2,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'sprint_15_palla',
    nome: 'Sprint 15 m con palla',
    descrizione: 'Nuotata con la palla davanti, partenza da fermi. Due prove.',
    unita: UnitaTest.secondi,
    piuBassoMeglio: true,
    prove: 2,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'sprint_ripetuti_6x15',
    nome: 'Sprint ripetuti 6 × 15 m',
    descrizione:
        "Una partenza ogni 20''. In classifica la media; l'indice di "
        "affaticamento dice quanto cala dalla prova migliore.",
    unita: UnitaTest.secondi,
    piuBassoMeglio: true,
    prove: 6,
    punteggio: PunteggioTest.media,
  ),
  (
    chiave: 'wist',
    nome: 'Navetta intermittente (WIST)',
    descrizione:
        'Water-polo Intermittent Shuttle Test: metri percorsi fino '
        "all'esaurimento.",
    unita: UnitaTest.metri,
    piuBassoMeglio: false,
    prove: 1,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'verticale_peso',
    nome: 'Verticale con peso',
    descrizione:
        'Secondi in verticale con il peso sopra la testa, braccia tese '
        '(scrivi qui il peso).',
    unita: UnitaTest.secondi,
    piuBassoMeglio: false,
    prove: 1,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'salto',
    nome: "Salto fuori dall'acqua",
    descrizione: 'Altezza raggiunta con la mano, da fermi. Tre prove.',
    unita: UnitaTest.centimetri,
    piuBassoMeglio: false,
    prove: 3,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'velocita_tiro',
    nome: 'Velocità di tiro',
    descrizione: 'Con il radar, da 5 m. Tre tiri.',
    unita: UnitaTest.kmh,
    piuBassoMeglio: false,
    prove: 3,
    punteggio: PunteggioTest.migliore,
  ),
  (
    chiave: 'precisione_tiro',
    nome: 'Precisione di tiro',
    descrizione:
        'Dieci tiri da 5 m sui bersagli negli angoli: un punto a '
        'bersaglio.',
    unita: UnitaTest.punti,
    piuBassoMeglio: false,
    prove: 1,
    punteggio: PunteggioTest.migliore,
  ),
];
