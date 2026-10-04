import '../domain/scheda_generata.dart';

/// Una seduta già generata, con la sua data — vista minima di
/// `SedutaConScheda` (che resta nella presentation layer) per non
/// importare un widget da qui.
typedef SedutaPerControllo = (DateTime data, SchedaGenerata scheda);

const _zoneLattacide = {'C1', 'C2'};

bool _haRiscaldamento(SchedaGenerata s) =>
    s.serie.any((serie) => serie.blocco == 'riscaldamento');

bool _haDefaticamento(SchedaGenerata s) =>
    s.serie.any((serie) => serie.blocco == 'defaticamento');

bool _eLattacida(SchedaGenerata s) => s.serie.any(
  (serie) =>
      serie.blocco == 'principale' && _zoneLattacide.contains(serie.zona),
);

double _percentualeNuotoPuro(SchedaGenerata s) {
  final totale = s.volumeTotaleM;
  if (totale == 0) return 0;
  final nuoto = s.serie
      .where((serie) => serie.esecuzione == 'nuoto')
      .fold<int>(0, (t, serie) => t + serie.distanzaTotaleM);
  return nuoto / totale * 100;
}

/// Entro [tolleranza] (default 10%) dal volume settimanale richiesto.
bool volumeEntroTolleranza(
  List<SedutaPerControllo> sedute,
  int volumeRichiesto, {
  double tolleranza = 0.10,
}) {
  if (volumeRichiesto <= 0) return true;
  final totale = sedute.fold<int>(0, (t, s) => t + s.$2.volumeTotaleM);
  final scarto = (totale - volumeRichiesto).abs() / volumeRichiesto;
  return scarto <= tolleranza;
}

/// Indici delle sedute senza riscaldamento o senza defaticamento.
List<int> sedutesenzaRiscaldamentoODefaticamento(
  List<SedutaPerControllo> sedute,
) {
  return [
    for (var i = 0; i < sedute.length; i++)
      if (!_haRiscaldamento(sedute[i].$2) || !_haDefaticamento(sedute[i].$2)) i,
  ];
}

/// Indici delle sedute lattacide (C1/C2 nel blocco principale) che
/// seguono — in ordine di data, non solo di posizione nell'elenco — un
/// altro giorno già lattacido: è il secondo dei due a dover essere
/// alleggerito, non il primo.
List<int> giornateLattacideConsecutive(List<SedutaPerControllo> sedute) {
  final ordine = List<int>.generate(sedute.length, (i) => i)
    ..sort((a, b) => sedute[a].$1.compareTo(sedute[b].$1));
  final risultato = <int>[];
  for (var i = 1; i < ordine.length; i++) {
    final precedente = sedute[ordine[i - 1]];
    final corrente = sedute[ordine[i]];
    if (_eLattacida(precedente.$2) && _eLattacida(corrente.$2)) {
      risultato.add(ordine[i]);
    }
  }
  return risultato;
}

/// Vero se il volume settimanale supera la media delle ultime settimane
/// più di [tolleranza] (default 10-15%, qui 15%) — solo un aumento
/// eccessivo conta, uno scarico (volume più basso) non è un problema.
bool caricoEccessivo(
  double volumeSettimana,
  double? mediaUltimeSettimane, {
  double tolleranza = 0.15,
}) {
  if (mediaUltimeSettimane == null || mediaUltimeSettimane <= 0) return false;
  return volumeSettimana > mediaUltimeSettimane * (1 + tolleranza);
}

/// Indice dell'ultima seduta della settimana (per data) se non risulta
/// uno scarico (volume sotto l'80% della media delle sedute della
/// settimana) mentre una gara/partita "alta" è imminente — `null` se non
/// c'è una gara imminente o se lo scarico c'è già.
int? indiceScaricoMancante(
  List<SedutaPerControllo> sedute, {
  required bool garaAltaImminente,
}) {
  if (!garaAltaImminente || sedute.isEmpty) return null;
  final ordine = List<int>.generate(sedute.length, (i) => i)
    ..sort((a, b) => sedute[a].$1.compareTo(sedute[b].$1));
  final ultimoIndice = ordine.last;
  final volumi = sedute.map((s) => s.$2.volumeTotaleM).toList();
  final media = volumi.reduce((a, b) => a + b) / volumi.length;
  final volumeUltima = sedute[ultimoIndice].$2.volumeTotaleM;
  return volumeUltima > media * 0.8 ? ultimoIndice : null;
}

/// Indici delle sedute pallanuoto dove il nuoto puro supera il 50% del
/// volume — ignorato se [richiestoEsplicito] (il coach lo ha chiesto a
/// parole, nei vincoli) o se lo sport non è pallanuoto.
List<int> pallanuotoNuotoPuroOltre50(
  List<SedutaPerControllo> sedute, {
  required bool sportPallanuoto,
  bool richiestoEsplicito = false,
}) {
  if (!sportPallanuoto || richiestoEsplicito) return [];
  return [
    for (var i = 0; i < sedute.length; i++)
      if (_percentualeNuotoPuro(sedute[i].$2) > 50) i,
  ];
}

