import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_providers.dart';
import 'app_database.dart';
import 'database_provider.dart';

const _chiaveUltimoUtente = 'ultimo_utente_id_cache_locale';

/// Svuota la cache locale (Drift) quando l'utente autenticato su questo
/// device e' diverso da chi l'ha popolata l'ultima volta.
///
/// Senza questo controllo, un device usato per piu' account (comune
/// durante i test, ma possibile anche nell'uso reale) mostra al nuovo
/// utente i dati dell'utente precedente finche' un refresh online non
/// sovrascrive per caso ogni singola tabella — è il bug per cui un
/// atleta appena registrato si è ritrovato la schermata "crea gruppo"
/// del coach, con il club e i gruppi rimasti in cache da una sessione
/// precedente su quel browser.
///
/// Se e' lo stesso utente di prima (incluso un nuovo login offline
/// dello stesso account, dopo una sessione scaduta), la cache resta
/// intatta: e' proprio quello che serve a bordo vasca senza rete.
Future<void> allineaCacheLocaleAllUtente(AppDatabase db, String? userId) async {
  if (userId == null) return;
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(_chiaveUltimoUtente)) {
    // Prima volta che questo controllo gira su questo device (es. subito
    // dopo aver aggiornato l'app): non sappiamo se la cache esistente
    // appartiene gia' a questo utente. Ci limitiamo a registrarlo senza
    // svuotare nulla, per non perdere scritture offline non ancora
    // sincronizzate di un utente legittimo già in uso da tempo.
    await prefs.setString(_chiaveUltimoUtente, userId);
    return;
  }
  final ultimo = prefs.getString(_chiaveUltimoUtente);
  if (ultimo == userId) return;
  await db.clearAll();
  await prefs.setString(_chiaveUltimoUtente, userId);
}

/// Da attendere prima di mostrare qualunque schermata che legga la
/// cache locale (Home, in `app.dart`): si ri-esegue ogni volta che lo
/// stato di autenticazione cambia.
final cacheLocaleAllineataProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateChangesProvider).value;
  final userId = authState?.session?.user.id;
  final db = ref.watch(appDatabaseProvider);
  await allineaCacheLocaleAllUtente(db, userId);
});
