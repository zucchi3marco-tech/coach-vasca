import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/palette_acqua.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/tonal_chip.dart';
import '../../home/atleta/grafica_pallanuoto.dart' show disegnaPalla;
import '../domain/schema_tattico.dart';
import 'geometria_frecce.dart';

enum _ModalitaLavagna { giocatori, frecce, zone, testo }

const _spiegazioneLavagna =
    'Modalità "Giocatori": scegli cosa mettere in acqua (calottina '
    'bianca, blu, portiere o palla) e tocca la vasca per piazzarlo; '
    'doppio tocco per toglierlo. Per spostarlo trascinalo, oppure '
    'toccalo (si evidenzia) e poi tocca il punto di arrivo. Al massimo 7 '
    'calottine per colore, numerate in ordine di piazzamento, e 2 '
    'portieri (uno solo a metà campo): una lavagna nuova parte con i '
    'portieri già in porta.\n\n'
    'La palla è una sola: toccala e poi tocca il giocatore che la riceve '
    'per agganciargliela, lo seguirà finché non la riassegni. Quando non '
    'è agganciata si sposta come un giocatore.\n\n'
    'Modalità "Frecce": scegli il tipo (nuotata, passaggio, con palla, '
    'tiro) e disegna la traiettoria col dito: la freccia la segue, dritta '
    'o curva. Tocca una freccia per sceglierla: trascina il pallino al '
    'centro per curvarla (doppio tocco per raddrizzarla) e quelli agli '
    'estremi per spostarla. Con una freccia scelta, tipo e colore valgono '
    'per lei e il cestino elimina solo lei.\n\n'
    'Modalità "Zone": trascina sull\'acqua per disegnare un rettangolo o '
    'un ovale colorato e trasparente (es. l\'area del pressing). Toccalo '
    'per sceglierlo: lo trascini per spostarlo, i pallini agli angoli ne '
    'cambiano la misura.\n\n'
    'Modalità "Testo": tocca l\'acqua e scrivi un\'etichetta (es. '
    '"Centroboa"). Toccala per sceglierla e trascinarla; toccala di nuovo '
    'per cambiarne il testo.\n\n'
    'Il lucchetto blocca lo scorrimento della pagina mentre disegni '
    '(utile se trascinando ti si sposta lo schermo).';

const _spiegazionePlayer =
    'Uno schema può avere più passi: ogni passo è una disposizione a sé '
    '(es. passo 1 le posizioni di partenza, passo 2 le frecce di '
    'movimento, passo 3 le posizioni finali). Tocca un numero per '
    'saltare a quel passo, oppure premi play per vedere i giocatori '
    'muoversi in sequenza da un passo all\'altro: giocatori e palla '
    'seguono le frecce disegnate, anche quelle curve.';

/// Numero (1-7) di un giocatore nel proprio colore: conta quanti
/// giocatori dello stesso colore lo precedono (se stesso incluso)
/// nell'ordine di piazzamento — condiviso fra la lavagna e
/// `SchemaTatticoPlayer`, così la numerazione resta identica ovunque.
int _numeroPerColore(List<GiocatoreLavagna> giocatori, int indice) => giocatori
    .take(indice + 1)
    .where((g) => g.colore == giocatori[indice].colore)
    .length;

/// Colore di un pezzo o di una freccia. Per i pezzi è la calottina
/// (bianca e blu come da regolamento, rossa del portiere) o la palla
/// (giallo); per le frecce è l'inchiostro scelto da chi disegna. Il nero
/// resta solo come inchiostro: in acqua non ci sono calottine nere.
enum ColoreLavagna {
  blu,
  bianco,
  nero,
  rosso,
  giallo;

  static final _grafite = Color.lerp(
    AcquaPalette.nero,
    AcquaPalette.bianco,
    0.18,
  )!;

  /// I pezzi che si possono mettere in acqua, nell'ordine dei pulsanti.
  static const pezzi = [bianco, blu, rosso, giallo];

  /// Gli inchiostri delle frecce: il nero per primo, il più leggibile
  /// sull'acqua chiara.
  static const inchiostri = [nero, bianco, giallo, rosso, blu];

  /// Inchiostro della freccia (e pallino del selettore).
  Color get colore => switch (this) {
    ColoreLavagna.blu => ColoreCalottina.blu.tessuto,
    ColoreLavagna.bianco => AcquaPalette.bianco,
    ColoreLavagna.nero => AcquaPalette.nero,
    ColoreLavagna.rosso => ColoreCalottina.rossa.tessuto,
    ColoreLavagna.giallo => AcquaPalette.palla,
  };

  /// Leggibile sopra [colore]: scuro sulle tinte chiare, chiaro sulle
  /// scure. Fa anche da alone attorno alle frecce, per staccarle
  /// dall'acqua.
  Color get controcolore => switch (this) {
    ColoreLavagna.bianco || ColoreLavagna.giallo => AcquaPalette.nero,
    ColoreLavagna.blu ||
    ColoreLavagna.nero ||
    ColoreLavagna.rosso => AcquaPalette.bianco,
  };

  /// Tessuto, numero e ombra della calottina.
  ({Color tessuto, Color numero, Color ombra}) get calottina => switch (this) {
    ColoreLavagna.bianco => _daCalottina(ColoreCalottina.bianca),
    ColoreLavagna.blu => _daCalottina(ColoreCalottina.blu),
    ColoreLavagna.rosso => _daCalottina(ColoreCalottina.rossa),
    ColoreLavagna.nero => (
      tessuto: _grafite,
      numero: AcquaPalette.bianco,
      ombra: AcquaPalette.nero,
    ),
    ColoreLavagna.giallo => (
      tessuto: AcquaPalette.palla,
      numero: AcquaPalette.nero,
      ombra: AcquaPalette.pallaRighe,
    ),
  };

  static ({Color tessuto, Color numero, Color ombra}) _daCalottina(
    ColoreCalottina c,
  ) => (tessuto: c.tessuto, numero: c.numero, ombra: c.ombra);

  bool get palla => this == ColoreLavagna.giallo;

  /// Quanti pezzi di questo colore possono stare in acqua.
  int get massimoInAcqua => switch (this) {
    ColoreLavagna.giallo => 1,
    ColoreLavagna.rosso => 2,
    _ => WaterPoloTacticsBoard.massimoGiocatoriPerColore,
  };

  /// Cosa c'è scritto sulla calottina: il numero, "P" per il portiere,
  /// niente sulla palla.
  String? etichetta(int numero) => switch (this) {
    ColoreLavagna.giallo => null,
    ColoreLavagna.rosso => 'P',
    _ => '$numero',
  };

  /// Nome dell'inchiostro.
  String get nome => switch (this) {
    ColoreLavagna.blu => 'Blu',
    ColoreLavagna.bianco => 'Bianco',
    ColoreLavagna.nero => 'Nero',
    ColoreLavagna.rosso => 'Rosso',
    ColoreLavagna.giallo => 'Giallo',
  };

  /// Nome del pezzo, sul pulsante della modalità "Giocatori".
  String get nomePezzo => switch (this) {
    ColoreLavagna.bianco => 'Bianchi',
    ColoreLavagna.blu => 'Blu',
    ColoreLavagna.rosso => 'Portiere',
    ColoreLavagna.giallo => 'Palla',
    ColoreLavagna.nero => 'Neri',
  };

  /// Descrizione per chi usa un lettore di schermo.
  String descrizionePezzo(int numero) => switch (this) {
    ColoreLavagna.giallo => 'Palla',
    ColoreLavagna.rosso => 'Portiere $numero',
    ColoreLavagna.bianco => 'Calottina bianca $numero',
    ColoreLavagna.blu => 'Calottina blu $numero',
    ColoreLavagna.nero => 'Calottina nera $numero',
  };
}

/// Il tipo di freccia, come nei disegni tattici di pallanuoto: si
/// distingue dal tratto, non dal colore (che resta libero).
enum TipoFreccia {
  /// Linea piena: spostamento senza palla.
  nuotata('Nuotata'),

  /// Tratteggiata: la palla passa da un giocatore all'altro.
  passaggio('Passaggio'),

  /// Ondulata: nuotata con la palla.
  conPalla('Con palla'),

  /// Doppia: tiro in porta.
  tiro('Tiro');

  const TipoFreccia(this.nome);
  final String nome;

  /// Le frecce salvate prima dei tipi sono tutte di nuotata.
  static TipoFreccia daNome(String? nome) => TipoFreccia.values.firstWhere(
    (t) => t.name == nome,
    orElse: () => TipoFreccia.nuotata,
  );

  /// Passaggio e tiro muovono la palla, non un giocatore.
  bool get muoveLaPalla =>
      this == TipoFreccia.passaggio || this == TipoFreccia.tiro;
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

  /// Larghezza su altezza della vasca disegnata: 20 m di larghezza, 25 m
  /// fra le porte più un metro dietro ciascuna (il campo intero), oppure
  /// 12,5 m più quello dietro la porta (metà campo).
  double get proporzioni => 20 / metriInAltezza;

  /// Metri d'acqua disegnati dalla testata in alto al bordo in basso.
  double get metriInAltezza => switch (this) {
    CampoLavagna.intero => lunghezzaCampo + 2 * metriDietroPorta,
    CampoLavagna.meta => lunghezzaCampo / 2 + metriDietroPorta,
  };

  /// Distanza fra le due linee di porta: il campo da 25 x 20 m delle
  /// vasche in cui si gioca di più (giovanili e femminile).
  static const lunghezzaCampo = 25.0;

  /// Acqua disegnata dietro ogni linea di porta, dove sta la rete.
  static const metriDietroPorta = 1.0;
}

/// I portieri in porta, al centro e mezzo metro davanti alla linea: uno
/// per porta sul campo intero, uno solo a metà campo. Una lavagna nuova
/// parte da qui (richiesta del coach 2026-10-08: "per non sbagliare").
List<GiocatoreLavagna> portieriInPorta(CampoLavagna campo) {
  final y = (CampoLavagna.metriDietroPorta + 0.5) / campo.metriInAltezza;
  return [
    GiocatoreLavagna(posizione: Offset(0.5, y), colore: ColoreLavagna.rosso),
    if (campo == CampoLavagna.intero)
      GiocatoreLavagna(
        posizione: Offset(0.5, 1 - y),
        colore: ColoreLavagna.rosso,
      ),
  ];
}

/// Un giocatore piazzato sulla lavagna: posizione frazionaria (0-1 su
/// entrambi gli assi, così resta corretta a qualunque dimensione della
/// card) e colore della calottina.
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

/// Una freccia disegnata sulla lavagna: inizio/fine frazionari, colore
/// del tratto, tipo e, se è curva, il punto di controllo della curva
/// (vedi `geometria_frecce.dart`).
class FrecciaLavagna {
  const FrecciaLavagna({
    required this.inizio,
    required this.fine,
    required this.colore,
    this.tipo = TipoFreccia.nuotata,
    this.controllo,
  });

  final Offset inizio;
  final Offset fine;
  final ColoreLavagna colore;
  final TipoFreccia tipo;

  /// In frazioni del campo, può cadere anche fuori dal campo (una curva
  /// ampia vicino al bordo). `null` = freccia dritta.
  final Offset? controllo;

  Offset get puntoMedio => puntoSuCurva(inizio, controllo, fine, 0.5);

  FrecciaLavagna copiaCon({
    Offset? inizio,
    Offset? fine,
    ColoreLavagna? colore,
    TipoFreccia? tipo,
    Offset? controllo,
    bool dritta = false,
  }) => FrecciaLavagna(
    inizio: inizio ?? this.inizio,
    fine: fine ?? this.fine,
    colore: colore ?? this.colore,
    tipo: tipo ?? this.tipo,
    controllo: dritta ? null : (controllo ?? this.controllo),
  );
}

