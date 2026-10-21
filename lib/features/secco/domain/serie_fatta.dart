import '../../test/domain/massimale.dart';
import 'esercizio_secco.dart';

/// Com'è andata una serie a secco, detto durante il recupero (proposta
/// 12): tre parole che capiscono anche i più piccoli.
enum VotoSerie {
  facile('Facile', 'facili'),
  giusta('Giusta', 'giuste'),
  dura('Dura', 'dure');

  const VotoSerie(this.etichetta, this.plurale);

  final String etichetta;

  /// "facili", "giuste", "dure".
  final String plurale;

  /// "facile", "giusta", "dura".
  String get singolare => etichetta.toLowerCase();

  static VotoSerie? daNome(String? nome) =>
      values.where((v) => v.name == nome).firstOrNull;
}

/// Una serie a secco fatta, registrata dall'atleta dal suo telefono (o
/// dal tablet della squadra): quante ripetizioni (o secondi), con che
/// carico, quando, e com'è andata. Il carico previsto è quello che aveva
/// scritto l'allenatore in quel momento.
class SerieFatta {
  const SerieFatta({
    required this.id,
    required this.atletaId,
    required this.clubId,
    required this.allenamentoId,
    required this.rigaId,
    required this.esercizioId,
    required this.serie,
    required this.fattaIl,
    this.ripetizioni,
    this.durataS,
    this.carico,
    this.caricoPrevisto,
    this.voto,
  });

  final String id;
  final String atletaId;
  final String clubId;
  final String allenamentoId;
  final String rigaId;
  final String esercizioId;

  /// Quale serie dell'esercizio (dalla 1).
  final int serie;
  final int? ripetizioni;
  final int? durataS;
  final String? carico;
  final String? caricoPrevisto;
  final DateTime fattaIl;

  /// Null se l'atleta non l'ha detto.
  final VotoSerie? voto;

  /// La stessa serie con il [voto] (null: lo toglie).
  SerieFatta conVoto(VotoSerie? voto) => SerieFatta(
    id: id,
    atletaId: atletaId,
    clubId: clubId,
    allenamentoId: allenamentoId,
    rigaId: rigaId,
    esercizioId: esercizioId,
    serie: serie,
    fattaIl: fattaIl,
    ripetizioni: ripetizioni,
    durataS: durataS,
    carico: carico,
    caricoPrevisto: caricoPrevisto,
    voto: voto,
  );

  factory SerieFatta.fromMap(Map<String, dynamic> m) => SerieFatta(
    id: m['id'] as String,
    atletaId: m['atleta_id'] as String,
    clubId: m['club_id'] as String,
    allenamentoId: m['allenamento_id'] as String,
    rigaId: m['riga_id'] as String,
    esercizioId: m['esercizio_id'] as String,
    serie: (m['serie'] as num).toInt(),
    ripetizioni: (m['ripetizioni'] as num?)?.toInt(),
    durataS: (m['durata_s'] as num?)?.toInt(),
    carico: m['carico'] as String?,
    caricoPrevisto: m['carico_previsto'] as String?,
    fattaIl: DateTime.parse(m['fatta_il'] as String).toLocal(),
    voto: VotoSerie.daNome(m['voto'] as String?),
  );

  Map<String, dynamic> toPayload() => {
    'id': id,
    'atleta_id': atletaId,
    'club_id': clubId,
    'allenamento_id': allenamentoId,
    'riga_id': rigaId,
    'esercizio_id': esercizioId,
    'serie': serie,
    'ripetizioni': ripetizioni,
    'durata_s': durataS,
    'carico': _pieno(carico),
    'carico_previsto': _pieno(caricoPrevisto),
    'fatta_il': fattaIl.toUtc().toIso8601String(),
    'voto': voto?.name,
  };
}

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();

bool _stessoCarico(String? a, String? b) =>
    (_pieno(a) ?? '').toLowerCase() == (_pieno(b) ?? '').toLowerCase();

/// Le serie fatte di un esercizio della seduta, per numero di serie.
List<SerieFatta> fatteDellaRiga(String rigaId, Iterable<SerieFatta> fatte) => [
  for (final f in fatte)
    if (f.rigaId == rigaId) f,
]..sort((a, b) => a.serie.compareTo(b.serie));

/// La prima serie non ancora fatta (dalla 1), null se sono tutte fatte.
int? prossimaSerie(EsercizioSeduta riga, Iterable<SerieFatta> fatteRiga) {
  final fatte = {for (final f in fatteRiga) f.serie};
  for (var s = 1; s <= riga.serie; s++) {
    if (!fatte.contains(s)) return s;
  }
  return null;
}

