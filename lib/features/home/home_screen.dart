import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/onboarding/onboarding_coach.dart';
import '../../core/pwa/installabilita_pwa.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../theme/colori_app.dart';
import '../../theme/tokens_dominio.dart';
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
import '../gare/presentation/gare_list_screen.dart';
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

/// La quarta voce è "Partite" per la pallanuoto e "Gare" per il nuoto
/// (sport nullo, cioè club vecchi senza sport: "Partite").
const _destinazioneGare = (
  icona: Icons.emoji_events_outlined,
  iconaSelezionata: Icons.emoji_events,
  etichetta: 'Gare',
);

const _guidaGare = (
  icona: Icons.emoji_events_outlined,
  titolo: 'Gare',
  descrizione:
      'Le gare del calendario: si aggiungono dalla stagione, toccando un '
      'giorno.',
);

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

/// Testo del tour mostrato una sola volta, al primo accesso da
/// allenatore — stessi 4 elementi di [_destinazioniTab], con una
/// spiegazione in più.
const _guidaTab = [
  (
    icona: Icons.groups_outlined,
    titolo: 'Atleti',
    descrizione:
        'L\'elenco dei tuoi atleti: profili, personal best, presenze e '
        'carico di lavoro.',
  ),
  (
    icona: Icons.calendar_month_outlined,
    titolo: 'Allenamenti',
    descrizione:
        'Pianifica le sedute con le loro serie, e segna le presenze a '
        'bordo vasca.',
  ),
  (
    icona: Icons.event_note_outlined,
    titolo: 'Stagioni',
    descrizione: 'Organizza la stagione in macrocicli, mesocicli e microcicli.',
  ),
  (
    icona: Icons.sports_outlined,
    titolo: 'Partite',
    descrizione:
        'Pallanuoto: distinta, eventi dal vivo, referti e statistiche di '
        'squadra.',
  ),
];

List<({IconData icona, IconData iconaSelezionata, String etichetta})>
_destinazioni(String? sport) => [
  ..._destinazioniTab.take(3),
  if (sport == 'nuoto') _destinazioneGare else _destinazioniTab[3],
];

List<({IconData icona, String titolo, String descrizione})> _guida(
  String? sport,
) => [..._guidaTab.take(3), if (sport == 'nuoto') _guidaGare else _guidaTab[3]];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
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
        if (mounted) _mostraOnboarding();
      });
    });
  }

  Future<void> _mostraOnboarding() async {
    // Segnato come visto subito, prima del tocco su "Ho capito": anche
    // chiudendo il dialogo toccando fuori o con "indietro" non deve
    // ripresentarsi al prossimo avvio.
    await segnaOnboardingCoachVisto();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Benvenuto su WaterTactics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final voce in _guida(
                ref.read(currentClubProvider).value?.sport,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(voce.icona),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voce.titolo,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              voce.descrizione,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ho capito, iniziamo'),
          ),
        ],
      ),
    );
  }

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
            AllenamentiListScreen(
              clubId: club.id,
              filtroGruppoId: selezione.gruppoId,
            ),
            StagioniListScreen(
              clubId: club.id,
              filtroGruppoId: selezione.gruppoId,
            ),
            if (club.sport == 'nuoto')
              GareListScreen(
                clubId: club.id,
                filtroGruppoId: selezione.gruppoId,
                onVaiAStagioni: () => setState(() => _tabIndex = 2),
              )
            else
              PartiteListScreen(
                clubId: club.id,
                filtroGruppoId: selezione.gruppoId,
                onVaiAStagioni: () => setState(() => _tabIndex = 2),
              ),
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
    // Un colore diverso per tab quando selezionata (tavolozza "evidenza",
    // stessa eccezione della dashboard atleta — vedi DESIGN.md "Dove
    // spendere l'audacia"): Atleti resta sul colore d'azione (l'ancora
    // neutra, come "Il tuo club" nella dashboard), le altre tre hanno un
    // colore vivace ciascuna. Da tenere in ordine con [_destinazioniTab].
    final destinazioni = _destinazioni(club?.sport);
    final coloriTab = [
      context.colori.azione,
      context.dominio.evidenzaCiano,
      context.dominio.evidenzaVerde,
      context.dominio.evidenzaAmbra,
    ];

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
          ? NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (index) =>
                  setState(() => _tabIndex = index),
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
            )
          : null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            // L'allenatore non ha una vera schermata "dashboard" a parte
            // (la sua home sono le 4 tab): il tocco sul logo torna alla
            // prima, Atleti. L'atleta ha già la dashboard come home:
            // il tocco chiude eventuali schermate aperte sopra di essa.
            if (areaAtleta) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              setState(() => _tabIndex = 0);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Image.asset('assets/images/logo.png'),
          ),
        ),
        title: Text(club?.nome ?? 'WaterTactics'),
        actions: [
          _MenuPrincipale(
            club: club,
            areaAtleta: areaAtleta,
            mostraTab: mostraTab,
            onCambiaGruppo: () =>
                ref.read(selezioneGruppoProvider.notifier).scegli(null),
            onRivediGuida: _mostraOnboarding,
            onEsci: _signOut,
          ),
          const ThemeToggle(),
        ],
      ),
      body: corpo,
      bottomNavigationBar: barraInferiore,
    );
  }
}

