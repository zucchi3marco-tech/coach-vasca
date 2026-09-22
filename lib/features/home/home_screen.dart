import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/barra_club_providers.dart';
import '../../core/onboarding/onboarding_coach.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_skeleton.dart';
import '../allenamenti/presentation/allenamenti_list_screen.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../atleti/presentation/atleti_list_screen.dart';
import '../club/application/current_club_provider.dart';
import '../club/domain/club.dart';
import '../club/presentation/club_setup_screen.dart';
import '../gare/presentation/gare_list_screen.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../gruppi/application/selezione_gruppo_provider.dart';
import '../gruppi/domain/gruppo.dart';
import '../gruppi/presentation/gruppi_chooser_screen.dart';
import '../gruppi/presentation/gruppi_onboarding_screen.dart';
import '../pallanuoto/presentation/partite_list_screen.dart';
import '../pallanuoto/presentation/schemi_tattici_list_screen.dart';
import '../stagioni/presentation/stagioni_list_screen.dart';
import 'area_atleta_home_screen.dart';
import 'tour_coach.dart';
import 'voci_home.dart';

/// Oltre questa larghezza la barra di navigazione passa dal basso (per
/// telefono/tablet) al lato, come su desktop (analisi video, punto 3.5):
/// in fondo allo schermo la barra e' il punto piu' lontano dal mouse.
const _larghezzaNavigazioneLaterale = 900.0;

/// La home: per l'allenatore le tab (Atleti, Allenamenti, Schemi tattici,
/// Stagioni, Partite/Gare), per l'atleta la sua dashboard. Non ha una
/// AppBar propria: in alto c'è la barra fissa con logo e nome del club
/// (vedi `BarraClubHost`), sopra il Navigator.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingRichiesto = false;

  /// Chiamato da `build()` quando le tab da coach diventano visibili:
  /// controlla (una volta sola per istanza di questa schermata) se il
  /// tour va mostrato, senza bloccare `build()` per il tempo della
  /// lettura da `shared_preferences`.
  void _controllaOnboarding() {
    if (_onboardingRichiesto) return;
    _onboardingRichiesto = true;
    onboardingCoachGiaVisto().then((visto) {
      if (visto || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          mostraTourCoach(context, ref.read(currentClubProvider).value?.sport);
        }
      });
    });
  }

  void _vaiAllaTab(int indice) =>
      ref.read(tabHomeProvider.notifier).imposta(indice);

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
        final voci = vociHome(club.sport);
        final tab = ref.watch(tabHomeProvider);
        return IndexedStack(
          index: tab.clamp(0, voci.length - 1),
          children: [
            for (final voce in voci)
              switch (voce) {
                VoceHome.atleti => AtletiListScreen(
                  clubId: club.id,
                  filtroGruppoId: selezione.gruppoId,
                ),
                VoceHome.allenamenti => AllenamentiListScreen(
                  clubId: club.id,
                  filtroGruppoId: selezione.gruppoId,
                ),
                VoceHome.schemi => SchemiTatticiListScreen(
                  clubId: club.id,
                  filtroGruppoId: selezione.gruppoId,
                  comeTab: true,
                ),
                VoceHome.stagioni => StagioniListScreen(
                  clubId: club.id,
                  filtroGruppoId: selezione.gruppoId,
                ),
                VoceHome.eventi =>
                  club.sport == 'nuoto'
                      ? GareListScreen(
                          clubId: club.id,
                          filtroGruppoId: selezione.gruppoId,
                          onVaiAStagioni: () =>
                              _vaiAllaTab(voci.indexOf(VoceHome.stagioni)),
                        )
                      : PartiteListScreen(
                          clubId: club.id,
                          filtroGruppoId: selezione.gruppoId,
                          onVaiAStagioni: () =>
                              _vaiAllaTab(voci.indexOf(VoceHome.stagioni)),
                        ),
              },
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
    if (mostraTab) _controllaOnboarding();
    final navigazioneLaterale =
        MediaQuery.sizeOf(context).width >= _larghezzaNavigazioneLaterale;
    final voci = vociHome(club?.sport);
    final destinazioni = [
      for (final v in voci) destinazioneHome(v, club?.sport),
    ];
    final coloriTab = [for (final v in voci) coloreVoceHome(context, v)];
    final indiceTab = ref.watch(tabHomeProvider).clamp(0, voci.length - 1);

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
            selectedIndex: indiceTab,
            onDestinationSelected: _vaiAllaTab,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (var i = 0; i < destinazioni.length; i++)
                NavigationRailDestination(
                  icon: Icon(destinazioni[i].icona),
                  selectedIcon: Icon(
                    destinazioni[i].iconaSelezionata,
                    color: coloriTab[i],
                  ),
                  label: Text(destinazioni[i].etichetta),
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
          // NavigationDestination.label vuole una String, non un widget: non
          // si può passare un Text(textAlign: center) per singola voce. La
          // barra Material disegna l'etichetta con un Text semplice che, se
          // va a capo su due righe ("Schemi tattici"), eredita l'allineamento
          // dall'ambiente — di default a sinistra, storta rispetto
          // all'icona sopra. DefaultTextStyle.merge lo corregge per tutta la
          // barra senza toccare nient'altro dello stile.
          ? DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              child: NavigationBar(
                selectedIndex: indiceTab,
                onDestinationSelected: _vaiAllaTab,
                destinations: [
                  for (var i = 0; i < destinazioni.length; i++)
                    NavigationDestination(
                      icon: Icon(destinazioni[i].icona),
                      selectedIcon: Icon(
                        destinazioni[i].iconaSelezionata,
                        color: coloriTab[i],
                      ),
                      label: destinazioni[i].etichetta,
                    ),
                ],
              ),
            )
          : null;
    }

    return Scaffold(body: corpo, bottomNavigationBar: barraInferiore);
  }
}
