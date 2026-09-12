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
