import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/demo/modalita_demo.dart';
import '../../core/navigation/navigator_key.dart';
import '../../core/rete/controllo_rete.dart';
import '../../core/rete/stato_rete.dart';
import '../../core/sync/modifiche_rifiutate.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/utils/date_italiane.dart';
import '../../core/utils/giorni.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/colori_app.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../club/application/current_club_provider.dart';
import '../segnalazioni/presentation/scrivimi_screen.dart';
import 'contesto_segnalazione.dart';

/// La spia della rete nella barra: si vede solo quando qualcosa non va
/// (scelta del coach, proposta 28). In ordine di importanza: modifiche che
/// il server ha rifiutato (rosso), niente rete (con quante modifiche
/// aspettano), modifiche in coda che stanno partendo. Con tutto a posto non
/// c'è. Un tocco apre il riquadro «La rete».
///
/// Sta sopra il Navigator, come il resto della barra: niente `Tooltip` né
/// `showModalBottomSheet` con il proprio contesto, il riquadro passa da
/// [navigatorKeyApp] (vedi `contestoNavigatorApp`).
class SpiaRete extends ConsumerWidget {
  const SpiaRete({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nella demo ogni modifica resta in coda per sempre (il server non
    // c'è): la spia sarebbe sempre accesa e non direbbe niente.
    if (dotenv.isInitialized && modalitaDemo) return const SizedBox.shrink();
    final senzaRete = ref.watch(senzaReteDaProvider) != null;
    final inCoda = ref.watch(pendingOperationsCountProvider).value ?? 0;
    final rifiutate = ref.watch(modificheRifiutateProvider).length;
    if (!senzaRete && inCoda == 0 && rifiutate == 0) {
      return const SizedBox.shrink();
    }

    final colori = context.colori;
    final Widget icona;
    if (rifiutate > 0) {
      icona = Icon(Icons.sync_problem_outlined, color: colori.rosso);
    } else {
      final nuvola = Icon(
        senzaRete ? Icons.cloud_off_outlined : Icons.cloud_upload_outlined,
      );
      icona = inCoda == 0
          ? nuvola
          // Il numero non è un errore: il colore dell'azione, non il rosso.
          : Badge(
              backgroundColor: colori.azione,
              textColor: colori.azioneInk,
              label: Text('$inCoda'),
              child: nuvola,
            );
    }

    void apri() => _apriRiquadroRete(context, ref);
    return Semantics(
      container: true,
      button: true,
      label: _descriviStato(
        senzaRete: senzaRete,
        inCoda: inCoda,
        rifiutate: rifiutate,
      ),
      onTap: apri,
      excludeSemantics: true,
      child: IconButton(icon: icona, onPressed: apri),
    );
  }
}

String _modifiche(int n, String singolare, String plurale) =>
    n == 1 ? '1 modifica $singolare' : '$n modifiche $plurale';

/// A parole, per chi usa un lettore di schermo: "Senza rete, 3 modifiche in
/// attesa".
String _descriviStato({
  required bool senzaRete,
  required int inCoda,
  required int rifiutate,
}) {
  final inAttesa = _modifiche(inCoda, 'in attesa', 'in attesa');
  return [
    if (rifiutate > 0)
      _modifiche(
        rifiutate,
        'non accettata dal server',
        'non accettate dal server',
      ),
    if (senzaRete)
      inCoda > 0 ? 'Senza rete, $inAttesa' : 'Senza rete'
    else if (inCoda > 0)
      inAttesa,
  ].join('. ');
}

/// Apre il riquadro «La rete» e, se chi legge tocca «Segnala», la pagina di
/// «Scrivimi» con le modifiche rifiutate già scritte.
Future<void> _apriRiquadroRete(BuildContext contesto, WidgetRef ref) async {
  final overlayContext = contestoNavigatorApp();
  if (overlayContext == null) return;
  final testo = await showModalBottomSheet<String>(
    context: overlayContext,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _RiquadroRete(),
  );
  if (testo == null || !contesto.mounted) return;

  final club = ref.read(currentClubProvider).value;
  if (club == null) return;
  // Il riquadro si sta chiudendo: la schermata si fa quando è sparito.
  final contestoSegn = await contestoSegnalazione(
    ref,
    club.sport,
    conSchede: homeConSchede(ref),
  );
  await navigatorKeyApp.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => ScrivimiScreen(
        clubId: club.id,
        contesto: contestoSegn,
        testoIniziale: testo,
      ),
    ),
  );
}

