import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/barra_club_providers.dart';
import '../../core/navigation/navigator_key.dart';
import '../../core/push/push_notifiche.dart';
import '../../core/pwa/aggiornamento_pwa.dart';
import '../../core/pwa/installabilita_pwa.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/error_messages.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import '../../theme/tema_provider.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../auth/data/auth_repository.dart';
import '../club/application/current_club_provider.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../gruppi/application/selezione_gruppo_provider.dart';
import '../notifiche/application/push_service.dart';
import '../notifiche/data/notifiche_repository.dart';
import '../notifiche/presentation/notifiche_screen.dart';
import 'tour_coach.dart';

/// Mette la barra fissa in alto sopra il Navigator dell'app (nel `builder`
/// di `MaterialApp`): resta visibile su ogni schermata, tranne quelle che
/// la nascondono con `NascondiBarraClub`, e solo con un utente
/// autenticato. La struttura dei widget non cambia mai fra barra visibile
/// e nascosta, così il Navigator (e le schermate aperte) non si smontano.
class BarraClubHost extends ConsumerWidget {
  const BarraClubHost({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessione = ref.watch(authStateChangesProvider).value?.session;
    final autenticato = sessione != null;
    // Una volta per utente e sessione: ri-registra l'iscrizione push se il
    // permesso c'e' gia' (non chiede nulla all'utente).
    if (sessione != null) {
      ref.watch(pushRisincronizzaProvider(sessione.user.id));
    }
    final nascosta = ref.watch(barraClubNascostaProvider) > 0;
    final visibile = autenticato && !nascosta;

    return _OsservatoreAggiornamentoPwa(
      child: Column(
        children: [
          visibile ? const BarraClub() : const SizedBox.shrink(),
          Expanded(
            // La barra assorbe l'area sicura in alto: le schermate sotto
            // non devono lasciarla di nuovo.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: visibile,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostra un avviso quando un nuovo service worker ha preso il controllo
/// della pagina (vedi `aggiornamento_pwa_web.dart`): senza, una PWA
/// installata e tenuta sempre aperta continuerebbe a eseguire codice
/// vecchio finché il coach non la chiude e riapre da sola. Nessun
/// ricaricamento automatico: solo un'azione a portata di tocco.
class _OsservatoreAggiornamentoPwa extends StatefulWidget {
  const _OsservatoreAggiornamentoPwa({required this.child});

  final Widget child;

  @override
  State<_OsservatoreAggiornamentoPwa> createState() =>
      _OsservatoreAggiornamentoPwaState();
}

class _OsservatoreAggiornamentoPwaState
    extends State<_OsservatoreAggiornamentoPwa> {
  @override
  void initState() {
    super.initState();
    aggiornamentoDisponibile.addListener(_mostraAvviso);
  }

  @override
  void dispose() {
    aggiornamentoDisponibile.removeListener(_mostraAvviso);
    super.dispose();
  }

  void _mostraAvviso() {
    if (!aggiornamentoDisponibile.value) return;
    final contesto = contestoNavigatorApp();
    if (contesto == null || !contesto.mounted) return;
    ScaffoldMessenger.of(contesto).showSnackBar(
      const SnackBar(
        content: Text('È disponibile una nuova versione della app.'),
        duration: Duration(days: 1),
        action: SnackBarAction(label: 'Aggiorna', onPressed: aggiornaPwa),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _AzioneMenu {
  notifiche,
  notifichePush,
  sincronizza,
  installa,
  cambiaGruppo,
  guida,
  esci,
}

/// La barra: logo (bottone home), nome del club, menu ☰ e tema.
///
/// Sta fuori dal Navigator: niente `PopupMenuButton`, `Tooltip` né
/// `showDialog` con il proprio contesto. Menu e dialoghi passano dalla
/// [navigatorKeyApp] (vedi `contestoNavigatorApp`).
class BarraClub extends ConsumerWidget {
  const BarraClub({super.key});

  static const altezza = 44.0;

  void _tornaAllaHome(WidgetRef ref, {required bool areaAtleta}) {
    navigatorKeyApp.currentState?.popUntil((route) => route.isFirst);
    // L'allenatore non ha una schermata "dashboard" a parte: la sua home
    // è la prima tab (Atleti, con il riepilogo del gruppo). L'atleta ha già
    // la dashboard come prima schermata.
    if (!areaAtleta) ref.read(tabHomeProvider.notifier).imposta(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final atleta = ref.watch(currentAtletaProvider).value;
    final areaAtleta = atleta != null;
    final clubCoach = ref.watch(currentClubProvider).value;
    final clubAtleta = atleta == null
        ? null
        : ref.watch(clubAtletaProvider(atleta.clubId)).value;
    final nome = (areaAtleta ? clubAtleta?.nome : clubCoach?.nome);
    // Le notifiche del club le vede il coach, quelle personali (es. una
    // convocazione) l'atleta: le regole di accesso del database filtrano.
    final clubNotificheId = atleta?.clubId ?? clubCoach?.id;
    final nonLette = clubNotificheId != null
        ? ref.watch(notificheNonLetteProvider(clubNotificheId)).value ??
              const []
        : const [];
    final temaScelto = ref.watch(temaAppProvider);

    return Material(
      color: colori.superficie,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colori.linea)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: SizedBox(
            height: altezza,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Torna alla home',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _tornaAllaHome(ref, areaAtleta: areaAtleta),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: altezza - AppSpacing.s8,
                        height: altezza - AppSpacing.s8,
                        // Decodificato alla misura di uso (con margine per
                        // gli schermi ad alta densità), non a piena
                        // risoluzione.
                        cacheWidth: 144,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  // Un nome di club lungo su telefono: invece di troncarlo
                  // a metà parola passa su due righe, un po' più piccolo.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final testo = nome ?? 'WaterTactics';
                      final stile = AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      );
                      final unaRiga = TextPainter(
                        text: TextSpan(text: testo, style: stile),
                        maxLines: 1,
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout(maxWidth: constraints.maxWidth);
                      final entra = !unaRiga.didExceedMaxLines;
                      unaRiga.dispose();
                      return Text(
                        testo,
                        maxLines: entra ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: entra
                            ? stile
                            : stile.copyWith(fontSize: 13, height: 1.2),
                      );
                    },
                  ),
                ),
                Builder(
                  builder: (bottoneContext) => IconButton(
                    icon: Icon(temaScelto.icona),
                    onPressed: () => _apriMenuTema(bottoneContext, ref),
                  ),
                ),
                Builder(
                  builder: (bottoneContext) => IconButton(
                    icon: nonLette.isEmpty
                        ? const Icon(Icons.menu)
                        : Badge(
                            label: Text('${nonLette.length}'),
                            child: const Icon(Icons.menu),
                          ),
                    onPressed: () => _apriMenuPrincipale(bottoneContext, ref),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dove aprire un menu ancorato a un pulsante della barra: subito sotto la
/// barra, con il bordo destro del menu allineato al bordo destro del
/// pulsante (come un `PopupMenuButton`), relativo all'overlay del
/// Navigator.
RelativeRect _posizioneSotto(
  BuildContext bottoneContext,
  BuildContext overlayContext,
) {
  final bottone = bottoneContext.findRenderObject()! as RenderBox;
  final overlay = overlayContext.findRenderObject()! as RenderBox;
  final origineOverlay = overlay.localToGlobal(Offset.zero);
  final destra =
      bottone.localToGlobal(bottone.size.bottomRight(Offset.zero)).dx -
      origineOverlay.dx;
  return RelativeRect.fromLTRB(
    destra,
    0,
    overlay.size.width - destra,
    overlay.size.height,
  );
}

Future<void> _apriMenuTema(BuildContext bottoneContext, WidgetRef ref) async {
  final overlayContext = contestoNavigatorApp();
  if (overlayContext == null) return;
  final scelta = ref.read(temaAppProvider);
  final nuova = await showMenu<ThemeMode>(
    context: overlayContext,
    position: _posizioneSotto(bottoneContext, overlayContext),
    initialValue: scelta,
    items: [
      for (final opzione in ThemeMode.values)
        PopupMenuItem(
          value: opzione,
          child: Row(
            children: [
              Icon(opzione.icona, size: 20),
              const SizedBox(width: 12),
              Text(opzione.etichetta),
              if (opzione == scelta) ...[
                const Spacer(),
                const Icon(Icons.check, size: 20),
              ],
            ],
          ),
        ),
    ],
  );
  if (nuova != null) ref.read(temaAppProvider.notifier).imposta(nuova);
}

Future<void> _apriMenuPrincipale(
  BuildContext bottoneContext,
  WidgetRef ref,
) async {
  final overlayContext = contestoNavigatorApp();
  if (overlayContext == null) return;

  final areaAtleta = ref.read(currentAtletaProvider).value != null;
  final club = areaAtleta ? null : ref.read(currentClubProvider).value;
  final gruppi = club == null
      ? const []
      : ref.read(gruppiListProvider(club.id)).value ?? const [];
  final selezione = ref.read(selezioneGruppoProvider);
  final mostraTab =
      !areaAtleta && club != null && gruppi.isNotEmpty && selezione != null;
  final clubNotificheId =
      ref.read(currentAtletaProvider).value?.clubId ?? club?.id;
  final mostraNotifiche = clubNotificheId != null;
  final nonLette = clubNotificheId != null
      ? ref.read(notificheNonLetteProvider(clubNotificheId)).value ?? const []
      : const [];
  final inCoda = ref.read(pendingOperationsCountProvider).value ?? 0;
  final installabile = installabilitaPwa.value;
  final statoPushAttuale = await ref.read(pushServiceProvider).stato();
  if (!bottoneContext.mounted || !overlayContext.mounted) return;

  final scelta = await showMenu<_AzioneMenu>(
    context: overlayContext,
    position: _posizioneSotto(bottoneContext, overlayContext),
    items: [
      if (mostraNotifiche)
        PopupMenuItem(
          value: _AzioneMenu.notifiche,
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
      if (statoPushAttuale != StatoPush.nonSupportato)
        PopupMenuItem(
          value: _AzioneMenu.notifichePush,
          enabled: statoPushAttuale != StatoPush.attivo,
          child: ListTile(
            leading: Icon(
              statoPushAttuale == StatoPush.attivo
                  ? Icons.notifications_active_outlined
                  : Icons.notification_add_outlined,
            ),
            title: Text(
              statoPushAttuale == StatoPush.attivo
                  ? 'Notifiche sul telefono attive'
                  : 'Attiva le notifiche sul telefono',
            ),
          ),
        ),
      PopupMenuItem(
        value: _AzioneMenu.sincronizza,
        enabled: inCoda > 0,
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
        const PopupMenuItem(
          value: _AzioneMenu.installa,
          child: ListTile(
            leading: Icon(Icons.install_mobile),
            title: Text('Installa l\'app'),
          ),
        ),
      if (mostraTab) ...const [
        PopupMenuItem(
          value: _AzioneMenu.cambiaGruppo,
          child: ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Cambia gruppo'),
          ),
        ),
        PopupMenuItem(
          value: _AzioneMenu.guida,
          child: ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Rivedi la guida'),
          ),
        ),
      ],
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _AzioneMenu.esci,
        child: ListTile(leading: Icon(Icons.logout), title: Text('Esci')),
      ),
    ],
  );

  switch (scelta) {
    case null:
      return;
    case _AzioneMenu.notifiche:
      final clubId = clubNotificheId;
      if (clubId == null) return;
      await navigatorKeyApp.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => NotificheScreen(clubId: clubId),
        ),
      );
      ref.invalidate(notificheNonLetteProvider(clubId));
    case _AzioneMenu.notifichePush:
      if (overlayContext.mounted) {
        await _gestisciNotifichePush(ref, overlayContext, statoPushAttuale);
      }
    case _AzioneMenu.sincronizza:
      await ref.read(syncEngineProvider).processQueue();
    case _AzioneMenu.installa:
      installaPwa();
    case _AzioneMenu.cambiaGruppo:
      navigatorKeyApp.currentState?.popUntil((route) => route.isFirst);
      ref.read(selezioneGruppoProvider.notifier).scegli(null);
    case _AzioneMenu.guida:
      final contesto = contestoNavigatorApp();
      if (contesto != null && contesto.mounted) {
        await mostraTourCoach(contesto, club?.sport);
      }
    case _AzioneMenu.esci:
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (e) {
        if (overlayContext.mounted) {
          ScaffoldMessenger.of(overlayContext).showSnackBar(
            SnackBar(
              content: Text('Uscita non riuscita: ${messaggioErrore(e)}'),
            ),
          );
        }
      }
  }
}

/// Attivazione delle notifiche push dal menu: il permesso del browser si
/// chiede solo da qui (un tocco dell'utente, come esige il browser).
Future<void> _gestisciNotifichePush(
  WidgetRef ref,
  BuildContext contesto,
  StatoPush stato,
) async {
  Future<void> spiega(String titolo, String testo) => showDialog<void>(
    context: contesto,
    builder: (context) => AlertDialog(
      title: Text(titolo),
      content: Text(testo),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ho capito'),
        ),
      ],
    ),
  );

  const bloccate =
      'Le notifiche sono bloccate per questo sito. Riattivale dalle '
      'impostazioni del browser (in Chrome: il lucchetto accanto '
      "all'indirizzo, poi Notifiche) e riprova da qui.";

  switch (stato) {
    case StatoPush.installaPrima:
      await spiega(
        'Aggiungi prima l\'app alla Home',
        'Su iPhone e iPad le notifiche funzionano solo se l\'app è '
            'aggiunta alla schermata Home: in Safari tocca Condividi, poi '
            '"Aggiungi alla schermata Home", quindi riaprila da lì e scegli '
            'di nuovo questa voce.',
      );
    case StatoPush.negato:
      await spiega('Notifiche bloccate', bloccate);
    case StatoPush.daAttivare:
      try {
        final nuovo = await ref.read(pushServiceProvider).attiva();
        if (!contesto.mounted) return;
        final testo = switch (nuovo) {
          StatoPush.attivo => 'Notifiche attivate su questo telefono.',
          StatoPush.negato => bloccate,
          _ => 'Notifiche non attivate.',
        };
        ScaffoldMessenger.of(contesto)
            .showSnackBar(SnackBar(content: Text(testo)));
      } catch (e) {
        if (!contesto.mounted) return;
        ScaffoldMessenger.of(contesto).showSnackBar(
          SnackBar(
            content: Text('Attivazione non riuscita: ${messaggioErrore(e)}'),
          ),
        );
      }
    case StatoPush.nonSupportato:
    case StatoPush.attivo:
      return;
  }
}
