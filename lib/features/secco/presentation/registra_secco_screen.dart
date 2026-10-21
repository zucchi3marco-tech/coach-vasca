import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/suono/bip.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/nascondi_barra_club.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../carico/application/carico_providers.dart';
import '../../carico/data/rpe_repository.dart';
import '../../carico/presentation/card_rpe.dart' show ScalaRpe;
import '../../test/application/test_club_providers.dart';
import '../../test/domain/massimale.dart';
import '../../test/domain/test_club.dart' show UnitaTest, formattaValore;
import '../application/secco_providers.dart';
import '../data/serie_fatte_repository.dart';
import '../domain/esercizio_secco.dart';
import '../domain/serie_fatta.dart';
import 'come_si_fa.dart';

/// I secondi di "pronti" prima di un esercizio a tempo: il tempo di
/// mettersi in posizione, con tre bip.
const secondiPronti = 3;

/// Quanti secondi aggiunge "+15''" al recupero.
const secondiInPiuRecupero = 15;

enum _Fase { pronto, via, lavoro, recupero }

/// La seduta a secco registrata dall'atleta, serie per serie: un
/// esercizio alla volta con quanto farne e il carico già proposti,
/// "Fatta" a ogni serie (o "Via" per quelli a tempo, che il telefono
/// conta), poi il recupero con il conto alla rovescia e il bip. Alla fine
/// "Quanto è stata dura?". Ogni serie si salva subito, anche senza rete, e
/// si può dire com'è andata («Facile», «Giusta», «Dura»).
///
/// È una schermata da bordo vasca (DESIGN.md, sezione 14): bersagli da
/// 64, al massimo tre azioni, schermo sempre acceso.
class RegistraSeccoScreen extends ConsumerStatefulWidget {
  const RegistraSeccoScreen({
    required this.allenamento,
    required this.atleta,
    required this.esercizi,
    this.adesso = DateTime.now,
    this.suona = suonaBip,
    this.daTablet = false,
    super.key,
  });

  final Allenamento allenamento;
  final Atleta atleta;
  final List<EsercizioSedutaAtleta> esercizi;

  /// L'orologio (nei test, uno finto): il conto alla rovescia si misura
  /// sull'ora, non sugli scatti del timer, che si fermano a schermo
  /// spento.
  final DateTime Function() adesso;

  /// Chi fa il bip: [suonaBip], o un registratore nei test.
  final void Function({bool lungo}) suona;

  /// Registra dal tablet della squadra: in alto c'è il nome dell'atleta,
  /// perché lo schermo passa di mano in mano.
  final bool daTablet;

  @override
  ConsumerState<RegistraSeccoScreen> createState() =>
      _RegistraSeccoScreenState();
}

class _RegistraSeccoScreenState extends ConsumerState<RegistraSeccoScreen> {
  int? _indice;

  /// Ripetizioni o secondi scelti per la prossima serie (null: quelli
  /// proposti).
  int? _quanto;
  bool _caricoCambiato = false;
  String? _caricoScelto;

  _Fase _fase = _Fase.pronto;
  DateTime? _fine;
  DateTime? _inizioLavoro;
  int _lavoroS = 0;
  int? _ultimoConto;
  Timer? _battito;
  bool _finita = false;

  /// Le serie segnate o tolte qui, finché il telefono non le restituisce.
  final _segnate = <SerieFatta>[];
  final _tolte = <(String, int)>{};

  /// L'ultima serie segnata qui: è quella a cui si riferisce il voto
  /// («Com'è andata la serie 2?»), con il voto di adesso.
  SerieFatta? _ultimaSegnata;

  /// Il salvataggio più recente di una serie o di un voto: il voto parte
  /// dopo la serie, mai prima.
  Future<void>? _ultimoSalvataggio;

  /// Il voto è già comparso nella schermata finale: resta, così si può
  /// cambiare.
  bool _votoInFine = false;

  /// I massimali dell'atleta (id esercizio → id atleta → massimale), letti
  /// solo se qualche carico è in percentuale.
  Map<String, Map<String, Massimale>> _massimali = const {};

  @override
  void dispose() {
    _battito?.cancel();
    super.dispose();
  }

  String get _seduta => widget.allenamento.id;

  List<SerieFatta> get _tutte =>
      ref.read(serieFatteAtletaProvider(widget.atleta.id)).value ?? const [];

  /// Le serie di questa seduta: quelle del telefono più quelle appena
  /// segnate, meno quelle appena tolte.
  List<SerieFatta> _qui(List<SerieFatta> tutte) {
    final dalTelefono = [
      for (final f in tutte)
        if (f.allenamentoId == _seduta && !_tolte.contains((f.rigaId, f.serie)))
          f,
    ];
    final chiavi = {for (final f in dalTelefono) (f.rigaId, f.serie)};
    return [
      ...dalTelefono,
      for (final f in _segnate)
        if (!chiavi.contains((f.rigaId, f.serie))) f,
    ];
  }

  List<EsercizioSeduta> get _righe => [for (final e in widget.esercizi) e.riga];

