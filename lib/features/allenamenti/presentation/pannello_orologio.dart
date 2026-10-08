import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/suono/bip.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/tonal_chip.dart';
import '../domain/durata_serie.dart';
import '../domain/orologio_vasca.dart';
import '../domain/serie.dart';

/// Quanti gruppi possono partire sfalsati, e a che distanza.
const _scelteGruppi = [1, 2, 3, 4];
const _scelteDistacco = [5, 10, 15, 20];

/// "1'05''" o "23''", come si dice guardando il pace clock. Per un conto
/// alla rovescia si arrotonda per eccesso: "1''" fino all'istante della
/// partenza, mai "0''" mentre manca ancora qualcosa.
String _comeAlCronometro(double secondi, {bool perEccesso = false}) {
  final s = perEccesso ? secondi.ceil() : secondi.floor();
  final m = s ~/ 60;
  final resto = s % 60;
  return m > 0 ? "$m'${resto.toString().padLeft(2, '0')}''" : "$resto''";
}

/// "1:07": il tempo dalla partenza, come sul cronometro.
String _minutiSecondi(double secondi) {
  final s = secondi.floor();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// L'orologio di vasca sotto la serie del "Bordo vasca" (idea presa da
/// Swimtraxx Hub). Fermo propone ogni quanto si parte (ritoccabile di 5
/// secondi) e le partenze sfalsate per gruppi; con "Via" conta le
/// ripetute, mostra in grande il tempo dalla partenza (o, nelle serie a
/// tempo, quanto manca alla fine del lavoro o del recupero) e quanto
/// manca alla prossima, e si illumina a ogni partenza. Con il suono
/// acceso fa tre bip brevi negli ultimi 3 secondi prima di ogni partenza
/// del primo gruppo, uno lungo a ogni partenza (di ogni gruppo) e uno
/// lungo a fine lavoro nelle serie a tempo. Quando l'ultimo gruppo ha
/// finito chiama [onFinita].
///
/// Il tempo viene dai fotogrammi ([Ticker]), non da un timer che si somma
/// a ogni scatto: un timer in ritardo farebbe andare l'orologio lento.
class PannelloOrologio extends StatefulWidget {
  const PannelloOrologio({
    required this.serie,
    this.riferimento,
    required this.gruppi,
    required this.distaccoS,
    required this.onGruppi,
    required this.onDistacco,
    required this.onFinita,
    this.suono = true,
    this.onSuono,
    this.suona = suonaBip,
    super.key,
  });

  final DatiSerie serie;

  /// Il passo del gruppo, per stimare le partenze di una serie senza
  /// ripartenza.
  final PassoRiferimento? riferimento;
  final int gruppi;
  final int distaccoS;
  final ValueChanged<int> onGruppi;
  final ValueChanged<int> onDistacco;
  final VoidCallback onFinita;

  /// Il suono è acceso (vale per tutta la seduta, lo tiene chi apre
  /// l'orologio); [onSuono] null = niente pulsante per cambiarlo.
  final bool suono;
  final ValueChanged<bool>? onSuono;

  /// Chi fa il bip: [suonaBip], o un registratore nei test.
  final void Function({bool lungo}) suona;

  @override
  State<PannelloOrologio> createState() => _PannelloOrologioState();
}

class _PannelloOrologioState extends State<PannelloOrologio>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_battito);
  late var _proposto = intervalloPartenze(
    widget.serie,
    riferimento: widget.riferimento,
  );
  late double _intervalloS = _proposto.secondi;

  /// Il tempo corso prima dell'ultima pausa, e quello della corsa in atto.
  Duration _primaDellaPausa = Duration.zero;
  Duration _corsa = Duration.zero;
  bool _avviato = false;
  bool _inPausa = false;
  bool _finita = false;
  int _decimi = -1;
  bool _eraPartita = false;
  bool _eraInRecupero = false;

  /// L'ultimo secondo del conto alla rovescia già suonato (3, 2, 1).
  int? _ultimoConto;

  PianoPartenze get _piano => PianoPartenze(
    ripetute: widget.serie.ripetute,
    intervalloS: _intervalloS,
    lavoroS: widget.serie.durataS?.toDouble(),
    gruppi: widget.gruppi,
    distaccoS: widget.distaccoS.toDouble(),
  );

  double get _secondi => (_primaDellaPausa + _corsa).inMilliseconds / 1000;

  /// I primati del gruppo arrivano dopo l'apertura: finché l'orologio è
  /// fermo e la partenza non è stata ritoccata, la stima si aggiorna.
  @override
  void didUpdateWidget(PannelloOrologio vecchio) {
    super.didUpdateWidget(vecchio);
    if (_avviato || widget.riferimento == vecchio.riferimento) return;
    final nuovo = intervalloPartenze(
      widget.serie,
      riferimento: widget.riferimento,
    );
    if (_intervalloS == _proposto.secondi) _intervalloS = nuovo.secondi;
    _proposto = nuovo;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _battito(Duration trascorso) {
    _corsa = trascorso;
    final t = _secondi;
    final stato = _piano.a(t);
    if (stato.finita) {
      _ticker.stop();
      setState(() => _finita = true);
      widget.onFinita();
      return;
    }
    if (stato.appenaPartita && !_eraPartita) {
      HapticFeedback.heavyImpact();
      _bip(lungo: true);
    } else if (stato.inRecupero && !_eraInRecupero) {
      _bip(lungo: true);
    }
    _eraPartita = stato.appenaPartita;
    _eraInRecupero = stato.inRecupero;
    final conto = stato.allaProssimaS?.ceil();
    if (conto != null && conto <= 3 && conto >= 1 && conto != _ultimoConto) {
      _bip();
    }
    _ultimoConto = conto;
    final decimi = (t * 10).floor();
    if (decimi != _decimi) setState(() => _decimi = decimi);
  }

  void _bip({bool lungo = false}) {
    if (widget.suono) widget.suona(lungo: lungo);
  }

  void _via() {
    // Dentro il tocco: è il momento in cui il browser lascia suonare.
    preparaSuono();
    setState(() {
      _primaDellaPausa = Duration.zero;
      _corsa = Duration.zero;
      _avviato = true;
      _inPausa = false;
      _finita = false;
      // La partenza del "Via" si segnala qui, non al primo battito.
      _eraPartita = true;
      _eraInRecupero = false;
      _ultimoConto = null;
    });
    HapticFeedback.heavyImpact();
    _bip(lungo: true);
    _ticker.start();
  }

  void _pausa() {
    _ticker.stop();
    setState(() {
      _primaDellaPausa += _corsa;
      _corsa = Duration.zero;
      _inPausa = true;
    });
  }

  void _riprendi() {
    preparaSuono();
    setState(() => _inPausa = false);
    _ticker.start();
  }

  void _ferma() {
    _ticker.stop();
    setState(() {
      _primaDellaPausa = Duration.zero;
      _corsa = Duration.zero;
      _avviato = false;
      _inPausa = false;
      _finita = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final inCorso = _avviato && !_finita;
    final stato = inCorso ? _piano.a(_secondi) : null;
    final via = stato != null && stato.appenaPartita && !_inPausa;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: via ? colori.azione : colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: via ? colori.azione : colori.linea),
      ),
      child: stato == null ? _fermo(context) : _inCorso(context, stato, via),
    );
  }

  Widget _fermo(BuildContext context) {
    final colori = context.colori;
    final etichetta = AppTypography.etichetta.copyWith(
      color: colori.testoSecondario,
    );
    final ogni = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Partenze 5 secondi prima',
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _intervalloS > 5
              ? () => setState(() => _intervalloS -= 5)
              : null,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // Con una ripetuta sola non ci sono partenze: è la durata.
              [
                widget.serie.ripetute == 1 ? 'Durata' : 'Partenze ogni',
                if (_proposto.stimato && _intervalloS == _proposto.secondi)
                  '(stima)',
              ].join(' '),
              style: etichetta,
            ),
            Text(
              _comeAlCronometro(_intervalloS),
              style: AppTypography.numerica(AppTypography.numeroMedio)
                  .copyWith(color: colori.testo),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Partenze 5 secondi dopo',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => setState(() => _intervalloS += 5),
        ),
      ],
    );
    final gruppi = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gruppi che partono sfalsati', style: etichetta),
        const SizedBox(height: AppSpacing.s4),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final g in _scelteGruppi)
              TonalChip(
                etichetta: '$g',
                selezionato: widget.gruppi == g,
                onSelezionato: (_) => widget.onGruppi(g),
              ),
          ],
        ),
      ],
    );
    final distacco = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uno dopo l\'altro a', style: etichetta),
        const SizedBox(height: AppSpacing.s4),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final d in _scelteDistacco)
              TonalChip(
                etichetta: "$d''",
                selezionato: widget.distaccoS == d,
                onSelezionato: (_) => widget.onDistacco(d),
              ),
          ],
        ),
      ],
    );
    final finita = [
      if (_finita) ...[
        Text(
          'Serie finita',
          style: AppTypography.corpoForte.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
      ],
    ];
    // Sul telefono l'orologio fermo sta in una riga: la serie, sopra,
    // deve restare in vista (segnalazione del coach 2026-10-08). Gruppi,
    // distacco e suono in un foglio a parte.
    if (Breakpoint.of(context) == Breakpoint.compatto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...finita,
          Row(
            children: [
              SizedBox(
                width: 116,
                child: FilledButton.icon(
                  onPressed: _via,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                    ),
                    textStyle: AppTypography.titolo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pannello),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: Text(
                    _finita ? 'Ancora' : 'Via',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(fit: BoxFit.scaleDown, child: ogni),
              ),
              IconButton(
                tooltip: 'Gruppi e suono',
                icon: Badge(
                  isLabelVisible: widget.gruppi > 1,
                  // Il rosso è solo per "in corso" ed errori (DESIGN.md).
                  backgroundColor: colori.azione,
                  textColor: colori.azioneInk,
                  label: Text('${widget.gruppi}'),
                  child: const Icon(Icons.tune),
                ),
                onPressed: _impostazioni,
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...finita,
        Wrap(
          spacing: AppSpacing.s24,
          runSpacing: AppSpacing.s12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: FilledButton.icon(
                onPressed: _via,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  textStyle: AppTypography.titolo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pannello),
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 32),
                label: Text(_finita ? 'Di nuovo' : 'Via'),
              ),
            ),
            ogni,
            gruppi,
            if (widget.gruppi > 1) distacco,
            ?_pulsanteSuono(colori.testoSecondario),
          ],
        ),
      ],
    );
  }

  /// Sul telefono: gruppi sfalsati, distacco e suono in un foglio.
  Future<void> _impostazioni() {
    var gruppi = widget.gruppi;
    var distacco = widget.distaccoS;
    var suono = widget.suono;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, aggiorna) {
          final colori = context.colori;
          final etichetta = AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          );
          final onSuono = widget.onSuono;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                0,
                AppSpacing.s16,
                AppSpacing.s24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gruppi che partono sfalsati', style: etichetta),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final g in _scelteGruppi)
                        TonalChip(
                          etichetta: '$g',
                          selezionato: gruppi == g,
                          onSelezionato: (_) {
                            widget.onGruppi(g);
                            aggiorna(() => gruppi = g);
                          },
                        ),
                    ],
                  ),
                  if (gruppi > 1) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text('Uno dopo l\'altro a', style: etichetta),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final d in _scelteDistacco)
                          TonalChip(
                            etichetta: "$d''",
                            selezionato: distacco == d,
                            onSelezionato: (_) {
                              widget.onDistacco(d);
                              aggiorna(() => distacco = d);
                            },
                          ),
                      ],
                    ),
                  ],
                  if (onSuono != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suono alle partenze'),
                      value: suono,
                      onChanged: (v) {
                        preparaSuono();
                        onSuono(v);
                        aggiorna(() => suono = v);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _pulsanteSuono(Color colore) {
    final onSuono = widget.onSuono;
    if (onSuono == null) return null;
    return IconButton(
      tooltip: widget.suono ? 'Togli il suono' : 'Metti il suono',
      color: colore,
      iconSize: 32,
      icon: Icon(widget.suono ? Icons.volume_up : Icons.volume_off),
      onPressed: () {
        preparaSuono();
        onSuono(!widget.suono);
      },
    );
  }

  Widget _inCorso(BuildContext context, StatoOrologio stato, bool via) {
    final colori = context.colori;
    final tablet = Breakpoint.of(context) != Breakpoint.compatto;
    final testo = via ? colori.azioneInk : colori.testo;
    final secondario = via ? colori.azioneInk : colori.testoSecondario;
    final aTempo = widget.serie.durataS != null;
    final ripetute = widget.serie.ripetute;

    final etichettaGrande = aTempo
        ? (stato.inRecupero ? 'Recupero, manca' : 'Lavoro, manca')
        : 'Dalla partenza';
    final grande = aTempo
        ? _comeAlCronometro(stato.allaFineFaseS!, perEccesso: true)
        : _minutiSecondi(stato.dallaPartenzaS);
    // All'ultima ripetuta non c'è una partenza da aspettare: si conta
    // alla fine della serie (dell'ultimo gruppo, se sono sfalsati).
    final ultima = !via && stato.allaProssimaS == null;
    final prossima = via
        ? 'Via'
        : ultima
        ? _comeAlCronometro(_piano.durataS - _secondi, perEccesso: true)
        : _comeAlCronometro(stato.allaProssimaS!, perEccesso: true);

    final gruppi = [
      for (var g = 0; g < stato.prossimiGruppi.length; g++)
        if (stato.prossimiGruppi[g] case final p?)
          'Gruppo ${g + 2} tra ${_comeAlCronometro(p, perEccesso: true)}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ripetuta ${stato.ripetuta} di $ripetute'
                '${_inPausa ? ' · in pausa' : ''}',
                style: AppTypography.corpoForte.copyWith(color: testo),
              ),
            ),
            IconButton(
              tooltip: _inPausa ? 'Riprendi' : 'Pausa',
              color: testo,
              iconSize: 32,
              icon: Icon(_inPausa ? Icons.play_arrow : Icons.pause),
              onPressed: _inPausa ? _riprendi : _pausa,
            ),
            IconButton(
              tooltip: "Ferma l'orologio",
              color: testo,
              iconSize: 32,
              icon: const Icon(Icons.stop),
              onPressed: _ferma,
            ),
            ?_pulsanteSuono(testo),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etichettaGrande,
                    style: AppTypography.corpo.copyWith(color: secondario),
                  ),
                  SizedBox(
                    height: tablet ? 120 : 64,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        grande,
                        style: AppTypography.numerica(
                          AppTypography.displayTablet,
                        ).copyWith(color: testo),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ultima ? 'Fine serie tra' : 'Prossima partenza',
                    style: AppTypography.corpo.copyWith(color: secondario),
                  ),
                  SizedBox(
                    height: tablet ? 72 : 44,
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      child: Text(
                        prossima,
                        style: AppTypography.numerica(AppTypography.display)
                            .copyWith(color: testo),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (gruppi.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            gruppi.join('   '),
            style: AppTypography.numerica(AppTypography.corpoForte)
                .copyWith(color: secondario),
          ),
        ],
      ],
    );
  }
}
