import 'dart:math' as math;

/// Scheda benessere compilata dall'atleta prima di allenamento o partita.
///
/// Le cinque voci 1-5 sono quelle del questionario di McLean et al.
/// (2010), il piu' usato negli sport di squadra: qualita' del sonno,
/// energia (l'inverso della fatica), indolenzimento muscolare, stress e
/// umore, sempre con 5 = meglio. In piu': ore di sonno, dolori localizzati
/// (la spalla e' il primo punto critico nella pallanuoto) e sintomi di
/// malattia.
class SchedaBenessere {
  const SchedaBenessere({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.data,
    required this.dolori,
    required this.oreSonno,
    required this.compilataIl,
    this.eventoTipo,
    this.eventoId,
    this.zoneDolore = const [],
    this.intensitaDolore,
    this.qualitaSonno,
    this.energia,
    this.muscoli,
    this.stress,
    this.umore,
    this.sintomi = const [],
  });

  final String id;
  final String atletaId;
  final String clubId;

  /// Giorno a cui si riferisce (una scheda per atleta al giorno).
  final DateTime data;

  /// 'allenamento' | 'partita' | null.
  final String? eventoTipo;
  final String? eventoId;
  final bool dolori;
  final List<String> zoneDolore;

  /// 1-10, solo se [dolori].
  final int? intensitaDolore;
  final double oreSonno;
  final DateTime compilataIl;

  /// Voci McLean, 1-5 (5 = meglio). null nelle schede della prima
  /// versione, che avevano solo dolori e ore di sonno.
  final int? qualitaSonno;
  final int? energia;
  final int? muscoli;
  final int? stress;
  final int? umore;
  final List<String> sintomi;

  /// Livello del semaforo (0 verde, 1 giallo, 2 rosso), senza confronto
  /// con lo storico: per i riepiloghi veloci. Il dettaglio con le
  /// spiegazioni e' [calcolaPunteggio].
  int get allerta => calcolaPunteggio(this).livello;
}

/// Le voci 1-5 della scheda, con domanda ed etichette agli estremi.
typedef VoceQuestionario = ({
  String chiave,
  String domanda,
  List<String> etichette,
});

const vociQuestionario = <VoceQuestionario>[
  (
    chiave: 'qualitaSonno',
    domanda: 'Come hai dormito?',
    etichette: ['Malissimo', 'Male', 'Così così', 'Bene', 'Benissimo'],
  ),
  (
    chiave: 'energia',
    domanda: 'Quanta energia hai?',
    etichette: ['Sfinito', 'Stanco', 'Normale', 'Carico', 'A mille'],
  ),
  (
    chiave: 'muscoli',
    domanda: 'Come senti i muscoli?',
    etichette: [
      'Molto doloranti',
      'Doloranti',
      'Un po\' rigidi',
      'Bene',
      'Freschissimi',
    ],
  ),
  (
    chiave: 'stress',
    domanda: 'Quanto sei stressato?',
    etichette: ['Moltissimo', 'Parecchio', 'Un po\'', 'Poco', 'Per niente'],
  ),
  (
    chiave: 'umore',
    domanda: 'Come va l\'umore?',
    etichette: ['Giù', 'Nervoso', 'Normale', 'Buono', 'Ottimo'],
  ),
];

/// Zone del corpo proposte nella scheda (chiave salvata, etichetta). La
/// spalla e' la prima: nella pallanuoto e' la sede di circa la meta' degli
/// infortuni, quasi sempre da sovraccarico.
const zoneCorpo = [
  ('spalla', 'Spalla'),
  ('gomito', 'Gomito'),
  ('schiena', 'Schiena'),
  ('ginocchio', 'Ginocchio'),
  ('anca', 'Anca / inguine'),
  ('polso_mano', 'Polso / mano'),
  ('caviglia_piede', 'Caviglia / piede'),
  ('testa_collo', 'Testa / collo'),
  ('altro', 'Altro'),
];