  int _proposto(EsercizioSeduta r) => r.durataS ?? r.ripetizioni ?? 0;

  double? _massimaleDi(EsercizioSeduta r) =>
      _massimali[r.esercizioId]?[widget.atleta.id]?.kg;

  String? _carico(EsercizioSeduta r, List<SerieFatta> tutte) => _caricoCambiato
      ? _caricoScelto
      : caricoProposto(
          riga: r,
          fatteRiga: fatteDellaRiga(r.id, _qui(tutte)),
          precedenti: [
            for (final f in tutte)
              if (f.allenamentoId != _seduta) f,
          ],
          massimale: _massimaleDi(r),
        );

  void _bip({bool lungo = false}) => widget.suona(lungo: lungo);

  void _avviso(String testo, {SnackBarAction? azione}) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(testo),
            action: azione,
            persist: false,
            duration: const Duration(seconds: 4),
          ),
        );

  // ---------------------------------------------------------------------
  // Il conto alla rovescia

  void _avvia(_Fase fase, int secondi) {
    _battito?.cancel();
    _fase = fase;
    _fine = widget.adesso().add(Duration(seconds: secondi));
    _ultimoConto = null;
    _battito = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _scatto(),
    );
  }

  void _ferma() {
    _battito?.cancel();
    _battito = null;
    _fase = _Fase.pronto;
    _fine = null;
    _inizioLavoro = null;
  }

  Duration get _restano {
    final fine = _fine;
    if (fine == null) return Duration.zero;
    final d = fine.difference(widget.adesso());
    return d.isNegative ? Duration.zero : d;
  }

  void _scatto() {
    if (!mounted || _fine == null) return;
    final restano = _restano;
    if (restano == Duration.zero) {
      _alTermine();
      return;
    }
    final conto = (restano.inMilliseconds / 1000).ceil();
    if (conto <= 3 && conto != _ultimoConto) _bip();
    _ultimoConto = conto;
    setState(() {});
  }

  void _alTermine() {
    HapticFeedback.heavyImpact();
    _bip(lungo: true);
    switch (_fase) {
      case _Fase.via:
        setState(() {
          _inizioLavoro = widget.adesso();
          _avvia(_Fase.lavoro, _lavoroS);
        });
      case _Fase.lavoro:
        _fatta(durataS: _lavoroS);
      case _Fase.recupero:
      case _Fase.pronto:
        setState(_ferma);
    }
  }

  // ---------------------------------------------------------------------
  // Le azioni

  void _via(EsercizioSeduta r) {
    preparaSuono();
    HapticFeedback.heavyImpact();
    setState(() {
      _lavoroS = _quanto ?? _proposto(r);
      _avvia(_Fase.via, secondiPronti);
    });
    _bip();
    _ultimoConto = secondiPronti;
  }

  /// Fermato prima della fine: vale il tempo tenuto.
  void _fineLavoro() {
    final inizio = _inizioLavoro;
    final tenuti = inizio == null
        ? 0
        : (widget.adesso().difference(inizio).inMilliseconds / 1000).round();
    _fatta(durataS: tenuti.clamp(1, _lavoroS < 1 ? 1 : _lavoroS));
  }

  void _fatta({int? durataS}) {
    preparaSuono();
    final indice = _indice;
    if (indice == null) return;
    final e = widget.esercizi[indice];
    final r = e.riga;
    final tutte = _tutte;
    final qui = _qui(tutte);
    final serie = prossimaSerie(r, fatteDellaRiga(r.id, qui));
    if (serie == null) return;
    final aTempo = r.durataS != null;
    final f = SerieFatta(
      id: '',
      atletaId: widget.atleta.id,
      clubId: widget.atleta.clubId,
      allenamentoId: _seduta,
      rigaId: r.id,
      esercizioId: r.esercizioId,
      serie: serie,
      ripetizioni: aTempo ? null : (_quanto ?? _proposto(r)),
      durataS: aTempo ? (durataS ?? _quanto ?? _proposto(r)) : null,
      carico: _carico(r, tutte),
      caricoPrevisto: r.carico,
      fattaIl: widget.adesso(),
    );
    _tolte.remove((f.rigaId, f.serie));
    _segnate
      ..removeWhere((s) => s.rigaId == f.rigaId && s.serie == f.serie)
      ..add(f);
    _ultimaSegnata = f;
    final salvataggio = ref
        .read(serieFatteRepositoryProvider)
        .salva(f)
        .then<void>((_) {})
        .catchError((Object errore) {
          _segnate.remove(f);
          if (_ultimaSegnata == f) _ultimaSegnata = null;
          if (mounted) {
            setState(() {});
            _avviso('Serie non salvata. ${messaggioErrore(errore)}');
          }
        });
    _ultimoSalvataggio = salvataggio;
    unawaited(salvataggio);

    final dopo = [...qui, f];
    final daFare = [
      for (final (i, x) in widget.esercizi.indexed)
        if (prossimaSerie(x.riga, fatteDellaRiga(x.riga.id, dopo)) != null) i,
    ];
    final esercizioFinito =
        prossimaSerie(r, fatteDellaRiga(r.id, dopo)) == null;
    setState(() {
      _quanto = null;
      _caricoCambiato = false;
      _caricoScelto = null;
      if (daFare.isEmpty) {
        _ferma();
        _finita = true;
        return;
      }
      if (esercizioFinito) {
        _indice = daFare.firstWhere(
          (i) => i > indice,
          orElse: () => daFare.first,
        );
      }
      final recupero = r.recuperoS ?? 0;
      if (recupero > 0) {
        _avvia(_Fase.recupero, recupero);
      } else {
        _ferma();
      }
    });
    _avviso(
      'Serie ${f.serie} di ${e.esercizio.nome} segnata',
      azione: SnackBarAction(
        label: 'Annulla',
        onPressed: () => _togli(f, indice: indice),
      ),
    );
  }

  void _togli(SerieFatta f, {required int indice}) {
    final daTogliere =
        _qui(_tutte)
            .where((s) => s.rigaId == f.rigaId && s.serie == f.serie)
            .firstOrNull ??
        f;
    _segnate.removeWhere((s) => s.rigaId == f.rigaId && s.serie == f.serie);
    _tolte.add((f.rigaId, f.serie));
    if (_ultimaSegnata?.rigaId == f.rigaId &&
        _ultimaSegnata?.serie == f.serie) {
      _ultimaSegnata = null;
    }
    setState(() {
      _ferma();
      _finita = false;
      _votoInFine = false;
      _indice = indice;
    });
    ref.read(serieFatteRepositoryProvider).togli(daTogliere).catchError((
      Object errore,
    ) {
      if (mounted) _avviso('Serie non tolta. ${messaggioErrore(errore)}');
    });
  }

  /// «Facile», «Giusta» o «Dura» per l'ultima serie segnata; lo stesso
  /// tocco due volte toglie il voto. Non blocca niente: parte dopo il
  /// salvataggio della serie e, se non va, il voto torna com'era.
  void _votaUltima(VotoSerie voto) {
    final prima = _ultimaSegnata;
    if (prima == null) return;
    final cosi = prima.conVoto(prima.voto == voto ? null : voto);
    bool stessa(SerieFatta s) =>
        s.rigaId == prima.rigaId && s.serie == prima.serie;
    void imposta(SerieFatta f) {
      _segnate
        ..removeWhere(stessa)
        ..add(f);
      _ultimaSegnata = f;
    }

    setState(() => imposta(cosi));
    final repository = ref.read(serieFatteRepositoryProvider);
    final salvataggio = (_ultimoSalvataggio ?? Future<void>.value())
        .then<void>((_) async {
          // La serie è stata tolta (o non salvata) nel frattempo.
          if (!_segnate.any(stessa)) return;
          await repository.salva(cosi);
        })
        .catchError((Object errore) {
          if (_ultimaSegnata == cosi) imposta(prima);
          if (mounted) {
            setState(() {});
            _avviso('Voto non salvato. ${messaggioErrore(errore)}');
          }
        });
    _ultimoSalvataggio = salvataggio;
    unawaited(salvataggio);
  }

  Future<void> _togliUltima(EsercizioSedutaAtleta e) async {
    final fatte = fatteDellaRiga(e.riga.id, _qui(_tutte));
    if (fatte.isEmpty) return;
    final ultima = fatte.last;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Togliere la serie ${ultima.serie}?'),
        content: Text('Di ${e.esercizio.nome}: la rifai quando vuoi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Togli'),
          ),
        ],
      ),
    );
    if (conferma == true && mounted) {
      _togli(ultima, indice: _indice ?? 0);
    }
  }

  void _vaiA(int indice) {
    if (indice < 0 || indice >= widget.esercizi.length) return;
    if (_fase == _Fase.via || _fase == _Fase.lavoro) return;
    setState(() {
      _indice = indice;
      _quanto = null;
      _caricoCambiato = false;
      _caricoScelto = null;
    });
  }

  Future<void> _cambiaCarico(EsercizioSeduta r) async {
    final tutte = _tutte;
    final recenti = <String>[];
    final dello = [
      for (final f in tutte)
        if (f.esercizioId == r.esercizioId && f.carico != null) f,
    ]..sort((a, b) => b.fattaIl.compareTo(a.fattaIl));
    // Un carico in percentuale si propone già in chili, dal massimale.
    final massimale = _massimaleDi(r);
    final chili = chiliProposti(r.carico, massimale);
    for (final c in [?(chili ?? r.carico), for (final f in dello) f.carico!]) {
      final t = c.trim();
      if (t.isNotEmpty && !recenti.contains(t) && recenti.length < 4) {
        recenti.add(t);
      }
    }
    final scelta = await _chiediCarico(
      context,
      attuale: _carico(r, tutte),
      previsto: chili == null || massimale == null
          ? r.carico
          : '${r.carico!.trim()}, con il tuo massimale di '
                '${formattaValore(UnitaTest.chili, massimale)} sono $chili',
      proposte: recenti,
    );
    if (scelta == null || !mounted) return;
    setState(() {
      _caricoCambiato = true;
      _caricoScelto = scelta.carico;
    });
  }

  Future<void> _salvaRpe(int rpe) async {
    try {
      await ref
          .read(rpeRepositoryProvider)
          .salva(
            atletaId: widget.atleta.id,
            clubId: widget.atleta.clubId,
            eventoTipo: 'allenamento',
            eventoId: _seduta,
            data: widget.allenamento.data,
            rpe: rpe,
          );
      ref.invalidate(seduteCaricoProvider);
    } catch (e) {
      if (mounted) _avviso('Risposta non salvata. ${messaggioErrore(e)}');
    }
  }

  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context)));

  Widget _costruisci(BuildContext context) {
    final temaVasca = temaBordoVascaDa(
      ref.watch(temaBordoVascaOverrideProvider),
    );
    final fatteAsync = ref.watch(serieFatteAtletaProvider(widget.atleta.id));
    final esercizi = widget.esercizi;
    _massimali =
        esercizi.any((e) => percentualeDelCarico(e.riga.carico) != null)
        ? ref.watch(massimaliProvider(widget.atleta.clubId))
        : const {};
    Widget corpo;
    EsercizioSedutaAtleta? attuale;
    List<SerieFatta> fatteRiga = const [];
    if (fatteAsync.isLoading && !fatteAsync.hasValue) {
      corpo = const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      );
    } else {
      final tutte = fatteAsync.value ?? const <SerieFatta>[];
      final qui = _qui(tutte);
      final indice = _indice ??= esercizioDaCuiPartire(_righe, qui);
      final conto = contaSerie(_righe, qui);
      if (_finita) {
        final rpe = ref
            .watch(rpeAtletaProvider(widget.atleta.id))
            .value
            ?.where(
              (r) => r.eventoTipo == 'allenamento' && r.eventoId == _seduta,
            )
            .firstOrNull
            ?.rpe;
        // Il voto dell'ultima serie, se non c'è ancora (o l'hai appena
        // dato qui: resta, così lo cambi).
        final ultima = _ultimaSegnata;
        final votoFine = ultima != null && (ultima.voto == null || _votoInFine)
            ? ultima
            : null;
        if (votoFine != null) _votoInFine = true;
        corpo = _Fine(
          fatte: conto.fatte,
          totali: conto.totali,
          rpe: rpe,
          onRpe: _salvaRpe,
          onFatto: () => Navigator.of(context).pop(),
          onTorna: conto.fatte < conto.totali
              ? () => setState(() {
                  _finita = false;
                  _votoInFine = false;
                  _indice = esercizioDaCuiPartire(_righe, qui);
                })
              : null,
          votoSerie: votoFine == null ? null : _votoSerie(votoFine),
        );
      } else {
        final e = attuale = esercizi[indice];
        final r = e.riga;
        fatteRiga = fatteDellaRiga(r.id, qui);
        final prossima = prossimaSerie(r, fatteRiga);
        final daFare = [
          for (final (i, x) in esercizi.indexed)
            if (prossimaSerie(x.riga, fatteDellaRiga(x.riga.id, qui)) != null)
              i,
        ];
        corpo = _Esercizio(
          esercizio: e,
          numero: indice + 1,
          di: esercizi.length,
          conto: conto,
          fatteRiga: fatteRiga,
          prossima: prossima,
          fase: _fase,
          quanto: _quanto ?? _proposto(r),
          carico: _carico(r, tutte),
          massimale: _massimaleDi(r),
          restano: _restano,
          poi: _fase == _Fase.recupero
              ? prossima != null
                    ? 'Poi: serie $prossima'
                    : daFare.isEmpty
                    ? null
                    : 'Poi: ${esercizi[daFare.firstWhere((i) => i > indice, orElse: () => daFare.first)].esercizio.nome}'
              : null,
          ultimaVolta: descriviVoti(ultimaVoltaDi(r, tutte)),
          votoSerie: _votoDaMostrare(r),
          onMeno: () => setState(
            () => _quanto = _passo(r, (_quanto ?? _proposto(r)), -1),
          ),
          onPiu: () =>
              setState(() => _quanto = _passo(r, (_quanto ?? _proposto(r)), 1)),
          onCarico: () => _cambiaCarico(r),
          onFatta: () => _fatta(),
          onVia: () => _via(r),
          onFine: _fineLavoro,
          onFerma: () => setState(_ferma),
          onSaltaRecupero: () => setState(_ferma),
          onPiuRecupero: () => setState(() {
            _fine = _fine?.add(const Duration(seconds: secondiInPiuRecupero));
            _ultimoConto = null;
          }),
          onAvanti: daFare.isEmpty
              ? () => setState(() {
                  _ferma();
                  _finita = true;
                })
              : () => _vaiA(
                  daFare.firstWhere(
                    (i) => i > indice,
                    orElse: () => daFare.first,
                  ),
                ),
          ultimoDaFare: daFare.isEmpty,
          onPrecedente: indice > 0 ? () => _vaiA(indice - 1) : null,
          onSuccessivo: indice < esercizi.length - 1
              ? () => _vaiA(indice + 1)
              : null,
        );
      }
    }

    final e = attuale;
    final indice = _indice;
    final titoloBarra = _finita || indice == null
        ? 'Seduta a secco'
        : 'Esercizio ${indice + 1} di ${esercizi.length}';
    Widget pagina = Scaffold(
      appBar: AppBar(
        toolbarHeight: widget.daTablet ? 72 : null,
        title: widget.daTablet
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.atleta.nomeCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Dentro il tema da bordo vasca: i colori sono i suoi.
                  Builder(
                    builder: (temaContext) => Text(
                      titoloBarra,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.piccolo.copyWith(
                        color: temaContext.colori.testoSecondario,
                      ),
                    ),
                  ),
                ],
              )
            : Text(titoloBarra),
        actions: [
          if (e != null)
            IconButton(
              tooltip: 'Come si fa',
              icon: const Icon(Icons.info_outline),
              onPressed: () =>
                  mostraComeSiFa(context, e, massimale: _massimaleDi(e.riga)),
            ),
          const BottoneTemaBordoVasca(),
          if (e != null && indice != null)
            PopupMenuButton<VoidCallback>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Altre azioni',
              onSelected: (azione) => azione(),
              itemBuilder: (_) => [
                if (indice > 0)
                  PopupMenuItem(
                    value: () => _vaiA(indice - 1),
                    child: const Text('Esercizio precedente'),
                  ),
                if (indice < esercizi.length - 1)
                  PopupMenuItem(
                    value: () => _vaiA(indice + 1),
                    child: const Text('Esercizio successivo'),
                  ),
                if (fatteRiga.isNotEmpty)
                  PopupMenuItem(
                    value: () => _togliUltima(e),
                    child: const Text('Togli l\'ultima serie'),
                  ),
                PopupMenuItem(
                  value: () => setState(() {
                    _ferma();
                    _finita = true;
                  }),
                  child: const Text('Finisci la seduta'),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(child: corpo),
    );
    if (temaVasca != null) pagina = Theme(data: temaVasca, child: pagina);
    return pagina;
  }

  /// La riga «Com'è andata la serie 2?» con i tre voti, per l'ultima
  /// serie segnata; se è di un altro esercizio di quello in vista, ne dice
  /// il nome.
  Widget _votoSerie(SerieFatta ultima, {String? nomeEsercizio}) =>
      _VotoSerieRiga(
        serie: ultima.serie,
        nomeEsercizio: nomeEsercizio,
        voto: ultima.voto,
        onVoto: _votaUltima,
      );

  /// Il voto sotto il recupero e, per un esercizio senza recupero, finché
  /// non si segna la serie dopo. Null: niente da mostrare.
  Widget? _votoDaMostrare(EsercizioSeduta inVista) {
    final ultima = _ultimaSegnata;
    if (ultima == null) return null;
    final riga = widget.esercizi
        .where((e) => e.riga.id == ultima.rigaId)
        .firstOrNull;
    final senzaRecupero = (riga?.riga.recuperoS ?? 0) <= 0;
    final mostra =
        _fase == _Fase.recupero || (_fase == _Fase.pronto && senzaRecupero);
    if (!mostra) return null;
    return _votoSerie(
      ultima,
      nomeEsercizio: riga != null && riga.riga.id != inVista.id
          ? riga.esercizio.nome
          : null,
    );
  }

  /// Un passo di − o +: una ripetizione, o 5'' per quelli a tempo.
  int _passo(EsercizioSeduta r, int valore, int verso) => r.durataS != null
      ? (valore + 5 * verso).clamp(5, 3600)
      : (valore + verso).clamp(1, 500);
}

