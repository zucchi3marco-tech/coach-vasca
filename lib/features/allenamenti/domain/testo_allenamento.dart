import '../../../core/utils/pace_format.dart';
import 'riordino_serie.dart';
import 'serie.dart';

/// Scrivere un allenamento come su un foglio, una serie per riga — idea
/// presa dall'editor di Swimtraxx Hub (richiesta del coach 2026-10-08):
/// il testo si interpreta qui, subito e senza AI, mentre lo si scrive.
///
/// ```text
/// Riscaldamento
/// 400 mi A1
/// 4x50 gambe pinne r15
///
/// Principale
/// 2x
/// 3x200 sl B1 @3:00
/// 4x75 do C1 r10
///
/// 50-100-200-100-50 sl A2 r20
/// 10' remate "palla alta"
/// ```
///
/// - Una riga di titolo ("Riscaldamento", "Principale", "Defaticamento",
///   "Altro", anche abbreviati) apre un blocco; può avere già una serie
///   dopo il titolo. Senza titoli tutto va nel blocco principale.
/// - "2x" da solo su una riga ripete le righe sotto, fino alla prima riga
///   vuota (o al prossimo titolo, o al prossimo "Nx").
/// - Il volume: "8x100", "400" (da solo, all'inizio della riga), una
///   piramide "50-100-200" o "2x(50-100)", oppure una durata "10'",
///   "3x5'", "30''".
/// - Il resto, in qualsiasi ordine: zona (A1…D), stile (sl, do, ra, df,
///   mi), esecuzione (gambe, braccia, pull, tecnica, remate), passo sui
///   100 "1:25", ripartenza "@1:30", recupero "r15" (o "r1:00"),
///   attrezzi (pinne, palette, …, o "[pinne corte]"), note fra
///   virgolette. Una parola che non si riconosce finisce nelle note.
///
/// [testoDaSerie] fa il contrario: riscrive le serie di un allenamento in
/// questo formato, in modo che rilette diano le stesse serie.

/// Una serie letta dal testo, non ancora salvata.
class SerieScritta implements DatiSerie {
  const SerieScritta({
    required this.blocco,
    required this.ripetute,
    this.distanzaM,
    this.durataS,
    this.stile = 'libero',
    this.esecuzione = 'nuoto',
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
    this.ripartenzaS,
    this.attrezzatura,
    this.note,
    this.piramideId,
  });

  @override
  final String blocco;
  @override
  final int ripetute;
  @override
  final int? distanzaM;
  @override
  final int? durataS;
  @override
  final String stile;
  @override
  final String esecuzione;
  @override
  final String? zona;
  @override
  final double? passoObiettivoS;
  @override
  final int? recuperoS;
  @override
  final double? ripartenzaS;
  @override
  final String? attrezzatura;
  @override
  final String? note;

  /// Un segnaposto ("g1", "g2"…) comune alle serie di una piramide o di
  /// un "2x": al salvataggio diventa un vero `piramideId`.
  @override
  final String? piramideId;

  int get distanzaTotaleM => ripetute * (distanzaM ?? 0);

  SerieScritta _conGruppo(String? gruppo) => SerieScritta(
    blocco: blocco,
    ripetute: ripetute,
    distanzaM: distanzaM,
    durataS: durataS,
    stile: stile,
    esecuzione: esecuzione,
    zona: zona,
    passoObiettivoS: passoObiettivoS,
    recuperoS: recuperoS,
    ripartenzaS: ripartenzaS,
    attrezzatura: attrezzatura,
    note: note,
    piramideId: gruppo,
  );
}

enum TipoRiga { vuota, titolo, giri, serie, errore }

/// Come è stata capita una riga del testo, per mostrarlo accanto mentre
/// si scrive.
class RigaScritta {
  const RigaScritta({
    required this.testo,
    required this.tipo,
    this.serie = const [],
    this.paroleIgnote = const [],
    this.problema,
    this.giri = 1,
    this.blocco,
  });

  final String testo;
  final TipoRiga tipo;

  /// Le serie della riga, una volta sola: un "2x" sopra le ripete.
  final List<SerieScritta> serie;

