import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';

enum _ModalitaLavagna { giocatori, frecce }

/// Lavagna tattica per pallanuoto: campo disegnato (stesso stile
/// grafico di `CampoTiro`, DESIGN.md sezione 9 — il tocco è l'input,
/// non c'è un form), con due modalità:
/// - **Giocatori**: tocca per piazzare un pallino numerato, trascinalo
///   per spostarlo, doppio tocco per rimuoverlo;
/// - **Frecce**: trascina per disegnare una freccia di movimento.
///
/// Con [modificabile] a `false` (schema salvato, sfogliato da un
/// atleta) il campo mostra solo `giocatoriIniziali`/`frecceIniziali`,
/// senza i controlli di modifica — stessa identica resa grafica, solo
/// in sola lettura. Con [modificabile] a `true` (default, usato
/// dall'allenatore per crearne/modificarne uno) ogni cambiamento
/// richiama [onCambiato], così chi lo contiene può salvarlo.
class WaterPoloTacticsBoard extends StatefulWidget {
  const WaterPoloTacticsBoard({
    this.giocatoriIniziali = const [],
    this.frecceIniziali = const [],
    this.modificabile = true,
    this.onCambiato,
    super.key,
  });

  final List<Offset> giocatoriIniziali;
  final List<(Offset, Offset)> frecceIniziali;
  final bool modificabile;
  final void Function(List<Offset> giocatori, List<(Offset, Offset)> frecce)?
  onCambiato;

  @override
  State<WaterPoloTacticsBoard> createState() => _WaterPoloTacticsBoardState();
}

class _WaterPoloTacticsBoardState extends State<WaterPoloTacticsBoard> {
  _ModalitaLavagna _modalita = _ModalitaLavagna.giocatori;

  /// Posizioni frazionarie (0-1 su entrambi gli assi) dei giocatori
  /// piazzati, così restano corrette a qualunque dimensione della card.
  late final List<Offset> _giocatori = List.of(widget.giocatoriIniziali);
  late final List<(Offset, Offset)> _frecce = List.of(widget.frecceIniziali);

  Offset? _freccitaInizio;
  Offset? _freccitaAnteprima;

  void _notifica() =>
      widget.onCambiato?.call(List.of(_giocatori), List.of(_frecce));

  void _cancellaTutto() {
    setState(() {
      _giocatori.clear();
      _frecce.clear();
    });
    _notifica();
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final vuoto = _giocatori.isEmpty && _frecce.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.modificabile) ...[
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_ModalitaLavagna>(
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: _ModalitaLavagna.giocatori,
                      label: Text('Giocatori'),
                      icon: Icon(Icons.circle_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: _ModalitaLavagna.frecce,
                      label: Text('Frecce'),
                      icon: Icon(Icons.north_east, size: 18),
                    ),
                  ],
                  selected: {_modalita},
                  onSelectionChanged: (s) =>
                      setState(() => _modalita = s.first),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Cancella tutto',
                onPressed: vuoto ? null : _cancellaTutto,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larghezza = constraints.maxWidth;
                final altezza = constraints.maxHeight;

                Offset relativa(Offset locale) => Offset(
                  (locale.dx / larghezza).clamp(0.0, 1.0),
                  (locale.dy / altezza).clamp(0.0, 1.0),
                );

                return GestureDetector(
                  onTapDown:
                      !widget.modificabile ||
                          _modalita != _ModalitaLavagna.giocatori
                      ? null
                      : (d) {
                          setState(
                            () => _giocatori.add(relativa(d.localPosition)),
                          );
                          _notifica();
                        },
                  onPanStart:
                      !widget.modificabile ||
                          _modalita != _ModalitaLavagna.frecce
                      ? null
                      : (d) => setState(() {
                          _freccitaInizio = relativa(d.localPosition);
                          _freccitaAnteprima = _freccitaInizio;
                        }),
                  onPanUpdate:
                      !widget.modificabile ||
                          _modalita != _ModalitaLavagna.frecce
                      ? null
                      : (d) => setState(
                          () => _freccitaAnteprima = relativa(d.localPosition),
                        ),
                  onPanEnd:
                      !widget.modificabile ||
                          _modalita != _ModalitaLavagna.frecce
                      ? null
                      : (_) {
                          setState(() {
                            final inizio = _freccitaInizio;
                            final fine = _freccitaAnteprima;
                            if (inizio != null &&
                                fine != null &&
                                (inizio - fine).distance > 0.02) {
                              _frecce.add((inizio, fine));
                            }
                            _freccitaInizio = null;
                            _freccitaAnteprima = null;
                          });
                          _notifica();
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colori.azioneTenue,
                      border: Border.all(color: colori.linea),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CampoCompletoPainter(
                              colori: colori,
                              frecce: _frecce,
                              anteprimaFreccia:
                                  _freccitaInizio != null &&
                                      _freccitaAnteprima != null
                                  ? (_freccitaInizio!, _freccitaAnteprima!)
                                  : null,
                            ),
                          ),
                        ),
                        for (var i = 0; i < _giocatori.length; i++)
                          _TokenGiocatore(
                            posizione: _giocatori[i],
                            numero: i + 1,
                            larghezza: larghezza,
                            altezza: altezza,
                            attivo:
                                widget.modificabile &&
                                _modalita == _ModalitaLavagna.giocatori,
                            onSposta: (nuova) {
                              setState(() => _giocatori[i] = nuova);
                              _notifica();
                            },
                            onRimuovi: () {
                              setState(() => _giocatori.removeAt(i));
                              _notifica();
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.modificabile) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            _modalita == _ModalitaLavagna.giocatori
                ? 'Tocca per aggiungere un giocatore, trascina per spostarlo, '
                      'doppio tocco per rimuoverlo.'
                : 'Trascina per disegnare una freccia di movimento.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
      ],
    );
  }
}

