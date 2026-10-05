import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/db/cache_utente_guard.dart';
import 'core/db/database_provider.dart';
import 'core/demo/dati_demo.dart';
import 'core/demo/inviti_demo.dart';
import 'core/demo/modalita_demo.dart';
import 'core/pwa/aggiornamento_pwa.dart';
import 'core/pwa/installabilita_pwa.dart';
import 'core/supabase/supabase_providers.dart';
import 'features/atleti/data/codici_gruppo_repository.dart';
import 'features/atleti/data/inviti_atleta_repository.dart';
import 'features/auth/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  avviaOsservazioneInstallabilitaPwa();
  avviaOsservazioneAggiornamentoPwa();
  await dotenv.load();

  if (modalitaDemo) {
    // Albero di accessibilita' sempre attivo in demo: i testi e i
    // pulsanti diventano leggibili dagli strumenti di prova nel browser.
    SemanticsBinding.instance.ensureSemantics();
    await Supabase.initialize(
      url: urlSupabaseDemo,
      publishableKey: 'demo',
      httpClient: ClientOffline(),
      // Senza: ogni lettura ritenta 3 volte prima di arrendersi e ogni
      // schermata resta in caricamento per secondi.
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
      // Token fisso: senza, ogni richiesta aspettava ~7 s una sessione
      // Supabase che in demo non arriva mai (getSession), e ogni
      // schermata restava in caricamento. Il login della demo e'
      // AuthRepositoryDemo, non Supabase Auth.
      accessToken: () async => 'demo',
    );
    final authDemo = AuthRepositoryDemo();
    final container = ProviderContainer(
      observers: [OsservatoreErroriDemo()],
      overrides: [
        authRepositoryProvider.overrideWithValue(authDemo),
        authStateChangesProvider.overrideWith((ref) => authDemo.cambiStato),
        // Allenatore e atleti demo condividono la stessa cache locale:
        // cambiare account non deve svuotarla.
        cacheLocaleAllineataProvider.overrideWith((ref) async {}),
        invitiAtletaRepositoryProvider.overrideWith(
          (ref) => InvitiAtletaRepositoryDemo(
            ref.watch(appDatabaseProvider),
            authDemo,
          ),
        ),
        codiciGruppoRepositoryProvider.overrideWith(
          (ref) => CodiciGruppoRepositoryDemo(
            ref.watch(appDatabaseProvider),
            authDemo,
          ),
        ),
      ],
    );
    await inserisciDatiDemo(container.read(appDatabaseProvider));
    authDemo.garantisciAtletaCollegato = (userId) =>
        garantisciAtletaDemo(container.read(appDatabaseProvider), userId);
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const CoachVascaApp(),
      ),
    );
    return;
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: CoachVascaApp()));
}