  /// Parole che non sono dati della serie: finiscono nelle sue note.
  final List<String> paroleIgnote;

  /// Perché la riga non è stata capita (e non verrà salvata).
  final String? problema;

  /// Per una riga "2x" le volte che si ripete il gruppo sotto, per una
  /// riga di serie dentro quel gruppo le stesse volte; 1 altrimenti.
  final int giri;

  /// Il blocco in cui cade la riga (per un titolo, quello che apre).
  final String? blocco;
}

class AllenamentoScritto {
  const AllenamentoScritto({required this.righe, required this.serie});

  final List<RigaScritta> righe;

  /// Tutte le serie, nell'ordine, con i "2x" già ripetuti.
  final List<SerieScritta> serie;

  int get metri => serie.fold(0, (t, s) => t + s.distanzaTotaleM);

  int get righeNonCapite =>
      righe.where((r) => r.tipo == TipoRiga.errore).length;
}

// ---------------------------------------------------------------------------
// Vocabolario

const _titoliBlocco = {
  'riscaldamento': 'riscaldamento',
  'risc': 'riscaldamento',
  'principale': 'principale',
  'centrale': 'principale',
  'defaticamento': 'defaticamento',
  'defat': 'defaticamento',
  'scioglimento': 'defaticamento',
  'altro': 'altro',
};

const _nomiBlocco = {
  'riscaldamento': 'Riscaldamento',
  'principale': 'Principale',
  'defaticamento': 'Defaticamento',
  'altro': 'Altro',
};

const _zone = {'A1', 'A2', 'B1', 'B2', 'C', 'C1', 'C2', 'C3', 'D'};

const _stili = {
  'sl': 'libero',
  'lib': 'libero',
  'libero': 'libero',
  'crawl': 'libero',
  'do': 'dorso',
  'dorso': 'dorso',
  'ra': 'rana',
  'rana': 'rana',
  'df': 'delfino',
  'de': 'delfino',
  'fa': 'delfino',
  'delfino': 'delfino',
  'farfalla': 'delfino',
  'mi': 'misti',
  'mx': 'misti',
  'misti': 'misti',
};

const _sigleStile = {
  'libero': 'sl',
  'dorso': 'do',
  'rana': 'ra',
  'delfino': 'df',
  'misti': 'mi',
};

const _esecuzioni = {
  'nuoto': 'nuoto',
  'gambe': 'gambe',
  'gb': 'gambe',
  'braccia': 'braccia',
  'br': 'braccia',
  'pull': 'pull',
  'tecnica': 'tecnica',
  'tec': 'tecnica',
  'remate': 'remate',
  'tecnico-tattico': 'pallanuoto tecnico-tattico',
  'tattica': 'pallanuoto tecnico-tattico',
  'secco': 'a secco',
  'a-secco': 'a secco',
};

const _paroleEsecuzione = {
  'gambe': 'gambe',
  'braccia': 'braccia',
  'pull': 'pull',
  'tecnica': 'tecnica',
  'remate': 'remate',
  'pallanuoto tecnico-tattico': 'tecnico-tattico',
  'a secco': 'a-secco',
};

const _senzaStile = {'pallanuoto tecnico-tattico', 'a secco'};

/// Attrezzi che si scrivono come parola sola; gli altri fra quadre.
const _attrezzi = {
  'pinne': 'pinne',
  'palette': 'palette',
  'pullbuoy': 'pullbuoy',
  'pull-buoy': 'pullbuoy',
  'tavoletta': 'tavoletta',
  'boccaglio': 'boccaglio',
  'snorkel': 'boccaglio',
  'elastico': 'elastico',
  'paracadute': 'paracadute',
  'monopinna': 'monopinna',
  'zavorra': 'zavorra',
};

/// Parole di contorno ("400 m stile libero con pinne"): si saltano.
const _riempitivi = {'m', 'mt', 'metri', 'stile', 'a', 'con', 'e'};

// ---------------------------------------------------------------------------
// Lettura

