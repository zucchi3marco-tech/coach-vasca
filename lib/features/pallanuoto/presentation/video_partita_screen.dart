import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/voce/voce.dart';
import '../../../core/video/lettore_youtube.dart';
import '../../../core/video/link_youtube.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../application/pallanuoto_providers.dart';
import '../application/video_partita_providers.dart';
import '../data/nomi_squadra_repository.dart';
import '../data/video_partite_repository.dart';
import '../domain/clip_video.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import '../domain/video_partita.dart';
import 'disegno_video.dart';
import 'eventi_labels.dart';
import 'water_polo_tactics_board.dart' show ColoreLavagna;

/// Il video della partita collegato agli eventi registrati dal vivo
/// (fase 3 del "Mako della pallanuoto"): l'allenatore incolla il link di
/// YouTube, lo allinea una volta su un evento (per esempio un gol) e da
/// lì ogni evento è una clip, da filtrare per situazione o giocatore e da
/// guardare di fila. Sul fotogramma fermo disegna frecce e cerchi e
/// scrive una nota, per tutta la squadra o per un convocato; il video si
/// ferma da solo sulle note.
///
/// L'atleta convocato ([modifica] false) guarda soltanto: in cima le clip
/// dove c'è lui ([atletaId]) e le note per lui.
class VideoPartitaScreen extends ConsumerStatefulWidget {
  const VideoPartitaScreen({
    required this.partita,
    this.modifica = true,
    this.atletaId,
    super.key,
  });

  final Partita partita;
  final bool modifica;
  final String? atletaId;

  @override
  ConsumerState<VideoPartitaScreen> createState() => _VideoPartitaScreenState();
}

/// Una nota mentre si disegna (nuova, o una da modificare con [id]).
class _Bozza {
  _Bozza({
    this.id,
    required this.secondo,
    this.eventoId,
    this.atletaId,
    required this.segni,
    required String testo,
    this.audioPath,
    this.audioSecondi,
  }) : testo = TextEditingController(text: testo);

  final String? id;
  final double secondo;
  final String? eventoId;
  String? atletaId;
  final List<SegnoVideo> segni;
  final TextEditingController testo;
  FormaSegno forma = FormaSegno.freccia;
  ColoreLavagna colore = ColoreLavagna.giallo;

  /// Il commento a voce già salvato sulla nota.
  final String? audioPath;
  final double? audioSecondi;

  /// Uno appena registrato (al posto di quello salvato), o quello salvato
  /// tolto.
  VoceRegistrata? voceNuova;
  var voceTolta = false;

  bool get conVoce => voceNuova != null || (audioPath != null && !voceTolta);

  double? get secondiVoce =>
      voceNuova?.secondi ?? (voceTolta ? null : audioSecondi);
}

