import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/barra_club_providers.dart';
import '../../core/onboarding/onboarding_coach.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
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
import 'allenatore/cruscotto_allenatore_screen.dart';
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
                VoceHome.oggi => CruscottoAllenatoreScreen(
                  club: club,
                  gruppoId: selezione.gruppoId,
                  onVaiATab: (t) => _vaiAllaTab(
                    voci.indexOf(switch (t) {
                      TabCruscotto.atleti => VoceHome.atleti,
                      TabCruscotto.allenamenti => VoceHome.allenamenti,
                      TabCruscotto.eventi => VoceHome.eventi,
                    }),
                  ),
                ),
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
          ? BarraSchedeTelefono(
              destinazioni: destinazioni,
              colori: coloriTab,
              selezionata: indiceTab,
              onSeleziona: _vaiAllaTab,
            )
          : null;
    }

    return Scaffold(body: corpo, bottomNavigationBar: barraInferiore);
  }
}

/// Barra in basso del telefono. Al posto della NavigationBar di Material,
/// che con 6 voci in 360 px mandava a capo "Allenamenti" e "Schemi
/// tattici": qui ogni etichetta sta sempre su una riga e, se proprio non
/// ci sta, si rimpicciolisce un poco invece di spezzarsi.
class BarraSchedeTelefono extends StatelessWidget {
  const BarraSchedeTelefono({
    required this.destinazioni,
    required this.colori,
    required this.selezionata,
    required this.onSeleziona,
    super.key,
  });

  final List<DestinazioneHome> destinazioni;
  final List<Color> colori;
  final int selezionata;
  final ValueChanged<int> onSeleziona;

  @override
  Widget build(BuildContext context) {
    final c = context.colori;
    return Material(
      color: c.superficie,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.linea)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: LayoutBuilder(
              builder: (context, vincoli) {
                final larghezze = _larghezzeCelle(context, vincoli.maxWidth);
                return Row(
                  children: [
                    for (var i = 0; i < destinazioni.length; i++)
                      SizedBox(
                        width: larghezze[i],
                        child: Semantics(
                          selected: i == selezionata,
                          button: true,
                          label: destinazioni[i].etichetta.replaceAll(
                            '\u00AD',
                            '',
                          ),
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => onSeleziona(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  width: 48,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: i == selezionata
                                        ? colori[i].withValues(alpha: 0.16)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Icon(
                                    i == selezionata
                                        ? destinazioni[i].iconaSelezionata
                                        : destinazioni[i].icona,
                                    size: 22,
                                    color: i == selezionata
                                        ? colori[i]
                                        : c.testoSecondario,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      destinazioni[i].etichettaBreve,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: _stileEtichetta(i == selezionata)
                                          .copyWith(
                                            color: i == selezionata
                                                ? colori[i]
                                                : c.testoSecondario,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static const _dimensioneEtichetta = 12.0;

  TextStyle _stileEtichetta(bool selezionata) =>
      AppTypography.etichetta.copyWith(
        fontSize: _dimensioneEtichetta,
        fontWeight: selezionata ? FontWeight.w700 : FontWeight.w500,
      );

  /// Celle larghe quanto serve alla loro etichetta: con sei celle uguali
  /// "Allenamenti" doveva rimpicciolirsi e su 360 px risultava piu'
  /// piccola delle altre. Cosi' tutte le etichette hanno la stessa misura
  /// e lo spazio avanzato si divide in parti uguali.
  List<double> _larghezzeCelle(BuildContext context, double totale) {
    final n = destinazioni.length;
    final scala = MediaQuery.textScalerOf(context);
    final minime = <double>[
      for (final d in destinazioni)
        math.max(
          52,
          (TextPainter(
                text: TextSpan(
                  text: d.etichettaBreve,
                  style: _stileEtichetta(true),
                ),
                textScaler: scala,
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout()).width +
              10,
        ),
    ];
    final somma = minime.fold<double>(0, (a, b) => a + b);
    // Se non ci stanno neanche cosi' (testo di sistema molto grande),
    // celle uguali: il FittedBox rimpicciolisce l'etichetta senza
    // spezzarla.
    if (somma > totale) return List.filled(n, totale / n);
    final extra = (totale - somma) / n;
    return [for (final m in minime) m + extra];
  }
}