final _rxGiri = RegExp(r'^(\d+)\s*(?:[xX×]|[vV]olte|[gG]iri)[.:]?$');
final _rxTitolo = RegExp(r'^([A-Za-zÀ-ÿ]+)[.:]?(?:\s+|$)');
// Le virgolette aprono una nota solo dopo uno spazio: quelle attaccate a
// un numero (6x30") sono i secondi.
final _rxNota = RegExp(r'(?:^|\s)["“”«»]([^"“”«»]*)["“”«»]');
final _rxAttrezzi = RegExp(r'\[([^\]]*)\]');
final _rxPiramideConGiri = RegExp(r'^(\d+)x\((\d+(?:-\d+)+)\)m?$');
final _rxPiramide = RegExp(r'^(\d+(?:-\d+)+)m?$');
final _rxRipetute = RegExp(r'^(\d+)x(.+)$');
final _rxDistanza = RegExp(r'^(\d+)m?$');
final _rxMinutiSecondi = RegExp(r'^(\d+):(\d{1,2}(?:[.,]\d+)?)$');
final _rxPrimi = RegExp(r'''^(\d+)['’′](\d{1,2})?(?:["”″]|'')?$''');
final _rxSecondi = RegExp(r'''^(\d+)(?:["”″]|'')$''');
final _rxMinuti = RegExp(r'^(\d+)min$', caseSensitive: false);
final _rxRecupero = RegExp(r'^r(?:ec)?(.+)$', caseSensitive: false);

/// "5'", "5'30\"", "30\"", "10min" → secondi.
int? _durata(String t) {
  final primi = _rxPrimi.firstMatch(t);
  if (primi != null) {
    return int.parse(primi[1]!) * 60 + int.parse(primi[2] ?? '0');
  }
  final secondi = _rxSecondi.firstMatch(t);
  if (secondi != null) return int.parse(secondi[1]!);
  final minuti = _rxMinuti.firstMatch(t);
  if (minuti != null) return int.parse(minuti[1]!) * 60;
  return null;
}

/// "90", "1:30", "1:30.5", "1'30" → secondi.
double? _tempo(String t) {
  if (RegExp(r'^\d+$').hasMatch(t)) return double.parse(t);
  final mmss = _rxMinutiSecondi.firstMatch(t);
  if (mmss != null) {
    return int.parse(mmss[1]!) * 60 +
        double.parse(mmss[2]!.replaceAll(',', '.'));
  }
  return _durata(t)?.toDouble();
}

/// Mette insieme quello che si scrive staccato: "8 x 100" → "8x100",
/// "8 volte 100" → "8x100", "50 - 100" → "50-100", "10 min" → "10min".
String _normalizza(String t) => t
    .replaceAllMapped(
      RegExp(r'(\d)\s*(?:[xX×]|[vV]olte)\s*(?=[\d(])'),
      (m) => '${m[1]}x',
    )
    .replaceAllMapped(RegExp(r'(\d)\s*-\s*(?=\d)'), (m) => '${m[1]}-')
    .replaceAllMapped(
      RegExp(r'(\d)\s+(?=min\b)', caseSensitive: false),
      (m) => m[1]!,
    );

class _Volume {
  const _Volume({
    this.ripetute = 1,
    this.distanzaM,
    this.durataS,
    this.distanze,
    this.giri = 1,
  });

  final int ripetute;
  final int? distanzaM;
  final int? durataS;

  /// Una piramide: una serie per distanza, ripetuta [giri] volte.
  final List<int>? distanze;
  final int giri;

  bool get valido =>
      ripetute > 0 &&
      giri > 0 &&
      (distanzaM ?? 1) > 0 &&
      (durataS ?? 1) > 0 &&
      (distanze?.every((d) => d > 0) ?? true);
}

