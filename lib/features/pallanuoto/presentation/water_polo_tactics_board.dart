import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/danger_button.dart';

enum _ModalitaLavagna { giocatori, frecce }

/// Colore scelto dall'allenatore per un giocatore o una freccia — una
/// tavolozza fissa di 5 colori "da pennarello", non i colori del tema:
/// qui è l'inchiostro scelto da chi disegna, non un token semantico
/// dell'app (per questo sono valori letterali, non `context.colori`).
enum ColoreLavagna {
  blu,
  bianco,
  nero,
  rosso,
  giallo;

  Color get colore => switch (this) {
    ColoreLavagna.blu => const Color(0xFF1565C0),
    ColoreLavagna.bianco => const Color(0xFFFFFFFF),
    ColoreLavagna.nero => const Color(0xFF000000),
    ColoreLavagna.rosso => const Color(0xFFD32F2F),
    ColoreLavagna.giallo => const Color(0xFFFBC02D),
  };

  /// Testo/contorno leggibile sopra [colore]: nero sulle tinte chiare
  /// (bianco, giallo), bianco su quelle scure.
  Color get controcolore => switch (this) {
    ColoreLavagna.bianco || ColoreLavagna.giallo => const Color(0xFF000000),
    ColoreLavagna.blu ||
    ColoreLavagna.nero ||
    ColoreLavagna.rosso => const Color(0xFFFFFFFF),
  };

  String get nome => switch (this) {
    ColoreLavagna.blu => 'Blu',
    ColoreLavagna.bianco => 'Bianco',
    ColoreLavagna.nero => 'Nero',
    ColoreLavagna.rosso => 'Rosso',
    ColoreLavagna.giallo => 'Giallo',
  };
}

/// Campo intero (entrambe le porte, per schemi che coinvolgono tutta la
/// vasca, es. transizioni) o solo metà campo (una porta, zona
/// d'attacco, per schemi come superiorità/inferiorità numerica).
enum CampoLavagna {
  intero,
  meta;

  String get nome => switch (this) {
    CampoLavagna.intero => 'Campo intero',
    CampoLavagna.meta => 'Metà campo',
  };
}

/// Un giocatore piazzato sulla lavagna: posizione frazionaria (0-1 su
/// entrambi gli assi, così resta corretta a qualunque dimensione della
/// card) e colore del pallino.
class GiocatoreLavagna {
  const GiocatoreLavagna({required this.posizione, required this.colore});

  final Offset posizione;
  final ColoreLavagna colore;

  GiocatoreLavagna spostato(Offset nuovaPosizione) =>
      GiocatoreLavagna(posizione: nuovaPosizione, colore: colore);
}

/// Una freccia di movimento disegnata sulla lavagna: inizio/fine
/// frazionari e colore del tratto.
class FrecciaLavagna {
  const FrecciaLavagna({
    required this.inizio,
    required this.fine,
    required this.colore,
  });

  final Offset inizio;
  final Offset fine;
  final ColoreLavagna colore;
}

/// Lavagna tattica per pallanuoto: campo disegnato (stesso stile
/// grafico di `CampoTiro`, DESIGN.md sezione 9 — il tocco è l'input,
/// non c'è un form), con due modalità:
/// - **Giocatori**: tocca per piazzare un pallino numerato (sempre
///   della stessa dimensione), trascinalo per spostarlo, doppio tocco
///   per rimuoverlo;
/// - **Frecce**: trascina per disegnare una freccia di movimento
///   (tratto dritto e punta calcolati, non un segno a mano libera: ogni
///   freccia è sempre uguale e precisa).
///
/// Entrambi si disegnano nel colore scelto dalla tavolozza sopra il
/// campo (blu/bianco/nero/rosso/giallo), su campo intero o solo metà
/// campo ([CampoLavagna]) a scelta.
///
/// Con [modificabile] a `false` (schema salvato, sfogliato da un
/// atleta) il campo mostra solo `giocatoriIniziali`/`frecceIniziali`
/// sul [campo] scelto in fase di creazione, senza i controlli di
/// modifica — stessa identica resa grafica, solo in sola lettura. Con
/// [modificabile] a `true` (default, usato dall'allenatore per crearne/
/// modificarne uno) ogni cambiamento richiama [onCambiato], così chi lo
/// contiene può salvarlo; cambiare campo con [onCampoCambiato] cancella
/// lo schema disegnato finora (le coordinate frazionarie non hanno più
/// senso passando da un campo all'altro), previa conferma.
class WaterPoloTacticsBoard extends StatefulWidget {
  const WaterPoloTacticsBoard({
    this.giocatoriIniziali = const [],
    this.frecceIniziali = const [],
    this.campo = CampoLavagna.intero,
    this.modificabile = true,
    this.bloccata = false,
    this.onCambiato,
    this.onCampoCambiato,
    this.onBloccataCambiato,
    super.key,
  });

