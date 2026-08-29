/// Formatta un passo in secondi (es. 92.5) come 'm:ss.cc' (es. '1:32.50').
String formatPaceSeconds(double totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds - minutes * 60;
  final secondsStr = seconds.toStringAsFixed(2).padLeft(5, '0');
  return '$minutes:$secondsStr';
}