_Volume? _volume(String token, {required bool primo}) {
  final conGiri = _rxPiramideConGiri.firstMatch(token);
  if (conGiri != null) {
    return _Volume(
      giri: int.parse(conGiri[1]!),
      distanze: conGiri[2]!.split('-').map(int.parse).toList(),
    );
  }
  final piramide = _rxPiramide.firstMatch(token);
  if (piramide != null) {
    return _Volume(distanze: piramide[1]!.split('-').map(int.parse).toList());
  }
  final ripetute = _rxRipetute.firstMatch(token);
  if (ripetute != null) {
    final volte = int.parse(ripetute[1]!);
    final durata = _durata(ripetute[2]!);
    if (durata != null) return _Volume(ripetute: volte, durataS: durata);
    final distanza = _rxDistanza.firstMatch(ripetute[2]!);
    if (distanza != null) {
      return _Volume(ripetute: volte, distanzaM: int.parse(distanza[1]!));
    }
    return null;
  }
  final durata = _durata(token);
  if (durata != null) return _Volume(durataS: durata);
  // Un numero da solo è una distanza solo all'inizio della riga ("400
  // sl"): in mezzo è più facile che sia altro ("respirazione 3").
  final distanza = _rxDistanza.firstMatch(token);
  if (primo && distanza != null) {
    final metri = int.parse(distanza[1]!);
    if (metri >= 25) return _Volume(distanzaM: metri);
  }
  return null;
}

typedef _LetturaSerie = ({
  List<SerieScritta> serie,
  List<String> ignote,
  String? problema,
});

_LetturaSerie _leggiSerie(String riga, String blocco) {
  final note = <String>[];
  final attrezzi = <String>[];
  var resto = riga.replaceAllMapped(_rxNota, (m) {
    final nota = m[1]!.trim();
    if (nota.isNotEmpty) note.add(nota);
    return ' ';
  });
  resto = resto.replaceAllMapped(_rxAttrezzi, (m) {
    final attrezzo = m[1]!.trim();
    if (attrezzo.isNotEmpty) attrezzi.add(attrezzo);
    return ' ';
  });

  final token = [
    for (final t in _normalizza(resto).split(RegExp(r'\s+')))
      if (t.replaceAll(RegExp(r'^[,;]+|[,;]+$'), '') case final pulito
          when pulito.isNotEmpty)
        pulito,
  ];

  _Volume? volume;
  var stile = 'libero';
  var esecuzione = 'nuoto';
  String? zona;
  double? passo;
  double? ripartenza;
  final recuperi = <int>[];
  final ignote = <String>[];

  for (var i = 0; i < token.length; i++) {
    final t = token[i];
    final basso = t.toLowerCase();
    if (volume == null) {
      final letto = _volume(basso, primo: i == 0);
      if (letto != null) {
        volume = letto;
        continue;
      }
    }
    if (_riempitivi.contains(basso)) continue;
    if (_zone.contains(t.toUpperCase())) {
      zona = t.toUpperCase();
      continue;
    }
    if (_stili[basso] case final s?) {
      stile = s;
      continue;
    }
    if (_esecuzioni[basso] case final e?) {
      esecuzione = e;
      continue;
    }
    if (_attrezzi[basso] case final a?) {
      attrezzi.add(a);
      continue;
    }
    if (basso.startsWith('@')) {
      if (_tempo(basso.substring(1)) case final r?) {
        ripartenza = r;
        continue;
      }
    }
    if (_rxRecupero.firstMatch(basso) case final m?) {
      if (_tempo(m[1]!) case final r?) {
        recuperi.add(r.round());
        continue;
      }
    }
    if (_rxMinutiSecondi.hasMatch(basso)) {
      passo = _tempo(basso);
      continue;
    }
    ignote.add(t);
  }

  if (volume == null) {
    return (
      serie: const [],
      ignote: ignote,
      problema: "Manca la distanza (es. 400 o 8x100) o la durata (es. 10')",
    );
  }
  if (!volume.valido) {
    return (
      serie: const [],
      ignote: ignote,
      problema: 'Ripetute, distanze e durate devono essere più di zero',
    );
  }

  final tutteLeNote = [...note, if (ignote.isNotEmpty) ignote.join(' ')];
  SerieScritta serie({
    required int ripetute,
    int? distanzaM,
    int? durataS,
    int? recuperoS,
  }) => SerieScritta(
    blocco: blocco,
    ripetute: ripetute,
    distanzaM: distanzaM,
    durataS: durataS,
    stile: stile,
    esecuzione: esecuzione,
    zona: zona,
    passoObiettivoS: passo,
    recuperoS: recuperoS,
    ripartenzaS: ripartenza,
    attrezzatura: attrezzi.isEmpty ? null : attrezzi.join(', '),
    note: tutteLeNote.isEmpty ? null : tutteLeNote.join(' '),
  );

  final distanze = volume.distanze;
  if (distanze == null) {
    return (
      serie: [
        serie(
          ripetute: volume.ripetute,
          distanzaM: volume.distanzaM,
          durataS: volume.durataS,
          recuperoS: recuperi.firstOrNull,
        ),
      ],
      ignote: ignote,
      problema: null,
    );
  }

  // Piramide: il primo recupero vale fra una distanza e l'altra, il
  // secondo (se c'è) fra un giro e l'altro, al posto del primo.
  final r1 = recuperi.firstOrNull;
  final r2 = recuperi.length > 1 ? recuperi[1] : r1;
  return (
    serie: [
      for (var g = 0; g < volume.giri; g++)
        for (var i = 0; i < distanze.length; i++)
          serie(
            ripetute: 1,
            distanzaM: distanze[i],
            recuperoS: i == distanze.length - 1 && g < volume.giri - 1
                ? r2
                : r1,
          ),
    ],
    ignote: ignote,
    problema: null,
  );
}

