import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/cache_utente_guard.dart';
import 'core/demo/modalita_demo.dart';
import 'core/navigation/navigator_key.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/sync/connectivity_sync_trigger.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/barra_club.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tema_provider.dart';

class CoachVascaApp extends ConsumerWidget {
  const CoachVascaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivitySyncTriggerProvider);
    // All'uscita si chiudono tutte le schermate aperte sopra la home:
    // senza, "Esci" da una schermata interna (es. il calendario della
    // stagione) lasciava quella schermata visibile e usabile sopra il
    // login, con la barra del club gia' sparita.
    ref.listen(authStateChangesProvider, (prima, adesso) {
      final eraDentro = prima?.value?.session != null;
      final ora = adesso.value?.session;
      if (eraDentro && ora == null) {
        navigatorKeyApp.currentState?.popUntil((r) => r.isFirst);
      }
    });
    final authState = ref.watch(authStateChangesProvider);
    final cacheAllineata = ref.watch(cacheLocaleAllineataProvider);
    final temaApp = ref.watch(temaAppProvider);

    return MaterialApp(
      title: 'WaterTactics',
      navigatorKey: navigatorKeyApp,
      // La barra fissa in alto (logo + nome del club) sta sopra il
      // Navigator, così resta ferma mentre le schermate cambiano.
      builder: (context, child) {
        final app = BarraClubHost(child: child);
        if (!modalitaDemo) return app;
        // Etichetta "DEMO" sul bordo alto: si vede sempre che non sono
        // dati reali, senza coprire le icone della barra.
        return Stack(
          children: [
            app,
            // Sopra l'angolo del logo: l'unico punto della barra senza
            // testo da coprire, anche quando il nome del club va a capo.
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB3261E),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      debugShowCheckedModeBanner: false,
      theme: AppTheme.chiaro,
      darkTheme: AppTheme.scuro,
      themeMode: temaApp,
      locale: const Locale('it'),
      supportedLocales: const [Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.when(
        data: (state) {
          if (state.session == null) return const LoginScreen();
          // Aspetta che la cache locale sia allineata all'utente
          // autenticato (vedi cache_utente_guard.dart) prima di mostrare
          // Home: altrimenti le prime schermate potrebbero leggere dati
          // rimasti in cache da un utente precedente su questo device.
          return cacheAllineata.when(
            data: (_) => const HomeScreen(),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const HomeScreen(),
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