/// Un'unica icona nell'AppBar per tutte le azioni secondarie — prima
/// erano fino a 6 icone separate (notifiche, installa PWA, stato sync,
/// cambia gruppo, tema, esci). Il tema resta a parte (è già un
/// popup-menu compatto a sé, non un'icona "in più"): tutto il resto sta
/// qui, con il badge del numero di notifiche non lette sull'icona
/// principale invece che su una singola voce.
class _MenuPrincipale extends ConsumerWidget {
  const _MenuPrincipale({
    required this.club,
    required this.areaAtleta,
    required this.mostraTab,
    required this.onCambiaGruppo,
    required this.onRivediGuida,
    required this.onEsci,
  });

  final Club? club;
  final bool areaAtleta;
  final bool mostraTab;
  final VoidCallback onCambiaGruppo;
  final VoidCallback onRivediGuida;
  final VoidCallback onEsci;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostraNotifiche = club != null && !areaAtleta;
    final nonLette = mostraNotifiche
        ? ref.watch(notificheNonLetteProvider(club!.id)).value ?? const []
        : const [];
    final inCoda = ref.watch(pendingOperationsCountProvider).value ?? 0;
    final installabile = installabilitaPwa.value;

    return PopupMenuButton<void>(
      tooltip: 'Altro',
      icon: nonLette.isEmpty
          ? const Icon(Icons.menu)
          : Badge(
              label: Text('${nonLette.length}'),
              child: const Icon(Icons.menu),
            ),
      itemBuilder: (context) => [
        if (mostraNotifiche)
          PopupMenuItem(
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificheScreen(clubId: club!.id),
                  ),
                )
                .then(
                  (_) => ref.invalidate(notificheNonLetteProvider(club!.id)),
                ),
            child: ListTile(
              leading: Icon(
                nonLette.isEmpty
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_outlined,
              ),
              title: const Text('Notifiche'),
              trailing: nonLette.isEmpty ? null : Text('${nonLette.length}'),
            ),
          ),
        PopupMenuItem(
          enabled: inCoda > 0,
          onTap: inCoda == 0
              ? null
              : () => ref.read(syncEngineProvider).processQueue(),
          child: ListTile(
            leading: Icon(
              inCoda == 0
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_upload_outlined,
            ),
            title: Text(inCoda == 0 ? 'Tutto sincronizzato' : 'Sincronizza'),
            subtitle: inCoda == 0
                ? null
                : Text('$inCoda modifiche in coda, in attesa di rete'),
          ),
        ),
        if (installabile)
          PopupMenuItem(
            onTap: installaPwa,
            child: const ListTile(
              leading: Icon(Icons.install_mobile),
              title: Text('Installa l\'app'),
            ),
          ),
        if (mostraTab) ...[
          PopupMenuItem(
            onTap: onCambiaGruppo,
            child: const ListTile(
              leading: Icon(Icons.groups_outlined),
              title: Text('Cambia gruppo'),
            ),
          ),
          PopupMenuItem(
            onTap: onRivediGuida,
            child: const ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Rivedi la guida'),
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: onEsci,
          child: const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Esci'),
          ),
        ),
      ],
    );
  }
}
