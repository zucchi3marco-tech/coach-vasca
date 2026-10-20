import '../../../core/utils/pace_format.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import 'dettato_allenamento.dart';
import 'riordino_serie.dart';
import 'serie.dart';
import 'volume_allenamento.dart';

/// Scrivere un allenamento come su un foglio, una serie per riga — idea
/// presa dall'editor di Swimtraxx Hub (richiesta del coach 2026-10-08):
/// il testo si interpreta qui, subito e senza AI, mentre lo si scrive.
///
/// ```text
/// Riscaldamento
/// 400 mix A1
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
///   mix), esecuzione (gambe, braccia, pull, tecnica, remate, test; per
///   la pallanuoto palleggio, tiri, uomo in +, uomo in -, gioco da
///   schierati, schemi, partita, tecnico-tattico; a-secco), come nuotarla
///   (sciolto, lungo, progressione: finisce nella nota), passo sui 100 "1:25",
///   ripartenza "@1:30", recupero "r15" (o "r1:00"),
///   attrezzi (pinne, palette, …, o "[pinne corte]"), note fra
///   virgolette. Una parola che non si riconosce finisce nelle note.
/// - Una riga con solo un recupero ("rec 2'", "recupero 1:30", "pausa
///   2'", "r30''") è il riposo dopo la serie sopra, prima della
///   successiva (`recuperoDopoS`): non è una serie e non conta nel
///   volume, solo nella durata.
/// - Per chi sono le serie ([Destinatari]): una riga da sola "Portieri",
///   "Movimento", "Rossi, Bianchi" (gli atleti del gruppo) vale per le
///   righe sotto, fino alla riga vuota, al prossimo titolo di blocco o a
///   "Tutti"; "Tutti tranne Rossi" fino al prossimo titolo o "Tutti";
///   davanti a una serie ("Portieri: 10' tiri", "Rossi: 4x50 gambe") vale
///   solo per quella riga, anche dentro un "2x". Anche "Centroboa",
///   "Marcatori", "Esterni".
/// - Lavori in parallelo (richiesta del coach 2026-10-15, rivista il
///   2026-10-17): il lavoro di "Portieri", "Centroboa", "Rossi,
///   Bianchi"... si fa **insieme** al paragrafo di tutti subito sopra (le
///   righe fino alla riga vuota prima), nello stesso tempo: è un momento
///   (`momentoId`), e ognuno fa la sua colonna (vedi `serieDellAtleta`).
///   Più gruppi uno sotto l'altro vanno con lo stesso paragrafo. Un
///   titolo di blocco, una riga "Tutti" (anche "Tutti tranne Rossi") o,
///   dopo una riga vuota, una riga di tutti aprono un momento nuovo: da lì
///   si riparte insieme.
///
///   ```text
///   Principale
///   3x
///   50 sl A1              ← tutti, e anche i centroboa
///   6x100 sl B1 @1:40
///
///   10' palleggio         ← tutti, mentre…
///   10' tiri A2
///
///   Centroboa: 20' gambe  ← …i centroboa fanno le gambe
///
///   30' tecnico-tattico   ← di nuovo tutti insieme
///   ```
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
    this.recuperoDopoS,
    this.destinatari = Destinatari.tutti,
    this.momentoId,
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

  @override
  final int? recuperoDopoS;

  @override
  final Destinatari destinatari;

  /// Un segnaposto ("m1", "m2"…) comune alle serie di un momento in
  /// parallelo, come [piramideId]; null fuori dai momenti.
  @override
  final String? momentoId;

  // Una serie scritta non è ancora stata fatta.
  @override
  String? get esito => null;
  @override
  int? get metriFatti => null;
  @override
  int? get secondiFatti => null;

  int get distanzaTotaleM => ripetute * (distanzaM ?? 0);

  SerieScritta _conGruppo(String? gruppo) => _copia(gruppo: gruppo);

  SerieScritta _conRecuperoDopo(int secondi) =>
      _copia(gruppo: piramideId, recuperoDopo: secondi);

  SerieScritta _conDestinatari(Destinatari perChi) =>
      _copia(gruppo: piramideId, destinatari: perChi);

  SerieScritta _nelMomento(String? momento) =>
      _copia(gruppo: piramideId, momento: (id: momento));

  SerieScritta _copia({
    String? gruppo,
    int? recuperoDopo,
    Destinatari? destinatari,
    ({String? id})? momento,
  }) => SerieScritta(
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
    recuperoDopoS: recuperoDopo ?? recuperoDopoS,
    destinatari: destinatari ?? this.destinatari,
    momentoId: momento == null ? momentoId : momento.id,
  );
}

enum TipoRiga { vuota, titolo, giri, serie, recupero, destinatari, errore }

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
    this.recuperoS,
    this.destinatari,
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

  /// Per una riga di recupero fra le serie: quanto, in secondi.
  final int? recuperoS;

  /// Per una riga "Portieri", "Rossi, Bianchi"...: per chi sono le serie
  /// da qui in giù; per una serie che lo dice davanti ("Rossi: 4x50
  /// gambe"), per chi è. Le serie lo hanno comunque in `destinatari`.
  final Destinatari? destinatari;
}

class AllenamentoScritto {
  const AllenamentoScritto({required this.righe, required this.serie});