const sintomiMalattia = [
  ('febbre', 'Febbre'),
  ('raffreddore', 'Raffreddore / tosse'),
  ('gola', 'Mal di gola'),
  ('stomaco', 'Mal di stomaco'),
  ('altro', 'Altro malessere'),
];

String etichettaZona(String chiave) =>
    zoneCorpo.where((z) => z.$1 == chiave).map((z) => z.$2).firstOrNull ??
    chiave;

String etichettaSintomo(String chiave) =>
    sintomiMalattia.where((z) => z.$1 == chiave).map((z) => z.$2).firstOrNull ??
    chiave;

/// "7,5 h" con la virgola italiana e senza ",0".
String formattaOre(double ore) {
  final intere = ore.truncateToDouble() == ore;
  return '${intere ? ore.toStringAsFixed(0) : ore.toStringAsFixed(1).replaceAll('.', ',')} h';
}

/// Ore di sonno consigliate: 8 per i minorenni (8-10 h a 13-18 anni),
/// 7 per gli adulti.
double obiettivoSonno(DateTime? dataNascita, DateTime giorno) {
  if (dataNascita == null) return 8;
  var anni = giorno.year - dataNascita.year;
  if (giorno.month < dataNascita.month ||
      (giorno.month == dataNascita.month && giorno.day < dataNascita.day)) {
    anni--;
  }
  return anni < 18 ? 8 : 7;
}

/// Un pezzo della spiegazione del punteggio: cosa, quanto pesa.
typedef MotivoPunteggio = ({String testo, int punti, bool critico});

/// Il punteggio "Prontezza" di una scheda, 0-100, con le spiegazioni.
class PunteggioBenessere {
  const PunteggioBenessere({
    required this.valore,
    required this.livello,
    required this.base,
    required this.motivi,
    this.mediaPersonale,
  });

  /// 0-100.
  final int valore;

  /// 0 verde (pronto), 1 giallo (da seguire), 2 rosso (da sentire prima
  /// di entrare in acqua).
  final int livello;

  /// Indice di benessere (le 5 voci McLean riportate su 100), prima delle
  /// penalita'. null nelle schede della prima versione.
  final int? base;

  /// Cosa ha abbassato (o determinato) il punteggio, dal piu' pesante.
  final List<MotivoPunteggio> motivi;

  /// Media dei suoi punteggi nelle 4 settimane precedenti, se ci sono
  /// almeno 5 schede: il "suo solito".
  final double? mediaPersonale;

  /// Differenza dal suo solito (negativa = sotto).
  int? get scartoDalSolito =>
      mediaPersonale == null ? null : valore - mediaPersonale!.round();

  String get etichetta => switch (livello) {
    0 => 'Pronto',
    1 => 'Da seguire',
    _ => 'Da sentire',
  };
}