/// L'esercizio in corso: nome, quanto, le serie, il valore della prossima
/// serie (o il conto alla rovescia) e le azioni in basso.
class _Esercizio extends StatelessWidget {
  const _Esercizio({
    required this.esercizio,
    required this.numero,
    required this.di,
    required this.conto,
    required this.fatteRiga,
    required this.prossima,
    required this.fase,
    required this.quanto,
    required this.carico,
    required this.massimale,
    required this.restano,
    required this.poi,
    required this.ultimaVolta,
    required this.votoSerie,
    required this.onMeno,
    required this.onPiu,
    required this.onCarico,
    required this.onFatta,
    required this.onVia,
    required this.onFine,
    required this.onFerma,
    required this.onSaltaRecupero,
    required this.onPiuRecupero,
    required this.onAvanti,
    required this.ultimoDaFare,
    required this.onPrecedente,
    required this.onSuccessivo,
  });

  final EsercizioSedutaAtleta esercizio;
  final int numero;
  final int di;
  final ({int fatte, int totali}) conto;
  final List<SerieFatta> fatteRiga;
  final int? prossima;
  final _Fase fase;
  final int quanto;
  final String? carico;

  /// Il massimale dell'atleta nell'esercizio: un carico «70%» si legge
  /// in chili.
  final double? massimale;
  final Duration restano;
  final String? poi;

