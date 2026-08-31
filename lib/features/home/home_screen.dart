import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_engine.dart';
import '../allenamenti/presentation/allenamenti_list_screen.dart';
import '../atleti/presentation/atleti_list_screen.dart';
import '../auth/data/auth_repository.dart';
import '../club/application/current_club_provider.dart';
import '../club/presentation/club_setup_screen.dart';
import '../stagioni/presentation/stagioni_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubProvider);
    final club = clubAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(club?.nome ?? 'SwimCoach FIN'),
        actions: [
          const _SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: clubAsync.when(
        data: (club) => club == null
            ? const ClubSetupScreen()
            : IndexedStack(
                index: _tabIndex,
                children: [
                  AtletiListScreen(clubId: club.id),
                  AllenamentiListScreen(clubId: club.id),
                  StagioniListScreen(clubId: club.id),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
      ),
      bottomNavigationBar: club == null
          ? null
          : NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) =>
                  setState(() => _tabIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Atleti',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Allenamenti',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note),
                  label: 'Stagioni',
                ),
              ],
            ),
    );
  }
}

/// Icona nell'AppBar: nascosta quando tutto e' sincronizzato, mostra il
/// numero di modifiche in coda quando manca la connessione (o il server
/// non ha ancora confermato). Un tocco ritenta subito la sincronizzazione.
class _SyncStatusIndicator extends ConsumerWidget {
  const _SyncStatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCoda = ref.watch(pendingOperationsCountProvider).value ?? 0;

    if (inCoda == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: 'Tutto sincronizzato',
          child: Icon(Icons.cloud_done_outlined),
        ),
      );
    }

    return IconButton(
      icon: Badge(
        label: Text('$inCoda'),
        child: const Icon(Icons.cloud_upload_outlined),
      ),
      tooltip:
          '$inCoda modifiche in coda, in attesa di rete. Tocca per riprovare.',
      onPressed: () => ref.read(syncEngineProvider).processQueue(),
    );
  }
}