/// Esito dei controlli sulla settimana intera: [avvisi] sono sempre
/// mostrati al coach (anche quelli non risolvibili con una
/// rigenerazione), [indiceDaRigenerare]/[vincoloExtra] indicano **al
/// massimo una** seduta da rigenerare — "un solo nuovo tentativo", come
/// deciso nel piano: mai più di una rigenerazione automatica per
/// settimana.
class EsitoControlliSettimana {
  const EsitoControlliSettimana({
    required this.avvisi,
    this.indiceDaRigenerare,
    this.vincoloExtra,
  });

  final List<String> avvisi;
  final int? indiceDaRigenerare;
  final String? vincoloExtra;
}

EsitoControlliSettimana controllaSettimana({
  required List<SedutaPerControllo> sedute,
  required int volumeSettimanaleRichiesto,
  double? mediaUltimeSettimane,
  bool garaAltaImminente = false,
  bool sportPallanuoto = false,
  bool nuotoPuroRichiestoEsplicito = false,
}) {
  final avvisi = <String>[];
  int? indiceDaRigenerare;
  String? vincoloExtra;

  void proponiRigenerazione(int indice, String vincolo) {
    // Priorità all'ordine di chiamata: la prima proposta vince, le
    // successive restano solo come avviso informativo (un solo
    // tentativo di rigenerazione per settimana).
    indiceDaRigenerare ??= indice;
    if (indiceDaRigenerare == indice && vincoloExtra == null) {
      vincoloExtra = vincolo;
    }
  }

  final senzaRiscDef = sedutesenzaRiscaldamentoODefaticamento(sedute);
  if (senzaRiscDef.isNotEmpty) {
    avvisi.add(
      'Qualche seduta non ha sia riscaldamento che defaticamento: '
      'controllala prima di salvare.',
    );
    proponiRigenerazione(
      senzaRiscDef.first,
      'La seduta precedente non aveva sia riscaldamento che '
      'defaticamento: deve averli entrambi, il riscaldamento sempre in '
      'zona A1.',
    );
  }

  final lattacideConsecutive = giornateLattacideConsecutive(sedute);
  if (lattacideConsecutive.isNotEmpty) {
    avvisi.add(
      'Due giorni lattacidi (C1/C2) di fila: può essere troppo carico, '
      'controlla prima di salvare.',
    );
    proponiRigenerazione(
      lattacideConsecutive.first,
      'La seduta precedente era lattacida (zona C1/C2) subito dopo '
      'un\'altra seduta lattacida: riduci l\'intensità di questa, '
      'evitando le zone C1/C2 se possibile.',
    );
  }

  final scaricoMancante = indiceScaricoMancante(
    sedute,
    garaAltaImminente: garaAltaImminente,
  );
  if (scaricoMancante != null) {
    avvisi.add(
      'C\'è una gara o partita importante nei prossimi giorni: l\'ultima '
      'seduta della settimana non sembra uno scarico.',
    );
    proponiRigenerazione(
      scaricoMancante,
      'Nei prossimi giorni c\'è una gara o partita importante: questa è '
      'la seduta di scarico pre-gara, riduci volume e intensità rispetto '
      'alle altre sedute della settimana.',
    );
  }

  final nuotoPuroEccessivo = pallanuotoNuotoPuroOltre50(
    sedute,
    sportPallanuoto: sportPallanuoto,
    richiestoEsplicito: nuotoPuroRichiestoEsplicito,
  );
  if (nuotoPuroEccessivo.isNotEmpty) {
    avvisi.add(
      'Qualche seduta ha più del 50% di nuoto puro (pallanuoto): '
      'controllala prima di salvare.',
    );
    proponiRigenerazione(
      nuotoPuroEccessivo.first,
      'La seduta precedente aveva troppo nuoto puro per la pallanuoto: '
      'il nuoto puro (esecuzione "nuoto") non deve superare il 50% del '
      'volume della seduta, aggiungi più lavoro tecnico-tattico o a secco.',
    );
  }

  if (!volumeEntroTolleranza(sedute, volumeSettimanaleRichiesto)) {
    final totale = sedute.fold<int>(0, (t, s) => t + s.$2.volumeTotaleM);
    avvisi.add(
      'Il volume totale generato ($totale m) si allontana di più del 10% '
      'da quello richiesto ($volumeSettimanaleRichiesto m).',
    );
  }

  final volumeSettimana = sedute.fold<int>(0, (t, s) => t + s.$2.volumeTotaleM);
  if (caricoEccessivo(volumeSettimana.toDouble(), mediaUltimeSettimane)) {
    avvisi.add(
      'Il carico di questa settimana supera di più del 15% la media '
      'delle ultime settimane: valuta se è voluto.',
    );
  }

  return EsitoControlliSettimana(
    avvisi: avvisi,
    indiceDaRigenerare: indiceDaRigenerare,
    vincoloExtra: vincoloExtra,
  );
}