  /// Com'è andata l'ultima volta («tutte facili»), se si sa.
  final String? ultimaVolta;

  /// La riga del voto dell'ultima serie segnata, quando va mostrata.
  final Widget? votoSerie;
  final VoidCallback onMeno;
  final VoidCallback onPiu;
  final VoidCallback onCarico;
  final VoidCallback onFatta;
  final VoidCallback onVia;
  final VoidCallback onFine;
  final VoidCallback onFerma;
  final VoidCallback onSaltaRecupero;
  final VoidCallback onPiuRecupero;
  final VoidCallback onAvanti;
  final bool ultimoDaFare;
  final VoidCallback? onPrecedente;
  final VoidCallback? onSuccessivo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tablet = Breakpoint.of(context) != Breakpoint.compatto;
    final r = esercizio.riga;
    final aTempo = r.durataS != null;
    final finito = prossima == null;
    final grande = AppTypography.numerica(
      tablet ? AppTypography.displayTablet : AppTypography.display,
    );

    // Il centro: il valore della prossima serie, il conto alla rovescia,
    // o cosa si è fatto.
    final Widget centro;
    switch (fase) {
      case _Fase.via:
      case _Fase.lavoro:
      case _Fase.recupero:
        final etichetta = switch (fase) {
          _Fase.via => 'Pronti',
          _Fase.lavoro => 'Tieni',
          _ => 'Recupero',
        };
        centro = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etichetta,
              style: AppTypography.titolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                fase == _Fase.via
                    ? '${restano.inMilliseconds == 0 ? 0 : (restano.inMilliseconds / 1000).ceil()}'
                    : formattaConto(restano),
                style: grande.copyWith(color: colori.testo),
              ),
            ),
            if (poi != null)
              Text(
                poi!,
                textAlign: TextAlign.center,
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
          ],
        );
      case _Fase.pronto when finito:
        centro = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: colori.ok),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Fatto',
              style: AppTypography.titolo.copyWith(color: colori.testo),
            ),
            if (descriviFatte(fatteRiga, aTempo: aTempo) case final d?)
              Text(
                d,
                textAlign: TextAlign.center,
                style: AppTypography.numerica(AppTypography.corpoForte)
                    .copyWith(color: colori.testo),
              ),
          ],
        );
      case _Fase.pronto:
        centro = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Serie $prossima di ${r.serie}',
              style: AppTypography.titolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Tondo(
                  icona: Icons.remove,
                  tooltip: aTempo ? "5'' in meno" : 'Una in meno',
                  onTap: onMeno,
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        aTempo ? formattaSecondi(quanto) : '$quanto',
                        style: grande.copyWith(color: colori.testo),
                      ),
                    ),
                  ),
                ),
                _Tondo(
                  icona: Icons.add,
                  tooltip: aTempo ? "5'' in più" : 'Una in più',
                  onTap: onPiu,
                ),
              ],
            ),
            Text(
              aTempo ? 'da tenere' : 'ripetizioni',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
        );
    }

    final List<Widget> azioni = switch (fase) {
      _Fase.via => [
        _Bottone(etichetta: 'Ferma', onTap: onFerma, principale: true),
      ],
      _Fase.lavoro => [
        _Bottone(etichetta: 'Fine', onTap: onFine, principale: true),
      ],
      _Fase.recupero => [
        Row(
          children: [
            Expanded(
              child: _Bottone(
                etichetta: "+15''",
                semantica: '15 secondi di recupero in più',
                onTap: onPiuRecupero,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              flex: 2,
              child: _Bottone(
                etichetta: 'Salta il recupero',
                onTap: onSaltaRecupero,
                principale: true,
              ),
            ),
          ],
        ),
      ],
      _Fase.pronto when finito => [
        _Bottone(
          etichetta: ultimoDaFare ? 'Finisci la seduta' : 'Prossimo esercizio',
          onTap: onAvanti,
          principale: true,
        ),
      ],
      _Fase.pronto => [
        _Bottone(
          etichetta: carico == null ? 'Carico: nessuno' : 'Carico: $carico',
          semantica: carico == null
              ? 'Carico: nessuno. Cambia il carico'
              : 'Carico: $carico. Cambia il carico',
          icona: Icons.edit_outlined,
          onTap: onCarico,
        ),
        if (ultimaVolta != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            'L\'ultima volta: $ultimaVolta',
            textAlign: TextAlign.center,
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Bottone(
          etichetta: aTempo ? 'Via' : 'Fatta',
          onTap: aTempo ? onVia : onFatta,
          principale: true,
          alto: true,
        ),
      ],
    };

    return LayoutBuilder(
      builder: (context, vincoli) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (vincoli.maxHeight - AppSpacing.s16 - AppSpacing.s24)
                .clamp(0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Avanzamento(fatte: conto.fatte, totali: conto.totali),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    esercizio.esercizio.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titoloXl.copyWith(color: colori.testo),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    prescrizioneEsercizio(r, massimale: massimale),
                    style: AppTypography.numerica(AppTypography.corpo)
                        .copyWith(color: colori.testoSecondario),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (var s = 1; s <= r.serie; s++)
                        _Serie(
                          numero: s,
                          fatta: fatteRiga
                              .where((f) => f.serie == s)
                              .firstOrNull,
                          aTempo: aTempo,
                          inCorso: s == prossima && fase != _Fase.recupero,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  // Il centro si sfoglia col dito: un esercizio avanti o
                  // indietro.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v < -200) onSuccessivo?.call();
                      if (v > 200) onPrecedente?.call();
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 200),
                      child: Center(child: centro),
                    ),
                  ),
                  if (votoSerie != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    votoSerie!,
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  ...azioni,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "0:32", "1:05": il conto alla rovescia, per eccesso (a 0,4 secondi
/// dalla fine si legge ancora "0:01").
String formattaConto(Duration restano) {
  final secondi = (restano.inMilliseconds / 1000).ceil();
  return '${secondi ~/ 60}:${(secondi % 60).toString().padLeft(2, '0')}';
}

/// Le serie fatte sul totale della seduta, con la barra.
class _Avanzamento extends StatelessWidget {
  const _Avanzamento({required this.fatte, required this.totali});

  final int fatte;
  final int totali;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fatte serie su $totali',
          style: AppTypography.numerica(AppTypography.piccolo)
              .copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: totali == 0 ? 0 : fatte / totali,
            minHeight: 6,
            backgroundColor: colori.superficieAlt,
            color: colori.ok,
          ),
        ),
      ],
    );
  }
}