  /// In acqua ci sono al più 7 giocatori di movimento per squadra: oltre
  /// questo numero, per colore, un tocco per aggiungerne un altro non
  /// fa nulla (con un avviso).
  static const massimoGiocatoriPerColore = 7;

  final List<GiocatoreLavagna> giocatoriIniziali;
  final List<FrecciaLavagna> frecceIniziali;
  final CampoLavagna campo;
  final bool modificabile;

  /// Blocca lo scroll della pagina che contiene la lavagna mentre e'
  /// `true`: senza, trascinare per disegnare una freccia puo' far
  /// scorrere la pagina invece di disegnare (il gesto di trascinamento
  /// e' identico). Chi usa il widget deve applicarlo passando la stessa
  /// fisica di scroll a `AppScaffold.physics` (vedi [onBloccataCambiato]).
  final bool bloccata;

  final void Function(
    List<GiocatoreLavagna> giocatori,
    List<FrecciaLavagna> frecce,
  )?
  onCambiato;
  final ValueChanged<CampoLavagna>? onCampoCambiato;
  final ValueChanged<bool>? onBloccataCambiato;

  @override
  State<WaterPoloTacticsBoard> createState() => _WaterPoloTacticsBoardState();
}

class _WaterPoloTacticsBoardState extends State<WaterPoloTacticsBoard> {
  _ModalitaLavagna _modalita = _ModalitaLavagna.giocatori;
  ColoreLavagna _coloreSelezionato = ColoreLavagna.blu;

  late final List<GiocatoreLavagna> _giocatori = List.of(
    widget.giocatoriIniziali,
  );
  late final List<FrecciaLavagna> _frecce = List.of(widget.frecceIniziali);

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

