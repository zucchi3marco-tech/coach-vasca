import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/superfici_tema.dart';
import '../../../theme/tema_bordo_vasca_provider.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../atleti/application/atleti_providers.dart';
import '../application/pallanuoto_providers.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import 'campo_tiro.dart';
import 'eventi_labels.dart';
import 'eventi_partita_screen.dart';
import 'fascia_calottine_partita.dart';
import 'selettore_giocatore_partita.dart';
import 'squalifiche_partita.dart';
import 'striscia_sanzionati_partita.dart';

enum _Interazione { riposo, sceltaGiocatoreTiro, sceltaGiocatoreSanzione }

/// Schermata da bordo vasca per gli eventi partita (DESIGN.md sezione 9):
/// campo disegnato al centro, fasce di calottine sui bordi sempre visibili,
/// punteggio in tempo reale in alto. Sostituisce, come punto d'ingresso di
/// "Eventi partita", i vecchi `RegistraTiroScreen`/`RegistraEspulsioneScreen`
/// (passi impilati): qui gli stessi passi sono un overlay su un'unica
/// schermata bloccata in orizzontale.
class PartitaLiveScreen extends ConsumerStatefulWidget {
  const PartitaLiveScreen({required this.partita, super.key});

  final Partita partita;

  @override
  ConsumerState<PartitaLiveScreen> createState() => _PartitaLiveScreenState();
}

