import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../demo/modalita_demo.dart';
import 'client_con_tempo.dart';

/// Il client HTTP di tutte le chiamate al server (vedi `main.dart`), con
/// il tempo massimo e lo [StatoRete].
final clientRete = ClientConTempoMassimo(http.Client());

/// Chiede al server se risponde, con una chiamata leggera e senza dati
/// (`/auth/v1/health`). Non dice niente da sé: com'è andata lo segna lo
/// [StatoRete], come per ogni altra chiamata.
final controllaReteProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (!dotenv.isInitialized || modalitaDemo) return;
    final url = dotenv.env['SUPABASE_URL'];
    final chiave = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || chiave == null) return;
    try {
      await clientRete.get(
        Uri.parse('$url/auth/v1/health'),
        headers: {'apikey': chiave},
      );
    } catch (_) {
      // Senza rete: lo ha già segnato lo stato.
    }
  };
});
