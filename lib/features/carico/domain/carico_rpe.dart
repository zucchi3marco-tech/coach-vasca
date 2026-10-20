import '../../../core/utils/giorni.dart';
import '../../allenamenti/domain/durata_serie.dart';
import '../../allenamenti/domain/serie.dart';
import '../../allenamenti/domain/volume_allenamento.dart' show lunediDi;
import '../../presenze/domain/presenza.dart';

/// La scala CR-10 di Foster, come la si chiede all'atleta a fine seduta:
/// "Quanto è stato duro?". Le voci senza parole stanno fra le due vicine.
const etichetteRpe = <int, String>{
  0: 'Riposo',
  1: 'Facilissimo',
  2: 'Facile',
  3: 'Moderato',
  4: 'Un po\' duro',
  5: 'Duro',
  7: 'Molto duro',
  9: 'Durissimo',
  10: 'Al massimo',
};

/// "7 · Molto duro"; le voci senza parole prendono quella sotto
/// ("6 · Duro").
String descriviRpe(int rpe) {
  for (var v = rpe; v >= 0; v--) {
    final parola = etichetteRpe[v];
    if (parola != null) return '$rpe · $parola';
  }
  return '$rpe';
}

/// Minuti di una partita nel carico: quattro tempi da 8 minuti effettivi
/// con le pause, i time-out e il riscaldamento. Una stima uguale per
/// tutti i convocati: chi gioca poco lo dice con un RPE più basso.
const minutiPartita = 60;

/// Durata di un allenamento senza serie scritte (l'allenatore ha segnato
/// solo le presenze): una seduta tipo di pallanuoto.
const minutiAllenamentoSenzaSerie = 90;

/// RPE stimato quando l'atleta non ha risposto: un allenamento senza
/// serie, e una partita.
const rpeStimatoAllenamento = 5.0;
const rpeStimatoPartita = 6.0;

/// Una seduta a secco senza durata scritta, e il suo RPE stimato quando
/// l'atleta non ha risposto.
const minutiSeccoPredefiniti = 45;
const rpeStimatoSecco = 5.0;

/// RPE che una serie fa percepire, dalla zona di intensità o, senza zona,
/// dal tipo di lavoro. Serve solo a stimare il carico delle sedute senza
/// la risposta dell'atleta: una stima di partenza, da ritoccare con l'uso.
double rpeStimatoSerie(String? zona, String esecuzione) => switch (zona) {
  'A1' => 3,
  'A2' => 4,
  'B1' => 5,
  'B2' => 6,
  'C1' => 7,
  'C' || 'C2' || 'C3' => 8,
  'D' => 9,
  _ => switch (esecuzione) {
    'test' => 8,
    'partita' || 'uomo in più' || 'uomo in meno' => 7,
    'gioco da schierati' || 'tiri' || 'a secco' => 5,
    'palleggio' || 'schemi' || 'pallanuoto tecnico-tattico' => 4,
    _ => 3,
  },
};

/// Una serie come arriva da `serie_per_carico`: quello che serve per la
/// durata e l'intensità.
class SerieCarico implements DatiSerie {
  const SerieCarico({
    required this.allenamentoId,
    required this.ripetute,
    required this.esecuzione,
    this.distanzaM,
    this.durataS,
    this.zona,
    this.recuperoS,
    this.ripartenzaS,
    this.passoObiettivoS,
    this.recuperoDopoS,
    this.destinatari = Destinatari.tutti,
    this.momentoId,
    this.metriFatti,
    this.secondiFatti,
  });

  factory SerieCarico.fromMap(Map<String, dynamic> r) => SerieCarico(
    allenamentoId: r['allenamento_id'] as String,
    ripetute: r['ripetute'] as int,
    esecuzione: r['esecuzione'] as String,
    distanzaM: r['distanza_m'] as int?,
    durataS: r['durata_s'] as int?,
    zona: r['zona'] as String?,
    recuperoS: r['recupero_s'] as int?,
    ripartenzaS: (r['ripartenza_s'] as num?)?.toDouble(),
    passoObiettivoS: (r['passo_obiettivo_s'] as num?)?.toDouble(),
    recuperoDopoS: r['recupero_dopo_s'] as int?,
    destinatari: Destinatari.fromMap(r),
    momentoId: r['momento_id'] as String?,
    metriFatti: r['metri_fatti'] as int?,
    secondiFatti: r['secondi_fatti'] as int?,
  );

