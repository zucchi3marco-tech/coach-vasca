/// Formatta una durata in secondi interi (es. 600) come testo compatto
/// per una serie "a tempo": `30"` sotto il minuto, `10'` o `5'30"` da un
/// minuto in su (mai i decimi, a differenza di [formatPaceSeconds]: qui è
/// la durata di un esercizio, non un passo di nuoto).
String formatDurataS(int secondi) {
  if (secondi < 60) return "$secondi\"";
  final minuti = secondi ~/ 60;
  final resto = secondi % 60;
  return resto == 0 ? "$minuti'" : "$minuti'${resto.toString().padLeft(2, '0')}\"";
}

/// Formatta una durata in secondi interi come 'm:ss' editabile (es. 630
/// -> '10:30'), per il campo "Durata" di [SerieFormScreen] — si
/// interpreta di nuovo con [parsePaceMmSs]. Diverso da [formatDurataS],
/// pensato per la sola lettura.
String formatDurataMmSs(int secondi) {
  final minuti = secondi ~/ 60;
  final resto = secondi % 60;
  return '$minuti:${resto.toString().padLeft(2, '0')}';
}

/// Formatta un passo in secondi (es. 92.5) come 'm:ss.cc' (es. '1:32.50').
String formatPaceSeconds(double totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds - minutes * 60;
  final secondsStr = seconds.toStringAsFixed(2).padLeft(5, '0');
  return '$minutes:$secondsStr';
}

final _rxPaceMmSs = RegExp(r'^(\d+):(\d+(?:\.\d+)?)$');

/// Interpreta un testo 'm:ss' o 'm:ss.cc' (es. '1:32.5') in secondi
/// totali; accetta anche un numero puro di secondi per chi scrive solo
/// quelli. Torna `null` se vuoto o non interpretabile.
double? parsePaceMmSs(String testo) {
  final t = testo.trim();
  if (t.isEmpty) return null;
  final match = _rxPaceMmSs.firstMatch(t);
  if (match != null) {
    final minuti = int.parse(match.group(1)!);
    final secondi = double.parse(match.group(2)!);
    return minuti * 60 + secondi;
  }
  return double.tryParse(t);
}
