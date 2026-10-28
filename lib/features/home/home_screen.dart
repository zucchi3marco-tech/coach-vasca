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
import '../../widgets/secondary_button.dart';
import '../allenamenti/presentation/allenamenti_list_screen.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../atleti/presentation/atleti_list_screen.dart';
import '../club/application/current_club_provider.dart';
import '../club/application/membri_club_providers.dart';
import '../club/domain/club.dart';
import '../club/domain/ruolo_club.dart';
import '../club/presentation/club_setup_screen.dart';
import '../configurazione/application/configurazione_providers.dart';
import '../configurazione/domain/stato_configurazione.dart';
import '../configurazione/presentation/configurazione_guidata_screen.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../gruppi/application/selezione_gruppo_provider.dart';
import '../gruppi/domain/gruppo.dart';
import '../gruppi/presentation/gruppi_chooser_screen.dart';
import '../gruppi/presentation/gruppi_onboarding_screen.dart';
import '../novita/data/novita_viste.dart';
import '../novita/presentation/finestra_novita.dart';
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
/// Stagioni, Partite), per l'atleta la sua dashboard. Non ha una
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
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (visto) {
          // Dopo un aggiornamento, le novità importanti (una volta sola).
          mostraNovitaSeServe(context, atleta: false);
          return;
        }
        // La guida racconta già le cose nuove: le novità di oggi non si
        // ripresentano dopo.
        segnaNovitaViste();
        mostraTourCoach(context, vaiAllaScheda: _vaiAllaTab);
      });
    });
  }

  bool _novitaAtletaRichieste = false;

  /// Per l'atleta, all'apertura della sua home: le novità importanti per
  /// gli atleti dopo un aggiornamento.
  void _controllaNovitaAtleta() {
    if (_novitaAtletaRichieste) return;
    _novitaAtletaRichieste = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostraNovitaSeServe(context, atleta: true);
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

  /// La configurazione guidata nel corpo della home, dalle squadre o dal
  /// primo passo ancora da fare (almeno gli allenatori) se le squadre ci
  /// sono già.
  Widget _configurazioneGuidata(Club club, List<Gruppo> gruppi) {
    var daPasso = PassoConfigurazione.squadre;
    if (gruppi.isNotEmpty) {
      final prossimo = ref
          .watch(statoConfigurazioneProvider(club.id))
          .value
          ?.prossimo;
      daPasso = prossimo != null && prossimo.index > daPasso.index
          ? prossimo
          : PassoConfigurazione.allenatori;
    }
    return ConfigurazioneGuidataScreen(
      club: club,
      daPasso: daPasso,
      onFine: () => ref.read(configurazioneInCorsoProvider.notifier).finisci(),
    );
  }

  Widget _corpoDaCoach(Club club) {
    final gruppiAsync = ref.watch(gruppiListProvider(club.id));
    final inCorso = ref.watch(configurazioneInCorsoProvider) == club.id;
    return gruppiAsync.when(
      data: (gruppi) {
        // Appena creato il club, o riaperta l'app a metà: il responsabile
        // viene guidato passo per passo.
        if (inCorso) return _configurazioneGuidata(club, gruppi);
        if (gruppi.isEmpty) {
          final ruolo = ref.watch(mioRuoloProvider(club.id));
          if (ruolo.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: LoadingSkeletonList(righe: 4),
            );
          }
          if (ruolo.value == RuoloClub.responsabile) {
            return _configurazioneGuidata(club, gruppi);
          }
          return GruppiOnboardingScreen(clubId: club.id);
        }
        final selezione = ref.watch(selezioneGruppoProvider);
        if (selezione == null) {
          return GruppiChooserScreen(clubId: club.id);
        }
        final voci = vociHome();
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
                VoceHome.eventi => PartiteListScreen(
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
    // Durante la configurazione guidata niente tab né tour: partono quando
    // finisce, come sempre.
    final inCorso =
        club != null && ref.watch(configurazioneInCorsoProvider) == club.id;
    final mostraTab =
        !areaAtleta &&
        club != null &&
        gruppi.isNotEmpty &&
        selezione != null &&
        !inCorso;
    if (mostraTab) _controllaOnboarding();
    if (areaAtleta) _controllaNovitaAtleta();
    final navigazioneLaterale =
        MediaQuery.sizeOf(context).width >= _larghezzaNavigazioneLaterale;
    final voci = vociHome();
    final destinazioni = [for (final v in voci) destinazioneHome(v)];
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
      // Prima qui si passava al club, e un atleta si vedeva proporre
      // "Crea il tuo club".
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(
              messaggio: 'Non riesco a leggere il tuo account.',
              suggerimento:
                  'Tocca «Riprova». Se l\'errore continua, chiudi e riapri '
                  'l\'app.',
              dettaglioTecnico: messaggioErrore(error),
            ),
            const SizedBox(height: AppSpacing.s12),
            SecondaryButton(
              label: 'Riprova',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(currentAtletaProvider),
            ),
          ],
        ),
      ),
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