/// Interpreta una riga sola, come quella del pannello "Aggiungi serie":
/// le sue serie (più d'una per una piramide, con lo stesso `piramideId`
/// segnaposto) o `null` se non c'è una serie da leggere.
List<SerieScritta>? leggiRigaSerie(String riga, {required String blocco}) {
  final testo = riga.trim();
  if (testo.isEmpty) return null;
  final lettura = _leggiSerie(testo, blocco);
  if (lettura.problema != null) return null;
  final serie = lettura.serie;
  return serie.length > 1 ? [for (final s in serie) s._conGruppo('g1')] : serie;
}

/// Interpreta tutto il testo di un allenamento, riga per riga.
AllenamentoScritto interpretaAllenamento(
  String testo, {
  String bloccoIniziale = 'principale',
}) {
  final righe = <RigaScritta>[];
  final serie = <SerieScritta>[];
  var blocco = bloccoIniziale;
  var gruppi = 0;

  // Il "2x" in corso: la sua riga, le volte, le serie da ripetere.
  int? rigaGiro;
  var volte = 1;
  final corpo = <SerieScritta>[];

  void chiudiGiro() {
    final indice = rigaGiro;
    if (indice == null) return;
    rigaGiro = null;
    if (corpo.isEmpty) {
      final riga = righe[indice];
      righe[indice] = RigaScritta(
        testo: riga.testo,
        tipo: TipoRiga.errore,
        problema: "Sotto non c'è nessuna serie da ripetere",
        blocco: riga.blocco,
      );
      return;
    }
    final ripetute = volte * corpo.length;
    final gruppo = ripetute > 1 ? 'g${++gruppi}' : null;
    for (var v = 0; v < volte; v++) {
      for (final s in corpo) {
        serie.add(s._conGruppo(gruppo));
      }
    }
    corpo.clear();
  }

  for (final grezza in testo.split('\n')) {
    var t = grezza.trim();
    if (t.isEmpty) {
      chiudiGiro();
      righe.add(RigaScritta(testo: grezza, tipo: TipoRiga.vuota));
      continue;
    }

    final titolo = _rxTitolo.firstMatch(t);
    final nuovoBlocco = titolo == null
        ? null
        : _titoliBlocco[titolo[1]!.toLowerCase()];
    if (nuovoBlocco != null) {
      chiudiGiro();
      blocco = nuovoBlocco;
      t = t.substring(titolo!.end).trim();
      if (t.isEmpty) {
        righe.add(
          RigaScritta(testo: grezza, tipo: TipoRiga.titolo, blocco: blocco),
        );
        continue;
      }
    }

    final giro = _rxGiri.firstMatch(t);
    if (giro != null) {
      chiudiGiro();
      final n = int.parse(giro[1]!);
      if (n <= 0) {
        righe.add(
          RigaScritta(
            testo: grezza,
            tipo: TipoRiga.errore,
            problema: 'Le volte devono essere più di zero',
            blocco: blocco,
          ),
        );
        continue;
      }
      rigaGiro = righe.length;
      volte = n;
      righe.add(
        RigaScritta(
          testo: grezza,
          tipo: TipoRiga.giri,
          giri: n,
          blocco: blocco,
        ),
      );
      continue;
    }

    final lettura = _leggiSerie(t, blocco);
    if (lettura.problema != null) {
      righe.add(
        RigaScritta(
          testo: grezza,
          tipo: TipoRiga.errore,
          problema: lettura.problema,
          paroleIgnote: lettura.ignote,
          blocco: blocco,
        ),
      );
      continue;
    }
    righe.add(
      RigaScritta(
        testo: grezza,
        tipo: TipoRiga.serie,
        serie: lettura.serie,
        paroleIgnote: lettura.ignote,
        giri: rigaGiro == null ? 1 : volte,
        blocco: blocco,
      ),
    );
    if (rigaGiro != null) {
      corpo.addAll(lettura.serie);
    } else if (lettura.serie.length > 1) {
      final gruppo = 'g${++gruppi}';
      serie.addAll([for (final s in lettura.serie) s._conGruppo(gruppo)]);
    } else {
      serie.addAll(lettura.serie);
    }
  }
  chiudiGiro();

  return AllenamentoScritto(righe: righe, serie: serie);
}

