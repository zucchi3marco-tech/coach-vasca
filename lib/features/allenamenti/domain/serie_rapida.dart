/// Risultato dell'interpretazione di una riga scritta a mano tipo
/// "10x100 A2 1:25 r15 sl" — vedi [parseSerieRapida].
class SerieRapida {
  const SerieRapida({
    required this.ripetute,
    required this.distanzaM,
    required this.stile,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
  });

  final int ripetute;
  final int distanzaM;
  final String stile;
  final String? zona;
  final double? passoObiettivoS;
  final int? recuperoS;
}

final _rxRipeteDistanza = RegExp(r'(\d+)\s*[xX×]\s*(\d+)');
final _rxPiramideConGiri = RegExp(r'(\d+)\s*[xX×]\s*\((\d+(?:-\d+)+)\)');
final _rxPiramide = RegExp(r'\b(\d+(?:-\d+)+)\b');
final _rxPasso = RegExp(r'^(\d+):(\d+(?:\.\d+)?)$');
final _rxRecupero = RegExp(r'^r(\d+)$', caseSensitive: false);

const _zoneValide = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'C3', 'D'};

const _stiliAbbreviati = {
  'sl': 'libero',
  'lib': 'libero',
  'libero': 'libero',
  'do': 'dorso',
  'dorso': 'dorso',
  'ra': 'rana',
  'rana': 'rana',
  'de': 'delfino',
  'delfino': 'delfino',
  'farfalla': 'delfino',
  'mi': 'misti',
  'misti': 'misti',
};

/// Zona/passo/recupero/stile letti dal testo restante dopo aver tolto il
/// token di ripetute×distanza (o la sequenza piramidale): stessi campi
/// opzionali, comuni a tutte le serie della riga. [recuperi] tiene
/// **tutti** i token "rNN" trovati, nell'ordine in cui compaiono (per una
/// piramide possono essercene due: tra una distanza e l'altra, e tra un
/// giro e l'altro).
class _AttributiComuni {
  const _AttributiComuni({
    required this.stile,
    this.zona,
    this.passoObiettivoS,
    required this.recuperi,
  });

  final String stile;
  final String? zona;
  final double? passoObiettivoS;
  final List<int> recuperi;
}

_AttributiComuni _leggiAttributiComuni(String resto) {
  var stile = 'libero';
  String? zona;
  double? passoObiettivoS;
  final recuperi = <int>[];

  for (final token in resto.split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;

    final tokenMaiuscolo = token.toUpperCase();
    if (_zoneValide.contains(tokenMaiuscolo)) {
      zona = tokenMaiuscolo;
      continue;
    }

    final recuperoMatch = _rxRecupero.firstMatch(token);
    if (recuperoMatch != null) {
      recuperi.add(int.parse(recuperoMatch.group(1)!));
      continue;
    }

    final passoMatch = _rxPasso.firstMatch(token);
    if (passoMatch != null) {
      final minuti = int.parse(passoMatch.group(1)!);
      final secondi = double.parse(passoMatch.group(2)!);
      passoObiettivoS = minuti * 60 + secondi;
      continue;
    }

    final stileTrovato = _stiliAbbreviati[token.toLowerCase()];
    if (stileTrovato != null) {
      stile = stileTrovato;
      continue;
    }

    // Token non riconosciuto: ignorato, non blocca la riga.
  }

  return _AttributiComuni(
    stile: stile,
    zona: zona,
    passoObiettivoS: passoObiettivoS,
    recuperi: recuperi,
  );
}

