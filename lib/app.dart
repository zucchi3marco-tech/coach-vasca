import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/cache_utente_guard.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/sync/connectivity_sync_trigger.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

class CoachVascaApp extends ConsumerWidget {
  const CoachVascaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivitySyncTriggerProvider);
    final authState = ref.watch(authStateChangesProvider);
    final cacheAllineata = ref.watch(cacheLocaleAllineataProvider);
    // `temaAppProvider` è pronto (persistenza inclusa) ma non ancora
    // collegato qui: con ThemeMode.system, un dispositivo/browser che
    // preferisce lo scuro faceva davvero scattare AppTheme.scuro —
    // sfondo scuro corretto, ma testo illeggibile perché nessuna
    // schermata legge ancora i colori dal tema (usano tutte AppColors
    // fisso, pensato solo per il chiaro). Resta forzato al chiaro finché
    // le schermate non migrano una per volta (DESIGN.md sezione 20,
    // "Ordine di lavoro"), poi si ripristina `themeMode:
    // ref.watch(temaAppProvider)`.

    return MaterialApp(
      title: 'SwimCoach FIN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.chiaro,
      darkTheme: AppTheme.scuro,
      themeMode: ThemeMode.light,
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