/// Forma di una zona colorata.
enum FormaZona {
  rettangolo('Rettangolo'),
  ovale('Ovale');

  const FormaZona(this.nome);
  final String nome;

  static FormaZona daNome(String? nome) => FormaZona.values.firstWhere(
    (f) => f.name == nome,
    orElse: () => FormaZona.rettangolo,
  );
}

/// Una zona colorata e trasparente sul campo (es. l'area del pressing):
/// [da] e [a] sono due angoli opposti, in frazioni del campo.
class ZonaLavagna {
  const ZonaLavagna({
    required this.da,
    required this.a,
    required this.colore,
    this.forma = FormaZona.rettangolo,
  });

  final Offset da;
  final Offset a;
  final ColoreLavagna colore;
  final FormaZona forma;

  /// Il rettangolo che la contiene, in pixel di un campo grande [size].
  Rect inPixel(Size size) => Rect.fromPoints(
    Offset(da.dx * size.width, da.dy * size.height),
    Offset(a.dx * size.width, a.dy * size.height),
  );

  /// Se [punto] (in pixel) cade dentro la zona.
  bool contiene(Offset punto, Size size) {
    final r = inPixel(size);
    if (forma == FormaZona.rettangolo) return r.contains(punto);
    if (r.width == 0 || r.height == 0) return false;
    final dx = (punto.dx - r.center.dx) / (r.width / 2);
    final dy = (punto.dy - r.center.dy) / (r.height / 2);
    return dx * dx + dy * dy <= 1;
  }

  ZonaLavagna copiaCon({
    Offset? da,
    Offset? a,
    ColoreLavagna? colore,
    FormaZona? forma,
  }) => ZonaLavagna(
    da: da ?? this.da,
    a: a ?? this.a,
    colore: colore ?? this.colore,
    forma: forma ?? this.forma,
  );
}

/// Una scritta sul campo, centrata in [punto] (frazioni del campo), su
/// un'etichetta del colore scelto.
class TestoLavagna {
  const TestoLavagna({
    required this.punto,
    required this.testo,
    required this.colore,
  });

  final Offset punto;
  final String testo;
  final ColoreLavagna colore;

  TestoLavagna copiaCon({
    Offset? punto,
    String? testo,
    ColoreLavagna? colore,
  }) => TestoLavagna(
    punto: punto ?? this.punto,
    testo: testo ?? this.testo,
    colore: colore ?? this.colore,
  );
}

/// Un passo della sequenza (vedi `SchemaTatticoPlayer`): stessa forma
/// di `PassoSchema` a livello di dominio, ma con i tipi Flutter usati
/// da questo widget.
typedef PassoLavagna = ({
  List<GiocatoreLavagna> giocatori,
  List<FrecciaLavagna> frecce,
  List<ZonaLavagna> zone,
  List<TestoLavagna> testi,
});

/// Da un passo salvato a quello disegnato dalla lavagna.
PassoLavagna passoLavagnaDaSchema(PassoSchema p) => (
  giocatori: [
    for (final g in p.giocatori)
      GiocatoreLavagna(
        posizione: Offset(g.punto.$1, g.punto.$2),
        colore: ColoreLavagna.values.byName(g.colore),
        portatore: switch (g.portatore) {
          (final colore, final numero) => (
            ColoreLavagna.values.byName(colore),
            numero,
          ),
          null => null,
        },
      ),
  ],
  frecce: [
    for (final f in p.frecce)
      FrecciaLavagna(
        inizio: Offset(f.inizio.$1, f.inizio.$2),
        fine: Offset(f.fine.$1, f.fine.$2),
        colore: ColoreLavagna.values.byName(f.colore),
        tipo: TipoFreccia.daNome(f.tipo),
        controllo: switch (f.controllo) {
          (final x, final y) => Offset(x, y),
          null => null,
        },
      ),
  ],
  zone: [
    for (final z in p.zone)
      ZonaLavagna(
        da: Offset(z.da.$1, z.da.$2),
        a: Offset(z.a.$1, z.a.$2),
        colore: ColoreLavagna.values.byName(z.colore),
        forma: FormaZona.daNome(z.forma),
      ),
  ],
  testi: [
    for (final t in p.testi)
      TestoLavagna(
        punto: Offset(t.punto.$1, t.punto.$2),
        testo: t.testo,
        colore: ColoreLavagna.values.byName(t.colore),
      ),
  ],
);

/// L'inverso di [passoLavagnaDaSchema], per salvare.
PassoSchema passoSchemaDaLavagna(PassoLavagna p) => (
  giocatori: [
    for (final g in p.giocatori)
      (
        punto: (g.posizione.dx, g.posizione.dy),
        colore: g.colore.name,
        portatore: switch (g.portatore) {
          (final colore, final numero) => (colore.name, numero),
          null => null,
        },
      ),
  ],
  frecce: [
    for (final f in p.frecce)
      (
        inizio: (f.inizio.dx, f.inizio.dy),
        fine: (f.fine.dx, f.fine.dy),
        colore: f.colore.name,
        tipo: f.tipo.name,
        controllo: switch (f.controllo) {
          final c? => (c.dx, c.dy),
          null => null,
        },
      ),
  ],
  zone: [
    for (final z in p.zone)
      (
        da: (z.da.dx, z.da.dy),
        a: (z.a.dx, z.a.dy),
        colore: z.colore.name,
        forma: z.forma.name,
      ),
  ],
  testi: [
    for (final t in p.testi)
      (punto: (t.punto.dx, t.punto.dy), testo: t.testo, colore: t.colore.name),
  ],
);

/// La freccia che descrive lo spostamento da [da] ad [a]: parte vicino a
/// [da] e arriva vicino ad [a] (entro [tolleranza], in frazioni del
/// campo). Fra più candidate la più aderente; `null` se nessuna.
FrecciaLavagna? frecciaPerSpostamento(
  List<FrecciaLavagna> frecce,
  Offset da,
  Offset a, {
  double tolleranza = 0.06,
}) {
  FrecciaLavagna? migliore;
  var costoMigliore = double.infinity;
  for (final f in frecce) {
    final scartoInizio = (f.inizio - da).distance;
    final scartoFine = (f.fine - a).distance;
    if (scartoInizio > tolleranza || scartoFine > tolleranza) continue;
    if (scartoInizio + scartoFine < costoMigliore) {
      migliore = f;
      costoMigliore = scartoInizio + scartoFine;
    }
  }
  return migliore;
}

/// Il punto di controllo per far seguire a chi va da [da] ad [a] la curva
/// di [freccia]: stessa piega, spostata quanto basta perché parta e
/// arrivi esattamente lì. `null` se la freccia è dritta.
Offset? controlloPerSpostamento(FrecciaLavagna freccia, Offset da, Offset a) {
  final controllo = freccia.controllo;
  if (controllo == null) return null;
  return controllo + ((da - freccia.inizio) + (a - freccia.fine)) / 2;
}

/// Lavagna tattica per pallanuoto: una vasca vista dall'alto, con i segni
/// di regolamento ai bordi, e due modalità:
/// - **Giocatori**: tocca per piazzare una calottina numerata (bianca,
///   blu, del portiere) o la palla, trascinala per spostarla, doppio
///   tocco per rimuoverla;
/// - **Frecce**: disegna col dito una freccia del tipo scelto (nuotata,
///   passaggio, con palla, tiro). Il tratto disegnato diventa una curva
///   regolare (o una retta, se il dito è andato quasi dritto); toccata
///   una freccia, la si piega e la si sposta con le maniglie.
///
/// Su campo intero o solo metà campo ([CampoLavagna]) a scelta: la vasca
/// si ridimensiona per stare tutta nello schermo.
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
    this.zoneIniziali = const [],
    this.testiIniziali = const [],
    this.passoFantasma,
    this.campo = CampoLavagna.intero,
    this.modificabile = true,
    this.bloccata = false,
    this.onCambiato,
    this.onCampoCambiato,
    this.onBloccataCambiato,
    this.sostitutoVasca,
    super.key,
  });

  /// In acqua ci sono al più 7 giocatori di movimento per squadra: oltre
  /// questo numero, per colore, un tocco per aggiungerne un altro non
  /// fa nulla (con un avviso).
  static const massimoGiocatoriPerColore = 7;

  final List<GiocatoreLavagna> giocatoriIniziali;
  final List<FrecciaLavagna> frecceIniziali;
  final List<ZonaLavagna> zoneIniziali;
  final List<TestoLavagna> testiIniziali;

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

  /// Il passo com'è dopo ogni modifica.
  final ValueChanged<PassoLavagna>? onCambiato;
  final ValueChanged<CampoLavagna>? onCampoCambiato;
  final ValueChanged<bool>? onBloccataCambiato;

  /// Mostrato al posto della vasca (es. l'animazione dello schema, fatta
  /// partire dalla striscia dei passi): gli strumenti restano al loro
  /// posto ma spenti, così la pagina non salta.
  final Widget? sostitutoVasca;

  @override
  State<WaterPoloTacticsBoard> createState() => _WaterPoloTacticsBoardState();
}

class _WaterPoloTacticsBoardState extends State<WaterPoloTacticsBoard> {
  _ModalitaLavagna _modalita = _ModalitaLavagna.giocatori;
  ColoreLavagna _pezzo = ColoreLavagna.bianco;
  ColoreLavagna _inchiostro = ColoreLavagna.nero;
  TipoFreccia _tipo = TipoFreccia.nuotata;

  late final List<GiocatoreLavagna> _giocatori = List.of(
    widget.giocatoriIniziali,
  );
  late final List<FrecciaLavagna> _frecce = List.of(widget.frecceIniziali);
  late final List<ZonaLavagna> _zone = List.of(widget.zoneIniziali);
  late final List<TestoLavagna> _testi = List.of(widget.testiIniziali);

  FormaZona _formaZona = FormaZona.rettangolo;
  ColoreLavagna _coloreZona = ColoreLavagna.giallo;
  ColoreLavagna _coloreTesto = ColoreLavagna.bianco;

  /// Angoli (in pixel) della zona che il dito sta disegnando.
  Offset? _inizioZona;
  Offset? _fineZona;

  /// Indici in [_zone] e [_testi] dell'elemento scelto in quella
  /// modalità: lo si sposta, lo si ridimensiona, il cestino elimina lui.
  int? _zonaSelezionata;
  int? _testoSelezionato;

  /// Uno stato precedente per ogni azione che modifica il disegno
  /// (piazzare/spostare/rimuovere un giocatore, disegnare o modificare
  /// una freccia, cancellare tutto): "Annulla" ripristina l'ultimo. Si
  /// svuota quando cambia il campo, perché le posizioni salvate lì non
  /// varrebbero più.
  final List<PassoLavagna> _cronologia = [];

  /// Gli stati tolti da "Annulla", per "Ripeti". Si svuota alla prima
  /// modifica nuova: da lì la storia prende un'altra strada.
  final List<PassoLavagna> _annullati = [];

  /// Il tratto che il dito sta disegnando, in pixel.
  List<Offset>? _traccia;

  /// Indice in [_frecce] della freccia toccata: mostra le maniglie per
  /// piegarla e spostarla, e tipo/colore scelti valgono per lei.
  int? _frecciaSelezionata;

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

  FrecciaLavagna? get _freccia {
    final i = _frecciaSelezionata;
    return i == null || i >= _frecce.length ? null : _frecce[i];
  }

  ZonaLavagna? get _zona {
    final i = _zonaSelezionata;
    return i == null || i >= _zone.length ? null : _zone[i];
  }

  TestoLavagna? get _testo {
    final i = _testoSelezionato;
    return i == null || i >= _testi.length ? null : _testi[i];
  }

  void _deselezionaTutto() {
    _selezionato = null;
    _frecciaSelezionata = null;
    _zonaSelezionata = null;
    _testoSelezionato = null;
  }