class _TokenGiocatore extends StatelessWidget {
  const _TokenGiocatore({
    required this.posizione,
    required this.numero,
    required this.larghezza,
    required this.altezza,
    required this.attivo,
    required this.onSposta,
    required this.onRimuovi,
  });

  final Offset posizione;
  final int numero;
  final double larghezza;
  final double altezza;

  /// Solo in modalità "Giocatori" il pallino risponde al trascinamento:
  /// in modalità "Frecce" il gesto deve arrivare al campo sotto, per
  /// poter disegnare una freccia che parte proprio da un giocatore.
  final bool attivo;
  final ValueChanged<Offset> onSposta;
  final VoidCallback onRimuovi;

  static const _diametro = 32.0;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Positioned(
      left: posizione.dx * larghezza - _diametro / 2,
      top: posizione.dy * altezza - _diametro / 2,
      child: IgnorePointer(
        ignoring: !attivo,
        child: GestureDetector(
          onPanUpdate: (d) {
            final nuovaX =
                (((posizione.dx * larghezza) + d.delta.dx) / larghezza).clamp(
                  0.0,
                  1.0,
                );
            final nuovaY = (((posizione.dy * altezza) + d.delta.dy) / altezza)
                .clamp(0.0, 1.0);
            onSposta(Offset(nuovaX, nuovaY));
          },
          onDoubleTap: onRimuovi,
          child: Container(
            width: _diametro,
            height: _diametro,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colori.azione,
              shape: BoxShape.circle,
              border: Border.all(color: colori.superficie, width: 2),
            ),
            child: Text(
              '$numero',
              style: AppTypography.piccolo.copyWith(
                color: colori.azioneInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoCompletoPainter extends CustomPainter {
  _CampoCompletoPainter({
    required this.colori,
    required this.frecce,
    this.anteprimaFreccia,
  });

  final ColoriApp colori;
  final List<(Offset, Offset)> frecce;
  final (Offset, Offset)? anteprimaFreccia;

  @override
  void paint(Canvas canvas, Size size) {
    final trattoCampo = Paint()
      ..color = colori.linea
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trattoCampo);

    // Porte, sopra e sotto: la lavagna mostra il campo per intero (non
    // solo la zona d'attacco come CampoTiro), per poter schierare
    // entrambe le squadre.
    final larghezzaPorta = size.width * 0.24;
    final altezzaPorta = size.height * 0.03;
    final centroX = size.width / 2;
    canvas.drawRect(
      Rect.fromLTWH(
        centroX - larghezzaPorta / 2,
        0,
        larghezzaPorta,
        altezzaPorta,
      ),
      trattoCampo,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        centroX - larghezzaPorta / 2,
        size.height - altezzaPorta,
        larghezzaPorta,
        altezzaPorta,
      ),
      trattoCampo,
    );

    final centroY = size.height / 2;
    canvas.drawLine(
      Offset(0, centroY),
      Offset(size.width, centroY),
      trattoCampo,
    );
    canvas.drawCircle(Offset(centroX, centroY), size.width * 0.12, trattoCampo);

    final trattoFreccia = Paint()
      ..color = colori.azione
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (inizio, fine) in frecce) {
      _disegnaFreccia(
        canvas,
        Offset(inizio.dx * size.width, inizio.dy * size.height),
        Offset(fine.dx * size.width, fine.dy * size.height),
        trattoFreccia,
      );
    }
    final anteprima = anteprimaFreccia;
    if (anteprima != null) {
      final (inizio, fine) = anteprima;
      final trattoAnteprima = Paint()
        ..color = colori.azione.withValues(alpha: 0.5)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _disegnaFreccia(
        canvas,
        Offset(inizio.dx * size.width, inizio.dy * size.height),
        Offset(fine.dx * size.width, fine.dy * size.height),
        trattoAnteprima,
      );
    }
  }

  void _disegnaFreccia(Canvas canvas, Offset da, Offset a, Paint tratto) {
    canvas.drawLine(da, a, tratto);
    final direzione = a - da;
    if (direzione.distance == 0) return;
    final angolo = direzione.direction;
    const angoloPunta = 0.45;
    const lunghezzaPunta = 10.0;
    final p1 =
        a -
        Offset(
          lunghezzaPunta * math.cos(angolo - angoloPunta),
          lunghezzaPunta * math.sin(angolo - angoloPunta),
        );
    final p2 =
        a -
        Offset(
          lunghezzaPunta * math.cos(angolo + angoloPunta),
          lunghezzaPunta * math.sin(angolo + angoloPunta),
        );
    canvas.drawLine(a, p1, tratto);
    canvas.drawLine(a, p2, tratto);
  }

  @override
  bool shouldRepaint(covariant _CampoCompletoPainter oldDelegate) =>
      oldDelegate.colori != colori ||
      oldDelegate.frecce != frecce ||
      oldDelegate.anteprimaFreccia != anteprimaFreccia;
}