  final String allenamentoId;
  @override
  final int ripetute;
  @override
  final String esecuzione;
  @override
  final int? distanzaM;
  @override
  final int? durataS;
  @override
  final String? zona;
  @override
  final int? recuperoS;
  @override
  final double? ripartenzaS;
  @override
  final double? passoObiettivoS;
  @override
  final int? recuperoDopoS;

  /// All'atleta collegato `serie_per_carico` dà solo le sue serie, senza
  /// gli elenchi di atleti: qui resta il ruolo.
  @override
  final Destinatari destinatari;

  /// All'atleta collegato arriva null: le sue serie sono già scelte.
  @override
  final String? momentoId;

  @override
  String get blocco => 'centrale';
  @override
  String get stile => 'libero';
  @override
  String? get attrezzatura => null;
  @override
  String? get note => null;
  @override
  String? get piramideId => null;

  /// Quanto si è fatto di una serie fatta in parte (`serie_per_carico`
  /// non dà le saltate): con i numeri è 'fatta', senza vale tutta.
  @override
  final int? metriFatti;
  @override
  final int? secondiFatti;
  @override
  String? get esito =>
      metriFatti != null || secondiFatti != null ? 'fatta' : null;
}

/// Il carico di una seduta in unità arbitrarie (RPE × minuti, il metodo
/// di Foster), diviso fra acqua, secco e partita.
class CaricoSeduta {
  const CaricoSeduta({
    required this.giorno,
    required this.tipo,
    required this.eventoId,
    required this.minuti,
    required this.rpe,
    required this.stimato,
    this.acqua = 0,
    this.secco = 0,
    this.partita = 0,
  });

  /// La mezzanotte del giorno della seduta.
  final DateTime giorno;

  /// 'allenamento' | 'partita'.
  final String tipo;
  final String eventoId;
  final int minuti;

  /// L'RPE usato: quello dato dall'atleta o, se [stimato], quello
  /// ricavato dalle serie.
  final double rpe;
  final bool stimato;
  final double acqua;
  final double secco;
  final double partita;

  double get totale => acqua + secco + partita;
}

/// Il carico di un allenamento con le sue [serie] (quelle non saltate).
/// Con l'[rpe] dell'atleta: RPE × minuti stimati della seduta. Senza:
/// l'RPE si stima dalle serie, ognuna pesata per quanto dura. I minuti
/// delle serie "a secco" vanno nel secco, il resto nell'acqua.
CaricoSeduta caricoAllenamento({
  required String id,
  required DateTime giorno,
  required Iterable<DatiSerie> serie,
  int? rpe,
}) {
  var secondi = 0.0;
  var secondiSecco = 0.0;
  var rpePesato = 0.0;
  for (final s in serie) {
    final durata = secondiSerie(s);
    secondi += durata;
    if (s.esecuzione == 'a secco') secondiSecco += durata;
    rpePesato += durata * rpeStimatoSerie(s.zona, s.esecuzione);
  }
  final senzaSerie = secondi <= 0;
  final minuti = senzaSerie
      ? minutiAllenamentoSenzaSerie
      : (secondi / 60).round().clamp(1, 600);
  final rpeUsato =
      rpe?.toDouble() ??
      (senzaSerie ? rpeStimatoAllenamento : rpePesato / secondi);
  final totale = rpeUsato * minuti;
  final quotaSecco = senzaSerie ? 0.0 : secondiSecco / secondi;
  return CaricoSeduta(
    giorno: soloData(giorno),
    tipo: 'allenamento',
    eventoId: id,
    minuti: minuti,
    rpe: rpeUsato,
    stimato: rpe == null,
    acqua: totale * (1 - quotaSecco),
    secco: totale * quotaSecco,
  );
}

/// Il carico di una seduta a secco: RPE × i suoi [minuti], tutto nel
/// secco.
CaricoSeduta caricoSecco({
  required String id,
  required DateTime giorno,
  required int minuti,
  int? rpe,
}) {
  final rpeUsato = rpe?.toDouble() ?? rpeStimatoSecco;
  final durata = minuti.clamp(1, 600);
  return CaricoSeduta(
    giorno: soloData(giorno),
    tipo: 'allenamento',
    eventoId: id,
    minuti: durata,
    rpe: rpeUsato,
    stimato: rpe == null,
    secco: rpeUsato * durata,
  );
}