/// Quanto resta acceso l'indicatore di «Riprova ora» almeno: se la rete
/// risponde subito, senza una pausa non si vedrebbe che ha lavorato (e la
/// coda ha il tempo di aggiornare il suo numero).
const _pausaMinima = Duration(milliseconds: 600);

/// Il riquadro dal basso: com'è la rete, cosa aspetta di partire, il
/// pulsante per riprovare subito e, se ci sono, le modifiche che il server
/// non ha accettato. Guarda gli stessi provider della spia: si aggiorna da
/// solo mentre è aperto. Si chiude con il testo della segnalazione quando si
/// tocca «Segnala».
class _RiquadroRete extends ConsumerStatefulWidget {
  const _RiquadroRete();

  @override
  ConsumerState<_RiquadroRete> createState() => _RiquadroReteState();
}

class _RiquadroReteState extends ConsumerState<_RiquadroRete> {
  bool _inCorso = false;
  bool _haRiprovato = false;

  Future<void> _riprova() async {
    if (_inCorso) return;
    // Letti subito: se il riquadro si chiude a metà, `ref` non si può più
    // usare.
    final controlla = ref.read(controllaReteProvider);
    final sincronizza = ref.read(syncEngineProvider);
    setState(() => _inCorso = true);
    try {
      await Future.wait([
        () async {
          await controlla();
          await sincronizza.processQueue();
        }(),
        Future<void>.delayed(_pausaMinima),
      ]);
    } catch (_) {
      // Com'è andata lo dicono lo stato della rete e la coda, che questa
      // schermata guarda: un errore qui non deve lasciare l'indicatore
      // acceso.
    }
    if (mounted) {
      setState(() {
        _inCorso = false;
        _haRiprovato = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final senzaReteDa = ref.watch(senzaReteDaProvider);
    final senzaRete = senzaReteDa != null;
    final inCoda = ref.watch(pendingOperationsCountProvider).value ?? 0;
    final rifiutate = ref.watch(modificheRifiutateProvider);
    final areaAtleta = ref.watch(currentAtletaProvider).value != null;
    // Come «Scrivimi» nel menu ☰: allenatori e assistenti; gli atleti
    // parlano con il loro allenatore.
    final puoScrivere =
        !areaAtleta && ref.watch(currentClubProvider).value != null;
    // «Ho capito»: l'elenco delle modifiche rifiutate si svuota.
    final hoCapito = SecondaryButton(
      label: 'Ho capito',
      unaRiga: true,
      onPressed: () => ref.read(modificheRifiutateProvider.notifier).svuota(),
    );
    final mostraRiprova = senzaRete || inCoda > 0 || _inCorso;
    final esito = _haRiprovato && !_inCorso
        ? _esitoRiprova(
            senzaRete: senzaRete,
            inCoda: inCoda,
            conRifiutate: rifiutate.isNotEmpty,
          )
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'La rete',
                style: AppTypography.titolo.copyWith(color: colori.testo),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _StatoDellaRete(senzaReteDa: senzaReteDa, inCoda: inCoda),
            if (mostraRiprova) ...[
              const SizedBox(height: AppSpacing.s20),
              PrimaryButton(
                label: 'Riprova ora',
                icon: Icons.refresh,
                isLoading: _inCorso,
                onPressed: _riprova,
              ),
            ],
            if (esito != null) ...[
              const SizedBox(height: AppSpacing.s12),
              // Si legge da solo con il lettore di schermo.
              Semantics(
                liveRegion: true,
                child: Text(
                  esito,
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              ),
            ],
            if (rifiutate.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s28),
              const ErrorBanner(
                messaggio: 'Modifiche non partite',
                suggerimento:
                    'Queste modifiche non sono partite e non partiranno: '
                    'rifalle dall\'app.',
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final (i, m) in rifiutate.indexed) ...[
                if (i > 0) Divider(height: 1, color: colori.lineaForte),
                _RigaRifiutata(modifica: m),
              ],
              const SizedBox(height: AppSpacing.s16),
              if (areaAtleta) ...[
                Text(
                  'Se ti serve aiuto, dillo al tuo allenatore.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                hoCapito,
              ] else
                Row(
                  children: [
                    if (puoScrivere) ...[
                      Expanded(
                        child: SecondaryButton(
                          label: 'Segnala',
                          unaRiga: true,
                          onPressed: () =>
                              Navigator.of(context)
                                  .pop(_testoSegnalazione(rifiutate)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spazioBersagli),
                    ],
                    Expanded(child: hoCapito),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Com'è andata dopo «Riprova ora», letta dallo stato di adesso.
String _esitoRiprova({
  required bool senzaRete,
  required int inCoda,
  required bool conRifiutate,
}) {
  if (senzaRete) {
    return 'Il server ancora non risponde: riprovo da solo ogni 20 secondi.';
  }
  if (inCoda > 0) return 'Ancora $inCoda in attesa.';
  // Se il server ha rifiutato qualcosa, «tutto partito» direbbe il falso.
  return conRifiutate ? 'Non c\'è più niente in attesa.' : 'Tutto partito.';
}

/// «Senza rete dalle 18:42» se è oggi, altrimenti «Senza rete dal 18
/// ottobre, alle 18:42».
String _senzaReteDal(DateTime da, {DateTime? adesso}) {
  final quando = da.toLocal();
  final oggi = giorniTra(quando, adesso ?? DateTime.now()) == 0;
  return oggi
      ? 'Senza rete dalle ${oraMinuti(quando)}'
      : 'Senza rete dal ${giornoMese(quando)}, alle ${oraMinuti(quando)}';
}

/// La prima parte del riquadro: se c'è la rete, da quando manca e quante
/// modifiche aspettano di partire.
class _StatoDellaRete extends StatelessWidget {
  const _StatoDellaRete({required this.senzaReteDa, required this.inCoda});

  final DateTime? senzaReteDa;
  final int inCoda;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final senzaRete = senzaReteDa;
    final icona = senzaRete != null
        ? Icons.cloud_off_outlined
        : inCoda > 0
        ? Icons.cloud_upload_outlined
        : Icons.cloud_done_outlined;
    final titolo = senzaRete != null ? _senzaReteDal(senzaRete) : 'In rete';
    final sotto = senzaRete != null
        ? 'Il server non risponde. Quello che salvi resta sul telefono e '
              'parte da solo quando torna la rete.'
        : inCoda > 0
        ? 'Le modifiche stanno partendo.'
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icona, size: 24, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titolo,
                style: AppTypography.numerica(AppTypography.corpoForte)
                    .copyWith(color: colori.testo),
              ),
              if (sotto != null) ...[
                const SizedBox(height: AppSpacing.s4),
                Text(
                  sotto,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
              if (inCoda > 0) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  inCoda == 1
                      ? '1 modifica aspetta di partire'
                      : '$inCoda modifiche aspettano di partire',
                  style: AppTypography.numerica(AppTypography.corpo)
                      .copyWith(color: colori.testo),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Una modifica che il server non ha accettato: cosa era, perché, quando.
class _RigaRifiutata extends StatelessWidget {
  const _RigaRifiutata({required this.modifica});

  final ModificaRifiutata modifica;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final m = modifica;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${m.cosa} · ${m.tipo}',
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          Text(
            m.perche,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          Text(
            dataEOra(m.quando.toLocal()),
            style: AppTypography.numerica(AppTypography.piccolo)
                .copyWith(color: colori.testoSecondario),
          ),
        ],
      ),
    );
  }
}

/// Il testo che «Scrivimi» trova già scritto: una riga per modifica, con
/// la risposta del server (codice e messaggio, accorciato) se c'è. Sta nei
/// limiti di una segnalazione: se le righe non ci stanno tutte, le ultime si
/// riassumono.
String _testoSegnalazione(List<ModificaRifiutata> rifiutate) {
  var testo = 'Il server non ha accettato queste modifiche:';
  var scritte = 0;
  for (final m in rifiutate) {
    final riga =
        '• ${m.cosa}, ${m.tipo}, ${dataEOra(m.quando.toLocal())}: '
        '${m.perche}${_rispostaDelServer(m)}';
    // Un po' di spazio per la riga finale «… e altre N».
    if (testo.length + riga.length + 1 > lunghezzaMassimaSegnalazione - 40) {
      break;
    }
    testo = '$testo\n$riga';
    scritte++;
  }
  if (scritte < rifiutate.length) {
    testo = '$testo\n• … e altre ${rifiutate.length - scritte}';
  }
  return testo;
}

/// " (42501: new row violates …)": quello che ha detto il server, per chi
/// sviluppa. Il messaggio si accorcia: a volte è lungo.
String _rispostaDelServer(ModificaRifiutata m) {
  const massimo = 120;
  final messaggio = m.messaggio;
  final corto = messaggio == null || messaggio.length <= massimo
      ? messaggio
      : '${messaggio.substring(0, massimo)}…';
  final parti = [?m.codice, ?corto];
  return parti.isEmpty ? '' : ' (${parti.join(': ')})';
}
