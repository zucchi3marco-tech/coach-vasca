import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/auth_repository.dart';

/// Placeholder post-login: le sezioni reali (atleti, test, calendario,
/// scheda bordo vasca) arrivano con i prossimi punti della FASE 2.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SwimCoach FIN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          user?.email == null ? 'Bentornato' : 'Bentornato, ${user!.email}',
        ),
      ),
    );
  }
}
