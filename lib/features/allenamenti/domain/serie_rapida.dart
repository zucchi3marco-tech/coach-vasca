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

/// Interpreta una riga di testo libero in ripetute, distanza, zona,
/// passo obiettivo, recupero e stile — pensata per come un allenatore
/// scrive davvero una serie a bordo vasca (es. "10x100 A2 1:25 r15 sl").
/// Gli unici campi obbligatori sono ripetute e distanza (formato
/// "NxM", tollera spazi intorno alla "x"): senza quelli torna `null`.
/// Ogni altro token è opzionale e riconosciuto in un solo modo (zona,
/// "rNN" per il recupero, "m:ss" per il passo, abbreviazione di stile);
/// un token non riconosciuto viene semplicemente ignorato, non blocca
/// l'interpretazione del resto della riga.
SerieRapida? parseSerieRapida(String testo) {
  final match = _rxRipeteDistanza.firstMatch(testo);
  if (match == null) return null;
  final ripetute = int.parse(match.group(1)!);
  final distanzaM = int.parse(match.group(2)!);
  if (ripetute <= 0 || distanzaM <= 0) return null;

  final resto = testo.replaceRange(match.start, match.end, ' ');

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

  return SerieRapida(
    ripetute: ripetute,
    distanzaM: distanzaM,
    stile: stile,
    zona: zona,
    passoObiettivoS: passoObiettivoS,
    recuperoS: recuperoS,
  );
}
