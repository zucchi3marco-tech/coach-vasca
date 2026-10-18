import '../../secco/domain/esercizio_secco.dart';
import 'serie.dart';

/// Una modifica di un allenamento fatta da un altro allenatore, in attesa
/// che il capo della squadra la guardi (riga di `modifiche_allenamento`).
/// Le modifiche successive prima del "Visto" si aggiungono alla stessa:
/// [prima] resta com'era prima della prima.
class ModificaAllenamento {
  const ModificaAllenamento({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.capoUserId,
    required this.autori,
    required this.nuovo,
    required this.apertaAt,
    required this.ultimaAt,
    this.prima,
    this.vistoAt,
    this.titolo,
    this.data,
    this.gruppoId,
  });

  final String id;
  final String allenamentoId;
  final String clubId;
  final String capoUserId;

  /// I nomi di chi ha cambiato l'allenamento, nell'ordine.
  final List<String> autori;

  /// L'allenamento l'ha aggiunto un altro: non c'è un "prima".
  final bool nuovo;

  /// `{allenamento: {...}, serie: [...], esercizi: [...]}` com'era prima
  /// della prima modifica; null se [nuovo].
  final Map<String, dynamic>? prima;
  final DateTime apertaAt;
  final DateTime ultimaAt;

  /// Null finché il capo non l'ha vista.
  final DateTime? vistoAt;

  /// Dell'allenamento, se la riga è stata letta con
  /// `allenamenti(titolo, data, gruppo_id)`.
  final String? titolo;
  final DateTime? data;
  final String? gruppoId;

  /// Il titolo da mostrare in elenco: quello scritto o "Allenamento".
  String get titoloMostrato =>
      titolo != null && titolo!.trim().isNotEmpty ? titolo! : 'Allenamento';

  /// I nomi di chi ha modificato: "Luca", "Luca e Anna", "Luca, Anna e Gino".
  String get autoriTesto => elencoNomi(autori);

  /// "Luca ha modificato «Tecnica»" (o "ha aggiunto").
  String get frase =>
      '$autoriTesto ${autori.length > 1 ? 'hanno' : 'ha'} '
      '${nuovo ? 'aggiunto' : 'modificato'} '
      '«$titoloMostrato»';

  bool get aperta => vistoAt == null;

  factory ModificaAllenamento.fromMap(Map<String, dynamic> map) {
    final allenamento = map['allenamenti'];
    final datiAllenamento = allenamento is Map
        ? Map<String, dynamic>.from(allenamento)
        : const <String, dynamic>{};
    final dataTesto = datiAllenamento['data'] as String?;
    final prima = map['prima'];
    return ModificaAllenamento(
      id: map['id'] as String,
      allenamentoId: map['allenamento_id'] as String,
      clubId: map['club_id'] as String,
      capoUserId: map['capo_user_id'] as String,
      autori: [
        for (final a in (map['autori'] as List<dynamic>? ?? const [])) '$a',
      ],
      nuovo: map['nuovo'] as bool? ?? false,
      prima: prima is Map ? Map<String, dynamic>.from(prima) : null,
      apertaAt: DateTime.parse(map['aperta_at'] as String).toLocal(),
      ultimaAt: DateTime.parse(map['ultima_at'] as String).toLocal(),
      vistoAt: map['visto_at'] == null
          ? null
          : DateTime.parse(map['visto_at'] as String).toLocal(),
      titolo: datiAllenamento['titolo'] as String?,
      data: dataTesto == null ? null : DateTime.parse(dataTesto),
      gruppoId: datiAllenamento['gruppo_id'] as String?,
    );
  }

  /// I dati dell'allenamento com'erano prima (titolo, data, note...).
  Map<String, dynamic> get allenamentoDiPrima {
    final dati = prima?['allenamento'];
    return dati is Map ? Map<String, dynamic>.from(dati) : const {};
  }

  /// Le serie com'erano prima della modifica (vuote se [nuovo]).
  List<Serie> serieDiPrima() => [
    for (final riga in (prima?['serie'] as List<dynamic>? ?? const []))
      Serie.fromMap(Map<String, dynamic>.from(riga as Map)),
  ];