/// Interpreta una riga di testo libero in una o più serie — pensata per
/// come un allenatore scrive davvero una serie a bordo vasca.
///
/// Tre formati per le ripetute/distanze (il primo che combacia vince):
/// - **piramide con giri**: `NxM(d1-d2-...)`, es. "2x(50-100-200-100-50)"
///   → ripete la sequenza di distanze `N` volte, una serie per ogni
///   distanza (1 ripetuta ciascuna). Il recupero accetta **due** valori
///   `rNN` nel resto della riga: il primo tra una distanza e l'altra
///   dentro un giro, il secondo tra un giro e l'altro — quest'ultimo si
///   applica solo all'ultima distanza di ogni giro che non sia l'ultimo
///   (con un solo giro non si applica mai, è una serie come le altre);
/// - **piramide semplice**: distanze separate da un trattino senza
///   prefisso, es. "50-100-200-100-50" → come sopra con un solo giro;
/// - **ripetute×distanza**: "NxM" (tollera spazi intorno alla "x"), es.
///   "10x100" → una sola serie con quelle ripetute.
///
/// Senza nessuno dei tre, torna `null`. Ogni altro token nella riga è
/// facoltativo e riconosciuto in un solo modo (zona, "rNN" per il
/// recupero, "m:ss" per il passo, abbreviazione di stile — comuni a
/// tutte le serie della riga): un token non riconosciuto viene
/// semplicemente ignorato, non blocca l'interpretazione del resto.
List<SerieRapida>? parseSerieRapida(String testo) {
  final conGiriMatch = _rxPiramideConGiri.firstMatch(testo);
  if (conGiriMatch != null) {
    final giri = int.parse(conGiriMatch.group(1)!);
    final distanze = conGiriMatch.group(2)!.split('-').map(int.parse).toList();
    if (giri <= 0 || distanze.any((d) => d <= 0)) return null;
    final resto = testo.replaceRange(conGiriMatch.start, conGiriMatch.end, ' ');
    return _serieDaPiramide(distanze, giri, _leggiAttributiComuni(resto));
  }

  final piramideMatch = _rxPiramide.firstMatch(testo);
  if (piramideMatch != null) {
    final distanze = piramideMatch.group(1)!.split('-').map(int.parse).toList();
    if (distanze.any((d) => d <= 0)) return null;
    final resto = testo.replaceRange(
      piramideMatch.start,
      piramideMatch.end,
      ' ',
    );
    return _serieDaPiramide(distanze, 1, _leggiAttributiComuni(resto));
  }

  final match = _rxRipeteDistanza.firstMatch(testo);
  if (match == null) return null;
  final ripetute = int.parse(match.group(1)!);
  final distanzaM = int.parse(match.group(2)!);
  if (ripetute <= 0 || distanzaM <= 0) return null;

  final resto = testo.replaceRange(match.start, match.end, ' ');
  final comuni = _leggiAttributiComuni(resto);

  return [
    SerieRapida(
      ripetute: ripetute,
      distanzaM: distanzaM,
      stile: comuni.stile,
      zona: comuni.zona,
      passoObiettivoS: comuni.passoObiettivoS,
      recuperoS: comuni.recuperi.isEmpty ? null : comuni.recuperi.first,
    ),
  ];
}

/// Costruisce le serie di una piramide (eventualmente ripetuta [giri]
/// volte): ogni distanza, in ogni giro, ha recupero [_AttributiComuni.
/// recuperi]'s primo valore (tra una distanza e l'altra), tranne
/// l'ultima distanza di un giro che non sia l'ultimo, che ha il secondo
/// valore se presente (tra un giro e l'altro) — altrimenti ricade sul
/// primo. Con un solo giro nessuna distanza riceve mai il secondo
/// valore: è una serie normale, stesso recupero per tutte.
List<SerieRapida> _serieDaPiramide(
  List<int> distanze,
  int giri,
  _AttributiComuni comuni,
) {
  final r1 = comuni.recuperi.isNotEmpty ? comuni.recuperi[0] : null;
  final r2 = comuni.recuperi.length > 1 ? comuni.recuperi[1] : r1;

  return [
    for (var g = 0; g < giri; g++)
      for (var i = 0; i < distanze.length; i++)
        SerieRapida(
          ripetute: 1,
          distanzaM: distanze[i],
          stile: comuni.stile,
          zona: comuni.zona,
          passoObiettivoS: comuni.passoObiettivoS,
          recuperoS: (i == distanze.length - 1 && g < giri - 1) ? r2 : r1,
        ),
  ];
}
