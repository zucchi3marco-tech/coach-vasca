import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pwa/installabilita_pwa.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/theme_toggle.dart';
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
import '../notifiche/data/notifiche_repository.dart';
import '../notifiche/presentation/notifiche_screen.dart';
import '../pallanuoto/presentation/partite_list_screen.dart';
import '../stagioni/presentation/stagioni_list_screen.dart';
import 'area_atleta_home_screen.dart';

/// Oltre questa larghezza la barra di navigazione passa dal basso (per
/// telefono/tablet) al lato, come su desktop (analisi video, punto 3.5):
/// in fondo allo schermo la barra e' il punto piu' lontano dal mouse.
const _larghezzaNavigazioneLaterale = 900.0;

const _destinazioniTab = [
  (
    icona: Icons.groups_outlined,
    iconaSelezionata: Icons.groups,
    etichetta: 'Atleti',
  ),
  (
    icona: Icons.calendar_month_outlined,
    iconaSelezionata: Icons.calendar_month,
    etichetta: 'Allenamenti',
  ),
  (
    icona: Icons.event_note_outlined,
    iconaSelezionata: Icons.event_note,
    etichetta: 'Stagioni',
  ),
  (
    icona: Icons.sports_outlined,
    iconaSelezionata: Icons.sports,
    etichetta: 'Partite',
  ),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uscita non riuscita: ${messaggioErrore(e)}')),
        );
      }
    }
  }

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
    final navigazioneLaterale =
        MediaQuery.sizeOf(context).width >= _larghezzaNavigazioneLaterale;

    final corpoPrincipale = atletaAsync.when(
      data: (atleta) => atleta != null
          ? AreaAtletaHomeScreen(atleta: atleta)
          : _corpoClub(clubAsync),
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      ),
      error: (_, _) => _corpoClub(clubAsync),
    );

    final Widget corpo;
    final Widget? barraInferiore;
    if (mostraTab && navigazioneLaterale) {
      corpo = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: _tabIndex,
            onDestinationSelected: (index) => setState(() => _tabIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinazioniTab)
                NavigationRailDestination(
                  icon: Icon(d.icona),
                  selectedIcon: Icon(d.iconaSelezionata),
                  label: Text(d.etichetta),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: corpoPrincipale),
        ],
      );
      barraInferiore = null;
    } else {
      corpo = corpoPrincipale;
      barraInferiore = mostraTab
          ? NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) =>
                  setState(() => _tabIndex = index),
              destinations: [
                for (final d in _destinazioniTab)
                  NavigationDestination(
                    icon: Icon(d.icona),
                    selectedIcon: Icon(d.iconaSelezionata),
                    label: d.etichetta,
                  ),
              ],
            )
          : null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Image.asset('assets/images/logo.png'),
        ),
        title: Text(club?.nome ?? 'WaterTactics'),
        actions: [
          if (club != null && !areaAtleta) _NotificheIndicator(clubId: club.id),
          const _InstallaPwaButton(),
          const _SyncStatusIndicator(),
          if (mostraTab)
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Cambia gruppo',
              onPressed: () =>
                  ref.read(selezioneGruppoProvider.notifier).scegli(null),
            ),
          const ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Esci',
            onPressed: _signOut,
          ),
        ],
      ),
      body: corpo,
      bottomNavigationBar: barraInferiore,
    );
  }
}

/// Icona nell'AppBar: visibile solo quando il browser (web) ha segnalato
/// che l'installazione come PWA e' disponibile in questo momento — invece
/// di affidarsi solo al popup automatico di Chrome, che compare secondo
/// criteri suoi non richiamabili a comando (vedi `installabilita_pwa.dart`).
/// No-op/sempre nascosta su Android/iOS/desktop nativi.
class _InstallaPwaButton extends StatelessWidget {
  const _InstallaPwaButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: installabilitaPwa,
      builder: (context, disponibile, _) {
        if (!disponibile) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.install_mobile),
          tooltip: 'Installa l\'app',
          onPressed: installaPwa,
        );
      },
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

/// Icona nell'AppBar: mostra quante notifiche non lette ha il coach (FASE
/// 13, punto 1 — es. un atleta che si e' appena registrato). Nascosta
/// quando non ce ne sono.
class _NotificheIndicator extends ConsumerWidget {
  const _NotificheIndicator({required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nonLette = ref.watch(notificheNonLetteProvider(clubId)).value ?? [];

    if (nonLette.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_outlined),
        tooltip: 'Notifiche',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificheScreen(clubId: clubId),
          ),
        ),
      );
    }

    return IconButton(
      icon: Badge(
        label: Text('${nonLette.length}'),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: '${nonLette.length} notifiche non lette',
      onPressed: () => Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => NotificheScreen(clubId: clubId),
            ),
          )
          .then((_) => ref.invalidate(notificheNonLetteProvider(clubId))),
    );
  }
}
