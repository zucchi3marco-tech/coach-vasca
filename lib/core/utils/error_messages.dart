import 'package:supabase_flutter/supabase_flutter.dart';

import '../sync/network_failure.dart';

/// Trasforma un'eccezione tecnica (Postgrest, Auth, rete, Edge Function...)
/// in un messaggio comprensibile in italiano da mostrare in UI. Va usato
/// ovunque un errore raggiunga l'utente, al posto di interpolare
/// l'eccezione grezza (es. `'Errore: $e'`), che espone testo tecnico spesso
/// in inglese (stack di Postgrest/GoTrue) e non dice cosa fare.
String messaggioErrore(Object error) {
  if (isNetworkFailure(error)) {
    return 'Connessione assente. Controlla la rete e riprova.';
  }
  if (error is AuthException) return _messaggioAuth(error);
  if (error is PostgrestException) return _messaggioPostgrest(error);
  if (error is FunctionException) {
    final dettagli = error.details;
    if (dettagli is Map && dettagli['error'] is String) {
      return dettagli['error'] as String;
    }
    return 'Errore nel servizio AI. Riprova tra qualche istante.';
  }
  return _ripulisci(error.toString());
}

String _messaggioAuth(AuthException error) {
  final messaggio = error.message;
  if (messaggio.contains('Invalid login credentials')) {
    return 'Email o password non corretti.';
  }
  if (messaggio.contains('Email not confirmed')) {
    return "Devi confermare l'email prima di accedere: controlla la posta.";
  }
  if (messaggio.contains('User already registered')) {
    return 'Esiste già un account con questa email.';
  }
  if (messaggio.contains('Password should be at least')) {
    return 'La password deve avere almeno 6 caratteri.';
  }
  if (messaggio.toLowerCase().contains('rate limit') ||
      messaggio.contains('security purposes')) {
    return 'Troppi tentativi in poco tempo. Riprova tra qualche minuto.';
  }
  return messaggio;
}

String _messaggioPostgrest(PostgrestException error) {
  switch (error.code) {
    case '23505':
      return 'Esiste già un elemento con questi dati.';
    case '42501':
      return 'Non hai i permessi per completare questa operazione.';
    case '23503':
      return 'Impossibile completare: ci sono altri dati collegati a questo elemento.';
    case '23502':
      return 'Manca un campo obbligatorio.';
    default:
      return 'Errore dal server: ${error.message}';
  }
}

String _ripulisci(String testo) {
  const prefisso = 'Exception: ';
  return testo.startsWith(prefisso) ? testo.substring(prefisso.length) : testo;
}
