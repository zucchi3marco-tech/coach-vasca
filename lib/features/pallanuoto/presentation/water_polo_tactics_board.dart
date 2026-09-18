import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/danger_button.dart';

enum _ModalitaLavagna { giocatori, frecce }

/// Numero (1-7) di un giocatore nel proprio colore: conta quanti
/// giocatori dello stesso colore lo precedono (se stesso incluso)
/// nell'ordine di piazzamento — condiviso fra la lavagna e
/// `SchemaTatticoPlayer`, così la numerazione resta identica ovunque.
int _numeroPerColore(List<GiocatoreLavagna> giocatori, int indice) => giocatori
    .take(indice + 1)
    .where((g) => g.colore == giocatori[indice].colore)
    .length;

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

/// Un passo della sequenza (vedi `SchemaTatticoPlayer`): stessa forma
/// di `PassoSchema` a livello di dominio, ma con i tipi Flutter usati
/// da questo widget.
typedef PassoLavagna = ({
  List<GiocatoreLavagna> giocatori,
  List<FrecciaLavagna> frecce,
});

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
                          // Il giallo e' riservato alla palla (nessun
                          // numero, vedi _TokenGiocatore): non e' un
                          // "giocatore di movimento", quindi non conta
                          // per il tetto dei 7.
                          final giaPresenti =
                              _coloreSelezionato == ColoreLavagna.giallo
                              ? 0
                              : _giocatori
                                    .where(
                                      (g) => g.colore == _coloreSelezionato,
                                    )
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
                            numero: _numeroPerColore(_giocatori, i),
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
            // Il giallo e' riservato alla palla: nessun numero sopra,
            // cosi' si distingue a colpo d'occhio dai giocatori e si
            // identificano i passaggi.
            child: giocatore.colore == ColoreLavagna.giallo
                ? null
                : Text(
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

/// Un giocatore abbinato fra due passi consecutivi, per l'animazione:
/// abbinato per (colore, numero-nel-colore), non per posizione nella
/// lista. Chi non ha corrispondenza nel passo di arrivo resta fermo e
/// sfuma; chi compare solo nel passo di arrivo appare sfumando dentro,
/// nella sua posizione finale.
class _TokenSequenza {
  const _TokenSequenza({
    required this.colore,
    required this.numero,
    required this.posizioneIniziale,
    required this.posizioneFinale,
    required this.opacitaIniziale,
    required this.opacitaFinale,
  });

  final ColoreLavagna colore;
  final int numero;
  final Offset posizioneIniziale;
  final Offset posizioneFinale;
  final double opacitaIniziale;
  final double opacitaFinale;
}

List<_TokenSequenza> _abbinaGiocatori(
  List<GiocatoreLavagna> da,
  List<GiocatoreLavagna> a,
) {
  Map<(ColoreLavagna, int), GiocatoreLavagna> mappaPerChiave(
    List<GiocatoreLavagna> giocatori,
  ) {
    final conteggio = <ColoreLavagna, int>{};
    final mappa = <(ColoreLavagna, int), GiocatoreLavagna>{};
    for (final g in giocatori) {
      final n = (conteggio[g.colore] ?? 0) + 1;
      conteggio[g.colore] = n;
      mappa[(g.colore, n)] = g;
    }
    return mappa;
  }

  final mappaDa = mappaPerChiave(da);
  final mappaA = mappaPerChiave(a);

  return [
    for (final chiave in {...mappaDa.keys, ...mappaA.keys})
      if (mappaDa[chiave] != null && mappaA[chiave] != null)
        _TokenSequenza(
          colore: chiave.$1,
          numero: chiave.$2,
          posizioneIniziale: mappaDa[chiave]!.posizione,
          posizioneFinale: mappaA[chiave]!.posizione,
          opacitaIniziale: 1,
          opacitaFinale: 1,
        )
      else if (mappaDa[chiave] != null)
        _TokenSequenza(
          colore: chiave.$1,
          numero: chiave.$2,
          posizioneIniziale: mappaDa[chiave]!.posizione,
          posizioneFinale: mappaDa[chiave]!.posizione,
          opacitaIniziale: 1,
          opacitaFinale: 0,
        )
      else
        _TokenSequenza(
          colore: chiave.$1,
          numero: chiave.$2,
          posizioneIniziale: mappaA[chiave]!.posizione,
          posizioneFinale: mappaA[chiave]!.posizione,
          opacitaIniziale: 0,
          opacitaFinale: 1,
        ),
  ];
}

class _TokenAnimato extends StatelessWidget {
  const _TokenAnimato({
    required this.token,
    required this.t,
    required this.larghezza,
    required this.altezza,
  });

  final _TokenSequenza token;
  final double t;
  final double larghezza;
  final double altezza;

  static const _diametro = 32.0;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final posizione = Offset.lerp(
      token.posizioneIniziale,
      token.posizioneFinale,
      t,
    )!;
    final opacita =
        token.opacitaIniziale +
        (token.opacitaFinale - token.opacitaIniziale) * t;
    return Positioned(
      left: posizione.dx * larghezza - _diametro / 2,
      top: posizione.dy * altezza - _diametro / 2,
      child: Opacity(
        opacity: opacita,
        child: Container(
          width: _diametro,
          height: _diametro,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: token.colore.colore,
            shape: BoxShape.circle,
            border: Border.all(color: colori.superficie, width: 2),
          ),
          child: token.colore == ColoreLavagna.giallo
              ? null
              : Text(
                  '${token.numero}',
                  style: AppTypography.piccolo.copyWith(
                    color: token.colore.controcolore,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Sfoglia e riproduce in animazione la sequenza di passi di uno
/// schema tattico: fermo su un passo mostra i giocatori e le sue
/// frecce (stessa resa di [WaterPoloTacticsBoard] in sola lettura); il
/// tasto play anima lo spostamento verso il passo successivo —
/// giocatori abbinati per colore+numero (vedi [_abbinaGiocatori]),
/// frecce nascoste durante il movimento — in sequenza fino all'ultimo
/// passo. Usato sia dal visualizzatore (schema salvato) sia
/// dall'anteprima nell'editor (schema ancora in bozza, non salvato).
class SchemaTatticoPlayer extends StatefulWidget {
  const SchemaTatticoPlayer({
    required this.passi,
    required this.campo,
    super.key,
  });

  final List<PassoLavagna> passi;
  final CampoLavagna campo;

  @override
  State<SchemaTatticoPlayer> createState() => _SchemaTatticoPlayerState();
}

class _SchemaTatticoPlayerState extends State<SchemaTatticoPlayer>
    with SingleTickerProviderStateMixin {
  static const _durataMovimento = Duration(milliseconds: 900);
  static const _durataPausa = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durataMovimento,
  );

  int _passoAttuale = 0;
  int? _passoSuccessivo;
  bool _inRiproduzione = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_inRiproduzione || widget.passi.length < 2) return;
    setState(() => _inRiproduzione = true);
    var i = _passoAttuale;
    while (_inRiproduzione && i < widget.passi.length - 1) {
      await Future.delayed(_durataPausa);
      if (!_inRiproduzione || !mounted) return;
      setState(() => _passoSuccessivo = i + 1);
      await _controller.forward(from: 0);
      if (!mounted) return;
      i++;
      setState(() {
        _passoAttuale = i;
        _passoSuccessivo = null;
      });
    }
    if (mounted) setState(() => _inRiproduzione = false);
  }

  void _stop() {
    _controller.stop();
    setState(() {
      _inRiproduzione = false;
      _passoSuccessivo = null;
    });
  }

  void _vaiAPasso(int indice) {
    _stop();
    setState(() => _passoAttuale = indice);
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final passi = widget.passi;
    final passoSuccessivo = _passoSuccessivo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (passi.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Passo precedente',
                onPressed: _inRiproduzione || _passoAttuale == 0
                    ? null
                    : () => _vaiAPasso(_passoAttuale - 1),
              ),
              IconButton(
                icon: Icon(_inRiproduzione ? Icons.stop : Icons.play_arrow),
                tooltip: _inRiproduzione
                    ? 'Ferma la riproduzione'
                    : 'Riproduci la sequenza',
                iconSize: 32,
                onPressed: _inRiproduzione
                    ? _stop
                    : (_passoAttuale == passi.length - 1 ? null : _play),
              ),
              Text(
                'Passo ${_passoAttuale + 1} di ${passi.length}',
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Passo successivo',
                onPressed: _inRiproduzione || _passoAttuale == passi.length - 1
                    ? null
                    : () => _vaiAPasso(_passoAttuale + 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < passi.length; i++)
                ChoiceChip(
                  label: Text('${i + 1}'),
                  selected: i == _passoAttuale,
                  onSelected: _inRiproduzione ? null : (_) => _vaiAPasso(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
        AspectRatio(
          aspectRatio: widget.campo == CampoLavagna.intero ? 3 / 4 : 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final larghezza = constraints.maxWidth;
                final altezza = constraints.maxHeight;

                if (passoSuccessivo == null) {
                  final passo = passi[_passoAttuale];
                  return Container(
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
                              frecce: passo.frecce,
                            ),
                          ),
                        ),
                        for (var i = 0; i < passo.giocatori.length; i++)
                          _TokenGiocatore(
                            giocatore: passo.giocatori[i],
                            numero: _numeroPerColore(passo.giocatori, i),
                            larghezza: larghezza,
                            altezza: altezza,
                            attivo: false,
                            onSposta: (_) {},
                            onRimuovi: () {},
                          ),
                      ],
                    ),
                  );
                }

                // In movimento verso il passo successivo: nessuna
                // freccia visibile (si rivedono ferme sul passo
                // d'arrivo), solo i giocatori che scivolano da una
                // posizione all'altra.
                final tokenAnimati = _abbinaGiocatori(
                  passi[_passoAttuale].giocatori,
                  passi[passoSuccessivo].giocatori,
                );
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Container(
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
                                frecce: const [],
                              ),
                            ),
                          ),
                          for (final token in tokenAnimati)
                            _TokenAnimato(
                              token: token,
                              t: _controller.value,
                              larghezza: larghezza,
                              altezza: altezza,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