  final List<RigaScritta> righe;

  /// Tutte le serie, nell'ordine, con i "2x" già ripetuti.
  final List<SerieScritta> serie;

  /// I metri del gruppo (un giocatore di movimento): senza il lavoro dei
  /// soli portieri né quello di alcuni atleti, e nei momenti in parallelo
  /// solo la colonna di tutti.
  int get metri => volumeDi(serieDelGruppo(serie)).metri;

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
  'mix': 'misti',
  'mi': 'misti',
  'misto': 'misti',
  'mx': 'misti',
  'misti': 'misti',
};

const _sigleStile = {
  'libero': 'sl',
  'dorso': 'do',
  'rana': 'ra',
  'delfino': 'df',
  'misti': 'mix',
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
  'palleggio': 'palleggio',
  'palleggi': 'palleggio',
  'tiri': 'tiri',
  'tiro': 'tiri',
  'uomo-in-più': 'uomo in più',
  'superiorità': 'uomo in più',
  'superiorita': 'uomo in più',
  'uomo-in-meno': 'uomo in meno',
  'inferiorità': 'uomo in meno',
  'inferiorita': 'uomo in meno',
  'gioco-da-schierati': 'gioco da schierati',
  'schierati': 'gioco da schierati',
  'schemi': 'schemi',
  'schema': 'schemi',
  'partita': 'partita',
  'partitella': 'partita',
  'test': 'test',
};

const _paroleEsecuzione = {
  'gambe': 'gambe',
  'braccia': 'braccia',
  'pull': 'pull',
  'tecnica': 'tecnica',
  'remate': 'remate',
  'pallanuoto tecnico-tattico': 'tecnico-tattico',
  'a secco': 'a-secco',
  'palleggio': 'palleggio',
  'tiri': 'tiri',
  // Si rileggono con [_frasiEsecuzione].
  'uomo in più': 'uomo in più',
  'uomo in meno': 'uomo in meno',
  'gioco da schierati': 'gioco da schierati',
  'schemi': 'schemi',
  'partita': 'partita',
  'test': 'test',
};

/// Come nuotare la serie ("400 sciolto", "4x200 progressione"): parole
/// riconosciute, che finiscono nella nota così si combinano con tutto il
/// resto ("400 gambe sciolto"). Richiesta del coach 2026-10-08.
const _paroleModo = {
  'sciolto',
  'sciolti',
  'sciolta',
  'lungo',
  'lunghi',
  'lunga',
  'progressione',
  'progressivo',
  'progressivi',
};

/// Esecuzioni di più parole, come si scrivono o si dicono ("uomo in +",
/// "uomo in meno", "gioco da schierati"): diventano una parola sola prima
/// di dividere la riga. Prima e dopo ci vuole uno spazio (o l'inizio o la
/// fine della riga), così "uomo-in-più" scritto attaccato resta com'è.
final _frasiEsecuzione = <(RegExp, String)>[
  (
    RegExp(
      r'(?<![^\s,;])uomo\s*(?:in\s*)?(?:\+|più|piu)(?![^\s,;])',
      caseSensitive: false,
    ),
    'uomo-in-più',
  ),
  (
    RegExp(
      r'(?<![^\s,;])uomo\s*(?:in\s*)?(?:-|–|meno)(?![^\s,;])',
      caseSensitive: false,
    ),
    'uomo-in-meno',
  ),
  (
    RegExp(
      r'(?<![^\s,;])gioco\s+da\s+schierati(?![^\s,;])',
      caseSensitive: false,
    ),
    'gioco-da-schierati',
  ),
];

String _uniscFrasi(String t) {
  var risultato = t;
  for (final (frase, parola) in _frasiEsecuzione) {
    risultato = risultato.replaceAll(frase, parola);
  }
  return risultato;
}

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

/// Parole di contorno ("400 m stile libero con pinne", "20 secondi di
/// recupero"): si saltano.
const _riempitivi = {
  'm',
  'mt',
  'metri',
  'stile',
  'a',
  'con',
  'e',
  'di',
  'in',
  'zona',
  'secondi',
  'sec',
};

/// Parole dette prima (o dopo) un tempo, come si parla a bordo vasca:
/// "recupero 20", "ripartenza 1:30", "passo 1:25".
enum _Tempo { recupero, ripartenza, passo }

const _paroleTempo = {
  'rec': _Tempo.recupero,
  'recupero': _Tempo.recupero,
  'ripartenza': _Tempo.ripartenza,
  'partenza': _Tempo.ripartenza,
  'ogni': _Tempo.ripartenza,
  'passo': _Tempo.passo,
};

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

/// Le parole di una riga che è solo un recupero fra le serie.
const _paroleRecuperoDopo = {'rec', 'recupero', 'pausa', 'riposo'};