  /// Gli esercizi di una seduta a secco com'erano prima, in ordine.
  List<EsercizioSeduta> eserciziDiPrima() {
    final righe = [
      for (final riga in (prima?['esercizi'] as List<dynamic>? ?? const []))
        Map<String, dynamic>.from(riga as Map),
    ];
    return [
      for (final m in righe)
        EsercizioSeduta(
          id: m['id'] as String,
          allenamentoId: m['allenamento_id'] as String,
          clubId: m['club_id'] as String,
          esercizioId: m['esercizio_id'] as String,
          ordine: (m['ordine'] as num).toInt(),
          serie: (m['serie'] as num?)?.toInt() ?? 3,
          ripetizioni: (m['ripetizioni'] as num?)?.toInt(),
          durataS: (m['durata_s'] as num?)?.toInt(),
          carico: m['carico'] as String?,
          recuperoS: (m['recupero_s'] as num?)?.toInt(),
          note: m['note'] as String?,
        ),
    ]..sort((a, b) => a.ordine.compareTo(b.ordine));
  }
}

/// "Luca", "Luca e Anna", "Luca, Anna e Gino".
String elencoNomi(List<String> nomi) {
  if (nomi.isEmpty) return 'Un allenatore';
  if (nomi.length == 1) return nomi.first;
  return '${nomi.sublist(0, nomi.length - 1).join(', ')} e ${nomi.last}';
}

/// Cosa è successo a una riga confrontando "prima" e "ora".
enum StatoRiga { uguale, tolta, aggiunta }

class RigaConfronto {
  const RigaConfronto(this.testo, this.stato);

  final String testo;
  final StatoRiga stato;

  @override
  bool operator ==(Object other) =>
      other is RigaConfronto && other.testo == testo && other.stato == stato;

  @override
  int get hashCode => Object.hash(testo, stato);

  @override
  String toString() => '${stato.name}: $testo';
}

/// Il confronto riga per riga fra [prima] e [ora], come un diff: le righe
/// in comune (la sottosequenza comune più lunga) sono [StatoRiga.uguale],
/// quelle solo di prima [StatoRiga.tolta], quelle solo di adesso
/// [StatoRiga.aggiunta]. Dove una riga cambia, la tolta viene prima della
/// aggiunta. "Prima" si legge ignorando le aggiunte, "Ora" ignorando le
/// tolte.
List<RigaConfronto> confrontaRighe(List<String> prima, List<String> ora) {
  final n = prima.length;
  final m = ora.length;
  // lcs[i][j]: lunghezza della sottosequenza comune di prima[i..] e ora[j..].
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = prima[i] == ora[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final righe = <RigaConfronto>[];
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (prima[i] == ora[j]) {
      righe.add(RigaConfronto(prima[i], StatoRiga.uguale));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      righe.add(RigaConfronto(prima[i], StatoRiga.tolta));
      i++;
    } else {
      righe.add(RigaConfronto(ora[j], StatoRiga.aggiunta));
      j++;
    }
  }
  for (; i < n; i++) {
    righe.add(RigaConfronto(prima[i], StatoRiga.tolta));
  }
  for (; j < m; j++) {
    righe.add(RigaConfronto(ora[j], StatoRiga.aggiunta));
  }
  return righe;
}

/// Le righe di una seduta a secco per il confronto:
/// "{nome} {serie}×{ripetizioni o durata} {carico}". [nomi] sono i nomi
/// degli esercizi del club per id; uno non trovato è "Esercizio".
List<String> righeSecco(
  List<EsercizioSeduta> esercizi,
  Map<String, String> nomi,
) {
  final ordinati = [...esercizi]..sort((a, b) => a.ordine.compareTo(b.ordine));
  return [
    for (final e in ordinati)
      [
        nomi[e.esercizioId] ?? 'Esercizio',
        '${e.serie}×${e.durataS != null ? formattaSecondi(e.durataS!) : (e.ripetizioni ?? 0)}',
        if (e.carico != null && e.carico!.trim().isNotEmpty) e.carico!.trim(),
      ].join(' '),
  ];
}
