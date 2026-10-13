import 'esercizio_secco.dart';

/// Una serie a secco fatta, registrata dall'atleta dal suo telefono:
/// quante ripetizioni (o secondi), con che carico, quando. Il carico
/// previsto è quello che aveva scritto l'allenatore in quel momento.
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
/// in questa seduta; se è la prima, quello dell'ultima volta che l'atleta
/// ha fatto l'esercizio, se l'allenatore non ha cambiato il carico da
/// allora; se no quello scritto dall'allenatore.
///
/// [precedenti] sono le serie fatte dall'atleta in altre sedute, con lo
/// stesso esercizio dell'elenco.
String? caricoProposto({
  required EsercizioSeduta riga,
  required List<SerieFatta> fatteRiga,
  required Iterable<SerieFatta> precedenti,
}) {
  if (fatteRiga.isNotEmpty) {
    return fatteRiga.reduce((a, b) => b.serie > a.serie ? b : a).carico;
  }
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