/// Una riga che è solo un recupero ("rec 2'", "pausa 1:30", "2' di
/// recupero", "r30''"): i secondi, o null se la riga è altro.
int? _leggiRecuperoDopo(String riga) {
  final token = [
    for (final t in _normalizza(riga.toLowerCase()).split(RegExp(r'\s+')))
      if (t.isNotEmpty && t != 'di' && t != ':') t,
  ];
  double? secondi;
  if (token.length == 1) {
    final m = _rxRecupero.firstMatch(token.single);
    if (m != null) secondi = _tempo(m[1]!);
  } else if (token.length == 2) {
    if (_paroleRecuperoDopo.contains(token.first)) {
      secondi = _tempo(token.last);
    } else if (_paroleRecuperoDopo.contains(token.last) &&
        // "400 recupero" non è un recupero di 400 secondi: dopo il
        // numero serve l'unità ("2'", "30''").
        !RegExp(r'^\d+$').hasMatch(token.first)) {
      secondi = _tempo(token.first);
    }
  }
  if (secondi == null || secondi <= 0) return null;
  return secondi.round();
}

// ---------------------------------------------------------------------------
// Per chi sono le serie

/// Le parole che dicono un gruppo di atleti: il ruolo (null: tutti).
const _gruppiDestinatari = <String, String?>{
  'tutti': null,
  'tutte': null,
  'portieri': 'portiere',
  'portiere': 'portiere',
  'movimento': 'movimento',
  'centroboa': 'centroboa',
  'centriboa': 'centroboa',
  'boe': 'centroboa',
  'marcatori': 'marcatore',
  'marcatore': 'marcatore',
  'difensori': 'marcatore',
  'esterni': 'esterno',
  'esterno': 'esterno',
};

/// Parole che si possono mettere davanti, e si saltano: "solo i
/// portieri", "per i giocatori di movimento".
const _davantiDestinatari = {
  'solo',
  'soltanto',
  'per',
  'i',
  'il',
  'gli',
  'la',
  'le',
  'lo',
  'giocatori',
  'di',
};

/// "Tutti tranne Rossi", "senza Rossi".
const _paroleTranne = {
  'tranne',
  'senza',
  'eccetto',
  'escluso',
  'esclusa',
  'esclusi',
  'meno',
};

typedef _LetturaDestinatari = ({
  Destinatari? destinatari,
  String? problema,
  String resto,
});

/// Se la riga [t] dice per chi sono le serie: per chi ([destinatari]) e
/// cosa resta della riga dopo ([resto], una serie, o vuoto se la riga è
/// solo questo). null se la riga non lo dice. [attuali] sono i
/// destinatari delle righe sopra: "tranne Rossi" toglie Rossi da quelli.
_LetturaDestinatari? _leggiDestinatari(
  String t,
  List<Atleta> atleti,
  Destinatari attuali,
) {
  // "Rossi: 4x50 gambe", "Portieri: 10' tiri": prima dei due punti, senza
  // cifre (in "@1:30" i due punti sono di un tempo).
  final duePunti = RegExp(r'^([^\d:]+):\s*(.*)$').firstMatch(t);
  var testa = duePunti?[1]?.trim() ?? t.trim();
  var resto = duePunti?[2]?.trim() ?? '';
  final conDuePunti = duePunti != null;

  final parole = testa.toLowerCase().split(RegExp(r'\s+'));
  var i = 0;
  while (i < parole.length && _davantiDestinatari.contains(parole[i])) {
    i++;
  }
  final primaParola = parole.isEmpty ? '' : parole.first;
  final parolaGruppo = i < parole.length ? parole[i] : null;
  final gruppo = _gruppiDestinatari.containsKey(parolaGruppo);

  // "Portieri 10' tiri", senza i due punti: il gruppo e poi una serie.
  if (!conDuePunti && gruppo && i + 1 < parole.length) {
    final dopo = testa.split(RegExp(r'\s+')).sublist(i + 1).join(' ');
    if (RegExp(r'^\d').hasMatch(dopo)) {
      testa = testa.split(RegExp(r'\s+')).take(i + 1).join(' ');
      resto = dopo;
    }
  }

  // Un nome non ha cifre: senza un gruppo, una riga con dei numeri è una
  // serie.
  if (!gruppo && RegExp(r'\d').hasMatch(testa)) return null;
  final perChiAvanti =
      gruppo ||
      const {'solo', 'soltanto', 'per'}.contains(primaParola) ||
      _paroleTranne.contains(primaParola);

  // Gli atleti dopo "tranne" o, senza gruppo, tutta la testa.
  final pezzi = testa.split(RegExp(r'\s+'));
  final tranneA = pezzi.indexWhere(
    (p) => _paroleTranne.contains(p.toLowerCase()),
  );
  final String? ruolo;
  final List<String> nomi;
  final bool tranne;
  if (gruppo) {
    // Solo "tutti", "portieri"... e semmai "tranne ...": niente altro.
    if (tranneA == -1 && pezzi.length != i + 1) return null;
    if (tranneA != -1 && tranneA != i + 1) return null;
    ruolo = _gruppiDestinatari[parolaGruppo];
    tranne = tranneA != -1;
    nomi = tranne ? _nomiDa(pezzi.sublist(tranneA + 1).join(' ')) : const [];
    if (tranne && nomi.isEmpty) return null;
  } else if (tranneA != -1) {
    // "Tranne Rossi": i destinatari di sopra, senza Rossi.
    if (pezzi
        .take(tranneA)
        .any((p) => !_davantiDestinatari.contains(p.toLowerCase()))) {
      return null;
    }
    ruolo = attuali.soloAtleti.isEmpty ? attuali.ruolo : null;
    tranne = true;
    nomi = _nomiDa(pezzi.sublist(tranneA + 1).join(' '));
    if (nomi.isEmpty) return null;
  } else {
    ruolo = null;
    tranne = false;
    nomi = _nomiDa(pezzi.skip(i).join(' '));
    if (nomi.isEmpty) return null;
  }

  final trovati = <String>[];
  final mancanti = <String>[];
  for (final nome in nomi) {
    final atleta = abbinaAtleta(nome, atleti);
    if (atleta == null) {
      mancanti.add(nome);
    } else if (!trovati.contains(atleta.id)) {
      trovati.add(atleta.id);
    }
  }
  if (mancanti.isNotEmpty) {
    // Dei nomi da soli che non sono atleti: la riga parla d'altro (sarà
    // una serie, o non si capisce come prima).
    if (!perChiAvanti && !tranne && trovati.isEmpty) return null;
    return (
      destinatari: null,
      problema: mancanti.length == 1
          ? 'Non trovo «${mancanti.single}» fra gli atleti del gruppo'
          : 'Non trovo ${mancanti.map((n) => '«$n»').join(', ')} fra gli '
                'atleti del gruppo',
      resto: resto,
    );
  }
  final Destinatari destinatari;
  if (!gruppo && !tranne) {
    destinatari = Destinatari(soloAtleti: trovati);
  } else {
    final esclusi = [
      if (!gruppo && attuali.soloAtleti.isEmpty) ...attuali.tranneAtleti,
      for (final id in trovati)
        if (gruppo || !attuali.tranneAtleti.contains(id)) id,
    ];
    destinatari = Destinatari(ruolo: ruolo, tranneAtleti: esclusi);
  }
  return (destinatari: destinatari, problema: null, resto: resto);
}