  /// Sposta il giocatore/palla all'indice [i] in [nuova]: se è lui stesso
  /// a portare la palla, la trascina con sé; se è la palla a essere
  /// spostata direttamente, si stacca dal portatore (altrimenti al primo
  /// spostamento del portatore tornerebbe a seguirlo, annullando il
  /// riposizionamento manuale appena fatto).
  void _muoviGiocatore(int i, Offset nuova) {
    final chiave = _chiave(i);
    final giocatore = _giocatori[i];
    _giocatori[i] = giocatore.colore.palla
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
        _giocatori[indiceSelezionato].colore.palla) {
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

  void _piazzaPezzo(Offset punto) {
    // Un tocco sul campo vuoto mentre un giocatore (o la palla) e'
    // selezionato lo sposta li', invece di piazzarne uno nuovo.
    if (_selezionato != null) {
      _muoviSelezionatoIn(punto);
      return;
    }
    final giaPresenti = _giocatori.where((g) => g.colore == _pezzo).length;
    if (giaPresenti >= _massimoInAcqua(_pezzo)) {
      final messaggio = switch (_pezzo) {
        ColoreLavagna.giallo =>
          'Puoi avere una sola palla: tocca quella già piazzata per '
              'riassegnarla a un altro giocatore.',
        ColoreLavagna.rosso when widget.campo == CampoLavagna.meta =>
          'A metà campo c\'è una porta sola: un solo portiere. Per '
              'spostarlo trascinalo.',
        ColoreLavagna.rosso => 'Al massimo 2 portieri, uno per squadra.',
        _ =>
          'Massimo ${WaterPoloTacticsBoard.massimoGiocatoriPerColore} '
              'calottine ${_pezzo.nomePezzo.toLowerCase()}: scegli l\'altra '
              'squadra per aggiungerne altre.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(messaggio)));
      return;
    }
    _registraCronologia();
    setState(
      () => _giocatori.add(GiocatoreLavagna(posizione: punto, colore: _pezzo)),
    );
    _notifica();
  }

  void _rimuoviGiocatore(int i) {
    _registraCronologia();
    final chiave = _chiave(i);
    setState(() {
      _giocatori.removeAt(i);
      // Un giocatore rimosso non puo' restare il portatore della palla:
      // resta dov'e', non agganciata a nessuno.
      for (var j = 0; j < _giocatori.length; j++) {
        if (_giocatori[j].portatore == chiave) {
          _giocatori[j] = _giocatori[j].conPortatore(null);
        }
      }
      if (_selezionato == chiave) _selezionato = null;
    });
    _notifica();
  }

  /// Le frecce sono annotazioni libere, senza un legame esplicito con un
  /// giocatore. Una volta che lo spostamento indicato è stato davvero
  /// fatto nello stesso passo — per una nuotata, un giocatore è arrivato
  /// alla punta e nessuno è rimasto alla partenza; per un passaggio o un
  /// tiro, lo stesso con la palla — la freccia ha fatto il suo lavoro e
  /// sparisce. È un'euristica di prossimità, non un vincolo esatto; la
  /// freccia scelta resta sempre visibile, per poterla modificare.
  bool _compiuta(FrecciaLavagna f) {
    if (identical(f, _freccia)) return false;
    final palla = f.tipo.muoveLaPalla;
    bool occupato(Offset p) => _giocatori.any(
      (g) => g.colore.palla == palla && (g.posizione - p).distance <= 0.02,
    );
    return occupato(f.fine) && !occupato(f.inizio);
  }

  void _notifica() => widget.onCambiato?.call(_istantanea);

  PassoLavagna get _istantanea => (
    giocatori: List.of(_giocatori),
    frecce: List.of(_frecce),
    zone: List.of(_zone),
    testi: List.of(_testi),
  );

  bool get _vuoto =>
      _giocatori.isEmpty && _frecce.isEmpty && _zone.isEmpty && _testi.isEmpty;

  /// Come appena aperta: solo i portieri in porta ([portieriInPorta]).
  bool get _comeNuova {
    final portieri = portieriInPorta(widget.campo);
    if (_frecce.isNotEmpty || _zone.isNotEmpty || _testi.isNotEmpty) {
      return false;
    }
    if (_giocatori.length != portieri.length) return false;
    for (var i = 0; i < portieri.length; i++) {
      if (_giocatori[i].colore != portieri[i].colore ||
          (_giocatori[i].posizione - portieri[i].posizione).distance > 0.001) {
        return false;
      }
    }
    return true;
  }

  /// Quanti pezzi di [pezzo] possono stare in acqua su questo campo: a
  /// metà campo c'è una porta sola, quindi un solo portiere.
  int _massimoInAcqua(ColoreLavagna pezzo) =>
      pezzo == ColoreLavagna.rosso && widget.campo == CampoLavagna.meta
      ? 1
      : pezzo.massimoInAcqua;

  void _registraCronologia() {
    _cronologia.add(_istantanea);
    _annullati.clear();
  }

  void _ripristina(PassoLavagna stato) {
    setState(() {
      _giocatori
        ..clear()
        ..addAll(stato.giocatori);
      _frecce
        ..clear()
        ..addAll(stato.frecce);
      _zone
        ..clear()
        ..addAll(stato.zone);
      _testi
        ..clear()
        ..addAll(stato.testi);
      _deselezionaTutto();
    });
    _notifica();
  }

  void _annulla() {
    if (_cronologia.isEmpty) return;
    _annullati.add(_istantanea);
    _ripristina(_cronologia.removeLast());
  }

  void _ripeti() {
    if (_annullati.isEmpty) return;
    _cronologia.add(_istantanea);
    _ripristina(_annullati.removeLast());
  }

  /// Si riparte da una lavagna nuova: i portieri restano in porta.
  void _cancellaTutto() {
    _registraCronologia();
    setState(() {
      _giocatori
        ..clear()
        ..addAll(portieriInPorta(widget.campo));
      _frecce.clear();
      _zone.clear();
      _testi.clear();
      _deselezionaTutto();
    });
    _notifica();
  }

  void _eliminaZonaSelezionata() {
    final i = _zonaSelezionata;
    if (i == null) return;
    _registraCronologia();
    setState(() {
      _zone.removeAt(i);
      _zonaSelezionata = null;
    });
    _notifica();
  }

  void _eliminaTestoSelezionato() {
    final i = _testoSelezionato;
    if (i == null) return;
    _registraCronologia();
    setState(() {
      _testi.removeAt(i);
      _testoSelezionato = null;
    });
    _notifica();
  }

  void _modificaZona(
    ZonaLavagna Function(ZonaLavagna) modifica, {
    bool registra = true,
  }) {
    final i = _zonaSelezionata;
    if (i == null) return;
    if (registra) _registraCronologia();
    setState(() => _zone[i] = modifica(_zone[i]));
    _notifica();
  }

  void _modificaTesto(
    TestoLavagna Function(TestoLavagna) modifica, {
    bool registra = true,
  }) {
    final i = _testoSelezionato;
    if (i == null) return;
    if (registra) _registraCronologia();
    setState(() => _testi[i] = modifica(_testi[i]));
    _notifica();
  }

  void _scegliForma(FormaZona forma) {
    setState(() => _formaZona = forma);
    if (_zona case final z? when z.forma != forma) {
      _modificaZona((z) => z.copiaCon(forma: forma));
    }
  }

  void _scegliColoreZona(ColoreLavagna colore) {
    setState(() => _coloreZona = colore);
    if (_zona case final z? when z.colore != colore) {
      _modificaZona((z) => z.copiaCon(colore: colore));
    }
  }

  void _scegliColoreTesto(ColoreLavagna colore) {
    setState(() => _coloreTesto = colore);
    if (_testo case final t? when t.colore != colore) {
      _modificaTesto((t) => t.copiaCon(colore: colore));
    }
  }

  /// Chiede il testo di una scritta; `null` se si annulla o resta vuoto.
  Future<String?> _chiediTesto({String iniziale = ''}) async {
    final testo = await showDialog<String>(
      context: context,
      builder: (context) => _DialogScritta(iniziale: iniziale),
    );
    final pulito = testo?.trim() ?? '';
    return pulito.isEmpty ? null : pulito;
  }

  Future<void> _nuovoTesto(Offset punto) async {
    final testo = await _chiediTesto();
    if (testo == null || !mounted) return;
    _registraCronologia();
    setState(() {
      _testi.add(
        TestoLavagna(punto: punto, testo: testo, colore: _coloreTesto),
      );
      _testoSelezionato = _testi.length - 1;
    });
    _notifica();
  }

  Future<void> _cambiaTesto() async {
    final attuale = _testo;
    if (attuale == null) return;
    final testo = await _chiediTesto(iniziale: attuale.testo);
    if (testo == null || !mounted || testo == attuale.testo) return;
    _modificaTesto((t) => t.copiaCon(testo: testo));
  }

  void _eliminaFrecciaSelezionata() {
    final i = _frecciaSelezionata;
    if (i == null) return;
    _registraCronologia();
    setState(() {
      _frecce.removeAt(i);
      _frecciaSelezionata = null;
    });
    _notifica();
  }

  /// Applica [modifica] alla freccia scelta, se c'è.
  void _modificaFreccia(
    FrecciaLavagna Function(FrecciaLavagna) modifica, {
    bool registra = true,
  }) {
    final i = _frecciaSelezionata;
    if (i == null) return;
    if (registra) _registraCronologia();
    setState(() => _frecce[i] = modifica(_frecce[i]));
    _notifica();
  }

  void _scegliTipo(TipoFreccia tipo) {
    setState(() => _tipo = tipo);
    if (_freccia case final f? when f.tipo != tipo) {
      _modificaFreccia((f) => f.copiaCon(tipo: tipo));
    }
  }

  void _scegliInchiostro(ColoreLavagna colore) {
    setState(() => _inchiostro = colore);
    if (_freccia case final f? when f.colore != colore) {
      _modificaFreccia((f) => f.copiaCon(colore: colore));
    }
  }

  Future<void> _cambiaCampo(CampoLavagna nuovo) async {
    if (nuovo == widget.campo) return;
    if (!_vuoto && !_comeNuova) {
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
    }
    setState(() {
      // Sul campo nuovo si riparte con i suoi portieri in porta.
      _giocatori
        ..clear()
        ..addAll(portieriInPorta(nuovo));
      _frecce.clear();
      _zone.clear();
      _testi.clear();
      // Le posizioni salvate nella cronologia erano per il campo
      // precedente: non avrebbero più senso qui.
      _cronologia.clear();
      _annullati.clear();
      _deselezionaTutto();
    });
    _notifica();
    widget.onCampoCambiato?.call(nuovo);
  }

  Widget _barraStrumenti(bool vuoto) => LayoutBuilder(
    builder: (context, vincoli) {
      final modalita = SegmentedButton<_ModalitaLavagna>(
        // Senza spunta: la scelta e' gia' evidenziata dal colore, e la
        // spunta toglieva spazio all'etichetta che su telefono andava a
        // capo a meta' parola.
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
          ButtonSegment(
            value: _ModalitaLavagna.zone,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Zone', maxLines: 1),
            ),
            icon: Icon(Icons.crop_square, size: 18),
          ),
          ButtonSegment(
            value: _ModalitaLavagna.testo,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Testo', maxLines: 1),
            ),
            icon: Icon(Icons.text_fields, size: 18),
          ),
        ],
        selected: {_modalita},
        onSelectionChanged: (s) => setState(() {
          _modalita = s.first;
          _deselezionaTutto();
        }),
      );
      // Il cestino elimina l'elemento scelto nella modalità in uso; senza
      // niente di scelto, svuota il passo.
      final (String, VoidCallback?) elimina = switch (_modalita) {
        _ModalitaLavagna.frecce when _freccia != null => (
          'Elimina la freccia scelta',
          _eliminaFrecciaSelezionata,
        ),
        _ModalitaLavagna.zone when _zona != null => (
          'Elimina la zona scelta',
          _eliminaZonaSelezionata,
        ),
        _ModalitaLavagna.testo when _testo != null => (
          'Elimina la scritta scelta',
          _eliminaTestoSelezionato,
        ),
        _ => ('Cancella tutto', vuoto || _comeNuova ? null : _cancellaTutto),
      };
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
          icon: const Icon(Icons.redo),
          tooltip: 'Ripeti la modifica annullata',
          onPressed: _annullati.isEmpty ? null : _ripeti,
        ),
        IconButton(
          icon: Icon(widget.bloccata ? Icons.lock : Icons.lock_open_outlined),
          tooltip: widget.bloccata
              ? 'Sblocca lo scorrimento della pagina'
              : 'Blocca lo scorrimento della pagina (utile mentre '
                    'disegni una freccia)',
          onPressed: () => widget.onBloccataCambiato?.call(!widget.bloccata),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: elimina.$1,
          onPressed: elimina.$2,
        ),
      ];
      // Sotto ~460 px cinque pulsanti da 48 lasciano al selettore meno
      // di 90 px per segmento: gli strumenti scendono sotto.
      if (vincoli.maxWidth < 460) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            modalita,
            const SizedBox(height: AppSpacing.s4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: strumenti),
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
  );

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final vuoto = _vuoto;
    final frecciaScelta = _freccia;
    final zonaScelta = _zona;
    final testoScelto = _testo;
    final inRiproduzione = widget.sostitutoVasca != null;
    final suggerimento = switch (_modalita) {
      _ModalitaLavagna.giocatori =>
        'Tocca l\'acqua per mettere ${_pezzo.palla ? 'la palla' : 'una calottina'}, '
            'trascina per spostare, doppio tocco per togliere.',
      _ModalitaLavagna.frecce when frecciaScelta != null =>
        'Trascina il pallino al centro per curvarla, quelli agli estremi '
            'per spostarla. Doppio tocco sul centro la raddrizza.',
      _ModalitaLavagna.frecce =>
        'Disegna la traiettoria col dito: la freccia la segue. Tocca una '
            'freccia per modificarla.',
      _ModalitaLavagna.zone when zonaScelta != null =>
        'Trascina la zona per spostarla, i pallini agli angoli per cambiarne '
            'la misura.',
      _ModalitaLavagna.zone =>
        'Trascina sull\'acqua per disegnare una zona. Tocca una zona per '
            'modificarla.',
      _ModalitaLavagna.testo when testoScelto != null =>
        'Trascina la scritta per spostarla, toccala di nuovo per cambiarla.',
      _ModalitaLavagna.testo =>
        'Tocca l\'acqua dove vuoi una scritta. Tocca una scritta per '
            'modificarla.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.modificabile)
          // Durante l'animazione gli strumenti restano visibili ma spenti.
          IgnorePointer(
            ignoring: inRiproduzione,
            child: Opacity(
              opacity: inRiproduzione ? 0.45 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _barraStrumenti(vuoto),
                  const SizedBox(height: AppSpacing.s8),
                  SegmentedButton<CampoLavagna>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: [
                      for (final c in CampoLavagna.values)
                        ButtonSegment(value: c, label: Text(c.nome)),
                    ],
                    selected: {widget.campo},
                    onSelectionChanged: (s) => _cambiaCampo(s.first),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (_modalita == _ModalitaLavagna.giocatori)
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final p in ColoreLavagna.pezzi)
                          _ChipStrumento(
                            etichetta: p.nomePezzo,
                            selezionato: p == _pezzo,
                            onTap: () => setState(() {
                              _pezzo = p;
                              _selezionato = null;
                            }),
                            icona: SizedBox(
                              width: 26,
                              height: 22,
                              child: CustomPaint(
                                painter: _PezzoPainter(
                                  colore: p,
                                  etichetta: p.etichetta(1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  else if (_modalita == _ModalitaLavagna.frecce) ...[
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final t in TipoFreccia.values)
                          _ChipStrumento(
                            etichetta: t.nome,
                            selezionato: t == (frecciaScelta?.tipo ?? _tipo),
                            onTap: () => _scegliTipo(t),
                            icona: SizedBox(
                              width: 30,
                              height: 14,
                              child: CustomPaint(
                                painter: _AnteprimaTipoPainter(
                                  tipo: t,
                                  colore: colori.testo,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                        for (final c in ColoreLavagna.inchiostri)
                          _SwatchColore(
                            colore: c,
                            selezionato:
                                c == (frecciaScelta?.colore ?? _inchiostro),
                            onTap: () => _scegliInchiostro(c),
                          ),
                      ],
                    ),
                  ] else if (_modalita == _ModalitaLavagna.zone) ...[
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final f in FormaZona.values)
                          _ChipStrumento(
                            etichetta: f.nome,
                            selezionato: f == (zonaScelta?.forma ?? _formaZona),
                            onTap: () => _scegliForma(f),
                            icona: Icon(
                              f == FormaZona.rettangolo
                                  ? Icons.crop_square
                                  : Icons.circle_outlined,
                              size: 20,
                              color: colori.testo,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    _RigaColori(
                      scelto: zonaScelta?.colore ?? _coloreZona,
                      onScelto: _scegliColoreZona,
                    ),
                  ] else
                    _RigaColori(
                      scelto: testoScelto?.colore ?? _coloreTesto,
                      onScelto: _scegliColoreTesto,
                    ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    suggerimento,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ),
            ),
          ),
        widget.sostitutoVasca ??
            _RiquadroVasca(
              campo: widget.campo,
              builder: (larghezza, altezza) =>
                  _vasca(context, larghezza, altezza),
            ),
      ],
    );
  }

  Widget _vasca(BuildContext context, double larghezza, double altezza) {
    final colori = context.colori;
    final modificabile = widget.modificabile;
    final inGiocatori = _modalita == _ModalitaLavagna.giocatori;
    final inFrecce = modificabile && _modalita == _ModalitaLavagna.frecce;
    final inZone = modificabile && _modalita == _ModalitaLavagna.zone;
    final inTesto = modificabile && _modalita == _ModalitaLavagna.testo;
    final dimensione = Size(larghezza, altezza);

    Offset relativa(Offset locale) => Offset(
      (locale.dx / larghezza).clamp(0.0, 1.0),
      (locale.dy / altezza).clamp(0.0, 1.0),
    );
    Offset inPixel(Offset frazione) =>
        Offset(frazione.dx * larghezza, frazione.dy * altezza);
    // Il controllo di una curva può stare fuori dal campo: non va
    // schiacciato sul bordo come un punto toccato.
    Offset inFrazione(Offset pixel) =>
        Offset(pixel.dx / larghezza, pixel.dy / altezza);

    final visibili = <int>[
      for (var i = 0; i < _frecce.length; i++)
        if (!_compiuta(_frecce[i])) i,
    ];

    int? frecciaToccata(Offset punto) {
      int? migliore;
      var distanzaMigliore = 18.0;
      for (final i in visibili) {
        final f = _frecce[i];
        final d = distanzaDaCurva(
          punto,
          inPixel(f.inizio),
          f.controllo == null ? null : inPixel(f.controllo!),
          inPixel(f.fine),
        );
        if (d < distanzaMigliore) {
          migliore = i;
          distanzaMigliore = d;
        }
      }
      return migliore;
    }

    final traccia = _traccia;
    FrecciaLavagna? anteprima;
    if (traccia != null && traccia.length > 1) {
      final controllo = controlloDaTraccia(traccia);
      anteprima = FrecciaLavagna(
        inizio: relativa(traccia.first),
        fine: relativa(traccia.last),
        colore: _inchiostro,
        tipo: _tipo,
        controllo: controllo == null ? null : inFrazione(controllo),
      );
    }

    final frecciaScelta = inFrecce ? _freccia : null;
    final zonaScelta = inZone ? _zona : null;

    final inizioZona = _inizioZona;
    final fineZona = _fineZona;
    final zonaInDisegno = inizioZona != null && fineZona != null
        ? ZonaLavagna(
            da: relativa(inizioZona),
            a: relativa(fineZona),
            colore: _coloreZona,
            forma: _formaZona,
          )
        : null;

    // La più in alto (l'ultima disegnata) vince, come si vede.
    int? zonaToccata(Offset punto) {
      for (var i = _zone.length - 1; i >= 0; i--) {
        if (_zone[i].contiene(punto, dimensione)) return i;
      }
      return null;
    }

    final GestureTapUpCallback? tocco = switch (_modalita) {
      _ when !modificabile => null,
      _ModalitaLavagna.giocatori => null,
      _ModalitaLavagna.frecce => (d) => setState(
        () => _frecciaSelezionata = frecciaToccata(d.localPosition),
      ),
      _ModalitaLavagna.zone => (d) => setState(
        () => _zonaSelezionata = zonaToccata(d.localPosition),
      ),
      // Con una scritta scelta, il tocco sull'acqua la lascia; senza,
      // ne crea una lì.
      _ModalitaLavagna.testo => (d) {
        if (_testoSelezionato != null) {
          setState(() => _testoSelezionato = null);
        } else {
          _nuovoTesto(relativa(d.localPosition));
        }
      },
    };

    Offset dentro(Offset p) =>
        Offset(p.dx.clamp(0.0, larghezza), p.dy.clamp(0.0, altezza));

    void fineFreccia() {
      final tratto = _traccia;
      setState(() => _traccia = null);
      if (tratto == null || (tratto.last - tratto.first).distance < 16) {
        return;
      }
      final controllo = controlloDaTraccia(tratto);
      _registraCronologia();
      setState(() {
        _frecce.add(
          FrecciaLavagna(
            inizio: relativa(tratto.first),
            fine: relativa(tratto.last),
            colore: _inchiostro,
            tipo: _tipo,
            controllo: controllo == null ? null : inFrazione(controllo),
          ),
        );
        // Appena disegnata resta scelta: si può subito piegarla o
        // cambiarle tipo.
        _frecciaSelezionata = _frecce.length - 1;
      });
      _notifica();
    }

    void fineZonaDisegnata() {
      final a = _inizioZona;
      final b = _fineZona;
      setState(() {
        _inizioZona = null;
        _fineZona = null;
      });
      // Un tratto quasi senza larghezza o altezza era un tocco mosso,
      // non una zona.
      if (a == null ||
          b == null ||
          (a.dx - b.dx).abs() < 12 ||
          (a.dy - b.dy).abs() < 12) {
        return;
      }
      _registraCronologia();
      setState(() {
        _zone.add(
          ZonaLavagna(
            da: relativa(a),
            a: relativa(b),
            colore: _coloreZona,
            forma: _formaZona,
          ),
        );
        _zonaSelezionata = _zone.length - 1;
      });
      _notifica();
    }

    return GestureDetector(
      // La freccia parte dal punto toccato, non da dove il trascinamento
      // viene riconosciuto (qualche decina di pixel più in là).
      dragStartBehavior: DragStartBehavior.down,
      // Un "tocco" dell'accessibilità non ha un punto preciso: con
      // l'albero di accessibilità attivo, ogni tocco sulla vasca piazzava
      // la calottina sempre nello stesso posto.
      excludeFromSemantics: true,
      onTapDown: modificabile && inGiocatori
          ? (d) => _piazzaPezzo(relativa(d.localPosition))
          : null,
      onTapUp: tocco,
      onPanStart: inFrecce
          ? (d) => setState(() {
              _frecciaSelezionata = null;
              _traccia = [d.localPosition];
            })
          : inZone
          ? (d) => setState(() {
              _zonaSelezionata = null;
              _inizioZona = dentro(d.localPosition);
              _fineZona = _inizioZona;
            })
          : null,
      onPanUpdate: inFrecce
          ? (d) => setState(() => _traccia?.add(d.localPosition))
          : inZone
          ? (d) => setState(() => _fineZona = dentro(d.localPosition))
          : null,
      onPanEnd: inFrecce
          ? (_) => fineFreccia()
          : inZone
          ? (_) => fineZonaDisegnata()
          : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: VascaPainter(campo: widget.campo)),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ZonePainter(
                  zone: _zone,
                  anteprima: zonaInDisegno,
                  evidenziata: zonaScelta,
                  coloreEvidenza: colori.azione,
                ),
              ),
            ),
          ),
          if (widget.passoFantasma case final fantasma?)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.3,
                  child: Stack(
                    children: [
                      for (var i = 0; i < fantasma.giocatori.length; i++)
                        // La palla non si mostra nel fantasma: una
                        // seconda in trasparenza vicino a quella vera
                        // sembra un secondo pallone invece di un
                        // riferimento al passo precedente.
                        if (!fantasma.giocatori[i].colore.palla)
                          _TokenGiocatore(
                            giocatore: fantasma.giocatori[i],
                            numero: _numeroPerColore(fantasma.giocatori, i),
                            larghezza: larghezza,
                            altezza: altezza,
                            attivo: false,
                            onTrascina: (_) {},
                            onRimuovi: () {},
                          ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FreccePainter(
                  frecce: [for (final i in visibili) _frecce[i]],
                  anteprima: anteprima,
                  evidenziata: frecciaScelta,
                  coloreEvidenza: colori.azione,
                  pezzi: _ingombri(_giocatori),
                ),
              ),
            ),
          ),
          for (var i = 0; i < _giocatori.length; i++)
            _TokenGiocatore(
              giocatore: _giocatori[i],
              // Numerato per colore (1-7), non in ordine assoluto di
              // piazzamento: al cambio colore riparte da 1.
              numero: _numeroPerColore(_giocatori, i),
              larghezza: larghezza,
              altezza: altezza,
              attivo: modificabile && inGiocatori,
              evidenziato: _chiave(i) == _selezionato,
              onTap: () => _onTapGiocatore(i),
              onInizioTrascinamento: () {
                _registraCronologia();
                _selezionato = null;
              },
              onTrascina: (delta) {
                final attuale = _giocatori[i].posizione;
                final nuova = Offset(
                  (attuale.dx + delta.dx / larghezza).clamp(0.0, 1.0),
                  (attuale.dy + delta.dy / altezza).clamp(0.0, 1.0),
                );
                setState(() => _muoviGiocatore(i, nuova));
                _notifica();
              },
              onRimuovi: () => _rimuoviGiocatore(i),
            ),
          for (var i = 0; i < _testi.length; i++)
            _EtichettaTesto(
              testo: _testi[i],
              larghezza: larghezza,
              altezza: altezza,
              attiva: inTesto,
              evidenza: inTesto && i == _testoSelezionato
                  ? colori.azione
                  : null,
              onTap: () {
                if (_testoSelezionato == i) {
                  _cambiaTesto();
                } else {
                  setState(() => _testoSelezionato = i);
                }
              },
              onInizioTrascinamento: () {
                _registraCronologia();
                setState(() => _testoSelezionato = i);
              },
              onTrascina: (delta) {
                final t = _testi[i];
                setState(
                  () => _testi[i] = t.copiaCon(
                    punto: Offset(
                      (t.punto.dx + delta.dx / larghezza).clamp(0.0, 1.0),
                      (t.punto.dy + delta.dy / altezza).clamp(0.0, 1.0),
                    ),
                  ),
                );
                _notifica();
              },
            ),
          if (frecciaScelta != null) ...[
            _Maniglia(
              centro: inPixel(frecciaScelta.puntoMedio),
              diametro: 20,
              etichetta: 'Curva la freccia',
              onInizio: _registraCronologia,
              onTrascina: (delta) => _modificaFreccia(registra: false, (f) {
                final medio = inPixel(f.puntoMedio) + delta;
                final controllo = controlloPerPuntoMedio(
                  inPixel(f.inizio),
                  medio,
                  inPixel(f.fine),
                );
                return f.copiaCon(controllo: inFrazione(controllo));
              }),
              onFine: () => _modificaFreccia(registra: false, (f) {
                // Quasi dritta: si raddrizza del tutto, una piega di
                // pochi pixel sembra un errore.
                final c = f.controllo;
                if (c == null) return f;
                final scarto = inPixel(c) - inPixel((f.inizio + f.fine) / 2);
                return scarto.distance < 8 ? f.copiaCon(dritta: true) : f;
              }),
              onDoppioTocco: () =>
                  _modificaFreccia((f) => f.copiaCon(dritta: true)),
            ),
            for (final estremo in [true, false])
              _Maniglia(
                centro: inPixel(
                  estremo ? frecciaScelta.inizio : frecciaScelta.fine,
                ),
                diametro: 14,
                etichetta: estremo
                    ? 'Sposta l\'inizio della freccia'
                    : 'Sposta la punta della freccia',
                onInizio: _registraCronologia,
                onTrascina: (delta) => _modificaFreccia(registra: false, (f) {
                  final punto = relativa(
                    inPixel(estremo ? f.inizio : f.fine) + delta,
                  );
                  return estremo
                      ? f.copiaCon(inizio: punto)
                      : f.copiaCon(fine: punto);
                }),
              ),
          ],
          if (zonaScelta != null) ...[
            // Il corpo della zona scelta si trascina per spostarla; un
            // tocco passa sotto e la lascia scelta.
            Positioned.fromRect(
              rect: zonaScelta.inPixel(dimensione),
              child: Semantics(
                label: 'Sposta la zona',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onPanStart: (_) => _registraCronologia(),
                  onPanUpdate: (d) => _modificaZona(
                    registra: false,
                    (z) => zonaSpostata(
                      z,
                      Offset(d.delta.dx / larghezza, d.delta.dy / altezza),
                    ),
                  ),
                ),
              ),
            ),
            for (final primo in [true, false])
              _Maniglia(
                centro: inPixel(primo ? zonaScelta.da : zonaScelta.a),
                diametro: 16,
                etichetta: 'Cambia la misura della zona',
                onInizio: _registraCronologia,
                onTrascina: (delta) => _modificaZona(registra: false, (z) {
                  final p = relativa(inPixel(primo ? z.da : z.a) + delta);
                  return primo ? z.copiaCon(da: p) : z.copiaCon(a: p);
                }),
              ),
          ],
        ],
      ),
    );
  }
}

