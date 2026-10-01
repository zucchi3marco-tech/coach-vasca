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
/// token di ripetute×distanza (o la sequenza piramidale): stessi 4 campi
/// opzionali, condivisi da entrambi i formati di riga.
class _AttributiComuni {
  const _AttributiComuni({
    required this.stile,
    this.zona,
    this.passoObiettivoS,
    this.recuperoS,
  });

  final String stile;
  final String? zona;
  final double? passoObiettivoS;
  final int? recuperoS;
}

_AttributiComuni _leggiAttributiComuni(String resto) {
  var stile = 'libero';
  String? zona;
  double? passoObiettivoS;
  int? recuperoS;

  for (final token in resto.split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;

    final tokenMaiuscolo = token.toUpperCase();
    if (_zoneValide.contains(tokenMaiuscolo)) {
      zona = tokenMaiuscolo;
      continue;
    }

    final recuperoMatch = _rxRecupero.firstMatch(token);
    if (recuperoMatch != null) {
      recuperoS = int.parse(recuperoMatch.group(1)!);
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
    recuperoS: recuperoS,
  );
}

/// Interpreta una riga di testo libero in una o più serie — pensata per
/// come un allenatore scrive davvero una serie a bordo vasca.
///
/// Due formati per le ripetute/distanze (il primo che combacia vince):
/// - **piramide**: distanze separate da un trattino, es. "50-100-200-
///   100-50" → una serie per ogni distanza, con 1 ripetuta ciascuna,
///   nell'ordine scritto;
/// - **ripetute×distanza**: "NxM" (tollera spazi intorno alla "x"), es.
///   "10x100" → una sola serie con quelle ripetute.
///
/// Senza nessuno dei due, torna `null`. Ogni altro token nella riga è
/// facoltativo e riconosciuto in un solo modo (zona, "rNN" per il
/// recupero, "m:ss" per il passo, abbreviazione di stile — comuni a
/// tutte le serie della riga): un token non riconosciuto viene
/// semplicemente ignorato, non blocca l'interpretazione del resto.
List<SerieRapida>? parseSerieRapida(String testo) {
  final piramideMatch = _rxPiramide.firstMatch(testo);
  if (piramideMatch != null) {
    final distanze = piramideMatch.group(1)!.split('-').map(int.parse).toList();
    if (distanze.any((d) => d <= 0)) return null;
    final resto = testo.replaceRange(
      piramideMatch.start,
      piramideMatch.end,
      ' ',
    );
    final comuni = _leggiAttributiComuni(resto);
    return [
      for (final distanzaM in distanze)
        SerieRapida(
          ripetute: 1,
          distanzaM: distanzaM,
          stile: comuni.stile,
          zona: comuni.zona,
          passoObiettivoS: comuni.passoObiettivoS,
          recuperoS: comuni.recuperoS,
        ),
    ];
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
      recuperoS: comuni.recuperoS,
    ),
  ];
}