/// Il carico da proporre per la prossima serie: quello della serie prima
/// in questa seduta; se è la prima e l'allenatore l'ha scritto come
/// percentuale ("70%"), i chili dal [massimale] dell'atleta; se no quello
/// dell'ultima volta che l'atleta ha fatto l'esercizio, se l'allenatore
/// non ha cambiato il carico da allora; se no quello scritto
/// dall'allenatore.
///
/// [precedenti] sono le serie fatte dall'atleta in altre sedute, con lo
/// stesso esercizio dell'elenco.
String? caricoProposto({
  required EsercizioSeduta riga,
  required List<SerieFatta> fatteRiga,
  required Iterable<SerieFatta> precedenti,
  double? massimale,
}) {
  if (fatteRiga.isNotEmpty) {
    return fatteRiga.reduce((a, b) => b.serie > a.serie ? b : a).carico;
  }
  // Dal massimale di adesso, non dai chili dell'ultima volta: se il
  // massimale è cresciuto, crescono anche loro.
  if (chiliProposti(riga.carico, massimale) case final chili?) return chili;
  SerieFatta? ultima;
  for (final p in precedenti) {
    if (p.esercizioId != riga.esercizioId ||
        p.allenamentoId == riga.allenamentoId) {
      continue;
    }
    if (ultima == null ||
        p.fattaIl.isAfter(ultima.fattaIl) ||
        (p.fattaIl == ultima.fattaIl && p.serie > ultima.serie)) {
      ultima = p;
    }
  }
  if (ultima != null && _stessoCarico(ultima.caricoPrevisto, riga.carico)) {
    return _pieno(ultima.carico) ?? _pieno(riga.carico);
  }
  return _pieno(riga.carico);
}

/// Quante serie sono fatte e quante ne prevede la seduta (le serie in
/// più, se l'allenatore ne ha tolte dopo, non contano).
({int fatte, int totali}) contaSerie(
  List<EsercizioSeduta> righe,
  Iterable<SerieFatta> fatte,
) {
  final perRiga = {for (final r in righe) r.id: r.serie};
  var n = 0;
  final contate = <(String, int)>{};
  for (final f in fatte) {
    final massimo = perRiga[f.rigaId];
    if (massimo == null || f.serie > massimo) continue;
    if (contate.add((f.rigaId, f.serie))) n++;
  }
  return (fatte: n, totali: righe.fold(0, (s, r) => s + r.serie));
}

/// L'esercizio da cui ripartire: il primo con una serie da fare, o il
/// primo se sono tutti fatti.
int esercizioDaCuiPartire(
  List<EsercizioSeduta> righe,
  Iterable<SerieFatta> fatte,
) {
  for (final (i, r) in righe.indexed) {
    if (prossimaSerie(r, fatteDellaRiga(r.id, fatte)) != null) return i;
  }
  return 0;
}

/// Cosa ha fatto l'atleta in un esercizio: "3 × 12, elastico rosso" se le
/// serie sono uguali, se no "12 + 12 + 10"; i carichi diversi in ordine,
/// "elastico rosso → elastico verde". Null senza serie fatte.
String? descriviFatte(List<SerieFatta> fatteRiga, {required bool aTempo}) {
  if (fatteRiga.isEmpty) return null;
  final ordinate = [...fatteRiga]..sort((a, b) => a.serie.compareTo(b.serie));
  String quanto(SerieFatta f) =>
      aTempo ? formattaSecondi(f.durataS ?? 0) : '${f.ripetizioni ?? 0}';
  final valori = [for (final f in ordinate) quanto(f)];
  final volume = valori.toSet().length == 1
      ? '${valori.length} × ${valori.first}'
      : valori.join(' + ');
  final carichi = <String>[];
  for (final f in ordinate) {
    final c = _pieno(f.carico);
    if (c != null && (carichi.isEmpty || carichi.last != c)) carichi.add(c);
  }
  return [volume, if (carichi.isNotEmpty) carichi.join(' → ')].join(', ');
}

/// Com'è andato un esercizio, dai voti delle sue serie: "giusta" (una
/// serie), "tutte giuste", "2 giuste · 1 dura" (da facile a dura). Le
/// serie senza voto non contano; null se nessuna ha il voto.
String? descriviVoti(Iterable<SerieFatta> fatteRiga) {
  final voti = [for (final f in fatteRiga) ?f.voto];
  if (voti.isEmpty) return null;
  final conti = {for (final v in VotoSerie.values) v: 0};
  for (final v in voti) {
    conti[v] = conti[v]! + 1;
  }
  final presenti = [
    for (final v in VotoSerie.values)
      if (conti[v]! > 0) v,
  ];
  if (presenti.length == 1) {
    final v = presenti.single;
    return voti.length == 1 ? v.singolare : 'tutte ${v.plurale}';
  }
  return [
    for (final v in presenti)
      '${conti[v]} ${conti[v] == 1 ? v.singolare : v.plurale}',
  ].join(' · ');
}

/// Le serie dell'ultima volta che l'atleta ha fatto l'esercizio di
/// [riga] in un'altra seduta (quella con la serie più recente), in
/// ordine; vuota se non l'ha mai fatto. [precedenti] sono le serie fatte
/// dall'atleta.
List<SerieFatta> ultimaVoltaDi(
  EsercizioSeduta riga,
  Iterable<SerieFatta> precedenti,
) {
  SerieFatta? ultima;
  for (final p in precedenti) {
    if (p.esercizioId != riga.esercizioId ||
        p.allenamentoId == riga.allenamentoId) {
      continue;
    }
    if (ultima == null || p.fattaIl.isAfter(ultima.fattaIl)) ultima = p;
  }
  if (ultima == null) return const [];
  return [
    for (final p in precedenti)
      if (p.rigaId == ultima.rigaId) p,
  ]..sort((a, b) => a.serie.compareTo(b.serie));
}