/// La finestra per scrivere o cambiare una scritta. Tiene lei il proprio
/// campo di testo: liberarlo appena chiusa, da fuori, faceva fallire
/// l'animazione di chiusura che lo usa ancora.
class _DialogScritta extends StatefulWidget {
  const _DialogScritta({required this.iniziale});

  final String iniziale;

  @override
  State<_DialogScritta> createState() => _DialogScrittaState();
}

class _DialogScrittaState extends State<_DialogScritta> {
  late final _controller = TextEditingController(text: widget.iniziale);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.iniziale.isEmpty ? 'Nuova scritta' : 'Cambia la scritta',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Es. Centroboa'),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

/// [zona] spostata di [delta] (frazioni del campo), senza farla uscire
/// dalla vasca: arrivata al bordo si ferma, invece di deformarsi.
ZonaLavagna zonaSpostata(ZonaLavagna zona, Offset delta) {
  final sinistra = math.min(zona.da.dx, zona.a.dx);
  final destra = math.max(zona.da.dx, zona.a.dx);
  final alto = math.min(zona.da.dy, zona.a.dy);
  final basso = math.max(zona.da.dy, zona.a.dy);
  final spostamento = Offset(
    delta.dx.clamp(-sinistra, 1 - destra),
    delta.dy.clamp(-alto, 1 - basso),
  );
  return zona.copiaCon(da: zona.da + spostamento, a: zona.a + spostamento);
}

/// Riga dei colori per zone e scritte: gli stessi inchiostri delle frecce.
class _RigaColori extends StatelessWidget {
  const _RigaColori({required this.scelto, required this.onScelto});