/// Calcola la Prontezza:
/// 1. **Base** = media delle 5 voci McLean × 20 (tutte "normale", 3 = 60;
///    tutte a 5 = 100). Le schede senza voci partono da 80.
/// 2. **Sonno**: -5 punti per ogni mezz'ora sotto l'obiettivo per eta'
///    (8 h minorenni, 7 h adulti), al massimo -25.
/// 3. **Dolore**: -3 punti per ogni punto di intensita' (dolore 6/10 =
///    -18); la spalla, punto debole della pallanuoto, pesa 1,2 volte.
/// 4. **Malattia**: febbre -30, altri sintomi -10 ciascuno.
/// Semaforo: verde da 60, giallo 40-59, rosso sotto 40; sempre rosso con
/// dolore da 7/10, febbre o meno di 5 ore di sonno. Con lo [storico]
/// dell'atleta: se il punteggio e' sotto il suo solito di oltre 1,5
/// deviazioni standard (e di almeno 10 punti) sale di un livello.
PunteggioBenessere calcolaPunteggio(
  SchedaBenessere s, {
  DateTime? dataNascita,
  List<SchedaBenessere> storico = const [],
}) {
  final motivi = <MotivoPunteggio>[];
  final voci = [s.qualitaSonno, s.energia, s.muscoli, s.stress, s.umore];
  final presenti = voci.whereType<int>().toList();
  // Ogni voce vale 20 punti per gradino: "normale" (3) = 60, cioe' gia'
  // verde; "bene" (4) = 80; "benissimo" (5) = 100.
  final base = presenti.isEmpty
      ? null
      : (presenti.map((v) => v * 20).reduce((a, b) => a + b) / presenti.length)
            .round();
  var valore = (base ?? 80).toDouble();

  // Le voci piu' basse diventano motivi (senza togliere altri punti: sono
  // gia' nella base).
  for (final (i, voce) in vociQuestionario.indexed) {
    final v = voci[i];
    if (v != null && v <= 2) {
      motivi.add((
        testo:
            '${voce.domanda.replaceAll('?', '')}: ${voce.etichette[v - 1].toLowerCase()}',
        punti: (v - 3) * 4,
        critico: v == 1,
      ));
    }
  }

  final obiettivo = obiettivoSonno(dataNascita, s.data);
  if (s.oreSonno < obiettivo) {
    final pen = math.min(25, ((obiettivo - s.oreSonno) / 0.5).ceil() * 5);
    valore -= pen;
    motivi.add((
      testo:
          'Sonno ${formattaOre(s.oreSonno)} (obiettivo ${formattaOre(obiettivo)})',
      punti: -pen,
      critico: s.oreSonno < 5,
    ));
  }

  if (s.dolori) {
    final intensita = s.intensitaDolore ?? 5;
    final spalla = s.zoneDolore.contains('spalla');
    final pen = (intensita * 3 * (spalla ? 1.2 : 1)).round();
    valore -= pen;
    motivi.add((
      testo:
          'Dolore ${s.zoneDolore.map(etichettaZona).join(', ').toLowerCase()} '
          '$intensita/10',
      punti: -pen,
      critico: intensita >= 7,
    ));
  }

  for (final sintomo in s.sintomi) {
    final pen = sintomo == 'febbre' ? 30 : 10;
    valore -= pen;
    motivi.add((
      testo: etichettaSintomo(sintomo),
      punti: -pen,
      critico: sintomo == 'febbre',
    ));
  }

  final finale = valore.round().clamp(0, 100);
  var livello = finale >= 60
      ? 0
      : finale >= 40
      ? 1
      : 2;
  if (motivi.any((m) => m.critico)) livello = 2;

  // Confronto con il suo solito: le 4 settimane prima di questa scheda.
  double? media;
  final precedenti = storico
      .where(
        (x) =>
            x.data.isBefore(s.data) && s.data.difference(x.data).inDays <= 28,
      )
      .map((x) => calcolaPunteggio(x, dataNascita: dataNascita).valore)
      .toList();
  if (precedenti.length >= 5) {
    media = precedenti.reduce((a, b) => a + b) / precedenti.length;
    final varianza =
        precedenti
            .map((v) => (v - media!) * (v - media))
            .reduce((a, b) => a + b) /
        precedenti.length;
    final ds = math.sqrt(varianza);
    final scarto = finale - media;
    if (scarto <= -10 && scarto < -1.5 * math.max(ds, 4)) {
      // Senza punti: e' un confronto, non una penalita' in piu'.
      motivi.add((
        testo:
            'Molto sotto il suo solito (${(-scarto).round()} punti in meno '
            'della sua media)',
        punti: 0,
        critico: false,
      ));
      livello = math.min(2, livello + 1);
    }
  }

  motivi.sort((a, b) => a.punti.compareTo(b.punti));
  return PunteggioBenessere(
    valore: finale,
    livello: livello,
    base: base,
    motivi: motivi,
    mediaPersonale: media,
  );
}
