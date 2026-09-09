import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_engine.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_skeleton.dart';
import '../allenamenti/presentation/allenamenti_list_screen.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../atleti/presentation/atleti_list_screen.dart';
import '../auth/data/auth_repository.dart';
import '../club/application/current_club_provider.dart';
import '../club/domain/club.dart';
import '../club/presentation/club_setup_screen.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../gruppi/application/selezione_gruppo_provider.dart';
import '../gruppi/domain/gruppo.dart';
import '../gruppi/presentation/gruppi_chooser_screen.dart';
import '../gruppi/presentation/gruppi_onboarding_screen.dart';
import '../pallanuoto/presentation/partite_list_screen.dart';
import '../stagioni/presentation/stagioni_list_screen.dart';
import 'area_atleta_home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  Widget _corpoClub(AsyncValue<Club?> clubAsync) {
    return clubAsync.when(
      data: (club) =>
          club == null ? const ClubSetupScreen() : _corpoDaCoach(club),
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: ErrorBanner(
          messaggio: 'Non è stato possibile caricare il club.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }

  Widget _corpoDaCoach(Club club) {
    final gruppiAsync = ref.watch(gruppiListProvider(club.id));
    return gruppiAsync.when(
      data: (gruppi) {
        if (gruppi.isEmpty) {
          return GruppiOnboardingScreen(clubId: club.id);
        }
        final selezione = ref.watch(selezioneGruppoProvider);
        if (selezione == null) {
          return GruppiChooserScreen(clubId: club.id);
        }
        return IndexedStack(
          index: _tabIndex,
          children: [
            AtletiListScreen(
              clubId: club.id,
              filtroGruppoId: selezione.gruppoId,
            ),
            AllenamentiListScreen(clubId: club.id),
            StagioniListScreen(clubId: club.id),
            PartiteListScreen(clubId: club.id),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: ErrorBanner(
          messaggio: 'Non è stato possibile caricare i gruppi.',
          suggerimento:
              'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atletaAsync = ref.watch(currentAtletaProvider);
    final clubAsync = ref.watch(currentClubProvider);
    final club = clubAsync.value;
    // null finche' non e' chiaro se questo login e' un atleta collegato:
    // in quel caso si aspetta prima di scegliere corpo/bottomNavigationBar,
    // per non mostrare per un istante le tab da coach (vedi _corpoDaCoach).
    final areaAtleta = atletaAsync.value != null;
    final List<Gruppo> gruppi = club == null
        ? const []
        : ref.watch(gruppiListProvider(club.id)).value ?? const [];
    final selezione = ref.watch(selezioneGruppoProvider);
    final mostraTab =
        !areaAtleta && club != null && gruppi.isNotEmpty && selezione != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(club?.nome ?? 'SwimCoach FIN'),
        actions: [
          const _SyncStatusIndicator(),
          if (mostraTab)
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Cambia gruppo',
              onPressed: () =>
                  ref.read(selezioneGruppoProvider.notifier).scegli(null),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: atletaAsync.when(
        data: (atleta) => atleta != null
            ? AreaAtletaHomeScreen(atleta: atleta)
            : _corpoClub(clubAsync),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (_, _) => _corpoClub(clubAsync),
      ),
      bottomNavigationBar: mostraTab
          ? NavigationBar(
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
                NavigationDestination(
                  icon: Icon(Icons.sports_outlined),
                  selectedIcon: Icon(Icons.sports),
                  label: 'Partite',
                ),
              ],
            )
          : null,
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
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4),
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
