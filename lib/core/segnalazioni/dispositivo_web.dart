import 'package:web/web.dart' as web;

/// Es. "Mozilla/5.0 (Linux; Android 14; …) … Chrome/129…": dice telefono,
/// sistema e versione del browser. Tagliato alla lunghezza che il database
/// accetta.
String descrizioneDispositivo() {
  final agente = web.window.navigator.userAgent;
  return agente.length <= 300 ? agente : agente.substring(0, 300);
}