  final ColoreLavagna scelto;
  final ValueChanged<ColoreLavagna> onScelto;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.s8,
      children: [
        Text(
          'Colore:',
          style: AppTypography.piccolo.copyWith(
            color: context.colori.testoSecondario,
          ),
        ),
        for (final c in ColoreLavagna.inchiostri)
          _SwatchColore(
            colore: c,
            selezionato: c == scelto,
            onTap: () => onScelto(c),
          ),
      ],
    );
  }
}

/// Una zona: riempimento trasparente del suo colore e bordo pieno.
void _disegnaZona(
  Canvas canvas,
  Size size,
  ZonaLavagna zona, {
  Color? evidenza,
  double opacita = 1,
}) {
  final r = zona.inPixel(size);
  final riempimento = Paint()
    ..color = zona.colore.colore.withValues(alpha: 0.28 * opacita);
  final bordo = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = zona.colore.colore.withValues(alpha: 0.9 * opacita);
  void forma(Rect rect, Paint pennello) => zona.forma == FormaZona.ovale
      ? canvas.drawOval(rect, pennello)
      : canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          pennello,
        );
  forma(r, riempimento);
  forma(r, bordo);
  if (evidenza != null) {
    forma(
      r.inflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = evidenza,
    );
  }
}

class _ZonePainter extends CustomPainter {
  _ZonePainter({
    required this.zone,
    this.anteprima,
    this.evidenziata,
    this.coloreEvidenza,
  });

  final List<ZonaLavagna> zone;

  /// La zona che il dito sta disegnando.
  final ZonaLavagna? anteprima;
  final ZonaLavagna? evidenziata;
  final Color? coloreEvidenza;

  @override
  void paint(Canvas canvas, Size size) {
    for (final z in zone) {
      _disegnaZona(
        canvas,
        size,
        z,
        evidenza: identical(z, evidenziata) ? coloreEvidenza : null,
      );
    }
    final a = anteprima;
    if (a != null) _disegnaZona(canvas, size, a, opacita: 0.6);
  }

  // Liste nuove a ogni build: ridisegnare poche zone costa poco.
  @override
  bool shouldRepaint(covariant _ZonePainter oldDelegate) => true;
}

/// L'etichetta di una scritta: testo in grassetto su una pastiglia del
/// colore scelto, al massimo su due righe.
class _EtichettaPainter extends CustomPainter {
  _EtichettaPainter({required this.testo, this.evidenza});

  final TestoLavagna testo;
  final Color? evidenza;

  static const _larghezzaMassima = 180.0;
  static const _marginiOrizzontali = 16.0;
  static const _marginiVerticali = 8.0;