/// Il carico di una partita: RPE × [minutiPartita].
CaricoSeduta caricoPartita({
  required String id,
  required DateTime giorno,
  int? rpe,
}) {
  final rpeUsato = rpe?.toDouble() ?? rpeStimatoPartita;
  return CaricoSeduta(
    giorno: soloData(giorno),
    tipo: 'partita',
    eventoId: id,
    minuti: minutiPartita,
    rpe: rpeUsato,
    stimato: rpe == null,
    partita: rpeUsato * minutiPartita,
  );
}

/// Il carico di un giorno o di una settimana, per tipo.
class CaricoPeriodo {
  const CaricoPeriodo({this.acqua = 0, this.secco = 0, this.partita = 0});

  static const zero = CaricoPeriodo();

  final double acqua;
  final double secco;
  final double partita;

  double get totale => acqua + secco + partita;

  CaricoPeriodo operator +(CaricoPeriodo altro) => CaricoPeriodo(
    acqua: acqua + altro.acqua,
    secco: secco + altro.secco,
    partita: partita + altro.partita,
  );

  static CaricoPeriodo daSeduta(CaricoSeduta s) =>
      CaricoPeriodo(acqua: s.acqua, secco: s.secco, partita: s.partita);
}

/// Il carico di ogni giorno con almeno una seduta (chiave: mezzanotte).
Map<DateTime, CaricoPeriodo> caricoPerGiorno(Iterable<CaricoSeduta> sedute) {
  final giorni = <DateTime, CaricoPeriodo>{};
  for (final s in sedute) {
    giorni[s.giorno] =
        (giorni[s.giorno] ?? CaricoPeriodo.zero) + CaricoPeriodo.daSeduta(s);
  }
  return giorni;
}

/// Il carico delle ultime [settimane] settimane, da lunedì a domenica,
/// fino a quella di [oggi] compresa; le settimane vuote valgono zero.
List<({DateTime lunedi, CaricoPeriodo carico})> caricoPerSettimana(
  Iterable<CaricoSeduta> sedute, {
  int settimane = 8,
  DateTime? oggi,
}) {
  final questa = lunediDi(oggi ?? DateTime.now());
  final perLunedi = <DateTime, CaricoPeriodo>{};
  for (final s in sedute) {
    final l = lunediDi(s.giorno);
    perLunedi[l] =
        (perLunedi[l] ?? CaricoPeriodo.zero) + CaricoPeriodo.daSeduta(s);
  }
  return [
    for (var i = settimane - 1; i >= 0; i--)
      (
        lunedi: aggiungiGiorni(questa, -7 * i),
        carico: perLunedi[aggiungiGiorni(questa, -7 * i)] ?? CaricoPeriodo.zero,
      ),
  ];
}

/// Dove cade il rapporto fra carico acuto e cronico. Fasce di
/// riferimento della letteratura (Gabbett 2016), senza diagnosi: dicono
/// quanto la settimana si discosta dal solito, non se l'atleta si farà
/// male.
enum FasciaAcwr {
  basso('Sotto il solito'),
  norma('Nella norma'),
  salita('In salita'),
  alto('Molto sopra il solito');

  const FasciaAcwr(this.etichetta);

  final String etichetta;
}

/// Il rapporto fra il carico degli ultimi 7 giorni e la media settimanale
/// delle ultime 4 settimane (ACWR, media mobile).
class Acwr {
  const Acwr({
    required this.acuto,
    required this.cronico,
    required this.giorniDiStorico,
  });

  /// Carico degli ultimi 7 giorni, oggi compreso.
  final double acuto;

  /// Media settimanale delle ultime 4 settimane (28 giorni / 4).
  final double cronico;

  /// Da quanti giorni ci sono sedute: sotto i 21 il rapporto non dice
  /// ancora niente (il "solito" non c'è).
  final int giorniDiStorico;

  bool get affidabile => giorniDiStorico >= 21 && cronico > 0;

  double? get rapporto => cronico > 0 ? acuto / cronico : null;

  FasciaAcwr? get fascia {
    final r = rapporto;
    if (r == null || !affidabile) return null;
    if (r < 0.8) return FasciaAcwr.basso;
    if (r <= 1.3) return FasciaAcwr.norma;
    if (r <= 1.5) return FasciaAcwr.salita;
    return FasciaAcwr.alto;
  }
}

