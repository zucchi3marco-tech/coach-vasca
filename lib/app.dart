import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/supabase/supabase_providers.dart';
import 'core/sync/connectivity_sync_trigger.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/home_screen.dart';

class CoachVascaApp extends ConsumerWidget {
  const CoachVascaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(connectivitySyncTriggerProvider);
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'SwimCoach FIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6FA4),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (state) =>
            state.session != null ? const HomeScreen() : const LoginScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}
