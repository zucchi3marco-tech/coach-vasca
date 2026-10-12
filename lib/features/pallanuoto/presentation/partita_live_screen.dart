import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../../widgets/secondary_button.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
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
import '../../../widgets/nascondi_barra_club.dart';

enum _Interazione {
  riposo,
  sceltaGiocatoreTiro,
  sceltaGiocatoreSanzione,

  /// Modalità completa: chi ha perso o recuperato palla.
  sceltaGiocatorePalla,

  /// Modalità completa, dopo un nostro gol già salvato: chi ha fatto
  /// l'assist.
  sceltaAssist,

  /// Modalità completa, dopo l'espulsione (o il rigore) di un avversario
  /// già salvata: chi dei nostri l'ha guadagnata.
  sceltaGuadagnata,
}

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
  bool _pallaRecuperata = false;
  int? _periodo;

  /// Il gol o l'espulsione appena salvati a cui si aggiunge l'assist o chi
  /// l'ha guadagnata: sono già salvati, il passo dopo si può saltare.
  EventoPartita? _eventoDaCompletare;

  bool get _completa => widget.partita.eventiCompleti;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Preso qui e non in [dispose]: lì la schermata è già staccata e
  /// cercare un antenato non è sicuro.
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    // Uno snackbar residuo (o una coda di snackbar accumulati da eventi
    // registrati in rapida successione) non deve seguire l'utente fuori
    // da questa schermata.
    _messenger?.clearSnackBars();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _annullaInterazione() {
    setState(() {
      _interazione = _Interazione.riposo;
      _posX = null;
      _posY = null;
      _rigorePendente = false;
      _eventoDaCompletare = null;
    });
  }

  /// Dopo un evento salvato: in modalità completa si passa a [poi] (assist
  /// o espulsione guadagnata) sullo stesso evento, altrimenti si torna a
  /// riposo.
  void _continuaOChiudi(EventoPartita evento, _Interazione? poi) {
    if (poi == null) {
      _annullaInterazione();
      return;
    }
    setState(() {
      _interazione = poi;
      _posX = null;
      _posY = null;
      _eventoDaCompletare = evento;
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
          // Con un'azione uno snackbar resterebbe finché non lo si tocca,
          // sopra i bottoni in basso: qui deve sparire da solo.
          persist: false,
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              // Annullato il gol (o l'espulsione) non c'è più l'assist
              // (o chi l'ha guadagnata) da scegliere.
              if (mounted && _eventoDaCompletare?.id == evento.id) {
                _annullaInterazione();
              }
              try {
                await ref
                    .read(eventiPartitaRepositoryProvider)
                    .eliminaEvento(evento.id);
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Annullamento non riuscito: ${messaggioErrore(e)}',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
  }

  void _mostraErrore(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
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
      if (!mounted) return;
      _mostraAnnulla(context, evento);
      // Un rigore non ha assist.
      _continuaOChiudi(
        evento,
        _completa && esito == 'gol' && contesto != 'rigore'
            ? _Interazione.sceltaAssist
            : null,
      );
    } catch (e) {
      _mostraErrore(e);
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
      if (!mounted) return;
      _mostraAnnulla(context, evento);
      _continuaOChiudi(
        evento,
        _completa && id is AvversarioGiocatoreId
            ? _Interazione.sceltaGuadagnata
            : null,
      );
    } catch (e) {
      _mostraErrore(e);
      if (mounted) _annullaInterazione();
    }
  }

  /// [atletaId] null: palla persa o recuperata dalla squadra, senza un
  /// giocatore.
  Future<void> _salvaPalla(String? atletaId) async {
    try {
      final evento = await ref
          .read(eventiPartitaRepositoryProvider)
          .registraPalla(
            partitaId: widget.partita.id,
            recuperata: _pallaRecuperata,
            atletaId: atletaId,
            periodo: _periodo,
          );
      if (mounted) _mostraAnnulla(context, evento);
    } catch (e) {
      _mostraErrore(e);
    } finally {
      if (mounted) _annullaInterazione();
    }
  }

  /// L'assist o chi ha guadagnato l'espulsione: un aggiornamento del gol
  /// o dell'espulsione appena salvati. [atletaId] null = nessuno.
  Future<void> _completaEvento(String? atletaId) async {
    final evento = _eventoDaCompletare;
    final interazione = _interazione;
    _annullaInterazione();
    if (evento == null || atletaId == null) return;
    final repository = ref.read(eventiPartitaRepositoryProvider);
    try {
      if (interazione == _Interazione.sceltaAssist) {
        await repository.impostaAssist(id: evento.id, atletaId: atletaId);
      } else {
        await repository.impostaGuadagnataDa(id: evento.id, atletaId: atletaId);
      }
    } catch (e) {
      _mostraErrore(e);
    }
  }

  Future<void> _salvaTiroAvversario(String esito, String contesto) async {
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
      _mostraErrore(e);
    }
  }

  /// Bottom sheet con gli esiti, uno per bottone da 64: un tocco salva.
  /// Affiancati quando c'è spazio (in orizzontale), uno sotto l'altro su
  /// uno schermo stretto. Torna il valore scelto, null se si chiude.
  Future<String?> _scegliEsito(String titolo, List<(String, String)> opzioni) {
    final tema = Theme.of(context);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Theme(
        data: tema,
        child: _FoglioEsito(
          titolo: titolo,
          opzioni: opzioni,
          onScelto: (valore) => Navigator.of(sheetContext).pop(valore),
        ),
      ),
    );
  }

  Future<void> _scegliEsitoTiroAvversario(List<EventoPartita> eventi) async {
    final contesto =
        contestoAutomatico(eventi, 'avversaria', DateTime.now()) ?? 'azione';
    final esito = await _scegliEsito(
      'Tiro avversario',
      _completa && contesto == 'azione'
          ? conControfuga(esitiTiroSemplice)
          : esitiTiroSemplice,
    );
    if (esito == null) return;
    if (esito == golInControfuga) {
      await _salvaTiroAvversario('gol', 'controfuga');
    } else {
      await _salvaTiroAvversario(esito, contesto);
    }
  }

  Future<void> _scegliEsitoTiro(
    List<EventoPartita> eventi,
    String atletaId,
    String nome,
  ) async {
    // Un tiro da rigore va sempre distinto fra parato e palo/fuori, anche
    // se la partita è impostata su "semplice" per il gioco normale.
    final contesto =
        contestoAutomatico(eventi, 'nostra', DateTime.now()) ?? 'azione';
    final base =
        contesto == 'rigore' || widget.partita.dettaglioTiro == 'dettagliato'
        ? esitiTiroDettagliato
        : esitiTiroSemplice;
    // La controfuga solo per un tiro in azione: in superiorità o su
    // rigore il contesto è già quello.
    final esito = await _scegliEsito(
      contesto == 'rigore' ? 'Rigore di $nome' : 'Tiro di $nome',
      _completa && contesto == 'azione' ? conControfuga(base) : base,
    );
    if (esito == null) {
      _annullaInterazione();
      return;
    }
    if (esito == golInControfuga) {
      await _salvaTiro(atletaId, 'gol', 'controfuga');
    } else {
      await _salvaTiro(atletaId, esito, contesto);
    }
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
    Map<String, Atleta> atletiPerId,
    GiocatorePartitaId id,
  ) {
    final atletaId = id is NostroGiocatoreId ? id.atletaId : null;
    switch (_interazione) {
      case _Interazione.sceltaGiocatoreTiro:
        if (atletaId != null) {
          _scegliEsitoTiro(
            eventi,
            atletaId,
            atletiPerId[atletaId]?.cognome ?? '',
          );
        }
      case _Interazione.sceltaGiocatoreSanzione:
        _salvaSanzione(id);
      case _Interazione.sceltaGiocatorePalla:
        if (atletaId != null) _salvaPalla(atletaId);
      case _Interazione.sceltaAssist:
      case _Interazione.sceltaGuadagnata:
        if (atletaId != null) _completaEvento(atletaId);
      case _Interazione.riposo:
        break;
    }
  }

  /// Cosa si sta scegliendo, scritto al centro del campo, e la scelta
  /// "nessun giocatore" quando c'è.
  ({String domanda, String? nessuno, VoidCallback? onNessuno}) _richiesta() =>
      switch (_interazione) {
        _Interazione.sceltaGiocatoreTiro => (
          domanda: 'Chi ha tirato?',
          nessuno: null,
          onNessuno: null,
        ),
        _Interazione.sceltaGiocatoreSanzione => (
          domanda: _rigorePendente
              ? 'Chi ha commesso il fallo da rigore?'
              : 'Chi è stato espulso?',
          nessuno: null,
          onNessuno: null,
        ),
        _Interazione.sceltaGiocatorePalla => (
          domanda: _pallaRecuperata
              ? 'Chi ha recuperato palla?'
              : 'Chi ha perso palla?',
          nessuno: 'Senza giocatore',
          onNessuno: () => _salvaPalla(null),
        ),
        _Interazione.sceltaAssist => (
          domanda: 'Chi ha fatto l\'assist?',
          nessuno: 'Nessun assist',
          onNessuno: () => _completaEvento(null),
        ),
        _Interazione.sceltaGuadagnata => (
          domanda: _eventoDaCompletare?.espulsioneDaRigore ?? false
              ? 'Chi ha guadagnato il rigore?'
              : 'Chi ha guadagnato l\'espulsione?',
          nessuno: 'Non so',
          onNessuno: () => _completaEvento(null),
        ),
        _Interazione.riposo => (domanda: '', nessuno: null, onNessuno: null),
      };

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context)));

  Widget _costruisci(BuildContext context) {
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
    final soloNostra = _interazione != _Interazione.sceltaGiocatoreSanzione;
    // Chi ha segnato non può essere l'assist di sé stesso.
    final atletaEscluso = _interazione == _Interazione.sceltaAssist
        ? _eventoDaCompletare?.atletaId
        : null;
    final richiesta = _richiesta();
    final overrideVasca = ref.watch(temaBordoVascaOverrideProvider);
    final temaVasca = temaBordoVascaDa(overrideVasca);

    Widget content = Builder(
      // Builder per un context che veda gia' l'eventuale Theme impostato
      // sotto (i widget figli leggono context.colori da qui).
      builder: (context) {
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
                    child: LayoutBuilder(
                      builder: (context, vincoli) {
                        // Tre pulsanti da 48 + quattro chip da 44 non
                        // lasciano spazio al punteggio sotto ~480 px: i
                        // chip dei tempi scendono su una seconda riga.
                        final tempiSotto =
                            widget.partita.tracciaTempo &&
                            vincoli.maxWidth < 480;
                        final chipTempi = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var t = 1; t <= 4; t++)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: t == 1 && tempiSotto
                                      ? 0
                                      : AppSpacing.s4,
                                ),
                                child: _ChipTempo(
                                  tempo: t,
                                  selezionato: _periodo == t,
                                  onTap: () => setState(() => _periodo = t),
                                ),
                              ),
                          ],
                        );
                        final riga = Row(
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
                              child: _Tabellone(
                                partita: widget.partita,
                                golCasa: golCasa,
                                golTrasferta: golTrasferta,
                              ),
                            ),
                            if (widget.partita.tracciaTempo && !tempiSotto)
                              chipTempi,
                            IconButton(
                              icon: const Icon(Icons.sports_score),
                              tooltip: 'Fine partita',
                              onPressed: () => _confermaFinePartita(context),
                            ),
                          ],
                        );
                        if (!tempiSotto) return riga;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            riga,
                            const SizedBox(height: AppSpacing.s4),
                            chipTempi,
                          ],
                        );
                      },
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
                            soloNostra: soloNostra,
                            atletaEscluso: atletaEscluso,
                            disqualificati: disqualificati,
                            conteggiRigore: conteggiRigore,
                            onSelezionato: (id) => _onSelezionatoGiocatore(
                              eventi,
                              atletiPerId,
                              id,
                            ),
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
                                // Il tiro si registra toccando il campo: va
                                // detto, non e' un gesto che si indovina.
                                if (!attiva)
                                  Positioned(
                                    top: AppSpacing.s8,
                                    child: _Suggerimento(
                                      convocati.isEmpty
                                          ? 'Nessun convocato: prepara prima '
                                                'la distinta per registrare i '
                                                'tiri'
                                          : 'Tocca il campo dove è partito '
                                                'il tiro',
                                    ),
                                  ),
                                if (attiva)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _annullaInterazione,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pannello,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (attiva)
                                  _Richiesta(
                                    domanda: richiesta.domanda,
                                    nessuno: richiesta.nessuno,
                                    onNessuno: richiesta.onNessuno,
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
                            soloNostra: soloNostra,
                            atletaEscluso: atletaEscluso,
                            disqualificati: disqualificati,
                            conteggiRigore: conteggiRigore,
                            onSelezionato: (id) => _onSelezionatoGiocatore(
                              eventi,
                              atletiPerId,
                              id,
                            ),
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
                    child: LayoutBuilder(
                      builder: (context, vincoli) {
                        // Sotto ~400 px (~720 con le palle perse e
                        // recuperate) niente icone: le etichette restano
                        // su una riga senza spezzarsi.
                        final stretto =
                            vincoli.maxWidth < (_completa ? 720 : 400);
                        final distacco = SizedBox(
                          width: stretto ? AppSpacing.s8 : AppSpacing.s16,
                        );
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: AppSpacing.altezzaMinimaBersaglioVasca,
                                child: SecondaryButton(
                                  label: 'Espulsione',
                                  unaRiga: true,
                                  icon: stretto
                                      ? null
                                      : Icons.warning_amber_outlined,
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
                              flex: 2,
                              child: SizedBox(
                                height: AppSpacing.altezzaMinimaBersaglioVasca,
                                child: SecondaryButton(
                                  label: 'Rigore',
                                  unaRiga: true,
                                  onPressed: () => setState(() {
                                    _interazione =
                                        _Interazione.sceltaGiocatoreSanzione;
                                    _rigorePendente = true;
                                  }),
                                ),
                              ),
                            ),
                            distacco,
                            // Modalità completa: palla persa e recuperata,
                            // due bersagli affiancati come espulsione e
                            // rigore (DESIGN.md sezione 14).
                            if (_completa) ...[
                              for (final recuperata in [false, true]) ...[
                                if (recuperata)
                                  const SizedBox(width: AppSpacing.s8),
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height:
                                        AppSpacing.altezzaMinimaBersaglioVasca,
                                    child: SecondaryButton(
                                      label: recuperata
                                          ? 'Recuperata'
                                          : 'Palla persa',
                                      unaRiga: true,
                                      onPressed: () => setState(() {
                                        _interazione =
                                            _Interazione.sceltaGiocatorePalla;
                                        _pallaRecuperata = recuperata;
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                              distacco,
                            ],
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: AppSpacing.altezzaMinimaBersaglioVasca,
                                child: SecondaryButton(
                                  label: 'Tiro avversario',
                                  unaRiga: true,
                                  icon: stretto
                                      ? null
                                      : Icons.sports_handball_outlined,
                                  onPressed: () =>
                                      _scegliEsitoTiroAvversario(eventi),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (temaVasca != null) {
      content = Theme(data: temaVasca, child: content);
    }
    return content;
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
    final colori = context.colori;
    return Material(
      color: selezionato ? colori.azione : colori.superficie,
      shape: CircleBorder(side: BorderSide(color: colori.linea)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              'T$tempo',
              style: AppTypography.corpoForte.copyWith(
                color: selezionato ? colori.azioneInk : colori.testo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Squadre e punteggio: la nostra in grassetto, cosi' a colpo d'occhio si
/// sa quale numero e' il nostro.
class _Tabellone extends StatelessWidget {
  const _Tabellone({
    required this.partita,
    required this.golCasa,
    required this.golTrasferta,
  });

  final Partita partita;
  final int golCasa;
  final int golTrasferta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final noiInCasa = partita.nostraSquadra == 'casa';
    Text nome(String testo, {required bool nostra, required TextAlign verso}) =>
        Text(
          testo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: verso,
          style: (nostra ? AppTypography.corpoForte : AppTypography.corpo)
              .copyWith(
                color: nostra ? colori.testo : colori.testoSecondario,
                height: 1.15,
              ),
        );
    return Row(
      children: [
        Expanded(
          child: nome(
            partita.squadraCasa,
            nostra: noiInCasa,
            verso: TextAlign.end,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$golCasa - $golTrasferta',
            maxLines: 1,
            style: AppTypography.numerica(
              AppTypography.display.copyWith(color: colori.testo),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: nome(
            partita.squadraTrasferta,
            nostra: !noiInCasa,
            verso: TextAlign.start,
          ),
        ),
      ],
    );
  }
}

class _Suggerimento extends StatelessWidget {
  const _Suggerimento(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: colori.superficie.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.pillola),
        ),
        child: Text(
          testo,
          style: AppTypography.piccolo.copyWith(color: colori.testo),
        ),
      ),
    );
  }
}

/// Gli esiti di un tiro: bottoni da 64, un tocco salva. Affiancati quando
/// c'è spazio (in orizzontale ci stanno tutti senza scorrere), uno sotto
/// l'altro su uno schermo stretto.
class _FoglioEsito extends StatelessWidget {
  const _FoglioEsito({
    required this.titolo,
    required this.opzioni,
    required this.onScelto,
  });

  final String titolo;
  final List<(String, String)> opzioni;
  final ValueChanged<String> onScelto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget bottone((String, String) opzione) => SizedBox(
      height: AppSpacing.altezzaMinimaBersaglioVasca,
      child: PrimaryButton(
        label: opzione.$2,
        onPressed: () => onScelto(opzione.$1),
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: LayoutBuilder(
          builder: (context, vincoli) {
            final affiancati = vincoli.maxWidth >= 140.0 * opzioni.length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titolo,
                  style: AppTypography.sezione.copyWith(color: colori.testo),
                ),
                const SizedBox(height: AppSpacing.s12),
                if (affiancati)
                  Row(
                    children: [
                      for (final (i, opzione) in opzioni.indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.s12),
                        Expanded(child: bottone(opzione)),
                      ],
                    ],
                  )
                else
                  for (final (i, opzione) in opzioni.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.s12),
                    bottone(opzione),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Al centro del campo velato, mentre si sceglie un giocatore: cosa si
/// sta scegliendo e, quando c'è, la scelta "nessuno" (palla persa dalla
/// squadra, nessun assist, non so chi ha guadagnato l'espulsione).
class _Richiesta extends StatelessWidget {
  const _Richiesta({required this.domanda, this.nessuno, this.onNessuno});

  final String domanda;
  final String? nessuno;
  final VoidCallback? onNessuno;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            domanda,
            textAlign: TextAlign.center,
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          if (nessuno != null) ...[
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: AppSpacing.altezzaMinimaBersaglioVasca,
              child: SecondaryButton(label: nessuno!, onPressed: onNessuno),
            ),
          ],
        ],
      ),
    );
  }
}