/// Una serie dell'esercizio: fatta (con quanto), in corso o da fare.
class _Serie extends StatelessWidget {
  const _Serie({
    required this.numero,
    required this.fatta,
    required this.aTempo,
    required this.inCorso,
  });

  final int numero;
  final SerieFatta? fatta;
  final bool aTempo;
  final bool inCorso;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final f = fatta;
    final valore = f == null
        ? null
        : aTempo
        ? formattaSecondi(f.durataS ?? 0)
        : '${f.ripetizioni ?? 0}';
    return Semantics(
      label: f == null
          ? 'Serie $numero${inCorso ? ', in corso' : ', da fare'}'
          : 'Serie $numero fatta: $valore',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: f != null
              ? colori.okTenue
              : inCorso
              ? colori.azioneTenue
              : colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          border: Border.all(
            color: f != null
                ? colori.ok
                : inCorso
                ? colori.azione
                : colori.linea,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f != null) ...[
              Icon(Icons.check, size: 18, color: colori.ok),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              valore ?? '$numero',
              style: AppTypography.numerica(AppTypography.corpoForte)
                  .copyWith(color: colori.testo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il − e il + accanto al valore: tondi da 64.
class _Tondo extends StatelessWidget {
  const _Tondo({
    required this.icona,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icona;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return SizedBox.square(
      dimension: AppSpacing.altezzaMinimaBersaglioVasca,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onTap,
        iconSize: 28,
        style: IconButton.styleFrom(
          foregroundColor: colori.testo,
          side: BorderSide(color: colori.lineaForte),
        ),
        icon: Icon(icona),
      ),
    );
  }
}

/// Un bottone da 64 (72 il principale alto), pieno o con il bordo.
class _Bottone extends StatelessWidget {
  const _Bottone({
    required this.etichetta,
    required this.onTap,
    this.principale = false,
    this.alto = false,
    this.icona,
    this.semantica,
  });

  final String etichetta;
  final VoidCallback? onTap;
  final bool principale;
  final bool alto;
  final IconData? icona;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stile = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.fromHeight(alto ? 72 : AppSpacing.altezzaMinimaBersaglioVasca),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        AppTypography.corpoForte.copyWith(fontSize: alto ? 22 : 18),
      ),
    );
    final testo = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            etichetta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            semanticsLabel: semantica,
          ),
        ),
        if (icona != null) ...[
          const SizedBox(width: AppSpacing.s8),
          Icon(icona, size: 20),
        ],
      ],
    );
    return principale
        ? FilledButton(onPressed: onTap, style: stile, child: testo)
        : OutlinedButton(
            onPressed: onTap,
            style: stile.copyWith(
              foregroundColor: WidgetStatePropertyAll(colori.testo),
              side: WidgetStatePropertyAll(
                BorderSide(color: colori.lineaForte),
              ),
            ),
            child: testo,
          );
  }
}