/// "0:42", "2:05".
String durataVoce(double secondi) {
  final s = secondi.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _VideoPartitaScreenState extends ConsumerState<VideoPartitaScreen> {
  final _controllore = ControlloreVideo();
  ScaffoldMessengerState? _messenger;

  FiltroClip _filtro = FiltroClip.tutte;
  String? _giocatore;

  ClipVideo? _clip;
  List<ClipVideo>? _coda;
  var _indice = 0;

  EventoPartita? _daAllineare;
  _Bozza? _bozza;
  NotaVideo? _notaInVista;
  var _salvando = false;

  /// Per accorgersi che il video, andando avanti, passa sopra una nota.
  var _ultimoSecondo = 0.0;
  var _ultimoSalto = DateTime.fromMillisecondsSinceEpoch(0);
  final _noteViste = <String>{};
  double? _durata;
  List<NotaVideo> _note = const [];

  // Il commento a voce: si registra mentre la clip scorre e si riascolta
  // con il video (si ferma e riparte con lui).
  late final RegistratoreVoce _registratore;
  LettoreVoce? _lettore;
  DateTime? _registrazioneDal;
  Timer? _orologioVoce;

  /// Il secondo del video da cui parte il commento che si sta ascoltando
  /// (null = nessuno).
  double? _ascoltoDa;
  var _ascoltoDal = DateTime.fromMillisecondsSinceEpoch(0);
  var _riprendoVoce = false;

  bool get _registrando => _registrazioneDal != null;

  @override
  void initState() {
    super.initState();
    _registratore = ref.read(creaRegistratoreVoceProvider)();
    _controllore.addListener(_suVideo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _controllore
      ..removeListener(_suVideo)
      ..dispose();
    _bozza?.testo.dispose();
    _orologioVoce?.cancel();
    _registratore.annulla();
    _lettore?.chiudi();
    super.dispose();
  }

  VideoPartiteRepository get _repository =>
      ref.read(videoPartiteRepositoryProvider);

  void _avviso(String testo) {
    _messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(testo)));
  }

  // -------------------------------------------------------------------
  // Riproduzione

  void _suVideo() {
    if (!mounted) return;
    // La durata arriva dal lettore dopo un po': decide quali eventi
    // cadono fuori dal video.
    if (_controllore.durata != _durata) {
      setState(() => _durata = _controllore.durata);
    }
    final s = _controllore.secondo;
    final prima = _ultimoSecondo;
    _ultimoSecondo = s;
    if (_ascoltoDa != null) {
      _seguiIlVideo(s);
      return;
    }
    if (!_controllore.inRiproduzione || _bozza != null) return;
    final clip = _clip;
    // Ripartito con play invece di "Continua": la nota se ne va, e una
    // clip di nota è finita.
    if (_notaInVista case final n? when s > n.secondo + 0.5) {
      setState(() => _notaInVista = null);
      if (clip?.nota != null) _dopoLaClip(fermaIlVideo: false);
      return;
    }
    // Solo mentre il video va avanti da solo: un salto non chiude la
    // clip e non apre note. Se però con la barra di YouTube si va
    // altrove, la clip non è più in onda (subito dopo un nostro "vai a"
    // il lettore dice ancora per un attimo il punto di prima: si
    // aspetta un momento).
    if (s <= prima || s - prima >= 2) {
      final dalSalto = DateTime.now().difference(_ultimoSalto);
      if (clip != null &&
          dalSalto > const Duration(milliseconds: 1500) &&
          (s < clip.inizio - 1 || s > clip.fine + 1)) {
        setState(() {
          _clip = null;
          _coda = null;
        });
      }
      return;
    }
    for (final n in _note) {
      if (n.secondo > prima && n.secondo <= s) {
        _controllore
          ..pausa()
          ..vaiA(n.secondo);
        _ultimoSecondo = n.secondo;
        _noteViste.add(n.id);
        setState(() => _notaInVista = n);
        return;
      }
    }
    if (clip != null && clip.evento != null && s >= clip.fine) _prossima();
  }

  // -------------------------------------------------------------------
  // Commento a voce

  /// Mentre si ascolta: il video in pausa ferma la voce, il video che
  /// riparte la fa riprendere dal punto giusto. Appena partiti il lettore
  /// dice ancora per un attimo «fermo»: si aspetta un momento.
  void _seguiIlVideo(double s) {
    final lettore = _lettore;
    final da = _ascoltoDa;
    if (lettore == null || da == null) return;
    if (DateTime.now().difference(_ascoltoDal) <
        const Duration(milliseconds: 1500)) {
      return;
    }
    if (!_controllore.inRiproduzione) {
      if (lettore.inRiproduzione) lettore.pausa();
      return;
    }
    if (!lettore.inRiproduzione && !_riprendoVoce) {
      final punto = s - da;
      if (punto < 0) return;
      _riprendoVoce = true;
      lettore
          .suona(secondo: punto)
          .catchError((Object _) {})
          .whenComplete(() => _riprendoVoce = false);
    }
  }

  /// Fa partire insieme il video da [daSecondo] e il commento: quello
  /// salvato in [path] o quello appena registrato.
  Future<void> _ascolta({
    required double daSecondo,
    String? path,
    VoceRegistrata? registrata,
  }) async {
    final lettore = _lettore ??= ref.read(creaLettoreVoceProvider)();
    try {
      if (registrata != null) {
        await lettore.apriRegistrata(registrata);
      } else if (path != null) {
        await lettore.apri(await _repository.indirizzoVoce(path));
      } else {
        return;
      }
      lettore.allaFine = _fineAscolto;
      _controllore
        ..impostaVelocita(1)
        ..vaiA(daSecondo)
        ..riproduci();
      _ascoltoDal = DateTime.now();
      if (mounted) setState(() => _ascoltoDa = daSecondo);
      await lettore.suona();
    } catch (e) {
      _fermaAscolto();
      _avviso(
        e is ErroreVoce
            ? e.messaggio
            : 'Il commento non si ascolta: ${messaggioErrore(e)}',
      );
    }
  }

  void _fineAscolto() {
    if (!mounted || _ascoltoDa == null) return;
    _controllore.pausa();
    setState(() => _ascoltoDa = null);
  }

  void _fermaAscolto() {
    _lettore?.pausa();
    if (_ascoltoDa == null) return;
    _controllore.pausa();
    if (mounted) setState(() => _ascoltoDa = null);
  }

  /// La clip riparte dal punto della nota e si registra mentre scorre,
  /// fino a [durataMassimaVoce].
  Future<void> _registraVoce() async {
    final bozza = _bozza;
    if (bozza == null || _registrando) return;
    _fermaAscolto();
    try {
      await _registratore.avvia();
    } on ErroreVoce catch (e) {
      _avviso(e.messaggio);
      return;
    }
    if (!mounted || _bozza != bozza) {
      _registratore.annulla();
      return;
    }
    _controllore
      ..impostaVelocita(1)
      ..vaiA(bozza.secondo)
      ..riproduci();
    setState(() => _registrazioneDal = DateTime.now());
    _orologioVoce?.cancel();
    _orologioVoce = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final dal = _registrazioneDal;
      if (dal == null || !mounted) return;
      if (DateTime.now().difference(dal) >= durataMassimaVoce) {
        _fermaVoce();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _fermaVoce() async {
    if (!_registrando) return;
    _orologioVoce?.cancel();
    _orologioVoce = null;
    final voce = await _registratore.ferma();
    _controllore.pausa();
    final bozza = _bozza;
    if (!mounted) return;
    setState(() {
      _registrazioneDal = null;
      if (bozza != null && voce != null) {
        bozza
          ..voceNuova = voce
          ..voceTolta = false;
      }
    });
    if (bozza != null) _controllore.vaiA(bozza.secondo);
    if (voce == null) _avviso('Non ho registrato niente: riprova.');
  }

  void _togliVoce() {
    final bozza = _bozza;
    if (bozza == null) return;
    _fermaAscolto();
    setState(() {
      bozza
        ..voceNuova = null
        ..voceTolta = true;
    });
  }

  /// Il giocatore scrive (o corregge) la sua risposta a una nota.
  Future<void> _rispondi(NotaVideo nota, RispostaNota? attuale) async {
    final atletaId = widget.atletaId;
    if (atletaId == null) return;
    final testo = await _sopraIlVideo(
      () => showDialog<String>(
        context: context,
        builder: (_) => _DialogoRisposta(testo: attuale?.testo),
      ),
    );
    if (testo == null || testo.trim().isEmpty || !mounted) return;
    try {
      await _repository.rispondiNota(
        nota: nota,
        atletaId: atletaId,
        testo: testo,
      );
      ref.invalidate(risposteNoteProvider(widget.partita.id));
      _avviso('Risposta mandata all\'allenatore.');
    } catch (e) {
      _avviso('Risposta non mandata: ${messaggioErrore(e)}');
    }
  }

  /// [daQui]: la clip comincia prima del punto in cui è il video (due
  /// eventi vicini guardati di fila): si continua senza tornare indietro.
  void _riproduci(
    ClipVideo clip, {
    List<ClipVideo>? coda,
    int indice = 0,
    bool daQui = false,
  }) {
    _fermaAscolto();
    if (coda == null || indice == 0) _noteViste.clear();
    setState(() {
      _clip = clip;
      _coda = coda;
      _indice = indice;
      _notaInVista = null;
      _daAllineare = null;
    });
    if (!daQui) {
      _ultimoSecondo = clip.inizio;
      _ultimoSalto = DateTime.now();
      _controllore.vaiA(clip.inizio);
    }
    _controllore.riproduci();
  }

  void _prossima() => _dopoLaClip(fermaIlVideo: true);

  /// Finita una clip: la successiva guardandole di fila (senza le note
  /// già mostrate dentro la clip di prima), se no il video si ferma (o
  /// continua, se l'ha fatto ripartire chi guarda).
  void _dopoLaClip({required bool fermaIlVideo}) {
    final coda = _coda;
    var i = _indice + 1;
    while (coda != null &&
        i < coda.length &&
        _noteViste.contains(coda[i].nota?.id)) {
      i++;
    }
    if (coda != null && i < coda.length) {
      final s = _controllore.secondo;
      final prossima = coda[i];
      _riproduci(
        prossima,
        coda: coda,
        indice: i,
        daQui: prossima.inizio <= s && s < prossima.fine,
      );
      return;
    }
    if (fermaIlVideo) _controllore.pausa();
    setState(() {
      _clip = null;
      _coda = null;
    });
  }

  void _precedente() {
    final coda = _coda;
    if (coda == null || _indice == 0) return;
    _riproduci(coda[_indice - 1], coda: coda, indice: _indice - 1);
  }

  void _guardaDiFila(List<ClipVideo> clip) {
    if (clip.isEmpty) return;
    _riproduci(clip.first, coda: clip);
  }

  /// Dopo una nota: la clip di una nota finisce lì, le altre continuano.
  void _continua() {
    _fermaAscolto();
    final eraNota = _clip?.nota != null;
    setState(() => _notaInVista = null);
    if (eraNota) {
      _prossima();
      if (_clip != null) return;
    }
    _controllore.riproduci();
  }

  // -------------------------------------------------------------------
  // Allineamento

  void _avviaAllineamento(EventoPartita evento, VideoPartita video) {
    _controllore.pausa();
    setState(() {
      _daAllineare = evento;
      _clip = null;
      _coda = null;
      _notaInVista = null;
    });
    final previsto = secondoNelVideo(
      video.allineamenti,
      momento: evento.creatoIl,
      periodo: evento.periodo,
    );
    if (previsto != null) _controllore.vaiA(previsto);
  }

  /// Apre un foglio o una finestra sopra il video. Sul web il video di
  /// YouTube è una pagina a sé: finché resta aperto, i clic sopra il
  /// video andrebbero a YouTube invece che alle righe del foglio.
  Future<T> _sopraIlVideo<T>(Future<T> Function() apri) async {
    _controllore.accettaTocchi(false);
    try {
      return await apri();
    } finally {
      // Disegnando il video resta senza tocchi.
      if (mounted) _controllore.accettaTocchi(_bozza == null);
    }
  }

  Future<void> _scegliEvento(
    VideoPartita video,
    List<EventoPartita> eventi,
    String Function(String?) nome,
  ) async {
    final evento = await _sopraIlVideo(
      () => showModalBottomSheet<EventoPartita>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _FoglioEventi(eventi: eventi, nome: nome),
      ),
    );
    if (evento != null && mounted) _avviaAllineamento(evento, video);
  }

  Future<void> _eQui(VideoPartita video) async {
    final evento = _daAllineare;
    if (evento == null) return;
    final punto = Allineamento(
      secondo: _controllore.secondo,
      momento: evento.creatoIl,
      periodo: evento.periodo,
      eventoId: evento.id,
    );
    setState(() => _salvando = true);
    try {
      await _repository.salvaAllineamenti(video.id, [
        for (final p in video.allineamenti)
          if (p.eventoId != evento.id) p,
        punto,
      ]);
      if (!mounted) return;
      setState(() => _daAllineare = null);
      _avviso(
        video.allineato
            ? 'Allineamento sistemato da questo punto.'
            : 'Video allineato: ogni evento ora è una clip.',
      );
    } catch (e) {
      if (mounted) _avviso('Allineamento non salvato: ${messaggioErrore(e)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _ricominciaAllineamento(VideoPartita video) async {
    final ok = await _conferma(
      titolo: 'Allineare di nuovo da capo?',
      testo:
          'I punti di allineamento si tolgono e le clip spariscono finché '
          'non scegli di nuovo un evento. Le note restano.',
      azione: 'Ricomincia',
    );
    if (!ok) return;
    try {
      await _repository.salvaAllineamenti(video.id, const []);
      if (mounted) setState(() => _clip = null);
    } catch (e) {
      if (mounted) _avviso('Non riuscito: ${messaggioErrore(e)}');
    }
  }

  Future<void> _cambiaVideo(VideoPartita video, int note) async {
    final ok = await _conferma(
      titolo: 'Cambiare video?',
      testo: [
        'Il video si scollega dalla partita',
        if (video.allineato || note > 0)
          ': si perdono l\'allineamento'
              '${note > 0 ? ' e ${note == 1 ? 'la nota' : 'le $note note'}' : ''}'
              ' di questo video',
        '. Poi incolli il link nuovo.',
      ].join(),
      azione: 'Cambia video',
    );
    if (!ok) return;
    try {
      await _repository.scollegaVideo(video.id);
      if (mounted) {
        setState(() {
          _clip = null;
          _coda = null;
          _notaInVista = null;
        });
      }
    } catch (e) {
      if (mounted) _avviso('Non riuscito: ${messaggioErrore(e)}');
    }
  }

  // -------------------------------------------------------------------
  // Note

  void _avviaDisegno({NotaVideo? nota}) {
    _fermaAscolto();
    _controllore.pausa();
    final evento = _clip?.evento;
    _bozza?.testo.dispose();
    setState(() {
      _bozza = _Bozza(
        id: nota?.id,
        secondo: nota?.secondo ?? _controllore.secondo,
        eventoId: nota?.eventoId ?? evento?.id,
        // Commentando la clip di un nostro giocatore la nota è per lui;
        // si cambia in "Tutta la squadra" con un tocco.
        atletaId: nota != null
            ? nota.atletaId
            : (evento?.squadra == 'nostra' ? evento?.atletaId : null),
        segni: [...?nota?.disegno],
        testo: nota?.testo ?? '',
        audioPath: nota?.audioPath,
        audioSecondi: nota?.audioSecondi,
      );
      _notaInVista = null;
      _daAllineare = null;
    });
    if (nota != null) _controllore.vaiA(nota.secondo);
    _controllore.accettaTocchi(false);
  }

  void _chiudiDisegno() {
    final bozza = _bozza;
    _fermaAscolto();
    if (_registrando) {
      _orologioVoce?.cancel();
      _registratore.annulla();
      _controllore.pausa();
      _registrazioneDal = null;
    }
    setState(() => _bozza = null);
    bozza?.testo.dispose();
    _controllore.accettaTocchi(true);
  }

  Future<void> _salvaNota(VideoPartita video, Map<String, String> nomi) async {
    final bozza = _bozza;
    if (bozza == null) return;
    final testo = bozza.testo.text.trim();
    if (bozza.segni.isEmpty && testo.isEmpty && !bozza.conVoce) {
      _avviso(
        'Disegna qualcosa sul fotogramma, scrivi la nota o registra un '
        'commento a voce.',
      );
      return;
    }
    _fermaAscolto();
    setState(() => _salvando = true);
    try {
      final idNota = bozza.id ?? _repository.nuovoIdNota();
      var audioPath = bozza.voceTolta ? null : bozza.audioPath;
      var audioSecondi = bozza.voceTolta ? null : bozza.audioSecondi;
      if (bozza.voceNuova case final voce?) {
        audioPath = await _repository.caricaVoce(
          clubId: video.clubId,
          notaId: idNota,
          voce: voce,
        );
        audioSecondi = voce.secondi.clamp(0.1, 180).toDouble();
      }
      await _repository.salvaNota(
        id: bozza.id,
        idNuova: bozza.id == null ? idNota : null,
        audioPath: audioPath,
        audioSecondi: audioSecondi,
        video: video,
        secondo: bozza.secondo,
        eventoId: bozza.eventoId,
        atletaId: bozza.atletaId,
        testo: testo,
        disegno: bozza.segni,
      );
      // Il commento di prima, sostituito o tolto.
      if (bozza.audioPath case final vecchio? when vecchio != audioPath) {
        unawaited(_repository.eliminaFileVoce(vecchio));
      }
      if (!mounted) return;
      final perChi = bozza.atletaId == null
          ? 'la vede tutta la squadra convocata.'
          : 'la vede solo ${nomi[bozza.atletaId] ?? 'il giocatore'}.';
      _chiudiDisegno();
      _avviso('Nota salvata: $perChi');
    } catch (e) {
      if (mounted) _avviso('Nota non salvata: ${messaggioErrore(e)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _eliminaNota(NotaVideo nota) async {
    final ok = await _conferma(
      titolo: 'Eliminare la nota?',
      testo: "L'operazione non si può annullare.",
      azione: 'Elimina',
    );
    if (!ok) return;
    _fermaAscolto();
    try {
      await _repository.eliminaNota(nota.id);
      if (nota.audioPath case final path?) {
        unawaited(_repository.eliminaFileVoce(path));
      }
      if (mounted) setState(() => _notaInVista = null);
    } catch (e) {
      if (mounted) _avviso('Non riuscito: ${messaggioErrore(e)}');
    }
  }

  Future<bool> _conferma({
    required String titolo,
    required String testo,
    required String azione,
  }) async {
    final ok = await _sopraIlVideo(
      () => showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(titolo),
          content: Text(testo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            DangerButton(
              label: azione,
              expanded: false,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  // -------------------------------------------------------------------
  // Costruzione

  Map<String, String> _nomi() {
    if (widget.modifica) {
      final atleti =
          ref
              .watch(
                atletiListProvider((
                  clubId: widget.partita.clubId,
                  includeInactive: true,
                )),
              )
              .value ??
          const [];
      return {for (final a in atleti) a.id: a.nomeCompleto};
    }
    return ref.watch(nomiSquadraProvider(widget.partita.clubId)).value ??
        const {};
  }

  @override
  Widget build(BuildContext context) {
    final partita = widget.partita;
    final videoAsync = ref.watch(videoPartitaProvider(partita.id));
    final video = videoAsync.value;

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      appBar: AppBar(
        title: Text('Video · vs ${partita.avversario}'),
        actions: [
          if (widget.modifica && video != null)
            PopupMenuButton<String>(
              tooltip: 'Altro',
              onSelected: (scelta) {
                final note = _note.length;
                switch (scelta) {
                  case 'ricomincia':
                    _ricominciaAllineamento(video);
                  case 'cambia':
                    _cambiaVideo(video, note);
                }
              },
              itemBuilder: (_) => [
                if (video.allineato)
                  const PopupMenuItem(
                    value: 'ricomincia',
                    child: Text('Allinea di nuovo da capo'),
                  ),
                const PopupMenuItem(
                  value: 'cambia',
                  child: Text('Cambia video'),
                ),
              ],
            ),
        ],
      ),
      body: videoAsync.when(
        data: (video) => video == null
            ? (widget.modifica
                  ? _CollegaVideo(partita: partita)
                  : const EmptyState(
                      icona: Icons.ondemand_video_outlined,
                      titolo: 'Nessun video',
                      descrizione:
                          'Il video di questa partita non è ancora stato '
                          'caricato.',
                      azionePrincipale: 'Ho capito',
                    ))
            : _conVideo(video),
        // Scorre: in orizzontale le righe non stanno in altezza.
        loading: () => const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: LoadingSkeletonList(righe: 4),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ErrorBanner(
            messaggio: 'Non è stato possibile caricare il video.',
            suggerimento:
                'Il video si guarda con la connessione: controllala e '
                'riprova.',
            dettaglioTecnico: messaggioErrore(e),
          ),
        ),
      ),
    );
  }

  Widget _conVideo(VideoPartita video) {
    final partita = widget.partita;
    final eventi =
        ref.watch(eventiPartitaListProvider(partita.id)).value ??
        const <EventoPartita>[];
    _note = ref.watch(noteVideoProvider(video.id)).value ?? const <NotaVideo>[];
    final convocati =
        ref.watch(distintaListProvider(partita.id)).value ??
        const <DistintaGiocatore>[];
    final nomi = _nomi();
    String nome(String? id) => nomi[id] ?? 'Atleta rimosso';

    final largo = Breakpoint.of(context).index >= Breakpoint.esteso.index;

    final lettore = AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        child: Stack(
          children: [
            Positioned.fill(
              child: LettoreYoutube(
                videoId: video.youtubeId,
                controllore: _controllore,
              ),
            ),
            // Mentre la clip scorre con la voce i segni del fotogramma
            // fermo non c'entrano.
            if (_registrando || _ascoltoDa != null)
              const SizedBox.shrink()
            else if (_bozza case final bozza?)
              Positioned.fill(
                child: TavolaDisegnoVideo(
                  segni: bozza.segni,
                  forma: bozza.forma,
                  colore: bozza.colore,
                  onSegno: (s) => setState(() => bozza.segni.add(s)),
                ),
              )
            else if (_notaInVista case final nota? when nota.disegno.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SegniVideoPainter(segni: nota.disegno),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Il video resta sempre fermo in alto: allineando o disegnando si
    // guarda il fotogramma mentre si toccano i comandi sotto.
    final sotto = <Widget>[
      const SizedBox(height: AppSpacing.s8),
      _BarraComandi(
        controllore: _controllore,
        onDisegna: widget.modifica && _bozza == null && _daAllineare == null
            ? () => _avviaDisegno()
            : null,
      ),
      ..._pannello(video, eventi, convocati, nomi, nome),
    ];

    final elenco = _elencoClip(video, eventi, nomi, nome, convocati);

    // Allineando, «È qui» sta fisso sotto il video: dentro l'elenco che
    // scorre, su un PC finiva sotto il bordo dello schermo.
    final barraAllineamento = _daAllineare == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: _Affiancati([
              PrimaryButton(
                label: 'È qui',
                icon: Icons.check,
                isLoading: _salvando,
                onPressed: _salvando ? null : () => _eQui(video),
              ),
              SecondaryButton(
                label: 'Annulla',
                onPressed: _salvando
                    ? null
                    : () => setState(() => _daAllineare = null),
              ),
            ]),
          );

    // Il video non prende mai più di metà altezza abbondante: con il
    // telefono in orizzontale copriva i comandi sotto (anche «È qui»).
    Widget colonnaVideo(List<Widget> figli) => LayoutBuilder(
      builder: (context, vincoli) => Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: vincoli.maxHeight * 0.55),
            child: Center(child: lettore),
          ),
          ?barraAllineamento,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s32),
              children: figli,
            ),
          ),
        ],
      ),
    );

    if (largo) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: colonnaVideo(sotto)),
            const SizedBox(width: AppSpacing.s24),
            SizedBox(
              width: AppLayout.larghezzaElencoDuePannelli,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s32),
                children: elenco,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: colonnaVideo([...sotto, ...elenco]),
    );
  }

  /// Il riquadro sotto il video: quello che si sta facendo adesso.
  List<Widget> _pannello(
    VideoPartita video,
    List<EventoPartita> eventi,
    List<DistintaGiocatore> convocati,
    Map<String, String> nomi,
    String Function(String?) nome,
  ) {
    final colori = context.colori;
    Widget riquadro(List<Widget> figli) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: PoolCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: figli,
        ),
      ),
    );
    Text titolo(String t) =>
        Text(t, style: AppTypography.sezione.copyWith(color: colori.testo));
    Text spiegazione(String t) => Text(
      t,
      style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
    );

    if (_bozza case final bozza?) {
      return [
        riquadro([
          titolo('Nota a ${minutaggio(bozza.secondo)}'),
          const SizedBox(height: AppSpacing.s4),
          spiegazione(
            'Trascina sul video per disegnare: una freccia segue il dito, '
            'anche curva.',
          ),
          const SizedBox(height: AppSpacing.s12),
          _StrumentiDisegno(bozza: bozza, onCambia: () => setState(() {})),
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            etichetta: 'Nota (facoltativa)',
            controller: bozza.testo,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.s16),
          ..._commentoAVoce(bozza),
          Text(
            'Per chi',
            style: AppTypography.etichetta.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              TonalChip(
                etichetta: 'Tutta la squadra',
                selezionato: bozza.atletaId == null,
                onSelezionato: (_) => setState(() => bozza.atletaId = null),
              ),
              for (final c in convocati)
                TonalChip(
                  etichetta: nome(c.atletaId),
                  selezionato: bozza.atletaId == c.atletaId,
                  onSelezionato: (_) =>
                      setState(() => bozza.atletaId = c.atletaId),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _Affiancati([
            PrimaryButton(
              label: 'Salva nota',
              isLoading: _salvando,
              onPressed: _salvando || _registrando
                  ? null
                  : () => _salvaNota(video, nomi),
            ),
            SecondaryButton(
              label: 'Annulla',
              onPressed: _salvando ? null : _chiudiDisegno,
            ),
          ]),
        ]),
      ];
    }

    if (_daAllineare case final evento?) {
      return [
        riquadro([
          titolo('Dov\'è nel video?'),
          const SizedBox(height: AppSpacing.s4),
          spiegazione(
            'Porta il video al momento in cui succede «${descriviEvento(evento, nome)}»'
            '${evento.esito == 'gol' ? ' (quando la palla entra)' : ''}, '
            'fermalo e tocca «È qui», subito sotto il video. Gli altri '
            'eventi si mettono a posto da soli.',
          ),
          const SizedBox(height: AppSpacing.s12),
          _PassiFini(controllore: _controllore),
        ]),
      ];
    }

    if (_notaInVista case final nota?) {
      return [
        riquadro([
          titolo(
            nota.perTutti
                ? 'Nota per la squadra'
                : 'Nota per ${nome(nota.atletaId)}',
          ),
          if (nota.testo case final testo?) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              testo,
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
          if (nota.conVoce) ...[
            const SizedBox(height: AppSpacing.s12),
            _ascoltoDa != null
                ? SecondaryButton(
                    label: 'Ferma il commento',
                    icon: Icons.stop,
                    onPressed: _fermaAscolto,
                  )
                : PrimaryButton(
                    label:
                        'Ascolta il commento'
                        '${nota.audioSecondi == null ? '' : ' · ${durataVoce(nota.audioSecondi!)}'}',
                    icon: Icons.volume_up_outlined,
                    onPressed: () =>
                        _ascolta(daSecondo: nota.secondo, path: nota.audioPath),
                  ),
          ],
          ..._risposteNota(nota, nome),
          const SizedBox(height: AppSpacing.s16),
          _Affiancati([
            PrimaryButton(
              label: 'Continua',
              icon: Icons.play_arrow,
              onPressed: _continua,
            ),
            if (widget.modifica)
              SecondaryButton(
                label: 'Modifica',
                onPressed: () => _avviaDisegno(nota: nota),
              ),
          ]),
          if (widget.modifica)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _eliminaNota(nota),
                child: const Text('Elimina la nota'),
              ),
            ),
        ]),
      ];
    }

    if (_clip case final clip? when clip.evento != null) {
      final coda = _coda;
      return [
        riquadro([
          Text(
            coda == null
                ? 'In onda'
                : 'In onda · ${_indice + 1} di ${coda.length}',
            style: AppTypography.etichetta.copyWith(color: colori.azione),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            descriviEvento(clip.evento!, nome),
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          if (coda != null) ...[
            const SizedBox(height: AppSpacing.s12),
            _Affiancati([
              SecondaryButton(
                label: 'Precedente',
                icon: Icons.skip_previous,
                onPressed: _indice == 0 ? null : _precedente,
              ),
              SecondaryButton(
                label: 'Successiva',
                icon: Icons.skip_next,
                onPressed: _prossima,
              ),
            ]),
          ],
          if (widget.modifica) ...[
            const SizedBox(height: AppSpacing.s4),
            TextButton(
              onPressed: () => _avviaAllineamento(clip.evento!, video),
              child: const Text('La clip è spostata? Allinea qui'),
            ),
          ],
        ]),
      ];
    }

    if (!video.allineato) {
      if (!widget.modifica) {
        return [
          riquadro([
            spiegazione(
              'Le clip delle azioni compariranno quando l\'allenatore avrà '
              'allineato il video agli eventi della partita.',
            ),
          ]),
        ];
      }
      return [
        riquadro([
          titolo('Allinea il video agli eventi'),
          const SizedBox(height: AppSpacing.s4),
          spiegazione(
            eventi.isEmpty
                ? 'Per avere le clip servono gli eventi registrati dal vivo: '
                      'questa partita non ne ha. Puoi comunque disegnare e '
                      'lasciare note sul video.'
                : 'Scegli un evento facile da trovare nel video, per esempio '
                      'il primo gol, e mostra all\'app in che punto succede: '
                      'da lì ogni evento diventa una clip.',
          ),
          if (eventi.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Allinea il video',
              icon: Icons.sync_alt,
              onPressed: () => _scegliEvento(video, eventi, nome),
            ),
          ],
        ]),
      ];
    }
    return const [];
  }

  /// Nella bozza della nota: registra, riascolta, rifai o togli il
  /// commento a voce. Dove il browser non sa registrare non compare.
  List<Widget> _commentoAVoce(_Bozza bozza) {
    final colori = context.colori;
    if (!_registratore.disponibile && !bozza.conVoce) return const [];
    final etichetta = Text(
      'Commento a voce',
      style: AppTypography.etichetta.copyWith(color: colori.testoSecondario),
    );
    if (_registrando) {
      final passati = DateTime.now()
          .difference(_registrazioneDal!)
          .inMilliseconds;
      return [
        etichetta,
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Icon(Icons.fiber_manual_record, color: colori.rosso, size: 16),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'Registro mentre la clip scorre · '
                '${durataVoce(passati / 1000)} di '
                '${durataVoce(durataMassimaVoce.inSeconds.toDouble())}',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        PrimaryButton(label: 'Ferma', icon: Icons.stop, onPressed: _fermaVoce),
        const SizedBox(height: AppSpacing.s16),
      ];
    }
    if (bozza.conVoce) {
      final secondi = bozza.secondiVoce;
      return [
        etichetta,
        const SizedBox(height: AppSpacing.s4),
        Text(
          [
            'Registrato',
            if (secondi != null) durataVoce(secondi),
            if (bozza.voceNuova != null) 'si salva con la nota',
          ].join(' · '),
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            if (_ascoltoDa != null)
              TextButton.icon(
                onPressed: _fermaAscolto,
                icon: const Icon(Icons.stop),
                label: const Text('Ferma'),
              )
            else
              TextButton.icon(
                onPressed: () => _ascolta(
                  daSecondo: bozza.secondo,
                  registrata: bozza.voceNuova,
                  path: bozza.voceNuova == null ? bozza.audioPath : null,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Riascolta'),
              ),
            if (_registratore.disponibile)
              TextButton.icon(
                onPressed: _registraVoce,
                icon: const Icon(Icons.mic_none),
                label: const Text('Rifai'),
              ),
            TextButton.icon(
              onPressed: _togliVoce,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Togli'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
      ];
    }
    return [
      etichetta,
      const SizedBox(height: AppSpacing.s4),
      Text(
        'La clip riparte da qui e registri mentre scorre, fino a '
        '${durataMassimaVoce.inMinutes} minuti. Chi vede la nota lo '
        'riascolta con il video.',
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
      const SizedBox(height: AppSpacing.s8),
      Align(
        alignment: Alignment.centerLeft,
        child: SecondaryButton(
          label: 'Registra il commento',
          icon: Icons.mic_none,
          expanded: false,
          onPressed: _registraVoce,
        ),
      ),
      const SizedBox(height: AppSpacing.s16),
    ];
  }

  /// Sotto la nota: per l'allenatore le risposte dei giocatori, per il
  /// giocatore la sua (da scrivere o correggere).
  List<Widget> _risposteNota(NotaVideo nota, String Function(String?) nome) {
    final colori = context.colori;
    final tutte = [
      for (final r
          in ref.watch(risposteNoteProvider(widget.partita.id)).value ??
              const <RispostaNota>[])
        if (r.notaId == nota.id) r,
    ];
    if (widget.modifica) {
      if (tutte.isEmpty) return const [];
      return [
        const SizedBox(height: AppSpacing.s16),
        Text(
          tutte.length == 1 ? 'La risposta' : 'Le risposte',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        for (final r in tutte) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            nome(r.atletaId),
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          Text(
            r.testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ],
      ];
    }
    final mio = widget.atletaId;
    if (mio == null) return const [];
    final mia = tutte.where((r) => r.atletaId == mio).firstOrNull;
    return [
      const SizedBox(height: AppSpacing.s16),
      if (mia != null) ...[
        Text(
          'La tua risposta',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          mia.testo,
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _rispondi(nota, mia),
          icon: const Icon(Icons.reply),
          label: Text(
            mia == null ? 'Rispondi all\'allenatore' : 'Correggi la risposta',
          ),
        ),
      ),
    ];
  }

  List<Widget> _elencoClip(
    VideoPartita video,
    List<EventoPartita> eventi,
    Map<String, String> nomi,
    String Function(String?) nome,
    List<DistintaGiocatore> convocati,
  ) {
    final durata = _durata;
    final superioritaAInizio =
        widget.partita.modalitaSuperiorita == 'inizio_fine';

    ({List<ClipVideo> clip, int fuoriDalVideo}) calcola({
      FiltroClip filtro = FiltroClip.tutte,
      String? atletaId,
    }) => clipVideo(
      video: video,
      eventi: eventi,
      note: _note,
      filtro: filtro,
      atletaId: atletaId,
      superioritaAInizio: superioritaAInizio,
      durata: durata,
    );

    List<Widget> righe(List<ClipVideo> clip) => [
      AppListPanel(righe: [for (final c in clip) _rigaClip(c, clip, nome)]),
    ];

    final figli = <Widget>[];
    final mie = widget.atletaId;
    if (mie != null) {
      final proprie = calcola(atletaId: mie).clip;
      figli.addAll([
        const SizedBox(height: AppSpacing.s16),
        TitoloSezione(
          'Le tue azioni',
          conteggio: proprie.length,
          azione: proprie.length > 1 ? 'Guarda di fila' : null,
          onAzione: () => _guardaDiFila(proprie),
        ),
        if (proprie.isEmpty)
          const RiquadroVuoto('Nessuna azione tua fra quelle registrate.')
        else
          ...righe(proprie),
      ]);
    }

    final filtri = filtriConClip(
      video: video,
      eventi: eventi,
      note: _note,
      atletaId: _giocatore,
    );
    final filtro = filtri.contains(_filtro) ? _filtro : FiltroClip.tutte;
    final risultato = calcola(filtro: filtro, atletaId: _giocatore);
    final clip = risultato.clip;

    figli.addAll([
      const SizedBox(height: AppSpacing.s16),
      TitoloSezione(
        mie != null ? 'Tutta la partita' : 'Clip',
        conteggio: clip.length,
        azione: clip.length > 1 ? 'Guarda di fila' : null,
        onAzione: () => _guardaDiFila(clip),
      ),
      if (video.allineato || _note.isNotEmpty) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (widget.modifica && convocati.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: TonalChip(
                    etichetta: _giocatore == null
                        ? 'Tutti i giocatori'
                        : nome(_giocatore),
                    selezionato: _giocatore != null,
                    onSelezionato: (_) => _scegliGiocatore(convocati, nome),
                    onEliminato: _giocatore == null
                        ? null
                        : () => setState(() => _giocatore = null),
                  ),
                ),
              for (final f in filtri)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: TonalChip(
                    etichetta: f.etichetta,
                    selezionato: filtro == f,
                    onSelezionato: (_) => setState(() => _filtro = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
      ],
      if (clip.isEmpty)
        RiquadroVuoto(
          video.allineato
              ? 'Nessuna clip con questi filtri.'
              : widget.modifica
              ? 'Le clip compaiono quando il video è allineato.'
              : 'Ancora nessuna clip.',
        )
      else
        ...righe(clip),
      if (risultato.fuoriDalVideo > 0)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8),
          child: Text(
            risultato.fuoriDalVideo == 1
                ? 'Un evento cade fuori dal video.'
                : '${risultato.fuoriDalVideo} eventi cadono fuori dal video.',
            style: AppTypography.piccolo.copyWith(
              color: context.colori.testoSecondario,
            ),
          ),
        ),
    ]);
    return figli;
  }

  Widget _rigaClip(
    ClipVideo c,
    List<ClipVideo> tutte,
    String Function(String?) nome,
  ) {
    final colori = context.colori;
    final inOnda = _clip?.id == c.id;
    final nota = c.nota;
    final evento = c.evento;
    return AppListRow(
      leading: Icon(
        evento != null ? iconaEvento(evento) : Icons.draw_outlined,
        size: 20,
        color: inOnda ? colori.azione : colori.testoSecondario,
      ),
      titolo: evento != null
          ? descriviEvento(evento, nome)
          : nota!.perTutti
          ? 'Nota per la squadra'
          : 'Nota per ${nome(nota.atletaId)}',
      sottotitolo: [
        minutaggio(c.secondo),
        ?nota?.testo,
        if (nota?.conVoce ?? false) 'commento a voce',
      ].join(' · '),
      trailing: inOnda
          ? Text(
              'In onda',
              style: AppTypography.piccolo.copyWith(color: colori.azione),
            )
          : null,
      onTap: () => _riproduci(c),
    );
  }

  Future<void> _scegliGiocatore(
    List<DistintaGiocatore> convocati,
    String Function(String?) nome,
  ) async {
    final scelto = await _sopraIlVideo(
      () => showModalBottomSheet<({String? atletaId})>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                Text(
                  'Le clip di chi?',
                  style: AppTypography.sezione.copyWith(
                    color: context.colori.testo,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AppListPanel(
                  righe: [
                    AppListRow(
                      titolo: 'Tutti i giocatori',
                      onTap: () => Navigator.of(context).pop((atletaId: null)),
                    ),
                    for (final c in convocati)
                      AppListRow(
                        titolo: nome(c.atletaId),
                        sottotitolo: 'Calottina ${c.numeroCalottina}',
                        onTap: () =>
                            Navigator.of(context).pop((atletaId: c.atletaId)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (scelto != null && mounted) {
      setState(() => _giocatore = scelto.atletaId);
    }
  }
}

/// Indietro e avanti di 5 secondi, play/pausa, il rallentatore e il
/// punto del video; per l'allenatore "Disegna".
class _BarraComandi extends StatelessWidget {
  const _BarraComandi({required this.controllore, this.onDisegna});

  final ControlloreVideo controllore;
  final VoidCallback? onDisegna;

  static const _velocita = [1.0, 0.5, 0.25];

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return ListenableBuilder(
      listenable: controllore,
      builder: (context, _) {
        final durata = controllore.durata;
        final prossima =
            _velocita[(_velocita.indexOf(controllore.velocita) + 1) %
                _velocita.length];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controllore.errore case final errore?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: ErrorBanner(
                  messaggio: 'Il video non si riesce a guardare.',
                  suggerimento: errore,
                ),
              ),
            Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Indietro di 5 secondi',
                  icon: const Icon(Icons.replay_5),
                  onPressed: () => controllore.avanti(-5),
                ),
                IconButton(
                  tooltip: controllore.inRiproduzione ? 'Pausa' : 'Guarda',
                  icon: Icon(
                    controllore.inRiproduzione
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: colori.azione,
                  ),
                  iconSize: 36,
                  onPressed: controllore.inRiproduzione
                      ? controllore.pausa
                      : controllore.riproduci,
                ),
                IconButton(
                  tooltip: 'Avanti di 5 secondi',
                  icon: const Icon(Icons.forward_5),
                  onPressed: () => controllore.avanti(5),
                ),
                TextButton(
                  onPressed: () => controllore.impostaVelocita(prossima),
                  child: Text(
                    controllore.velocita == 1
                        ? 'Rallenta'
                        : '${_cifre(controllore.velocita)}×',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                  child: Text(
                    durata == null
                        ? minutaggio(controllore.secondo)
                        : '${minutaggio(controllore.secondo)} / '
                              '${minutaggio(durata)}',
                    style: AppTypography.cifreTabulari(AppTypography.piccolo)
                        .copyWith(color: colori.testoSecondario),
                  ),
                ),
                if (onDisegna != null)
                  TextButton.icon(
                    onPressed: onDisegna,
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Disegna'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _cifre(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v'.replaceAll('.', ',');
}

/// Due o più pulsanti in riga, larghi uguali: il tema dà ai pulsanti
/// tutta la larghezza, e uno sotto l'altro occuperebbero mezzo riquadro.
class _Affiancati extends StatelessWidget {
  const _Affiancati(this.pulsanti);

  final List<Widget> pulsanti;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, p) in pulsanti.indexed) ...[
        if (i > 0) const SizedBox(width: AppSpacing.s12),
        Expanded(child: p),
      ],
    ],
  );
}

/// Passi piccoli per trovare il fotogramma giusto, a video fermo.
class _PassiFini extends StatelessWidget {
  const _PassiFini({required this.controllore});

  final ControlloreVideo controllore;

  @override
  Widget build(BuildContext context) => _Affiancati([
    for (final (passo, etichetta) in const [
      (-1.0, '−1 s'),
      (-0.2, '−0,2 s'),
      (0.2, '+0,2 s'),
      (1.0, '+1 s'),
    ])
      SecondaryButton(
        label: etichetta,
        unaRiga: true,
        onPressed: () {
          controllore.pausa();
          controllore.avanti(passo);
        },
      ),
  ]);
}

/// Freccia o cerchio, l'inchiostro e "togli l'ultimo segno".
class _StrumentiDisegno extends StatelessWidget {
  const _StrumentiDisegno({required this.bozza, required this.onCambia});

  final _Bozza bozza;
  final VoidCallback onCambia;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<FormaSegno>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: FormaSegno.freccia,
              icon: Icon(Icons.north_east),
              label: Text('Freccia'),
            ),
            ButtonSegment(
              value: FormaSegno.cerchio,
              icon: Icon(Icons.circle_outlined),
              label: Text('Cerchio'),
            ),
          ],
          selected: {bozza.forma},
          onSelectionChanged: (s) {
            bozza.forma = s.first;
            onCambia();
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in ColoreLavagna.inchiostri)
              Semantics(
                button: true,
                selected: bozza.colore == c,
                label: 'Inchiostro ${c.name}',
                child: InkResponse(
                  onTap: () {
                    bozza.colore = c;
                    onCambia();
                  },
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.colore,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: bozza.colore == c
                              ? colori.azione
                              : colori.lineaForte,
                          width: bozza.colore == c ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        TextButton.icon(
          onPressed: bozza.segni.isEmpty
              ? null
              : () {
                  bozza.segni.removeLast();
                  onCambia();
                },
          icon: const Icon(Icons.undo),
          label: const Text('Togli l\'ultimo'),
        ),
      ],
    );
  }
}

/// Su quale evento allineare il video: tutti, in ordine di partita, con i
/// gol in evidenza (si trovano subito nel video).
class _FoglioEventi extends StatelessWidget {
  const _FoglioEventi({required this.eventi, required this.nome});

  final List<EventoPartita> eventi;
  final String Function(String?) nome;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final ordinati = [...eventi]
      ..sort((a, b) => a.creatoIl.compareTo(b.creatoIl));
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            Text(
              'Su quale evento allineare?',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Un gol è il più facile da trovare nel video.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            AppListPanel(
              righe: [
                for (final e in ordinati)
                  AppListRow(
                    leading: Icon(
                      iconaEvento(e),
                      size: 20,
                      color: e.esito == 'gol'
                          ? colori.azione
                          : colori.testoSecondario,
                    ),
                    titolo: descriviEvento(e, nome),
                    onTap: () => Navigator.of(context).pop(e),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Senza video: il link da incollare, con due righe su come caricarlo.
class _CollegaVideo extends ConsumerStatefulWidget {
  const _CollegaVideo({required this.partita});

  final Partita partita;

  @override
  ConsumerState<_CollegaVideo> createState() => _CollegaVideoState();
}

class _CollegaVideoState extends ConsumerState<_CollegaVideo> {
  final _chiave = GlobalKey<FormState>();
  final _link = TextEditingController();
  var _salvando = false;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _collega() async {
    if (!(_chiave.currentState?.validate() ?? false)) return;
    final id = idYoutubeDa(_link.text)!;
    setState(() => _salvando = true);
    try {
      await ref
          .read(videoPartiteRepositoryProvider)
          .collegaVideo(
            partitaId: widget.partita.id,
            clubId: widget.partita.clubId,
            youtubeId: id,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video non collegato: ${messaggioErrore(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.larghezzaMassimaForm,
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
          children: [
            Text(
              'Collega il video della partita',
              style: AppTypography.titolo.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Carica il video su YouTube come «non in elenco» (lo vede solo '
              'chi ha il link) e incollalo qui. Gli eventi registrati dal '
              'vivo diventano clip; lo vedono gli allenatori e i convocati, '
              'che ricevono un avviso.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Sono riprese di ragazzi: caricale solo con il consenso delle '
              'famiglie.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Form(
              key: _chiave,
              child: AppTextField(
                etichetta: 'Link del video',
                controller: _link,
                keyboardType: TextInputType.url,
                aiuto: 'Su YouTube: «Condividi» → «Copia link».',
                validator: (v) => idYoutubeDa(v ?? '') == null
                    ? 'Non è un link di un video di YouTube.'
                    : null,
                onFieldSubmitted: (_) => _collega(),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: 'Collega video',
              icon: Icons.link,
              isLoading: _salvando,
              onPressed: _salvando ? null : _collega,
            ),
          ],
        ),
      ),
    );
  }
}

/// La finestra della risposta del giocatore a una nota. Torna il testo
/// scritto, null se si annulla.
class _DialogoRisposta extends StatefulWidget {
  const _DialogoRisposta({this.testo});

  final String? testo;

  @override
  State<_DialogoRisposta> createState() => _DialogoRispostaState();
}

class _DialogoRispostaState extends State<_DialogoRisposta> {
  late final _testo = TextEditingController(text: widget.testo ?? '');

  @override
  void initState() {
    super.initState();
    _testo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.testo == null
          ? 'Rispondi all\'allenatore'
          : 'Correggi la risposta',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('La leggono solo i tuoi allenatori.'),
        const SizedBox(height: AppSpacing.s12),
        TextField(
          controller: _testo,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          maxLength: lunghezzaMassimaRispostaNota,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Es. Ho capito: dovevo passarla al centro',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annulla'),
      ),
      TextButton(
        onPressed: _testo.text.trim().isEmpty
            ? null
            : () => Navigator.of(context).pop(_testo.text),
        child: const Text('Manda'),
      ),
    ],
  );
}