  Future<void> _cambiaCampo(CampoLavagna nuovo) async {
    if (nuovo == widget.campo) return;
    if (_giocatori.isNotEmpty || _frecce.isNotEmpty) {
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiare campo?'),
          content: const Text(
            'Le posizioni disegnate finora hanno senso solo per il campo '
            'attuale: cambiando, lo schema si svuota.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            DangerButton(
              label: 'Cambia e svuota',
              expanded: false,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (conferma != true) return;
      setState(() {
        _giocatori.clear();
        _frecce.clear();
      });
      _notifica();
    }
    widget.onCampoCambiato?.call(nuovo);
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
                icon: Icon(
                  widget.bloccata ? Icons.lock : Icons.lock_open_outlined,
                ),
                tooltip: widget.bloccata
                    ? 'Sblocca lo scorrimento della pagina'
                    : 'Blocca lo scorrimento della pagina (utile mentre '
                          'disegni una freccia)',
                onPressed: () =>
                    widget.onBloccataCambiato?.call(!widget.bloccata),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Cancella tutto',
                onPressed: vuoto ? null : _cancellaTutto,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          SegmentedButton<CampoLavagna>(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final c in CampoLavagna.values)
                ButtonSegment(value: c, label: Text(c.nome)),
            ],
            selected: {widget.campo},
            onSelectionChanged: (s) => _cambiaCampo(s.first),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s8,
            children: [
              Text(
                'Colore:',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              for (final c in ColoreLavagna.values)
                _SwatchColore(
                  colore: c,
                  selezionato: c == _coloreSelezionato,
                  onTap: () => setState(() => _coloreSelezionato = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        AspectRatio(
          aspectRatio: widget.campo == CampoLavagna.intero ? 3 / 4 : 4 / 3,
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
                          final giaPresenti = _giocatori
                              .where((g) => g.colore == _coloreSelezionato)
                              .length;
                          if (giaPresenti >=
                              WaterPoloTacticsBoard.massimoGiocatoriPerColore) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Massimo '
                                  '${WaterPoloTacticsBoard.massimoGiocatoriPerColore} '
                                  'giocatori ${_coloreSelezionato.nome.toLowerCase()}: '
                                  'cambia colore per aggiungerne altri.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(
                            () => _giocatori.add(
                              GiocatoreLavagna(
                                posizione: relativa(d.localPosition),
                                colore: _coloreSelezionato,
                              ),
                            ),
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
                              _frecce.add(
                                FrecciaLavagna(
                                  inizio: inizio,
                                  fine: fine,
                                  colore: _coloreSelezionato,
                                ),
                              );
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
                              campo: widget.campo,
                              frecce: _frecce,
                              anteprimaFreccia:
                                  _freccitaInizio != null &&
                                      _freccitaAnteprima != null
                                  ? FrecciaLavagna(
                                      inizio: _freccitaInizio!,
                                      fine: _freccitaAnteprima!,
                                      colore: _coloreSelezionato,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        for (var i = 0; i < _giocatori.length; i++)
                          _TokenGiocatore(
                            giocatore: _giocatori[i],
                            // Numerato per colore (1-7), non in ordine
                            // assoluto di piazzamento: al cambio colore
                            // riparte da 1.
                            numero: _giocatori
                                .take(i + 1)
                                .where((g) => g.colore == _giocatori[i].colore)
                                .length,
                            larghezza: larghezza,
                            altezza: altezza,
                            attivo:
                                widget.modificabile &&
                                _modalita == _ModalitaLavagna.giocatori,
                            onSposta: (nuova) {
                              setState(
                                () => _giocatori[i] = _giocatori[i].spostato(
                                  nuova,
                                ),
                              );
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

class _SwatchColore extends StatelessWidget {
  const _SwatchColore({
    required this.colore,
    required this.selezionato,
    required this.onTap,
  });

  final ColoreLavagna colore;
  final bool selezionato;
  final VoidCallback onTap;

  static const _diametro = 28.0;

  @override
  Widget build(BuildContext context) {
    final coloriApp = context.colori;
    return Tooltip(
      message: colore.nome,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _diametro,
          height: _diametro,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colore.colore,
            shape: BoxShape.circle,
            border: Border.all(
              color: selezionato ? coloriApp.azione : coloriApp.linea,
              width: selezionato ? 3 : 1,
            ),
          ),
          child: selezionato
              ? Icon(Icons.check, size: 14, color: colore.controcolore)
              : null,
        ),
      ),
    );
  }
}

class _TokenGiocatore extends StatelessWidget {
  const _TokenGiocatore({
    required this.giocatore,
    required this.numero,
    required this.larghezza,
    required this.altezza,
    required this.attivo,
    required this.onSposta,
    required this.onRimuovi,
  });

  final GiocatoreLavagna giocatore;
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
    final posizione = giocatore.posizione;
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
              color: giocatore.colore.colore,
              shape: BoxShape.circle,
              border: Border.all(color: colori.superficie, width: 2),
            ),
            child: Text(
              '$numero',
              style: AppTypography.piccolo.copyWith(
                color: giocatore.colore.controcolore,
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
    required this.campo,
    required this.frecce,
    this.anteprimaFreccia,
  });

  final ColoriApp colori;
  final CampoLavagna campo;
  final List<FrecciaLavagna> frecce;
  final FrecciaLavagna? anteprimaFreccia;

  @override
  void paint(Canvas canvas, Size size) {
    // `colori.testo` (non `colori.linea`, pensato per bordi discreti fra
    // superfici): il disegno del campo deve restare ben leggibile sopra
    // `azioneTenue` in entrambi i temi, non essere un dettaglio sfumato.
    final trattoCampo = Paint()
      ..color = colori.testo
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), trattoCampo);

    final larghezzaPorta = size.width * 0.24;
    final altezzaPorta = size.height * 0.05;
    final centroX = size.width / 2;

    // Porta in alto, sempre presente.
    canvas.drawRect(
      Rect.fromLTWH(
        centroX - larghezzaPorta / 2,
        0,
        larghezzaPorta,
        altezzaPorta,
      ),
      trattoCampo,
    );

    if (campo == CampoLavagna.intero) {
      // Campo intero: anche la porta in basso, linea e cerchio di
      // centrocampo — per schemi che coinvolgono tutta la vasca (es.
      // transizioni).
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
      canvas.drawCircle(
        Offset(centroX, centroY),
        size.width * 0.12,
        trattoCampo,
      );
    }

    for (final f in frecce) {
      final trattoFreccia = Paint()
        ..color = f.colore.colore
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _disegnaFreccia(
        canvas,
        Offset(f.inizio.dx * size.width, f.inizio.dy * size.height),
        Offset(f.fine.dx * size.width, f.fine.dy * size.height),
        trattoFreccia,
      );
    }
    final anteprima = anteprimaFreccia;
    if (anteprima != null) {
      final trattoAnteprima = Paint()
        ..color = anteprima.colore.colore.withValues(alpha: 0.5)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _disegnaFreccia(
        canvas,
        Offset(
          anteprima.inizio.dx * size.width,
          anteprima.inizio.dy * size.height,
        ),
        Offset(anteprima.fine.dx * size.width, anteprima.fine.dy * size.height),
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

  // Sempre true: la lista frecce e' lo stesso oggetto mutato in place tra
  // una build e l'altra (mai riassegnato), quindi un confronto per
  // identita' qui sarebbe sempre "invariato" anche quando il contenuto
  // e' cambiato (es. dopo "Cancella tutto") — il campo e' comunque
  // leggero da ridisegnare.
  @override
  bool shouldRepaint(covariant _CampoCompletoPainter oldDelegate) => true;
}