/// «Com'è andata la serie 2?» con tre bottoni uguali: Facile, Giusta,
/// Dura. Quello scelto è evidenziato; toccarlo di nuovo toglie il voto.
/// Il voto è facoltativo: la serie è già segnata.
class _VotoSerieRiga extends StatelessWidget {
  const _VotoSerieRiga({
    required this.serie,
    required this.nomeEsercizio,
    required this.voto,
    required this.onVoto,
  });

  final int serie;

  /// Solo se la serie è di un altro esercizio di quello in vista.
  final String? nomeEsercizio;
  final VotoSerie? voto;
  final ValueChanged<VotoSerie> onVoto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nomeEsercizio == null
              ? 'Com\'è andata la serie $serie?'
              : 'Com\'è andata la serie $serie di $nomeEsercizio?',
          textAlign: TextAlign.center,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s8),
        // Alti uguali anche se una parola va a capo (testo grande).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, v) in VotoSerie.values.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: _BottoneVoto(
                    key: ValueKey('voto-${v.name}'),
                    voto: v,
                    scelto: voto == v,
                    onTap: () => onVoto(v),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BottoneVoto extends StatelessWidget {
  const _BottoneVoto({
    required this.voto,
    required this.scelto,
    required this.onTap,
    super.key,
  });

  final VotoSerie voto;
  final bool scelto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      selected: scelto,
      label: voto.etichetta,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scelto ? colori.azioneTenue : colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.altezzaMinimaBersaglioVasca,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.controllo),
              border: Border.all(
                color: scelto ? colori.azione : colori.lineaForte,
                width: scelto ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scelto) ...[
                  Icon(Icons.check, size: 18, color: colori.azione),
                  const SizedBox(width: AppSpacing.s4),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      voto.etichetta,
                      maxLines: 1,
                      style: AppTypography.corpoForte.copyWith(
                        fontSize: 18,
                        color: colori.testo,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La seduta finita: quante serie, "Quanto è stata dura?" e "Fatto".
class _Fine extends StatelessWidget {
  const _Fine({
    required this.fatte,
    required this.totali,
    required this.rpe,
    required this.onRpe,
    required this.onFatto,
    required this.onTorna,
    required this.votoSerie,
  });

  final int fatte;
  final int totali;
  final int? rpe;
  final ValueChanged<int> onRpe;
  final VoidCallback onFatto;
  final VoidCallback? onTorna;

  /// Il voto dell'ultima serie, se manca o l'hai appena dato.
  final Widget? votoSerie;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s24),
              Icon(Icons.check_circle, size: 48, color: colori.ok),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Seduta finita',
                textAlign: TextAlign.center,
                style: AppTypography.titoloXl.copyWith(color: colori.testo),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '$fatte serie su $totali',
                textAlign: TextAlign.center,
                style: AppTypography.numerica(AppTypography.corpo)
                    .copyWith(color: colori.testoSecondario),
              ),
              if (votoSerie != null) ...[
                const SizedBox(height: AppSpacing.s24),
                votoSerie!,
              ],
              const SizedBox(height: AppSpacing.s32),
              Text(
                'Quanto è stata dura?',
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'Da 0 (riposo) a 10 (al massimo): conta nel tuo carico.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              ScalaRpe(valore: rpe, onScelto: onRpe),
              const SizedBox(height: AppSpacing.s32),
              _Bottone(etichetta: 'Fatto', onTap: onFatto, principale: true),
              if (onTorna != null) ...[
                const SizedBox(height: AppSpacing.s12),
                _Bottone(etichetta: 'Torna agli esercizi', onTap: onTorna),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Il foglio del carico: le proposte (quello dell'allenatore e gli ultimi
/// usati) come chip, "Nessuno", e un campo per scriverne un altro. Null
/// se si chiude senza scegliere.
Future<({String? carico})?> _chiediCarico(
  BuildContext context, {
  required String? attuale,
  required String? previsto,
  required List<String> proposte,
}) => showModalBottomSheet<({String? carico})>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) =>
      _FoglioCarico(attuale: attuale, previsto: previsto, proposte: proposte),
);

class _FoglioCarico extends StatefulWidget {
  const _FoglioCarico({
    required this.attuale,
    required this.previsto,
    required this.proposte,
  });

  final String? attuale;
  final String? previsto;
  final List<String> proposte;

  @override
  State<_FoglioCarico> createState() => _FoglioCaricoState();
}

class _FoglioCaricoState extends State<_FoglioCarico> {
  late final _testo = TextEditingController();

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  void _scegli(String? carico) {
    final t = carico?.trim();
    Navigator.of(context).pop((carico: t == null || t.isEmpty ? null : t));
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final attuale = widget.attuale?.trim();
    Widget chip(String etichetta, String? valore) {
      final scelto =
          (valore ?? '').toLowerCase() == (attuale ?? '').toLowerCase();
      return ChoiceChip(
        label: Text(etichetta),
        selected: scelto,
        onSelected: (_) => _scegli(valore),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Carico',
            style: AppTypography.sezione.copyWith(color: colori.testo),
          ),
          if (widget.previsto case final p? when p.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              'L\'allenatore ha scritto: $p',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final p in widget.proposte) chip(p, p),
              chip('Nessuno', null),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _testo,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Un altro',
                    hintText: '8 kg, elastico verde',
                  ),
                  onSubmitted: (t) {
                    if (t.trim().isNotEmpty) _scegli(t);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s4),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: () {
                    if (_testo.text.trim().isNotEmpty) _scegli(_testo.text);
                  },
                  child: const Text('Usa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