/// "Rossi, Bianchi e Verdi" → i tre nomi.
List<String> _nomiDa(String testo) => [
  for (final n in testo.split(RegExp(r'\s*(?:,|/|\+|&|\s+e\s+|\s+ed\s+)\s*')))
    if (n.trim().replaceAll(RegExp(r'[.;]+$'), '') case final pulito
        when pulito.isNotEmpty)
      pulito,
];

/// La riga che dice per chi sono le serie sotto: "Tutti", "Portieri",
/// "Rossi, Bianchi", "Tutti tranne Rossi". null se nessuno degli atleti
/// è fra quelli che si conoscono.
String? _testaDestinatari(Destinatari d, List<Atleta> atleti) {
  String? nomi(List<String> ids) {
    final scritti = [
      for (final id in ids)
        if (atleti.where((a) => a.id == id).firstOrNull case final a?)
          nomeBreve(a, atleti),
    ];
    return scritti.isEmpty ? null : scritti.join(', ');
  }

  if (d.soloAtleti.isNotEmpty) return nomi(d.soloAtleti);
  final gruppo = nomiGruppoRuolo[d.ruolo] ?? 'Tutti';
  if (d.tranneAtleti.isEmpty) return gruppo;
  final esclusi = nomi(d.tranneAtleti);
  return esclusi == null ? gruppo : '$gruppo tranne $esclusi';
}

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

/// "90", "1:30", "1:30.5", "1'30" → secondi; anche "1.30", come lo
/// scrive a volte la dettatura del browser.
double? _tempo(String t) {
  if (RegExp(r'^\d+$').hasMatch(t)) return double.parse(t);
  final conPunto = RegExp(r'^(\d+)\.(\d{2})$').firstMatch(t);
  if (conPunto != null) {
    return int.parse(conPunto[1]!) * 60 + double.parse(conPunto[2]!);
  }
  final mmss = _rxMinutiSecondi.firstMatch(t);
  if (mmss != null) {
    return int.parse(mmss[1]!) * 60 +
        double.parse(mmss[2]!.replaceAll(',', '.'));
  }
  return _durata(t)?.toDouble();
}