// ---------------------------------------------------------------------------
// Scrittura

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();

/// Stessi dati, a parte ripetute, volume e recupero (che in una piramide
/// cambiano da riga a riga).
bool _stessiAttributi(DatiSerie a, DatiSerie b) =>
    a.blocco == b.blocco &&
    a.stile == b.stile &&
    a.esecuzione == b.esecuzione &&
    a.zona == b.zona &&
    a.passoObiettivoS == b.passoObiettivoS &&
    a.ripartenzaS == b.ripartenzaS &&
    _pieno(a.attrezzatura) == _pieno(b.attrezzatura) &&
    _pieno(a.note) == _pieno(b.note);

/// Due serie con gli stessi dati (non guarda id, ordine e gruppo).
bool stessaSerie(DatiSerie a, DatiSerie b) =>
    _stessiAttributi(a, b) &&
    a.ripetute == b.ripetute &&
    a.distanzaM == b.distanzaM &&
    a.durataS == b.durataS &&
    a.recuperoS == b.recuperoS;

/// Se [gruppo] è una piramide (una ripetuta per riga, stessi dati, le
/// distanze che si ripetono a giri): i giri e quante distanze per giro.
({int giri, int distanze})? strutturaPiramide(List<DatiSerie> gruppo) {
  final n = gruppo.length;
  final primo = gruppo.first;
  if (n < 2 ||
      gruppo.any(
        (s) =>
            s.ripetute != 1 ||
            s.distanzaM == null ||
            !_stessiAttributi(s, primo),
      )) {
    return null;
  }
  for (var p = 2; p <= n; p++) {
    if (n % p != 0) continue;
    var periodico = true;
    for (var i = p; i < n && periodico; i++) {
      periodico = gruppo[i].distanzaM == gruppo[i % p].distanzaM;
    }
    if (periodico) return (giri: n ~/ p, distanze: p);
  }
  return null;
}

/// Quante serie, all'inizio di [gruppo], si ripetono identiche fino in
/// fondo (il corpo di un "2x"); la lunghezza del gruppo se non si ripete.
int periodoGruppo(List<DatiSerie> gruppo) {
  final n = gruppo.length;
  for (var p = 1; p < n; p++) {
    if (n % p != 0) continue;
    var periodico = true;
    for (var i = p; i < n && periodico; i++) {
      periodico = stessaSerie(gruppo[i], gruppo[i % p]);
    }
    if (periodico) return p;
  }
  return n;
}

/// "10'", "5'30''", "30''": i secondi con due apici, perché le
/// virgolette nel testo sono delle note.
String _durataTesto(int secondi) {
  if (secondi < 60) return "$secondi''";
  final minuti = secondi ~/ 60;
  final resto = secondi % 60;
  return resto == 0
      ? "$minuti'"
      : "$minuti'${resto.toString().padLeft(2, '0')}''";
}

