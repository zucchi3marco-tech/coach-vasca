import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/cache_utente_guard.dart';
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
    final authState = ref.watch(authStateChangesProvider);
    final cacheAllineata = ref.watch(cacheLocaleAllineataProvider);
    final temaApp = ref.watch(temaAppProvider);

    return MaterialApp(
      title: 'WaterTactics',
      navigatorKey: navigatorKeyApp,
      // La barra fissa in alto (logo + nome del club) sta sopra il
      // Navigator, così resta ferma mentre le schermate cambiano.
      builder: (context, child) => BarraClubHost(child: child),
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
