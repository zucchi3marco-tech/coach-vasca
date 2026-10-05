import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';

enum _ModalitaLavagna { giocatori, frecce }

const _spiegazioneLavagna =
    'Modalità "Giocatori": tocca il campo vuoto per piazzare un pallino, '
    'doppio tocco per rimuoverlo. Per spostarne uno: trascinalo, oppure '
    'toccalo (si evidenzia) e poi tocca il punto di arrivo. Modalità '
    '"Frecce": trascina per disegnare una freccia di movimento.\n\n'
    'Scegli il colore prima di disegnare: al massimo 7 pallini per '
    'colore (i giocatori in acqua), numerati in ordine di piazzamento. '
    'Il giallo è riservato alla palla: una sola, più piccola e senza '
    'numero. Tocca la palla e poi il giocatore che la riceve per '
    'agganciargliela: lo seguirà finché non la riassegni a un altro. '
    'Quando non è agganciata si sposta come un giocatore qualunque.\n\n'
    'Il lucchetto blocca lo scorrimento della pagina mentre disegni una '
    'freccia (utile se trascinando ti si sposta lo schermo).';

const _spiegazionePlayer =
    'Uno schema può avere più passi: ogni passo è una disposizione a sé '
    '(es. passo 1 le posizioni di partenza, passo 2 le frecce di '
    'movimento, passo 3 le posizioni finali). Tocca un numero per '
    'saltare a quel passo, oppure premi play per vedere i giocatori '
    'muoversi in sequenza da un passo all\'altro.';

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
  const GiocatoreLavagna({
    required this.posizione,
    required this.colore,
    this.portatore,
  });

  final Offset posizione;
  final ColoreLavagna colore;

  /// Solo per la palla (colore giallo): il giocatore che la porta,
  /// identificato con la stessa chiave (colore, numero-nel-colore) usata
  /// da [_abbinaGiocatori] — più stabile di un indice di lista, che
  /// cambia se un giocatore viene rimosso. `null` = palla libera, non
  /// agganciata a nessuno.
  final (ColoreLavagna, int)? portatore;

  GiocatoreLavagna spostato(Offset nuovaPosizione) => GiocatoreLavagna(
    posizione: nuovaPosizione,
    colore: colore,
    portatore: portatore,
  );

  GiocatoreLavagna conPortatore((ColoreLavagna, int)? nuovoPortatore) =>
      GiocatoreLavagna(
        posizione: posizione,
        colore: colore,
        portatore: nuovoPortatore,
      );
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
    this.passoFantasma,
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

  /// Passo precedente, mostrato in trasparenza dietro al disegno reale
  /// (non interattivo) come riferimento — utile passando a un nuovo
  /// passo, per non ritrovarsi la lavagna vuota e dover ricordare a
  /// memoria da dove si era partiti.
  final PassoLavagna? passoFantasma;

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

  /// Uno stato precedente per ogni azione che modifica il disegno
  /// (piazzare/spostare/rimuovere un giocatore, disegnare una freccia,
  /// cancellare tutto): "Annulla" ripristina l'ultimo. Si svuota quando
  /// cambia il campo, perché le posizioni salvate lì non varrebbero più.
  final List<PassoLavagna> _cronologia = [];

  Offset? _freccitaInizio;
  Offset? _freccitaAnteprima;

  /// Il giocatore (o la palla) toccato in attesa di un secondo tocco: su
  /// un punto libero del campo lo sposta lì, su un altro giocatore — solo
  /// se il selezionato è la palla — gliela assegna come portatore.
  /// Identificato per chiave (colore, numero), non per indice di lista:
  /// più stabile se nel frattempo un altro giocatore viene rimosso.
  (ColoreLavagna, int)? _selezionato;

  (ColoreLavagna, int) _chiave(int indice) =>
      (_giocatori[indice].colore, _numeroPerColore(_giocatori, indice));

  int? _indiceDaChiave((ColoreLavagna, int)? chiave) {
    if (chiave == null) return null;
    for (var i = 0; i < _giocatori.length; i++) {
      if (_chiave(i) == chiave) return i;
    }
    return null;
  }

  /// Sposta il giocatore/palla all'indice [i] in [nuova]: se è lui stesso
  /// a portare la palla, la trascina con sé; se è la palla a essere
  /// spostata direttamente, si stacca dal portatore (altrimenti al primo
  /// spostamento del portatore tornerebbe a seguirlo, annullando il
  /// riposizionamento manuale appena fatto).
  void _muoviGiocatore(int i, Offset nuova) {
    final chiave = _chiave(i);
    final giocatore = _giocatori[i];
    _giocatori[i] = giocatore.colore == ColoreLavagna.giallo
        ? giocatore.spostato(nuova).conPortatore(null)
        : giocatore.spostato(nuova);
    for (var j = 0; j < _giocatori.length; j++) {
      if (j != i && _giocatori[j].portatore == chiave) {
        _giocatori[j] = _giocatori[j].spostato(nuova);
      }
    }
  }

  void _onTapGiocatore(int i) {
    final chiave = _chiave(i);
    if (_selezionato == null || _selezionato == chiave) {
      // Primo tocco (lo seleziona) o tocco di nuovo sullo stesso
      // giocatore (lo deseleziona).
      setState(() => _selezionato = _selezionato == chiave ? null : chiave);
      return;
    }
    final indiceSelezionato = _indiceDaChiave(_selezionato);
    if (indiceSelezionato != null &&
        _giocatori[indiceSelezionato].colore == ColoreLavagna.giallo) {
      // La palla era selezionata: questo secondo tocco su un giocatore
      // gliela assegna come portatore.
      _registraCronologia();
      setState(() {
        _giocatori[indiceSelezionato] = _giocatori[indiceSelezionato]
            .conPortatore(chiave);
        _selezionato = null;
      });
      _notifica();
    } else {
      // Un giocatore qualunque (non la palla) era selezionato: il tocco
      // su un altro giocatore sposta semplicemente la selezione.
      setState(() => _selezionato = chiave);
    }
  }

  /// Tocco sul campo libero mentre un giocatore/la palla è selezionato:
  /// lo sposta lì invece di piazzarne uno nuovo.
  void _muoviSelezionatoIn(Offset punto) {
    final indice = _indiceDaChiave(_selezionato);
    if (indice == null) {
      setState(() => _selezionato = null);
      return;
    }
    _registraCronologia();
    setState(() {
      _muoviGiocatore(indice, punto);
      _selezionato = null;
    });
    _notifica();
  }

  /// Le frecce disegnate per il passo corrente sono annotazioni libere,
  /// senza un legame esplicito con un giocatore. Una volta che il
  /// giocatore è stato davvero trascinato fino al punto indicato dalla
  /// freccia (stessa soglia di distanza usata per riconoscere un
  /// trascinamento valido, vedi sopra), la freccia ha fatto il suo
  /// lavoro e sparisce: è un'euristica di prossimità, non un vincolo
  /// esatto.
  List<FrecciaLavagna> get _frecceVisibili => _frecce.where((freccia) {
    return !_giocatori.any(
      (g) =>
          g.colore == freccia.colore &&
          (g.posizione - freccia.fine).distance <= 0.02,
    );
  }).toList();

  void _notifica() =>
      widget.onCambiato?.call(List.of(_giocatori), List.of(_frecce));

  void _registraCronologia() => _cronologia.add((
    giocatori: List.of(_giocatori),
    frecce: List.of(_frecce),
  ));

  void _annulla() {
    if (_cronologia.isEmpty) return;
    final precedente = _cronologia.removeLast();
    setState(() {
      _giocatori
        ..clear()
        ..addAll(precedente.giocatori);
      _frecce
        ..clear()
        ..addAll(precedente.frecce);
      _selezionato = null;
    });
    _notifica();
  }

  void _cancellaTutto() {
    _registraCronologia();
    setState(() {
      _giocatori.clear();
      _frecce.clear();
      _selezionato = null;
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
        // Le posizioni salvate nella cronologia erano per il campo
        // precedente: non avrebbero più senso qui.
        _cronologia.clear();
        _selezionato = null;
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
          LayoutBuilder(
            builder: (context, vincoli) {
              final modalita = SegmentedButton<_ModalitaLavagna>(
                // Senza spunta: la scelta e' gia' evidenziata dal
                // colore, e la spunta toglieva spazio all'etichetta
                // che su telefono andava a capo a meta' parola.
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(
                    value: _ModalitaLavagna.giocatori,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Giocatori', maxLines: 1),
                    ),
                    icon: Icon(Icons.circle_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _ModalitaLavagna.frecce,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Frecce', maxLines: 1),
                    ),
                    icon: Icon(Icons.north_east, size: 18),
                  ),
                ],
                selected: {_modalita},
                onSelectionChanged: (s) => setState(() {
                  _modalita = s.first;
                  _selezionato = null;
                }),
              );
              final strumenti = <Widget>[
                const PulsanteSpiegazione(
                  titolo: 'Lavagna tattica',
                  spiegazione: _spiegazioneLavagna,
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Annulla l\'ultima modifica',
                  onPressed: _cronologia.isEmpty ? null : _annulla,
                ),
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
              ];
              // Sotto ~400 px quattro pulsanti da 48 lasciano al selettore
              // meno di 70 px per segmento: gli strumenti scendono sotto.
              if (vincoli.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    modalita,
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: strumenti,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: modalita),
                  const SizedBox(width: AppSpacing.s8),
                  ...strumenti,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.s8),
          SegmentedButton<CampoLavagna>(
            // Senza spunta: la scelta e' gia' evidenziata dal
            // colore, e la spunta toglieva spazio all'etichetta
            // che su telefono andava a capo a meta' parola.
            showSelectedIcon: false,
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
                          // Un tocco sul campo vuoto mentre un giocatore
                          // (o la palla) e' selezionato lo sposta li',
                          // invece di piazzarne uno nuovo.
                          if (_selezionato != null) {
                            _muoviSelezionatoIn(relativa(d.localPosition));
                            return;
                          }
                          // Il giallo e' riservato alla palla: al
                          // massimo una (non conta per il tetto dei 7
                          // dei giocatori di movimento, che ha un tetto
                          // a parte).
                          final giaPresenti = _giocatori
                              .where((g) => g.colore == _coloreSelezionato)
                              .length;
                          final tetto =
                              _coloreSelezionato == ColoreLavagna.giallo
                              ? 1
                              : WaterPoloTacticsBoard.massimoGiocatoriPerColore;
                          if (giaPresenti >= tetto) {
                            if (_coloreSelezionato == ColoreLavagna.giallo) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Puoi avere una sola palla: tocca '
                                    'quella già piazzata per riassegnarla '
                                    'a un altro giocatore.',
                                  ),
                                ),
                              );
                              return;
                            }
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
                          _registraCronologia();
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
                          final inizio = _freccitaInizio;
                          final fine = _freccitaAnteprima;
                          final daAggiungere =
                              inizio != null &&
                              fine != null &&
                              (inizio - fine).distance > 0.02;
                          if (daAggiungere) _registraCronologia();
                          setState(() {
                            if (daAggiungere) {
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
                              frecce: _frecceVisibili,
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
                        if (widget.passoFantasma != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.3,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _CampoCompletoPainter(
                                          colori: colori,
                                          campo: widget.campo,
                                          // Il fantasma mostra solo i
                                          // giocatori: le frecce sono
                                          // del passo in cui sono state
                                          // disegnate, non devono
                                          // restare visibili dopo.
                                          frecce: const [],
                                          disegnaCampo: false,
                                        ),
                                      ),
                                    ),
                                    for (
                                      var i = 0;
                                      i <
                                          widget
                                              .passoFantasma!
                                              .giocatori
                                              .length;
                                      i++
                                    )
                                      // La palla non si mostra nel
                                      // fantasma: senza numero, una
                                      // seconda in trasparenza vicino a
                                      // quella vera sembra un secondo
                                      // pallone invece di un riferimento
                                      // al passo precedente.
                                      if (widget
                                              .passoFantasma!
                                              .giocatori[i]
                                              .colore !=
                                          ColoreLavagna.giallo)
                                        _TokenGiocatore(
                                          giocatore: widget
                                              .passoFantasma!
                                              .giocatori[i],
                                          numero: _numeroPerColore(
                                            widget.passoFantasma!.giocatori,
                                            i,
                                          ),
                                          larghezza: larghezza,
                                          altezza: altezza,
                                          attivo: false,
                                          onSposta: (_) {},
                                          onRimuovi: () {},
                                        ),
                                  ],
                                ),
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
                            evidenziato: _chiave(i) == _selezionato,
                            onTap: () => _onTapGiocatore(i),
                            onInizioTrascinamento: () {
                              _registraCronologia();
                              _selezionato = null;
                            },
                            onSposta: (nuova) {
                              setState(() => _muoviGiocatore(i, nuova));
                              _notifica();
                            },
                            onRimuovi: () {
                              _registraCronologia();
                              final chiave = _chiave(i);
                              setState(() {
                                _giocatori.removeAt(i);
                                // Un giocatore rimosso non puo' restare
                                // il portatore della palla: resta dov'e',
                                // non agganciata a nessuno.
                                for (var j = 0; j < _giocatori.length; j++) {
                                  if (_giocatori[j].portatore == chiave) {
                                    _giocatori[j] = _giocatori[j].conPortatore(
                                      null,
                                    );
                                  }
                                }
                                if (_selezionato == chiave) {
                                  _selezionato = null;
                                }
                              });
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
    this.onInizioTrascinamento,
    this.onTap,
    this.evidenziato = false,
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

  /// Chiamato una sola volta all'inizio del trascinamento (non a ogni
  /// pixel di movimento, a differenza di [onSposta]): usato per
  /// registrare la posizione di partenza nella cronologia di "Annulla".
  final VoidCallback? onInizioTrascinamento;

  /// Tocco semplice (non trascinamento): usato per armare la palla o,
  /// con la palla già armata, per assegnarla a questo giocatore.
  final VoidCallback? onTap;

  /// true sulla palla mentre è "armata" (in attesa del giocatore che la
  /// riceve): un bordo evidenziato segnala lo stato in attesa.
  final bool evidenziato;

  static const _diametro = 32.0;

  /// La palla (giallo) e' meta' del diametro degli altri pallini —
  /// non e' un giocatore, deve distinguersi a colpo d'occhio anche
  /// dalla sola dimensione, non solo dall'assenza del numero.
  double get _diametroEffettivo =>
      giocatore.colore == ColoreLavagna.giallo ? _diametro / 2 : _diametro;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final posizione = giocatore.posizione;
    final diametro = _diametroEffettivo;
    return Positioned(
      left: posizione.dx * larghezza - diametro / 2,
      top: posizione.dy * altezza - diametro / 2,
      child: IgnorePointer(
        ignoring: !attivo,
        child: GestureDetector(
          onTap: onTap,
          onPanStart: (_) => onInizioTrascinamento?.call(),
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
            width: diametro,
            height: diametro,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: giocatore.colore.colore,
              shape: BoxShape.circle,
              border: Border.all(
                color: evidenziato ? colori.azione : colori.superficie,
                width: evidenziato ? 3 : 2,
              ),
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
    this.disegnaCampo = true,
  });

  final ColoriApp colori;
  final CampoLavagna campo;
  final List<FrecciaLavagna> frecce;
  final FrecciaLavagna? anteprimaFreccia;

  /// `false` per disegnare solo le frecce, senza le linee del campo —
  /// usato per il fantasma del passo precedente (le linee del campo
  /// sono già disegnate dal livello reale sotto, ridisegnarle due volte
  /// non serve).
  final bool disegnaCampo;

  @override
  void paint(Canvas canvas, Size size) {
    final larghezzaPorta = size.width * 0.24;
    final altezzaPorta = size.height * 0.05;
    final centroX = size.width / 2;

    if (disegnaCampo) {
      // `colori.testo` (non `colori.linea`, pensato per bordi discreti
      // fra superfici): il disegno del campo deve restare ben
      // leggibile sopra `azioneTenue` in entrambi i temi, non essere
      // un dettaglio sfumato.
      final trattoCampo = Paint()
        ..color = colori.testo
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        trattoCampo,
      );

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

      // Righe di regolamento 2m/6m (come in "eventi live partita",
      // CampoTiro — 5m volutamente omessa), verso il centro campo a
      // partire da ogni porta disegnata.
      final centroY = size.height / 2;
      _disegnaLineeRegolamento(
        canvas,
        size,
        yBaseGoal: altezzaPorta,
        yLimite: campo == CampoLavagna.intero ? centroY : size.height,
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
        _disegnaLineeRegolamento(
          canvas,
          size,
          yBaseGoal: size.height - altezzaPorta,
          yLimite: centroY,
        );
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

  /// Righe dei 2m e 6m dalla porta verso [yLimite] (il centro campo, o
  /// il fondo/inizio opposto per il campo a metà) — stesse proporzioni
  /// e colori di `CampoTiro` (`colori.rosso`/`colori.attenzione`), 5m
  /// volutamente omessa qui.
  void _disegnaLineeRegolamento(
    Canvas canvas,
    Size size, {
    required double yBaseGoal,
    required double yLimite,
  }) {
    final profondita = yLimite - yBaseGoal;
    final tratto2m = Paint()
      ..color = colori.rosso
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final tratto6m = Paint()
      ..color = colori.attenzione
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, yBaseGoal + profondita * (1.0 / 8.0)),
      Offset(size.width, yBaseGoal + profondita * (1.0 / 8.0)),
      tratto2m,
    );
    canvas.drawLine(
      Offset(0, yBaseGoal + profondita * (4.4 / 8.0)),
      Offset(size.width, yBaseGoal + profondita * (4.4 / 8.0)),
      tratto6m,
    );
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

  /// Stessa regola di [_TokenGiocatore._diametroEffettivo]: la palla
  /// (giallo) e' meta' del diametro degli altri pallini.
  double get _diametroEffettivo =>
      token.colore == ColoreLavagna.giallo ? _diametro / 2 : _diametro;

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
    final diametro = _diametroEffettivo;
    return Positioned(
      left: posizione.dx * larghezza - diametro / 2,
      top: posizione.dy * altezza - diametro / 2,
      child: Opacity(
        opacity: opacita,
        child: Container(
          width: diametro,
          height: diametro,
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
  static const _durataBase = Duration(milliseconds: 900);
  static const _velocitaDisponibili = [0.5, 1.0, 1.5, 2.0];

  double _velocita = 1.0;

  Duration get _durataMovimento =>
      Duration(milliseconds: (_durataBase.inMilliseconds / _velocita).round());
  Duration get _durataPausa => _durataMovimento;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durataMovimento,
  );

  int _passoAttuale = 0;
  int? _passoSuccessivo;
  bool _inRiproduzione = false;

  /// Impostato solo quando la riproduzione arriva da sola in fondo alla
  /// sequenza (non con Stop manuale né saltando a un passo): a quel
  /// punto si vogliono rivedere tutte le frecce dello schema insieme,
  /// non solo quelle dell'ultimo passo.
  bool _mostraTutteLeFrecce = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_inRiproduzione || widget.passi.length < 2) return;
    setState(() {
      _inRiproduzione = true;
      _mostraTutteLeFrecce = false;
    });
    var i = _passoAttuale;
    while (_inRiproduzione && i < widget.passi.length - 1) {
      await Future.delayed(_durataPausa);
      if (!_inRiproduzione || !mounted) return;
      setState(() => _passoSuccessivo = i + 1);
      _controller.duration = _durataMovimento;
      await _controller.forward(from: 0);
      if (!mounted) return;
      i++;
      setState(() {
        _passoAttuale = i;
        _passoSuccessivo = null;
      });
    }
    if (mounted) {
      setState(() {
        _inRiproduzione = false;
        _mostraTutteLeFrecce = true;
      });
    }
  }

  void _stop() {
    _controller.stop();
    setState(() {
      _inRiproduzione = false;
      _passoSuccessivo = null;
      _mostraTutteLeFrecce = false;
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
              const PulsanteSpiegazione(
                titolo: 'Sequenza a passi',
                spiegazione: _spiegazionePlayer,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < passi.length; i++)
                TonalChip(
                  etichetta: '${i + 1}',
                  selezionato: i == _passoAttuale,
                  onSelezionato: _inRiproduzione ? null : (_) => _vaiAPasso(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s8,
            children: [
              for (final v in _velocitaDisponibili)
                TonalChip(
                  etichetta: '${v}x'.replaceAll('.0x', 'x'),
                  selezionato: v == _velocita,
                  onSelezionato: _inRiproduzione
                      ? null
                      : (_) => setState(() => _velocita = v),
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
                  // A fine riproduzione (non su uno stop manuale o su un
                  // salto a un passo) si rivedono insieme le frecce di
                  // tutti i passi, non solo quelle dell'ultimo.
                  final mostraRiepilogoFrecce =
                      _mostraTutteLeFrecce && _passoAttuale == passi.length - 1;
                  final frecceDaMostrare = mostraRiepilogoFrecce
                      ? [for (final p in passi) ...p.frecce]
                      : passo.frecce;
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
                              frecce: frecceDaMostrare,
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