/// ACWR a [oggi] (di solito adesso) dalle [sedute] dell'atleta; null
/// senza sedute.
Acwr? calcolaAcwr(Iterable<CaricoSeduta> sedute, {DateTime? oggi}) {
  if (sedute.isEmpty) return null;
  final fine = soloData(oggi ?? DateTime.now());
  final inizioAcuto = aggiungiGiorni(fine, -6);
  final inizioCronico = aggiungiGiorni(fine, -27);
  var acuto = 0.0;
  var cronico = 0.0;
  DateTime? prima;
  for (final s in sedute) {
    if (s.giorno.isAfter(fine)) continue;
    if (prima == null || s.giorno.isBefore(prima)) prima = s.giorno;
    if (!s.giorno.isBefore(inizioCronico)) cronico += s.totale;
    if (!s.giorno.isBefore(inizioAcuto)) acuto += s.totale;
  }
  if (prima == null) return null;
  return Acwr(
    acuto: acuto,
    cronico: cronico / 4,
    giorniDiStorico: giorniTra(prima, fine) + 1,
  );
}

/// "1,24" con la virgola.
String formattaAcwr(double rapporto) =>
    rapporto.toStringAsFixed(2).replaceAll('.', ',');

/// Le sedute che contano nel carico di un atleta, ognuna con il suo
/// carico:
/// - un allenamento in cui è segnato presente, o a cui ha dato l'RPE (se
///   l'allenatore non l'ha segnato assente);
/// - una partita in cui era convocato, giocata prima di [oggi], o a cui
///   ha dato l'RPE.
/// Le sedute senza la sua risposta hanno un carico stimato.
///
/// Di un allenamento contano solo le serie che fa lui ([atletaId], con il
/// suo [ruolo]): non quelle dei soli portieri se è di movimento, né la
/// variante di un compagno. Senza [atletaId], tutte.
///
/// Le sedute a secco ([minutiSecco]: id -> minuti) valgono i loro minuti,
/// tutti nel secco.
List<CaricoSeduta> seduteDiAtleta({
  required Map<String, DateTime> dataAllenamenti,
  required Map<String, List<DatiSerie>> seriePerAllenamento,
  Map<String, int> minutiSecco = const {},
  required Map<String, String> statoPresenze,
  required Map<String, DateTime> dataPartite,
  required Set<String> partiteConvocato,
  required Map<(String, String), int> rpe,
  String? atletaId,
  String? ruolo,
  DateTime? oggi,
}) {
  final inizioOggi = soloData(oggi ?? DateTime.now());
  final sedute = <CaricoSeduta>[];

  final allenamenti = {
    for (final MapEntry(key: id, value: stato) in statoPresenze.entries)
      if (contaComePresente(stato)) id,
    for (final (tipo, id) in rpe.keys)
      if (tipo == 'allenamento' &&
          statoPresenze[id] != 'assente' &&
          statoPresenze[id] != 'giustificato')
        id,
  };
  for (final id in allenamenti) {
    final data = dataAllenamenti[id];
    if (data == null) continue;
    if (minutiSecco[id] case final minuti?) {
      sedute.add(
        caricoSecco(
          id: id,
          giorno: data,
          minuti: minuti,
          rpe: rpe[('allenamento', id)],
        ),
      );
      continue;
    }
    final serie = seriePerAllenamento[id] ?? const <DatiSerie>[];
    sedute.add(
      caricoAllenamento(
        id: id,
        giorno: data,
        serie: atletaId == null
            ? serie
            : serieDellAtleta(serie, atletaId, ruolo),
        rpe: rpe[('allenamento', id)],
      ),
    );
  }

  final partite = {
    for (final id in partiteConvocato)
      if (dataPartite[id] case final data? when data.isBefore(inizioOggi)) id,
    for (final (tipo, id) in rpe.keys)
      if (tipo == 'partita') id,
  };
  for (final id in partite) {
    final data = dataPartite[id];
    if (data == null) continue;
    sedute.add(caricoPartita(id: id, giorno: data, rpe: rpe[('partita', id)]));
  }

  sedute.sort((a, b) => a.giorno.compareTo(b.giorno));
  return sedute;
}