class _PartitaLiveScreenState extends ConsumerState<PartitaLiveScreen> {
  _Interazione _interazione = _Interazione.riposo;
  double? _posX;
  double? _posY;
  bool _rigorePendente = false;
  int? _periodo;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Uno snackbar residuo (o una coda di snackbar accumulati da eventi
    // registrati in rapida successione) non deve seguire l'utente fuori
    // da questa schermata.
    ScaffoldMessenger.of(context).clearSnackBars();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _annullaInterazione() {
    setState(() {
      _interazione = _Interazione.riposo;
      _posX = null;
      _posY = null;
      _rigorePendente = false;
    });
  }

  void _mostraAnnulla(BuildContext context, EventoPartita evento) {
    // clearSnackBars (non solo hideCurrentSnackBar) prima di ognuno:
    // registrando più eventi in rapida successione altrimenti si
    // accodano, e l'ultimo compare solo dopo che tutti i precedenti
    // hanno esaurito i loro 4 secondi — con più eventi ravvicinati
    // sembra uno snackbar "bloccato" per decine di secondi.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Evento registrato'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () {
              ref
                  .read(eventiPartitaRepositoryProvider)
                  .eliminaEvento(evento.id);
            },
          ),
        ),
      );
  }

  Future<void> _salvaTiro(
    String atletaId,
    String esito,
    String contesto,
  ) async {
    try {
      final evento = await ref
          .read(eventiPartitaRepositoryProvider)
          .registraTiro(
            partitaId: widget.partita.id,
            atletaId: atletaId,
            esito: esito,
            periodo: _periodo,
            contestoTiro: contesto,
            posX: _posX,
            posY: _posY,
          );
      if (mounted) _mostraAnnulla(context, evento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    } finally {
      if (mounted) _annullaInterazione();
    }
  }

  Future<void> _salvaSanzione(GiocatorePartitaId id) async {
    try {
      final evento = await ref
          .read(eventiPartitaRepositoryProvider)
          .registraEspulsione(
            partitaId: widget.partita.id,
            atletaId: id is NostroGiocatoreId ? id.atletaId : null,
            numeroCalottinaAvversario: id is AvversarioGiocatoreId
                ? id.numeroCalottina
                : null,
            periodo: _periodo,
            espulsioneDaRigore: _rigorePendente,
          );
      if (mounted) _mostraAnnulla(context, evento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    } finally {
      if (mounted) _annullaInterazione();
    }
  }

  Future<void> _salvaTiroAvversario(
    List<EventoPartita> eventi,
    String esito,
  ) async {
    final contesto =
        contestoAutomatico(eventi, 'avversaria', DateTime.now()) ?? 'azione';
    try {
      final evento = await ref
          .read(eventiPartitaRepositoryProvider)
          .registraTiroAvversario(
            partitaId: widget.partita.id,
            esito: esito,
            periodo: _periodo,
            contestoTiro: contesto,
          );
      if (mounted) _mostraAnnulla(context, evento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  Future<void> _scegliEsitoTiroAvversario(List<EventoPartita> eventi) async {
    final tema = Theme.of(context);
    final esito = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Theme(
        data: tema,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (valore, etichetta) in esitiTiroSemplice) ...[
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: PrimaryButton(
                      label: etichetta,
                      onPressed: () => Navigator.of(sheetContext).pop(valore),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (esito == null) return;
    await _salvaTiroAvversario(eventi, esito);
  }

  Future<void> _scegliEsitoTiro(
    List<EventoPartita> eventi,
    String atletaId,
  ) async {
    // Un tiro da rigore va sempre distinto fra parato e palo/fuori, anche
    // se la partita è impostata su "semplice" per il gioco normale.
    final contesto =
        contestoAutomatico(eventi, 'nostra', DateTime.now()) ?? 'azione';
    final opzioni =
        contesto == 'rigore' || widget.partita.dettaglioTiro == 'dettagliato'
        ? esitiTiroDettagliato
        : esitiTiroSemplice;
    final tema = Theme.of(context);
    final esito = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Theme(
        data: tema,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (valore, etichetta) in opzioni) ...[
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: PrimaryButton(
                      label: etichetta,
                      onPressed: () => Navigator.of(sheetContext).pop(valore),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (esito == null) {
      _annullaInterazione();
      return;
    }
    await _salvaTiro(atletaId, esito, contesto);
  }

  Future<void> _confermaFinePartita(BuildContext context) async {
    final tema = Theme.of(context);
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: tema,
        child: AlertDialog(
          title: const Text('Concludere la partita?'),
          content: const Text(
            'Punteggio ed eventi restano salvati. Potrai riaprire questa '
            'partita in un secondo momento da Distinta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Fine partita'),
            ),
          ],
        ),
      ),
    );
    if (conferma == true && context.mounted) {
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }

  void _onSelezionatoGiocatore(
    List<EventoPartita> eventi,
    GiocatorePartitaId id,
  ) {
    switch (_interazione) {
      case _Interazione.sceltaGiocatoreTiro:
        if (id is NostroGiocatoreId) _scegliEsitoTiro(eventi, id.atletaId);
      case _Interazione.sceltaGiocatoreSanzione:
        _salvaSanzione(id);
      case _Interazione.riposo:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(widget.partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(widget.partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((
        clubId: widget.partita.clubId,
        includeInactive: false,
      )),
    );

    if (eventiAsync.isLoading ||
        convocatiAsync.isLoading ||
        atletiAsync.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingSkeleton(width: 240, height: 40)),
      );
    }
    if (eventiAsync.hasError ||
        convocatiAsync.hasError ||
        atletiAsync.hasError) {
      final errore =
          eventiAsync.error ?? convocatiAsync.error ?? atletiAsync.error;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: ErrorBanner(
              messaggio: 'Non è stato possibile caricare la partita.',
              suggerimento:
                  'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
              dettaglioTecnico: messaggioErrore(errore!),
            ),
          ),
        ),
      );
    }

    final eventi = eventiAsync.value!;
    final atletiPerId = {for (final a in atletiAsync.value!) a.id: a};
    final convocati = <ConvocatoConAtleta>[
      for (final g in convocatiAsync.value!)
        if (atletiPerId[g.atletaId] != null)
          (giocatore: g, atleta: atletiPerId[g.atletaId]!),
    ];
    final disqualificati = calcolaSqualificati(eventi);
    final conteggiRigore = contaEspulsioniRigore(eventi);

    final golCasa = eventi
        .where(
          (e) =>
              e.tipo == 'tiro' &&
              e.esito == 'gol' &&
              e.squadra ==
                  (widget.partita.nostraSquadra == 'casa'
                      ? 'nostra'
                      : 'avversaria'),
        )
        .length;
    final golTrasferta = eventi
        .where(
          (e) =>
              e.tipo == 'tiro' &&
              e.esito == 'gol' &&
              e.squadra ==
                  (widget.partita.nostraSquadra == 'casa'
                      ? 'avversaria'
                      : 'nostra'),
        )
        .length;

    final attiva = _interazione != _Interazione.riposo;
    final scuro = ref.watch(temaBordoVascaScuroProvider);

    return Theme(
      data: scuro ? AppTheme.scuroBordoVasca : AppTheme.chiaro,
      // Builder per un context che veda gia' il Theme appena impostato
      // sopra (serve a SuperficiTema.of piu' sotto).
      child: Builder(
        builder: (context) {
          final tema = SuperficiTema.of(context);
          return PopScope(
            canPop: !attiva,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && attiva) _annullaInterazione();
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: 'Cronologia',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EventiPartitaScreen(
                                  partita: widget.partita,
                                ),
                              ),
                            ),
                          ),
                          const BottoneTemaBordoVasca(),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$golCasa - $golTrasferta',
                                style: AppTypography.display.copyWith(
                                  color: tema.testo,
                                ),
                              ),
                            ),
                          ),
                          if (widget.partita.tracciaTempo)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var t = 1; t <= 4; t++)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.s4,
                                    ),
                                    child: _ChipTempo(
                                      tempo: t,
                                      selezionato: _periodo == t,
                                      onTap: () => setState(() => _periodo = t),
                                    ),
                                  ),
                              ],
                            ),
                          IconButton(
                            icon: const Icon(Icons.sports_score),
                            tooltip: 'Fine partita',
                            onPressed: () => _confermaFinePartita(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (attiva)
                            FasciaCalottinePartita(
                              partita: widget.partita,
                              casa: true,
                              convocati: convocati,
                              attiva: attiva,
                              soloNostra:
                                  _interazione ==
                                  _Interazione.sceltaGiocatoreTiro,
                              disqualificati: disqualificati,
                              conteggiRigore: conteggiRigore,
                              onSelezionato: (id) =>
                                  _onSelezionatoGiocatore(eventi, id),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s12,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CampoTiro(
                                    onTocca: convocati.isEmpty
                                        ? null
                                        : (x, y) {
                                            setState(() {
                                              _posX = x;
                                              _posY = y;
                                              _interazione = _Interazione
                                                  .sceltaGiocatoreTiro;
                                            });
                                          },
                                  ),
                                  if (attiva)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onTap: _annullaInterazione,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.raggioPannello,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (attiva)
                            FasciaCalottinePartita(
                              partita: widget.partita,
                              casa: false,
                              convocati: convocati,
                              attiva: attiva,
                              soloNostra:
                                  _interazione ==
                                  _Interazione.sceltaGiocatoreTiro,
                              disqualificati: disqualificati,
                              conteggiRigore: conteggiRigore,
                              onSelezionato: (id) =>
                                  _onSelezionatoGiocatore(eventi, id),
                            ),
                        ],
                      ),
                    ),
                    if (!attiva)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: StrisciaSanzionatiPartita(
                          partita: widget.partita,
                          convocati: convocati,
                          conteggiRigore: conteggiRigore,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: AppSpacing.altezzaMinimaBersaglioVasca,
                              child: SecondaryButton(
                                label: 'Espulsione',
                                icon: Icons.warning_amber_outlined,
                                onPressed: () => setState(() {
                                  _interazione =
                                      _Interazione.sceltaGiocatoreSanzione;
                                  _rigorePendente = false;
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: SizedBox(
                              height: AppSpacing.altezzaMinimaBersaglioVasca,
                              child: SecondaryButton(
                                label: 'Rigore',
                                onPressed: () => setState(() {
                                  _interazione =
                                      _Interazione.sceltaGiocatoreSanzione;
                                  _rigorePendente = true;
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s16),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: AppSpacing.altezzaMinimaBersaglioVasca,
                              child: SecondaryButton(
                                label: 'Tiro avversario',
                                icon: Icons.sports_handball_outlined,
                                onPressed: () =>
                                    _scegliEsitoTiroAvversario(eventi),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipTempo extends StatelessWidget {
  const _ChipTempo({
    required this.tempo,
    required this.selezionato,
    required this.onTap,
  });

  final int tempo;
  final bool selezionato;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = SuperficiTema.of(context);
    return Material(
      color: selezionato ? AppColors.blu : tema.superficie,
      shape: CircleBorder(side: BorderSide(color: tema.linea)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              'T$tempo',
              style: AppTypography.corpoForte.copyWith(
                color: selezionato ? Colors.white : tema.testo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