/// Mette insieme quello che si scrive (o si detta) staccato: "8 x 100",
/// "8 volte 100", "8 da 100", "8 per 100" → "8x100", "50 - 100" →
/// "50-100", "10 min" → "10min".
String _normalizza(String t) => t
    .replaceAllMapped(
      RegExp(r'(\d)\s*(?:[xX×]|[vV]olte|[dD]a|[pP]er)\s*(?=[\d(])'),
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
    for (final t in _normalizza(_uniscFrasi(resto)).split(RegExp(r'\s+')))
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
  final modi = <String>[];
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
    if (_paroleTempo[basso] case final tipo?) {
      // "recupero 20": il tempo viene dopo; "20 di recupero": era il
      // numero appena prima, rimasto fra le parole non capite.
      final dopo = i + 1 < token.length
          ? _tempo(token[i + 1].toLowerCase())
          : null;
      double? prima;
      if (dopo == null && ignote.isNotEmpty) {
        prima = _tempo(ignote.last);
        if (prima != null) ignote.removeLast();
      }
      final valore = dopo ?? prima;
      if (dopo != null) i++;
      if (valore != null) {
        switch (tipo) {
          case _Tempo.recupero:
            recuperi.add(valore.round());
          case _Tempo.ripartenza:
            ripartenza = valore;
          case _Tempo.passo:
            passo = valore;
        }
      }
      continue;
    }
    if (_riempitivi.contains(basso)) continue;
    if (_paroleModo.contains(basso)) {
      modi.add(basso);
      continue;
    }
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

  final tutteLeNote = [
    if (modi.isNotEmpty) modi.join(' '),
    ...note,
    if (ignote.isNotEmpty) ignote.join(' '),
  ];
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

/// Una frase dettata ("riscaldamento 400 misti, poi 8 da 100 stile
/// libero B1 recupero 20") divisa in righe del testo: un pezzo per ogni
/// pausa (il dettatore le separa con un a capo), virgola, punto, "poi" o
/// "a capo" detto. Virgole e punti fra due cifre ("1.30") restano.
///
/// Ogni pezzo passa da [normalizzaDettato] (numeri in lettere, "8%",
/// tempi e zone a parole). Un pezzo che da solo non è una serie e non
/// comincia con un numero ("B1 recupero 20", detto dopo una pausa) si
/// attacca alla serie della riga prima — ma non un "per chi" ("portieri",
/// "Rossi e Bianchi", con gli [atleti] del gruppo): quello è una riga.
String righeDaDettato(String dettato, {List<Atleta> atleti = const []}) {
  final righe = <String>[];
  final pezzi = dettato.split(
    RegExp(
      r'\n|;|[,.](?!\d)|\s+(?:e\s+)?poi\s+|\s+(?:a capo|nuova riga)\s+',
      caseSensitive: false,
    ),
  );
  for (final grezzo in pezzi) {
    final pezzo = normalizzaDettato(
      grezzo.trim().replaceFirst(
        RegExp(r'^(?:e\s+)?poi\b\s*', caseSensitive: false),
        '',
      ),
    ).trim();
    if (pezzo.isEmpty) continue;
    if (righe.isNotEmpty &&
        !RegExp(r'^\d').hasMatch(pezzo) &&
        _continuaLaSerie(pezzo, righe.last, atleti)) {
      righe.last = '${righe.last} $pezzo';
    } else {
      righe.add(pezzo);
    }
  }
  return righe.join('\n');
}

/// [pezzo] da solo non si capisce e [prima] è una serie: è il seguito.
/// Anche "recupero 20" detto dopo una serie è il suo recupero fra le
/// ripetute; per il recupero fra due serie si dice "pausa".
bool _continuaLaSerie(String pezzo, String prima, List<Atleta> atleti) {
  if (interpretaAllenamento(prima, atleti: atleti).righe.single.tipo !=
      TipoRiga.serie) {
    return false;
  }
  if (_leggiRecuperoDopo(pezzo) != null) {
    return RegExp(r'^rec', caseSensitive: false).hasMatch(pezzo.trim());
  }
  return interpretaAllenamento(pezzo, atleti: atleti).righe.single.tipo ==
      TipoRiga.errore;
}

/// Interpreta una riga sola, come quella del pannello "Aggiungi serie":
/// le sue serie (più d'una per una piramide, con lo stesso `piramideId`
/// segnaposto) o `null` se non c'è una serie da leggere. Anche con
/// davanti per chi è ("Portieri: 10' tiri", "Rossi: 4x50 gambe", con gli
/// [atleti] del gruppo).
List<SerieScritta>? leggiRigaSerie(
  String riga, {
  required String blocco,
  List<Atleta> atleti = const [],
}) {
  var testo = riga.trim();
  if (testo.isEmpty) return null;
  var perChi = Destinatari.tutti;
  final destinatari = _leggiDestinatari(testo, atleti, perChi);
  if (destinatari != null) {
    if (destinatari.problema != null || destinatari.resto.isEmpty) {
      return null;
    }
    perChi = destinatari.destinatari!;
    testo = destinatari.resto;
  }
  final lettura = _leggiSerie(testo, blocco);
  if (lettura.problema != null) return null;
  final serie = [
    for (final s in lettura.serie)
      perChi.perTutti ? s : s._conDestinatari(perChi),
  ];
  return serie.length > 1 ? [for (final s in serie) s._conGruppo('g1')] : serie;
}

/// Interpreta tutto il testo di un allenamento, riga per riga. Gli
/// [atleti] del gruppo servono a capire i nomi delle righe "per chi"
/// ("Rossi, Bianchi", "Tutti tranne Rossi").
AllenamentoScritto interpretaAllenamento(
  String testo, {
  String bloccoIniziale = 'principale',
  List<Atleta> atleti = const [],
}) {
  final righe = <RigaScritta>[];
  final serie = <SerieScritta>[];
  var blocco = bloccoIniziale;
  var gruppi = 0;

  // Per chi sono le serie da qui in giù: fino al prossimo titolo di
  // blocco o alla prossima riga "per chi"; quelle di un gruppo
  // ("Portieri") fino alla riga vuota, poi di nuovo [perChiBase].
  var perChi = Destinatari.tutti;
  var perChiBase = Destinatari.tutti;
  // Le serie scritte dall'ultima riga "per chi" di un gruppo: la riga
  // vuota la chiude solo dopo almeno una.
  var sottoIlGruppo = 0;

  // Il momento in corso: le serie per chi è diverso si fanno insieme.
  // Un titolo, una riga "Tutti" o un paragrafo nuovo di tutti (dopo una
  // riga vuota) ne aprono uno nuovo; il lavoro di un gruppo si unisce al
  // momento in corso, cioè al paragrafo di tutti subito sopra (richiesta
  // del coach 2026-10-17: "Centroboa: 20' gambe" sotto "10' palleggio,
  // 10' tiri" vale solo per quei 20 minuti).
  var momento = 1;
  var dopoRigaVuota = false;

  // Una riga di tutti che apre un paragrafo nuovo apre anche un momento.
  void rigaDiTutti() {
    if (dopoRigaVuota) momento++;
    dopoRigaVuota = false;
  }

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
      // Il lavoro di un gruppo finisce alla riga vuota: sotto si torna
      // insieme, salvo un'altra riga "Portieri", "Centroboa"...
      if (!perChi.base && sottoIlGruppo > 0) perChi = perChiBase;
      dopoRigaVuota = true;
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
      perChi = Destinatari.tutti;
      perChiBase = Destinatari.tutti;
      momento++;
      dopoRigaVuota = false;
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
      if (perChi.base) {
        rigaDiTutti();
      } else {
        dopoRigaVuota = false;
      }
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

    final pausa = _leggiRecuperoDopo(t);
    if (pausa != null) {
      // Il recupero va dopo la serie scritta sopra: dentro un "2x" quella
      // del gruppo (e si ripete a ogni giro), altrimenti l'ultima.
      final destinazione = rigaGiro != null ? corpo : serie;
      if (destinazione.isEmpty) {
        righe.add(
          RigaScritta(
            testo: grezza,
            tipo: TipoRiga.errore,
            problema: rigaGiro != null
                ? 'Il recupero va dopo una serie del gruppo'
                : 'Il recupero va dopo una serie',
            blocco: blocco,
          ),
        );
        continue;
      }
      destinazione.last = destinazione.last._conRecuperoDopo(pausa);
      righe.add(
        RigaScritta(
          testo: grezza,
          tipo: TipoRiga.recupero,
          recuperoS: pausa,
          giri: rigaGiro == null ? 1 : volte,
          blocco: blocco,
        ),
      );
      continue;
    }

    // "Portieri", "Rossi, Bianchi": per chi sono le serie sotto (non
    // chiude un "2x"); "Portieri: 10' tiri": per chi è questa.
    var perQuesta = perChi;
    final destinatari = _leggiDestinatari(t, atleti, perChi);
    if (destinatari != null) {
      if (destinatari.problema != null) {
        righe.add(
          RigaScritta(
            testo: grezza,
            tipo: TipoRiga.errore,
            problema: destinatari.problema,
            blocco: blocco,
          ),
        );
        continue;
      }
      if (destinatari.resto.isEmpty) {
        perChi = destinatari.destinatari!;
        // "Tutti" (anche "tranne Rossi"): si riparte insieme. "Portieri",
        // "Centroboa", "Rossi, Bianchi": in parallelo con il paragrafo di
        // tutti sopra (o con il gruppo sopra), fino alla riga vuota.
        if (perChi.base) {
          momento++;
          perChiBase = perChi;
        } else {
          sottoIlGruppo = 0;
        }
        dopoRigaVuota = false;
        righe.add(
          RigaScritta(
            testo: grezza,
            tipo: TipoRiga.destinatari,
            destinatari: perChi,
            giri: rigaGiro == null ? 1 : volte,
            blocco: blocco,
          ),
        );
        continue;
      }
      perQuesta = destinatari.destinatari!;
      t = destinatari.resto;
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
    // "Centroboa: 20' gambe", anche dopo una riga vuota: con il paragrafo
    // sopra. Una riga di tutti dopo una riga vuota: un paragrafo nuovo.
    if (perQuesta.base) {
      rigaDiTutti();
    } else {
      dopoRigaVuota = false;
    }
    if (!perChi.base) sottoIlGruppo++;
    final lette = [
      for (final s in lettura.serie)
        (perQuesta.perTutti ? s : s._conDestinatari(perQuesta))._nelMomento(
          'm$momento',
        ),
    ];
    righe.add(
      RigaScritta(
        testo: grezza,
        tipo: TipoRiga.serie,
        serie: lette,
        paroleIgnote: lettura.ignote,
        giri: rigaGiro == null ? 1 : volte,
        blocco: blocco,
        // Solo se la riga lo dice da sé ("Rossi: 4x50 gambe").
        destinatari: destinatari == null ? null : perQuesta,
      ),
    );
    if (rigaGiro != null) {
      corpo.addAll(lette);
    } else if (lette.length > 1) {
      final gruppo = 'g${++gruppi}';
      serie.addAll([for (final s in lette) s._conGruppo(gruppo)]);
    } else {
      serie.addAll(lette);
    }
  }
  chiudiGiro();

  // Un momento è in parallelo solo con almeno due colonne: le altre serie
  // restano una dopo l'altra, come prima.
  final colonne = <String, Set<Destinatari>>{};
  for (final s in serie) {
    (colonne[s.momentoId!] ??= {}).add(s.destinatari);
  }
  String? vero(String? m) => (colonne[m]?.length ?? 0) > 1 ? m : null;
  List<SerieScritta> rifai(List<SerieScritta> elenco) => [
    for (final s in elenco) s._nelMomento(vero(s.momentoId)),
  ];
  return AllenamentoScritto(
    righe: [
      for (final r in righe)
        r.serie.isEmpty
            ? r
            : RigaScritta(
                testo: r.testo,
                tipo: r.tipo,
                serie: rifai(r.serie),
                paroleIgnote: r.paroleIgnote,
                problema: r.problema,
                giri: r.giri,
                blocco: r.blocco,
                recuperoS: r.recuperoS,
                destinatari: r.destinatari,
              ),
    ],
    serie: rifai(serie),
  );
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
    _pieno(a.note) == _pieno(b.note) &&
    a.destinatari == b.destinatari;

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

/// La riga di recupero dopo una serie: "rec 2'", "rec 30''".
String _rigaRecuperoDopo(int secondi) => 'rec ${_durataTesto(secondi)}';

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
  if (s.stile != 'libero' || !esecuzioniSenzaStile.contains(s.esecuzione))
    _sigleStile[s.stile] ?? s.stile,
  ?_paroleEsecuzione[s.esecuzione],
  ?s.zona,
  if (s.passoObiettivoS case final p?) formatTempoCompatto(p),
  if (s.ripartenzaS case final r?) '@${formatTempoCompatto(r)}',
];

/// Attrezzi (parole note da sole, il resto fra quadre) e note fra
/// virgolette — senza, se sono solo parole come "sciolto" ([_paroleModo]).
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
    if (nota != null)
      if (nota.split(' ').every(_paroleModo.contains))
        nota
      else
        '"${nota.replaceAll('"', "'").replaceAll('\n', ' ')}"',
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
  // Un recupero fra un pezzo e l'altro non si scrive in una piramide:
  // allora è un "2x".
  if (gruppo.take(gruppo.length - 1).any((s) => s.recuperoDopoS != null)) {
    return null;
  }
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
/// titolo per ogni blocco: rilette con [interpretaAllenamento] (con gli
/// stessi [atleti]) danno le stesse serie, gruppi compresi.
///
/// Per chi sono: una riga "Portieri", "Rossi, Bianchi"... prima di un
/// gruppo di serie per altri; dentro un "2x" con serie per persone
/// diverse, davanti alla riga ("Rossi: 4x50 gambe"). Una serie solo per
/// atleti che non ci sono più fra gli [atleti] non si scrive.
///
/// I momenti in parallelo: prima di un momento, e dopo, una riga "Tutti"
/// quando sopra nello stesso blocco ci sono già delle serie (così non si
/// unisce a quelle); dentro il momento le serie di tutti che vengono dopo
/// quelle di altri hanno "Tutti:" davanti, perché una riga "Tutti" lo
/// chiuderebbe, nessuna riga vuota prima di un "2x" (aprirebbe un
/// paragrafo nuovo) e, dopo il "2x" di un gruppo, la sua riga "Portieri"
/// di nuovo.
String testoDaSerie(List<DatiSerie> serie, {List<Atleta> atleti = const []}) {
  final righe = <String>[];
  String? blocco;
  var perChi = Destinatari.tutti;
  // A cui si torna dopo la riga vuota che chiude un "2x" di un gruppo.
  var perChiBase = Destinatari.tutti;
  // Dopo una riga "per chi", come dopo un titolo, un "2x" non vuole la
  // riga vuota prima.
  var dopoIntestazione = false;
  // Il momento delle ultime serie scritte, e se dall'ultimo titolo o
  // dall'ultima riga "Tutti" è già stata scritta una serie.
  String? momento;
  var serieScritte = false;

  void aggiungi(String riga) {
    righe.add(riga);
    dopoIntestazione = false;
  }

  void intestazione(String testa) {
    if (righe.isNotEmpty && righe.last.isNotEmpty && !dopoIntestazione) {
      righe.add('');
    }
    aggiungi(testa);
    dopoIntestazione = true;
  }

  for (final gruppo in raggruppaPerPiramide(serie)) {
    final primo = gruppo.first;
    if (primo.blocco != blocco) {
      if (righe.isNotEmpty && righe.last.isNotEmpty) righe.add('');
      aggiungi(_nomiBlocco[primo.blocco] ?? primo.blocco);
      dopoIntestazione = true;
      blocco = primo.blocco;
      perChi = Destinatari.tutti;
      perChiBase = Destinatari.tutti;
      serieScritte = false;
    }
    final uniforme = gruppo.every((s) => s.destinatari == primo.destinatari);

    bool dimenticata(DatiSerie s) =>
        s.destinatari.soloAtleti.isNotEmpty &&
        _testaDestinatari(s.destinatari, atleti) == null;

    if (gruppo.every(dimenticata)) continue;

    // Un momento nuovo, o la fine di uno: si riparte insieme.
    if (primo.momentoId != momento) {
      if (serieScritte) {
        final insieme = uniforme && primo.destinatari.base
            ? primo.destinatari
            : Destinatari.tutti;
        intestazione(_testaDestinatari(insieme, atleti)!);
        perChi = insieme;
        perChiBase = insieme;
        serieScritte = false;
      }
      momento = primo.momentoId;
    }
    // Nello stesso momento, dopo altre sue serie: una riga vuota prima di
    // un "2x" aprirebbe un paragrafo nuovo, cioè un altro momento.
    final dentroIlMomento = momento != null && serieScritte;

    // Le serie di tutti dopo quelle di altri, nello stesso momento.
    final tuttiDavanti =
        momento != null &&
        uniforme &&
        primo.destinatari.base &&
        primo.destinatari != perChi &&
        serieScritte;
    // Davanti alla riga, quando nel "2x" le serie sono per persone
    // diverse; null quando la riga è per chi dice la riga "per chi".
    String? davanti(DatiSerie s) {
      if (tuttiDavanti) return _testaDestinatari(s.destinatari, atleti);
      if (uniforme || s.destinatari == perChi) return null;
      return _testaDestinatari(s.destinatari, atleti);
    }

    // Il lavoro di alcuni fuori dai momenti (una variante per Rossi, i
    // soli portieri) dopo altre serie: senza una riga "Tutti" prima,
    // riletto si unirebbe al paragrafo sopra come lavoro in parallelo, e
    // Rossi perdeva le serie di tutti.
    if (momento == null &&
        serieScritte &&
        uniforme &&
        !primo.destinatari.base &&
        primo.destinatari != perChi) {
      intestazione(_testaDestinatari(Destinatari.tutti, atleti)!);
      perChi = Destinatari.tutti;
      perChiBase = Destinatari.tutti;
    }
    if (uniforme && primo.destinatari != perChi && !tuttiDavanti) {
      intestazione(_testaDestinatari(primo.destinatari, atleti)!);
      perChi = primo.destinatari;
      if (perChi.base) perChiBase = perChi;
    }
    serieScritte = true;
    String riga(DatiSerie s, String testo) =>
        davanti(s) == null ? testo : '${davanti(s)}: $testo';

    final ultimo = gruppo.last.recuperoDopoS;
    if (gruppo.length == 1) {
      aggiungi(riga(primo, _rigaSerie(primo)));
      if (ultimo != null) aggiungi(_rigaRecuperoDopo(ultimo));
      continue;
    }
    final piramide = _rigaPiramide(gruppo);
    if (piramide != null) {
      aggiungi(riga(primo, piramide));
      if (ultimo != null) aggiungi(_rigaRecuperoDopo(ultimo));
      continue;
    }
    final periodo = periodoGruppo(gruppo);
    if (righe.isNotEmpty &&
        righe.last.isNotEmpty &&
        !dopoIntestazione &&
        !dentroIlMomento &&
        !_nomiBlocco.containsValue(righe.last)) {
      righe.add('');
    }
    aggiungi('${gruppo.length ~/ periodo}x');
    for (final s in gruppo.take(periodo)) {
      if (dimenticata(s)) continue;
      aggiungi(riga(s, _rigaSerie(s)));
      if (s.recuperoDopoS case final r?) aggiungi(_rigaRecuperoDopo(r));
    }
    righe.add('');
    // La riga vuota chiude anche il lavoro del gruppo: per altre sue serie
    // la riga "Portieri" va riscritta.
    if (!perChi.base) perChi = perChiBase;
    // Un recupero diverso dopo l'ultimo giro: fuori dal gruppo, sotto la
    // riga vuota.
    if (ultimo != null && ultimo != gruppo[periodo - 1].recuperoDopoS) {
      righe.add(_rigaRecuperoDopo(ultimo));
    }
  }
  while (righe.isNotEmpty && righe.last.isEmpty) {
    righe.removeLast();
  }
  return righe.join('\n');
}

/// Il volume di un blocco del testo e quello di tutto l'allenamento fino
/// alla fine di quel blocco.
typedef VolumeBlocco = ({VolumeAllenamento blocco, VolumeAllenamento totale});

/// Il volume di ogni blocco, per indice della riga che lo apre (il titolo,
/// anche con una serie sulla stessa riga): accanto a "Riscaldamento",
/// "Principale"... nel compilatore. Le serie di un "2x" contano tante
/// volte quanti i giri. Le serie prima del primo titolo non hanno una
/// riga a cui stare accanto: contano solo nel totale. È il volume del
/// gruppo (un giocatore di movimento, [Destinatari.delGruppo]).
Map<int, VolumeBlocco> volumiPerBlocco(AllenamentoScritto scritto) {
  final volumi = <int, VolumeBlocco>{};
  var totale = VolumeAllenamento.zero;
  int? aperto;
  final delGruppo = filtroDellAtleta(scritto.serie, null, 'movimento');
  var delBlocco = VolumeAllenamento.zero;

  void chiudi() {
    if (aperto case final riga?) {
      volumi[riga] = (blocco: delBlocco, totale: totale);
    }
  }

  for (final (i, riga) in scritto.righe.indexed) {
    final titolo = _rxTitolo.firstMatch(riga.testo.trim());
    final apre =
        riga.tipo == TipoRiga.titolo ||
        (titolo != null &&
            _titoliBlocco.containsKey(titolo[1]!.toLowerCase()) &&
            riga.tipo != TipoRiga.vuota);
    if (apre) {
      chiudi();
      aperto = i;
      delBlocco = VolumeAllenamento.zero;
    }
    if (riga.tipo != TipoRiga.serie) continue;
    final dellaRiga = volumeDi(riga.serie.where(delGruppo));
    final volume = VolumeAllenamento(
      metri: riga.giri * dellaRiga.metri,
      secondi: riga.giri * dellaRiga.secondi,
    );
    delBlocco += volume;
    totale += volume;
  }
  chiudi();
  return volumi;
}