/// Stile, esecuzione, zona, passo e ripartenza, come parole del testo.
List<String> _dati(DatiSerie s) => [
  // Nel lavoro di pallanuoto e a secco lo stile non conta: "libero" è
  // quello che si legge quando non è scritto.
  if (s.stile != 'libero' || !_senzaStile.contains(s.esecuzione))
    _sigleStile[s.stile] ?? s.stile,
  ?_paroleEsecuzione[s.esecuzione],
  ?s.zona,
  if (s.passoObiettivoS case final p?) formatTempoCompatto(p),
  if (s.ripartenzaS case final r?) '@${formatTempoCompatto(r)}',
];

/// Attrezzi (parole note da sole, il resto fra quadre) e note fra
/// virgolette.
List<String> _attrezziENote(DatiSerie s) {
  final attrezzatura = _pieno(s.attrezzatura);
  final nota = _pieno(s.note);
  final parti = attrezzatura?.split(', ');
  return [
    if (attrezzatura != null)
      if (parti!.every((p) => _attrezzi[p] == p))
        ...parti
      else
        '[${attrezzatura.replaceAll(']', ')')}]',
    if (nota != null) '"${nota.replaceAll('"', "'").replaceAll('\n', ' ')}"',
  ];
}

String _rigaSerie(DatiSerie s) {
  final durata = s.durataS;
  final distanza = s.distanzaM ?? 0;
  final volume = durata != null
      ? (s.ripetute == 1
            ? _durataTesto(durata)
            : '${s.ripetute}x${_durataTesto(durata)}')
      : (s.ripetute == 1 && distanza >= 25
            ? '$distanza'
            : '${s.ripetute}x$distanza');
  return [
    volume,
    ..._dati(s),
    if (s.recuperoS case final r?) 'r$r',
    ..._attrezziENote(s),
  ].join(' ');
}

String? _rigaPiramide(List<DatiSerie> gruppo) {
  final struttura = strutturaPiramide(gruppo);
  if (struttura == null) return null;
  final n = gruppo.length;
  final p = struttura.distanze;
  final r1 = gruppo.first.recuperoS;
  final r2 = struttura.giri > 1 ? gruppo[p - 1].recuperoS : r1;
  if (r1 == null && r2 != null) return null;
  for (var i = 0; i < n; i++) {
    final atteso = i % p == p - 1 && i < n - 1 ? r2 : r1;
    if (gruppo[i].recuperoS != atteso) return null;
  }
  final sequenza = gruppo.take(p).map((s) => s.distanzaM).join('-');
  return [
    if (struttura.giri > 1) '${struttura.giri}x($sequenza)' else sequenza,
    ..._dati(gruppo.first),
    if (r1 != null) 'r$r1',
    if (r2 != null && r2 != r1) 'r$r2',
    ..._attrezziENote(gruppo.first),
  ].join(' ');
}

/// Le serie di un allenamento (nell'ordine) scritte come testo, con un
/// titolo per ogni blocco: rilette con [interpretaAllenamento] danno le
/// stesse serie, gruppi compresi.
String testoDaSerie(List<DatiSerie> serie) {
  final righe = <String>[];
  String? blocco;
  for (final gruppo in raggruppaPerPiramide(serie)) {
    final primo = gruppo.first;
    if (primo.blocco != blocco) {
      if (righe.isNotEmpty && righe.last.isNotEmpty) righe.add('');
      righe.add(_nomiBlocco[primo.blocco] ?? primo.blocco);
      blocco = primo.blocco;
    }
    if (gruppo.length == 1) {
      righe.add(_rigaSerie(primo));
      continue;
    }
    final piramide = _rigaPiramide(gruppo);
    if (piramide != null) {
      righe.add(piramide);
      continue;
    }
    final periodo = periodoGruppo(gruppo);
    if (righe.isNotEmpty &&
        righe.last.isNotEmpty &&
        !_nomiBlocco.containsValue(righe.last)) {
      righe.add('');
    }
    righe
      ..add('${gruppo.length ~/ periodo}x')
      ..addAll(gruppo.take(periodo).map(_rigaSerie))
      ..add('');
  }
  while (righe.isNotEmpty && righe.last.isEmpty) {
    righe.removeLast();
  }
  return righe.join('\n');
}