  static TextPainter _impagina(String testo, Color colore) => TextPainter(
    text: TextSpan(
      text: testo,
      style: TextStyle(
        color: colore,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: _larghezzaMassima - _marginiOrizzontali);

  /// Quanto spazio occupa l'etichetta di [testo].
  static Size misura(String testo) {
    final tp = _impagina(testo, AcquaPalette.nero);
    final dimensione = Size(
      tp.width + _marginiOrizzontali,
      tp.height + _marginiVerticali,
    );
    tp.dispose();
    return dimensione;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pastiglia = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(
      pastiglia.shift(const Offset(0, 1.5)),
      Paint()
        ..color = AcquaPalette.nero.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawRRect(pastiglia, Paint()..color = testo.colore.colore);
    canvas.drawRRect(
      pastiglia,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = testo.colore.controcolore.withValues(alpha: 0.35),
    );
    final colore = evidenza;
    if (colore != null) {
      canvas.drawRRect(
        pastiglia.inflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = colore,
      );
    }
    final tp = _impagina(testo.testo, testo.colore.controcolore);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(_EtichettaPainter old) =>
      old.testo.testo != testo.testo ||
      old.testo.colore != testo.colore ||
      old.evidenza != evidenza;
}

/// Una scritta sulla vasca: si tocca e si trascina solo in modalità
/// "Testo", nelle altre lascia passare i tocchi all'acqua sotto.
class _EtichettaTesto extends StatelessWidget {
  const _EtichettaTesto({
    required this.testo,
    required this.larghezza,
    required this.altezza,
    required this.attiva,
    required this.onTap,
    required this.onInizioTrascinamento,
    required this.onTrascina,
    this.evidenza,
  });

  final TestoLavagna testo;
  final double larghezza;
  final double altezza;
  final bool attiva;
  final VoidCallback onTap;
  final VoidCallback onInizioTrascinamento;
  final ValueChanged<Offset> onTrascina;
  final Color? evidenza;

  @override
  Widget build(BuildContext context) {
    final dimensione = _EtichettaPainter.misura(testo.testo);
    return Positioned(
      left: testo.punto.dx * larghezza - dimensione.width / 2,
      top: testo.punto.dy * altezza - dimensione.height / 2,
      child: IgnorePointer(
        ignoring: !attiva,
        child: Semantics(
          label: 'Scritta: ${testo.testo}',
          selected: evidenza != null,
          child: GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onTap: onTap,
            onPanStart: (_) => onInizioTrascinamento(),
            onPanUpdate: (d) => onTrascina(d.delta),
            child: CustomPaint(
              size: dimensione,
              painter: _EtichettaPainter(testo: testo, evidenza: evidenza),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le scritte disegnate e basta (animazione, miniature, esportazione).
void _disegnaTesti(Canvas canvas, Size size, List<TestoLavagna> testi) {
  for (final t in testi) {
    final dimensione = _EtichettaPainter.misura(t.testo);
    canvas.save();
    canvas.translate(
      t.punto.dx * size.width - dimensione.width / 2,
      t.punto.dy * size.height - dimensione.height / 2,
    );
    _EtichettaPainter(testo: t).paint(canvas, dimensione);
    canvas.restore();
  }
}

class _TestiPainter extends CustomPainter {
  _TestiPainter(this.testi);

  final List<TestoLavagna> testi;

  @override
  void paint(Canvas canvas, Size size) => _disegnaTesti(canvas, size, testi);

  @override
  bool shouldRepaint(covariant _TestiPainter oldDelegate) => true;
}

/// Un passo intero — vasca, zone, frecce, calottine, scritte — come lo
/// mostra la lavagna, su una tela grande [size]: per l'esportazione.
void disegnaPassoCompleto(
  Canvas canvas,
  Size size,
  PassoLavagna passo,
  CampoLavagna campo,
) {
  VascaPainter(campo: campo).paint(canvas, size);
  for (final z in passo.zone) {
    _disegnaZona(canvas, size, z);
  }
  _FreccePainter(
    frecce: passo.frecce,
    pezzi: _ingombri(passo.giocatori),
  ).paint(canvas, size);
  for (var i = 0; i < passo.giocatori.length; i++) {
    final g = passo.giocatori[i];
    final dimensione = _dimensionePezzo(g.colore);
    canvas.save();
    canvas.translate(
      g.posizione.dx * size.width - dimensione.width / 2,
      g.posizione.dy * size.height - dimensione.height / 2,
    );
    _PezzoPainter(
      colore: g.colore,
      etichetta: g.colore.etichetta(_numeroPerColore(passo.giocatori, i)),
    ).paint(canvas, dimensione);
    canvas.restore();
  }
  _disegnaTesti(canvas, size, passo.testi);
}

/// Il passo come immagine PNG: [larghezza] in punti logici (calottine e
/// scritte hanno la stessa misura che sullo schermo di un telefono),
/// [densita] pixel per punto per un'immagine nitida.
Future<Uint8List> immaginePasso(
  PassoLavagna passo,
  CampoLavagna campo, {
  double larghezza = 600,
  double densita = 2,
}) async {
  final altezza = larghezza / campo.proporzioni;
  final registratore = ui.PictureRecorder();
  final canvas = Canvas(registratore)..scale(densita);
  disegnaPassoCompleto(canvas, Size(larghezza, altezza), passo, campo);
  final immagine = await registratore.endRecording().toImage(
    (larghezza * densita).round(),
    (altezza * densita).round(),
  );
  final dati = await immagine.toByteData(format: ui.ImageByteFormat.png);
  immagine.dispose();
  return dati!.buffer.asUint8List();
}

/// Centri (frazioni del campo) e raggi in pixel dei pezzi in acqua: una
/// freccia che arriva su un giocatore si ferma al bordo della calottina,
/// invece di finire nascosta sotto.
List<(Offset, double)> _ingombri(List<GiocatoreLavagna> giocatori) => [
  for (final g in giocatori)
    (g.posizione, g.colore.palla ? _raggioPalla + 1 : _raggioCalottina + 1),
];

const _altezzaCalottina = 30.0;
const _raggioCalottina = _altezzaCalottina * 0.42;
const _diametroPalla = 18.0;
const _raggioPalla = _diametroPalla / 2 - 1;

Size _dimensionePezzo(ColoreLavagna colore) => colore.palla
    ? const Size(_diametroPalla, _diametroPalla)
    : const Size(36, _altezzaCalottina);

/// La vasca della lavagna, grande quanto lo spazio disponibile ma mai più
/// alta del 70% dello schermo: il campo intero in verticale, a tutta
/// larghezza, costringeva a scorrere la pagina per vederlo tutto.
class _RiquadroVasca extends StatelessWidget {
  const _RiquadroVasca({required this.campo, required this.builder});

  final CampoLavagna campo;
  final Widget Function(double larghezza, double altezza) builder;

  @override
  Widget build(BuildContext context) {
    final altezzaMassima = math.max(
      280.0,
      MediaQuery.sizeOf(context).height * 0.7,
    );
    return LayoutBuilder(
      builder: (context, vincoli) {
        var larghezza = vincoli.maxWidth;
        var altezza = larghezza / campo.proporzioni;
        if (altezza > altezzaMassima) {
          altezza = altezzaMassima;
          larghezza = altezza * campo.proporzioni;
        }
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            child: SizedBox(
              key: const Key('vasca-lavagna'),
              width: larghezza,
              height: altezza,
              child: builder(larghezza, altezza),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsante di scelta dello strumento (pezzo da piazzare, tipo di
/// freccia): figura e nome, evidenziato quando è quello in uso.
class _ChipStrumento extends StatelessWidget {
  const _ChipStrumento({
    required this.etichetta,
    required this.selezionato,
    required this.onTap,
    required this.icona,
  });

  final String etichetta;
  final bool selezionato;
  final VoidCallback onTap;
  final Widget icona;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      selected: selezionato,
      label: etichetta,
      excludeSemantics: true,
      child: Material(
        color: selezionato ? colori.azioneTenue : colori.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          side: BorderSide(
            color: selezionato ? colori.azione : colori.linea,
            width: selezionato ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pannello),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icona,
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    etichetta,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testo,
                      fontWeight: selezionato
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      child: Semantics(
        button: true,
        selected: selezionato,
        label: 'Colore ${colore.nome.toLowerCase()}',
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
      ),
    );
  }
}

/// Maniglia di una freccia scelta: un pallino da trascinare, con un'area
/// di tocco più grande del disegno (difficile centrarlo col dito).
class _Maniglia extends StatelessWidget {
  const _Maniglia({
    required this.centro,
    required this.diametro,
    required this.etichetta,
    required this.onInizio,
    required this.onTrascina,
    this.onFine,
    this.onDoppioTocco,
  });

  final Offset centro;
  final double diametro;
  final String etichetta;
  final VoidCallback onInizio;
  final ValueChanged<Offset> onTrascina;
  final VoidCallback? onFine;
  final VoidCallback? onDoppioTocco;

  static const _area = 44.0;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Positioned(
      left: centro.dx - _area / 2,
      top: centro.dy - _area / 2,
      child: Semantics(
        label: etichetta,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // La maniglia segue il dito da subito, senza perdere il primo
          // tratto del trascinamento.
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (_) => onInizio(),
          onPanUpdate: (d) => onTrascina(d.delta),
          onPanEnd: (_) => onFine?.call(),
          onDoubleTap: onDoppioTocco,
          child: SizedBox(
            width: _area,
            height: _area,
            child: Center(
              child: Container(
                width: diametro,
                height: diametro,
                decoration: BoxDecoration(
                  color: AcquaPalette.bianco,
                  shape: BoxShape.circle,
                  border: Border.all(color: colori.azione, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AcquaPalette.nero.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    required this.onTrascina,
    required this.onRimuovi,
    this.onInizioTrascinamento,
    this.onTap,
    this.evidenziato = false,
  });

  final GiocatoreLavagna giocatore;
  final int numero;
  final double larghezza;
  final double altezza;

  /// Solo in modalità "Giocatori" la calottina risponde al
  /// trascinamento: in modalità "Frecce" il gesto deve arrivare al campo
  /// sotto, per poter disegnare una freccia che parte proprio da un
  /// giocatore.
  final bool attivo;

  /// Lo spostamento del dito in pixel: chi contiene la calottina lo somma
  /// alla posizione *attuale*. Calcolare qui la nuova posizione dalla
  /// [giocatore] ricevuta all'ultima build perdeva strada quando più
  /// movimenti arrivavano nello stesso fotogramma (dito veloce): ognuno
  /// ripartiva dalla stessa posizione vecchia.
  final ValueChanged<Offset> onTrascina;
  final VoidCallback onRimuovi;

  /// Chiamato una sola volta all'inizio del trascinamento (non a ogni
  /// pixel di movimento, a differenza di [onTrascina]): usato per
  /// registrare la posizione di partenza nella cronologia di "Annulla".
  final VoidCallback? onInizioTrascinamento;

  /// Tocco semplice (non trascinamento): usato per armare la palla o,
  /// con la palla già armata, per assegnarla a questo giocatore.
  final VoidCallback? onTap;

  /// true sul pezzo toccato, in attesa del punto d'arrivo o del
  /// giocatore che riceve la palla: un anello lo segnala.
  final bool evidenziato;

  @override
  Widget build(BuildContext context) {
    final posizione = giocatore.posizione;
    final dimensione = _dimensionePezzo(giocatore.colore);
    return Positioned(
      left: posizione.dx * larghezza - dimensione.width / 2,
      top: posizione.dy * altezza - dimensione.height / 2,
      child: IgnorePointer(
        ignoring: !attivo,
        child: Semantics(
          label: giocatore.colore.descrizionePezzo(numero),
          selected: evidenziato,
          child: GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onTap: onTap,
            onPanStart: (_) => onInizioTrascinamento?.call(),
            onPanUpdate: (d) => onTrascina(d.delta),
            onDoubleTap: onRimuovi,
            child: CustomPaint(
              size: dimensione,
              painter: _PezzoPainter(
                colore: giocatore.colore,
                etichetta: giocatore.colore.etichetta(numero),
                evidenza: evidenziato ? context.colori.azione : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una calottina vista dall'alto (cupola, paraorecchie ai lati e numero)
/// o la palla a spicchi: stessi colori delle calottine del resto
/// dell'app.
class _PezzoPainter extends CustomPainter {
  _PezzoPainter({required this.colore, this.etichetta, this.evidenza});

  final ColoreLavagna colore;
  final String? etichetta;
  final Color? evidenza;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final ombra = Paint()
      ..color = AcquaPalette.nero.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    if (colore.palla) {
      final raggio = size.shortestSide / 2 - 1;
      canvas.drawCircle(centro.translate(0, 1.2), raggio, ombra);
      disegnaPalla(canvas, centro, raggio);
      canvas.drawCircle(
        centro,
        raggio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AcquaPalette.pallaRighe,
      );
      _anello(canvas, centro, raggio + 3);
      return;
    }

    final c = colore.calottina;
    final raggio = size.height * 0.42;
    canvas.drawCircle(centro.translate(0, 1.5), raggio + 1, ombra);

    // Paraorecchie: due ovali ai lati, dietro la cupola.
    for (final lato in [-1.0, 1.0]) {
      final orecchio = Rect.fromCenter(
        center: centro.translate(lato * raggio * 0.98, raggio * 0.1),
        width: raggio * 0.46,
        height: raggio * 0.7,
      );
      canvas.drawOval(orecchio, Paint()..color = c.ombra);
      canvas.drawOval(
        orecchio.deflate(raggio * 0.08),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = c.tessuto.withValues(alpha: 0.6),
      );
    }

    // Cupola con luce dall'alto a sinistra.
    final cupola = Rect.fromCircle(center: centro, radius: raggio);
    canvas.drawCircle(
      centro,
      raggio,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(c.tessuto, AcquaPalette.bianco, 0.35)!,
            c.tessuto,
            c.ombra,
          ],
          stops: const [0, 0.62, 1],
        ).createShader(cupola),
    );
    canvas.drawCircle(
      centro,
      raggio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = c.ombra,
    );

    final testo = etichetta;
    if (testo != null && testo.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: testo,
          style: TextStyle(
            color: c.numero,
            fontSize: raggio * (testo.length > 1 ? 0.85 : 1.05),
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, centro - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
    _anello(canvas, centro, raggio + 3.5);
  }

  void _anello(Canvas canvas, Offset centro, double raggio) {
    final colore = evidenza;
    if (colore == null) return;
    canvas.drawCircle(
      centro,
      raggio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colore,
    );
  }

  @override
  bool shouldRepaint(_PezzoPainter old) =>
      old.colore != colore ||
      old.etichetta != etichetta ||
      old.evidenza != evidenza;
}

/// La vasca vista dall'alto: acqua chiara, la porta in alto (e in basso
/// sul campo intero), i segni colorati ai bordi come le boe vere (rosso
/// fino ai 2 m, giallo fino ai 5 m, verde fino a metà campo) e, per
/// leggere le distanze in mezzo all'acqua, le righe tratteggiate dei 2 e
/// dei 5 m. Proporzioni di un campo da 25 x 20 m.
class VascaPainter extends CustomPainter {
  const VascaPainter({required this.campo});

  final CampoLavagna campo;

  @override
  void paint(Canvas canvas, Size size) {
    final rettangolo = Offset.zero & size;
    canvas.drawRect(rettangolo, Paint()..color = VascaPalette.bordo);

    final margine = size.shortestSide * 0.025;
    final acqua = rettangolo.deflate(margine);
    final acquaArrotondata = RRect.fromRectAndRadius(
      acqua,
      Radius.circular(margine),
    );
    canvas.drawRRect(
      acquaArrotondata,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [VascaPalette.acqua, VascaPalette.acquaFonda],
        ).createShader(acqua),
    );

    canvas.save();
    canvas.clipRRect(acquaArrotondata);
    _riflessi(canvas, acqua);

    final metro = acqua.height / campo.metriInAltezza;
    const dietro = CampoLavagna.metriDietroPorta;
    final yPortaAlta = acqua.top + metro * dietro;
    final intero = campo == CampoLavagna.intero;
    final yMeta = intero
        ? acqua.top + metro * (dietro + CampoLavagna.lunghezzaCampo / 2)
        : acqua.bottom;

    _metaVasca(canvas, acqua, yPorta: yPortaAlta, verso: 1, yMeta: yMeta);
    if (intero) {
      _metaVasca(
        canvas,
        acqua,
        yPorta: acqua.bottom - metro * dietro,
        verso: -1,
        yMeta: yMeta,
      );
    }

    // Metà campo: riga bianca da bordo a bordo (sul campo a metà è il
    // fondo del disegno).
    final rigaMeta = Paint()
      ..color = AcquaPalette.bianco.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    final yRigaMeta = intero ? yMeta : acqua.bottom - 1;
    canvas.drawLine(
      Offset(acqua.left, yRigaMeta),
      Offset(acqua.right, yRigaMeta),
      rigaMeta,
    );
    canvas.restore();

    canvas.drawRRect(
      acquaArrotondata,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AcquaPalette.bianco.withValues(alpha: 0.3),
    );
  }

  /// Una metà vasca, dalla linea di porta [yPorta] verso [yMeta]:
  /// [verso] +1 se la porta è in alto, -1 se è in basso.
  void _metaVasca(
    Canvas canvas,
    Rect acqua, {
    required double yPorta,
    required double verso,
    required double yMeta,
  }) {
    const metaCampo = CampoLavagna.lunghezzaCampo / 2;
    final metro = (yMeta - yPorta).abs() / metaCampo;
    double aMetri(double m) => yPorta + verso * metro * m;

    // Segni ai bordi: rosso, giallo, verde.
    final spessore = math.max(4.0, acqua.width * 0.014);
    for (final (da, a, colore) in [
      (0.0, 2.0, VascaPalette.segnoRosso),
      (2.0, 5.0, VascaPalette.segnoGiallo),
      (5.0, metaCampo, VascaPalette.segnoVerde),
    ]) {
      final y1 = aMetri(da);
      final y2 = aMetri(a);
      final pennello = Paint()..color = colore;
      canvas.drawRect(
        Rect.fromLTRB(
          acqua.left,
          math.min(y1, y2),
          acqua.left + spessore,
          math.max(y1, y2),
        ),
        pennello,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          acqua.right - spessore,
          math.min(y1, y2),
          acqua.right,
          math.max(y1, y2),
        ),
        pennello,
      );
    }

    // Righe dei 2 e dei 5 m in mezzo all'acqua, tratteggiate e tenui:
    // in vasca non ci sono, ma aiutano a leggere le distanze.
    for (final (metri, colore) in [
      (2.0, VascaPalette.segnoRosso),
      (5.0, VascaPalette.segnoGiallo),
    ]) {
      _rigaTratteggiata(
        canvas,
        acqua.left + spessore,
        acqua.right - spessore,
        aMetri(metri),
        Paint()
          ..color = colore.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
      );
    }

    // Linea di porta.
    canvas.drawLine(
      Offset(acqua.left, yPorta),
      Offset(acqua.right, yPorta),
      Paint()
        ..color = AcquaPalette.bianco.withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );

    // Porta: 3 m fra i pali, con la rete dietro la linea.
    final centroX = acqua.center.dx;
    final mezzaLuce = acqua.width * 1.5 / 20;
    final fondoRete = yPorta - verso * metro * 0.8;
    final rete = Rect.fromLTRB(
      centroX - mezzaLuce,
      math.min(yPorta, fondoRete),
      centroX + mezzaLuce,
      math.max(yPorta, fondoRete),
    );
    canvas.drawRect(
      rete,
      Paint()..color = AcquaPalette.bianco.withValues(alpha: 0.22),
    );
    final maglia = Paint()
      ..color = AcquaPalette.bianco.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 8; i++) {
      final x = rete.left + rete.width * i / 8;
      canvas.drawLine(Offset(x, rete.top), Offset(x, rete.bottom), maglia);
    }
    canvas.drawLine(
      Offset(rete.left, (rete.top + rete.bottom) / 2),
      Offset(rete.right, (rete.top + rete.bottom) / 2),
      maglia,
    );
    final pali = Paint()
      ..color = AcquaPalette.bianco
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rete.left, yPorta),
      Offset(rete.right, yPorta),
      pali,
    );
    canvas.drawLine(
      Offset(rete.left, yPorta),
      Offset(rete.left, fondoRete),
      pali..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(rete.right, yPorta),
      Offset(rete.right, fondoRete),
      pali,
    );
  }

  void _rigaTratteggiata(
    Canvas canvas,
    double da,
    double a,
    double y,
    Paint pennello,
  ) {
    for (var x = da; x < a; x += 14) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 8, a), y), pennello);
    }
  }

  /// Le "caustiche": poche righe ondulate chiare, la luce sul fondo.
  /// Ferme: la lavagna è un foglio su cui disegnare, non uno sfondo.
  void _riflessi(Canvas canvas, Rect acqua) {
    final pennello = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AcquaPalette.schiuma.withValues(alpha: 0.08);
    const passo = 30.0;
    for (var riga = 0; riga < acqua.height / passo + 1; riga++) {
      final path = Path();
      final y0 = acqua.top + riga * passo;
      for (var x = acqua.left; x <= acqua.right; x += 8) {
        final y = y0 + math.sin(x / 38 + riga * 0.9) * 5 + math.sin(x / 17) * 2;
        x == acqua.left ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, pennello);
    }
  }

  @override
  bool shouldRepaint(VascaPainter old) => old.campo != campo;
}

/// Un passo in miniatura, per la striscia dei passi dell'editor: la
/// vasca, i pezzi come pallini colorati e le frecce come tratti sottili.
class MiniaturaPassoPainter extends CustomPainter {
  const MiniaturaPassoPainter({required this.passo, required this.campo});

  final PassoLavagna passo;
  final CampoLavagna campo;

  @override
  void paint(Canvas canvas, Size size) {
    VascaPainter(campo: campo).paint(canvas, size);
    for (final z in passo.zone) {
      _disegnaZona(canvas, size, z);
    }
    Offset inPixel(Offset p) => Offset(p.dx * size.width, p.dy * size.height);

    for (final f in passo.frecce) {
      final punti = campionaCurva(
        inPixel(f.inizio),
        f.controllo == null ? null : inPixel(f.controllo!),
        inPixel(f.fine),
        segmenti: 16,
      );
      canvas.drawPath(
        percorsoFreccia(punti, tratteggiata: f.tipo == TipoFreccia.passaggio),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = f.colore.colore,
      );
    }

    final raggio = math.max(2.5, size.shortestSide * 0.045);
    for (final g in passo.giocatori) {
      final centro = inPixel(g.posizione);
      final c = g.colore.calottina;
      final r = g.colore.palla ? raggio * 0.75 : raggio;
      canvas.drawCircle(centro, r, Paint()..color = c.tessuto);
      canvas.drawCircle(
        centro,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = c.ombra,
      );
    }
  }

  // I passi arrivano come record nuovi a ogni build: ridisegnare una
  // miniatura costa poco.
  @override
  bool shouldRepaint(MiniaturaPassoPainter old) => true;
}

/// Disegna una freccia: tratto del suo tipo, punta piena e un alone del
/// colore opposto che la stacca dall'acqua.
void _disegnaFreccia(
  Canvas canvas,
  Size size,
  FrecciaLavagna f, {
  List<(Offset, double)> pezzi = const [],
  Color? evidenza,
  double opacita = 1,
}) {
  Offset inPixel(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
  final inizio = inPixel(f.inizio);
  final fine = inPixel(f.fine);
  final controllo = f.controllo == null ? null : inPixel(f.controllo!);

  // Se la punta cade su una calottina, la freccia si ferma al suo bordo.
  var rientro = 0.0;
  for (final (centro, raggio) in pezzi) {
    final c = inPixel(centro);
    final dallaFine = (fine - c).distance;
    if (dallaFine < raggio + 2 && (inizio - c).distance > raggio + 2) {
      rientro = math.max(rientro, raggio + 3 - dallaFine);
    }
  }

  final punti = campionaCurva(inizio, controllo, fine, segmenti: 48);
  final troncati = percorsoTroncato(punti, rientro);
  if (troncati.length < 2) return;
  final vertice = troncati.last;
  final direzione = vertice - troncati[troncati.length - 2];
  final tiro = f.tipo == TipoFreccia.tiro;
  final lunghezzaPunta = tiro ? 14.0 : 11.0;

  final tratti = [
    for (final scostamento in tiro ? [-2.6, 2.6] : [0.0])
      percorsoFreccia(
        troncati,
        accorciamento: lunghezzaPunta * 0.7,
        tratteggiata: f.tipo == TipoFreccia.passaggio,
        ondulata: f.tipo == TipoFreccia.conPalla,
        scostamento: scostamento,
      ),
  ];
  final punta = puntaFreccia(
    vertice,
    direzione,
    lunghezza: lunghezzaPunta,
    semiApertura: tiro ? 0.55 : 0.48,
  );

  Paint tratto(Color colore, double spessore) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = spessore
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = colore;

  if (evidenza != null) {
    final alone = tratto(evidenza.withValues(alpha: 0.45), 10);
    for (final t in tratti) {
      canvas.drawPath(t, alone);
    }
    canvas.drawPath(punta, alone);
  }

  final contorno = tratto(
    f.colore.controcolore.withValues(alpha: 0.45 * opacita),
    tiro ? 4.5 : 5.5,
  );
  for (final t in tratti) {
    canvas.drawPath(t, contorno);
  }
  canvas.drawPath(punta, contorno..strokeWidth = 3);

  final inchiostro = f.colore.colore.withValues(alpha: opacita);
  for (final t in tratti) {
    canvas.drawPath(t, tratto(inchiostro, tiro ? 2 : 2.6));
  }
  canvas.drawPath(punta, Paint()..color = inchiostro);
}

class _FreccePainter extends CustomPainter {
  _FreccePainter({
    required this.frecce,
    this.anteprima,
    this.evidenziata,
    this.coloreEvidenza,
    this.pezzi = const [],
  });

  final List<FrecciaLavagna> frecce;

  /// Il tratto che il dito sta disegnando, già come diventerà.
  final FrecciaLavagna? anteprima;
  final FrecciaLavagna? evidenziata;
  final Color? coloreEvidenza;
  final List<(Offset, double)> pezzi;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in frecce) {
      _disegnaFreccia(
        canvas,
        size,
        f,
        pezzi: pezzi,
        evidenza: identical(f, evidenziata) ? coloreEvidenza : null,
      );
    }
    final a = anteprima;
    if (a != null) _disegnaFreccia(canvas, size, a, opacita: 0.6);
  }

  // Sempre true: le liste arrivano nuove a ogni build e il confronto
  // profondo costerebbe quanto ridisegnare poche frecce.
  @override
  bool shouldRepaint(covariant _FreccePainter oldDelegate) => true;
}

/// Il tratto di un tipo di freccia, in piccolo: sui pulsanti di scelta e
/// nella legenda.
class _AnteprimaTipoPainter extends CustomPainter {
  _AnteprimaTipoPainter({required this.tipo, required this.colore});

  final TipoFreccia tipo;
  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final punti = campionaCurva(
      Offset(1, y),
      null,
      Offset(size.width - 1, y),
      segmenti: 24,
    );
    final tiro = tipo == TipoFreccia.tiro;
    final pennello = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tiro ? 1.4 : 1.8
      ..strokeCap = StrokeCap.round
      ..color = colore;
    for (final scostamento in tiro ? [-2.0, 2.0] : [0.0]) {
      canvas.drawPath(
        percorsoFreccia(
          punti,
          accorciamento: 5,
          tratteggiata: tipo == TipoFreccia.passaggio,
          ondulata: tipo == TipoFreccia.conPalla,
          scostamento: scostamento,
        ),
        pennello,
      );
    }
    canvas.drawPath(
      puntaFreccia(punti.last, const Offset(1, 0), lunghezza: 7),
      Paint()..color = colore,
    );
  }

  @override
  bool shouldRepaint(_AnteprimaTipoPainter old) =>
      old.tipo != tipo || old.colore != colore;
}

/// Che cosa vuol dire ogni tratto, sotto lo schema che lo usa: chi lo
/// sfoglia non deve conoscere la convenzione.
class _LegendaFrecce extends StatelessWidget {
  const _LegendaFrecce({required this.tipi});

  final Set<TipoFreccia> tipi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.s16,
      runSpacing: AppSpacing.s8,
      children: [
        for (final t in TipoFreccia.values)
          if (tipi.contains(t))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 12,
                  child: CustomPaint(
                    painter: _AnteprimaTipoPainter(
                      tipo: t,
                      colore: colori.testoSecondario,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Text(
                  t.nome,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

/// Un giocatore abbinato fra due passi consecutivi, per l'animazione:
/// abbinato per (colore, numero-nel-colore), non per posizione nella
/// lista. Chi non ha corrispondenza nel passo di arrivo resta fermo e
/// sfuma; chi compare solo nel passo di arrivo appare sfumando dentro,
/// nella sua posizione finale. Chi si sposta lungo una freccia curva
/// del passo di partenza ne segue la curva ([controllo]).
class _TokenSequenza {
  const _TokenSequenza({
    required this.colore,
    required this.numero,
    required this.posizioneIniziale,
    required this.posizioneFinale,
    required this.opacitaIniziale,
    required this.opacitaFinale,
    this.controllo,
  });

  final ColoreLavagna colore;
  final int numero;
  final Offset posizioneIniziale;
  final Offset posizioneFinale;
  final double opacitaIniziale;
  final double opacitaFinale;
  final Offset? controllo;
}

List<_TokenSequenza> _abbinaGiocatori(
  List<GiocatoreLavagna> da,
  List<GiocatoreLavagna> a, {
  List<FrecciaLavagna> frecce = const [],
}) {
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

  Offset? curva(Offset inizio, Offset fine) {
    if ((fine - inizio).distance < 0.01) return null;
    final freccia = frecciaPerSpostamento(frecce, inizio, fine);
    return freccia == null
        ? null
        : controlloPerSpostamento(freccia, inizio, fine);
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
          controllo: curva(
            mappaDa[chiave]!.posizione,
            mappaA[chiave]!.posizione,
          ),
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

  @override
  Widget build(BuildContext context) {
    final posizione = puntoSuCurva(
      token.posizioneIniziale,
      token.controllo,
      token.posizioneFinale,
      t,
    );
    final opacita =
        token.opacitaIniziale +
        (token.opacitaFinale - token.opacitaIniziale) * t;
    final dimensione = _dimensionePezzo(token.colore);
    return Positioned(
      left: posizione.dx * larghezza - dimensione.width / 2,
      top: posizione.dy * altezza - dimensione.height / 2,
      child: Opacity(
        opacity: opacita,
        child: CustomPaint(
          size: dimensione,
          painter: _PezzoPainter(
            colore: token.colore,
            etichetta: token.colore.etichetta(token.numero),
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
/// lungo le frecce del passo se ce ne sono, frecce nascoste durante il
/// movimento — in sequenza fino all'ultimo passo. Usato sia dal
/// visualizzatore (schema salvato) sia dall'anteprima nell'editor
/// (schema ancora in bozza, non salvato).
class SchemaTatticoPlayer extends StatefulWidget {
  const SchemaTatticoPlayer({
    required this.passi,
    required this.campo,
    this.mostraComandi = true,
    this.passoIniziale = 0,
    this.avviaSubito = false,
    this.velocita,
    this.onPassoCambiato,
    this.onFine,
    super.key,
  });

  final List<PassoLavagna> passi;
  final CampoLavagna campo;

  /// `false` nell'editor: lì play, passi e velocità stanno nella striscia
  /// dei passi sotto la vasca, e qui resta solo la vasca che si muove.
  final bool mostraComandi;

  final int passoIniziale;

  /// Parte da solo appena mostrato (play premuto nell'editor).
  final bool avviaSubito;

  /// Velocità imposta da fuori (l'editor); `null` = scelta qui.
  final double? velocita;

  /// A ogni passo raggiunto, per evidenziarlo nella striscia dei passi.
  final ValueChanged<int>? onPassoCambiato;

  /// Arrivata in fondo alla sequenza.
  final VoidCallback? onFine;

  @override
  State<SchemaTatticoPlayer> createState() => _SchemaTatticoPlayerState();
}

class _SchemaTatticoPlayerState extends State<SchemaTatticoPlayer>
    with SingleTickerProviderStateMixin {
  static const _durataBase = Duration(milliseconds: 900);
  static const _velocitaDisponibili = [0.5, 1.0, 1.5, 2.0];

  late double _velocita = widget.velocita ?? 1.0;

  Duration get _durataMovimento =>
      Duration(milliseconds: (_durataBase.inMilliseconds / _velocita).round());
  Duration get _durataPausa => _durataMovimento;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durataMovimento,
  );

  late int _passoAttuale = widget.passoIniziale.clamp(
    0,
    widget.passi.length - 1,
  );
  int? _passoSuccessivo;
  bool _inRiproduzione = false;

  /// Impostato solo quando la riproduzione arriva da sola in fondo alla
  /// sequenza (non con Stop manuale né saltando a un passo): a quel
  /// punto si vogliono rivedere tutte le frecce dello schema insieme,
  /// non solo quelle dell'ultimo passo.
  bool _mostraTutteLeFrecce = false;

  @override
  void initState() {
    super.initState();
    if (widget.avviaSubito) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_inRiproduzione) return;
    if (widget.passi.length < 2) {
      widget.onFine?.call();
      return;
    }
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
      widget.onPassoCambiato?.call(i);
    }
    if (mounted) {
      setState(() {
        _inRiproduzione = false;
        _mostraTutteLeFrecce = true;
      });
      widget.onFine?.call();
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
    final tipiUsati = {
      for (final p in passi)
        for (final f in p.frecce) f.tipo,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (passi.length > 1 && widget.mostraComandi) ...[
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
        _RiquadroVasca(
          campo: widget.campo,
          builder: (larghezza, altezza) {
            final vasca = Positioned.fill(
              child: CustomPaint(painter: VascaPainter(campo: widget.campo)),
            );
            // Zone e scritte del passo mostrato: durante il movimento
            // restano quelle del passo di partenza.
            final passoFermo = passi[_passoAttuale];
            final zone = Positioned.fill(
              child: CustomPaint(painter: _ZonePainter(zone: passoFermo.zone)),
            );
            final testi = Positioned.fill(
              child: CustomPaint(painter: _TestiPainter(passoFermo.testi)),
            );

            if (passoSuccessivo == null) {
              final passo = passi[_passoAttuale];
              // A fine riproduzione (non su uno stop manuale o su un
              // salto a un passo) si rivedono insieme le frecce di tutti
              // i passi, non solo quelle dell'ultimo.
              final mostraRiepilogoFrecce =
                  _mostraTutteLeFrecce && _passoAttuale == passi.length - 1;
              final frecceDaMostrare = mostraRiepilogoFrecce
                  ? [for (final p in passi) ...p.frecce]
                  : passo.frecce;
              return Stack(
                children: [
                  vasca,
                  zone,
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FreccePainter(
                        frecce: frecceDaMostrare,
                        pezzi: _ingombri(passo.giocatori),
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
                      onTrascina: (_) {},
                      onRimuovi: () {},
                    ),
                  testi,
                ],
              );
            }

            // In movimento verso il passo successivo: nessuna freccia
            // visibile (si rivedono ferme sul passo d'arrivo), solo i
            // giocatori che scivolano da una posizione all'altra, lungo
            // le frecce del passo di partenza.
            final tokenAnimati = _abbinaGiocatori(
              passi[_passoAttuale].giocatori,
              passi[passoSuccessivo].giocatori,
              frecce: passi[_passoAttuale].frecce,
            );
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Stack(
                children: [
                  vasca,
                  zone,
                  for (final token in tokenAnimati)
                    _TokenAnimato(
                      token: token,
                      t: _controller.value,
                      larghezza: larghezza,
                      altezza: altezza,
                    ),
                  testi,
                ],
              ),
            );
          },
        ),
        if (widget.mostraComandi && tipiUsati.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          _LegendaFrecce(tipi: tipiUsati),
        ],
      ],
    );
  }
}
