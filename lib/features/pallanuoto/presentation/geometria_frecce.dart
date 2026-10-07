import 'dart:math' as math;
import 'dart:ui';

/// Geometria delle frecce della lavagna tattica. Una freccia è una curva
/// di Bézier quadratica da `inizio` a `fine` con punto di controllo
/// `controllo`; senza controllo è un segmento dritto. Le funzioni
/// lavorano in un unico sistema di coordinate (pixel o frazioni del
/// campo): la curva di Bézier non cambia forma passando dall'uno
/// all'altro, quindi basta convertire i punti.

Offset puntoSuCurva(Offset inizio, Offset? controllo, Offset fine, double t) {
  if (controllo == null) return Offset.lerp(inizio, fine, t)!;
  final u = 1 - t;
  return inizio * (u * u) + controllo * (2 * u * t) + fine * (t * t);
}

/// La direzione della curva in [t]: orienta la punta della freccia.
Offset tangenteSuCurva(
  Offset inizio,
  Offset? controllo,
  Offset fine,
  double t,
) {
  if (controllo == null) return fine - inizio;
  final tangente =
      (controllo - inizio) * (2 * (1 - t)) + (fine - controllo) * (2 * t);
  // Controllo sovrapposto a un estremo: la derivata lì si annulla.
  return tangente.distance == 0 ? fine - inizio : tangente;
}

/// Il punto di controllo che fa passare la curva per [medio] a metà
/// (t = 0,5): così si curva una freccia trascinandone il centro.
Offset controlloPerPuntoMedio(Offset inizio, Offset medio, Offset fine) =>
    medio * 2 - (inizio + fine) / 2;

/// Dal tratto disegnato col dito alla curva che lo approssima: passa per
/// il primo punto, l'ultimo e il punto a metà della lunghezza del tratto.
/// `null` (freccia dritta) se nessun punto si scosta dalla corda più di
/// [sogliaPx]: una mano non traccia mai una riga perfetta, e una curva
/// appena accennata sembrerebbe un errore.
Offset? controlloDaTraccia(List<Offset> traccia, {double sogliaPx = 12}) {
  if (traccia.length < 3) return null;
  final inizio = traccia.first;
  final fine = traccia.last;
  final corda = fine - inizio;
  final lunghezzaCorda = corda.distance;
  if (lunghezzaCorda == 0) return null;

  var scostamentoMassimo = 0.0;
  for (final p in traccia) {
    final v = p - inizio;
    final scostamento =
        (v.dx * corda.dy - v.dy * corda.dx).abs() / lunghezzaCorda;
    scostamentoMassimo = math.max(scostamentoMassimo, scostamento);
  }
  if (scostamentoMassimo < sogliaPx) return null;

  return controlloPerPuntoMedio(inizio, _puntoAMetaLunghezza(traccia), fine);
}

Offset _puntoAMetaLunghezza(List<Offset> traccia) {
  var totale = 0.0;
  for (var i = 1; i < traccia.length; i++) {
    totale += (traccia[i] - traccia[i - 1]).distance;
  }
  var percorsa = 0.0;
  for (var i = 1; i < traccia.length; i++) {
    final tratto = (traccia[i] - traccia[i - 1]).distance;
    if (percorsa + tratto >= totale / 2 && tratto > 0) {
      return Offset.lerp(
        traccia[i - 1],
        traccia[i],
        (totale / 2 - percorsa) / tratto,
      )!;
    }
    percorsa += tratto;
  }
  return traccia.last;
}

/// Punti della curva a passo regolare in t, estremi compresi.
List<Offset> campionaCurva(
  Offset inizio,
  Offset? controllo,
  Offset fine, {
  int segmenti = 32,
}) => [
  for (var i = 0; i <= segmenti; i++)
    puntoSuCurva(inizio, controllo, fine, i / segmenti),
];

/// Distanza di [p] dalla curva: serve a capire quale freccia si è
/// toccata.
double distanzaDaCurva(
  Offset p,
  Offset inizio,
  Offset? controllo,
  Offset fine,
) {
  final punti = campionaCurva(inizio, controllo, fine, segmenti: 40);
  var minima = double.infinity;
  for (var i = 1; i < punti.length; i++) {
    minima = math.min(minima, _distanzaDaSegmento(p, punti[i - 1], punti[i]));
  }
  return minima;
}

double _distanzaDaSegmento(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lunghezza2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lunghezza2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lunghezza2).clamp(
    0.0,
    1.0,
  );
  return (p - (a + ab * t)).distance;
}

/// Il tratto della freccia lungo la polilinea [punti], fermato
/// [accorciamento] pixel prima della fine (lì comincia la punta):
/// - [tratteggiata]: trattini da 9 px ogni 15 (il passaggio);
/// - [ondulata]: un'onda attorno alla curva, che si spegne verso la
///   punta (la nuotata con la palla);
/// - altrimenti una linea continua.
Path percorsoFreccia(
  List<Offset> punti, {
  double accorciamento = 0,
  bool tratteggiata = false,
  bool ondulata = false,
  double scostamento = 0,
}) {
  final base = _accorcia(punti, accorciamento);
  final linea = scostamento == 0 ? base : _parallela(base, scostamento);
  if (ondulata) return _polilinea(_onda(linea));
  if (tratteggiata) return _trattini(linea, pieno: 9, vuoto: 6);
  return _polilinea(linea);
}

/// [punti] senza gli ultimi [quanto] pixel di percorso: la freccia che
/// arriva su un giocatore si ferma al bordo della sua calottina.
List<Offset> percorsoTroncato(List<Offset> punti, double quanto) =>
    _accorcia(punti, quanto);

Path _polilinea(List<Offset> punti) {
  final path = Path();
  if (punti.isEmpty) return path;
  path.moveTo(punti.first.dx, punti.first.dy);
  for (final p in punti.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

List<Offset> _accorcia(List<Offset> punti, double quanto) {
  if (quanto <= 0 || punti.length < 2) return punti;
  var daTogliere = quanto;
  final risultato = List.of(punti);
  while (risultato.length >= 2) {
    final ultimo = risultato.last;
    final penultimo = risultato[risultato.length - 2];
    final tratto = (ultimo - penultimo).distance;
    if (tratto > daTogliere) {
      risultato[risultato.length - 1] = Offset.lerp(
        ultimo,
        penultimo,
        daTogliere / tratto,
      )!;
      return risultato;
    }
    daTogliere -= tratto;
    risultato.removeLast();
  }
  return risultato;
}

Offset _normale(List<Offset> punti, int i) {
  final a = punti[math.max(0, i - 1)];
  final b = punti[math.min(punti.length - 1, i + 1)];
  final d = b - a;
  if (d.distance == 0) return Offset.zero;
  return Offset(-d.dy, d.dx) / d.distance;
}

List<Offset> _parallela(List<Offset> punti, double distanza) => [
  for (var i = 0; i < punti.length; i++)
    punti[i] + _normale(punti, i) * distanza,
];

List<Offset> _onda(
  List<Offset> punti, {
  double ampiezza = 4,
  double lunghezzaOnda = 14,
}) {
  final fitti = _ricampiona(punti, passo: 2);
  var totale = 0.0;
  for (var i = 1; i < fitti.length; i++) {
    totale += (fitti[i] - fitti[i - 1]).distance;
  }
  final risultato = <Offset>[];
  var percorsa = 0.0;
  for (var i = 0; i < fitti.length; i++) {
    if (i > 0) percorsa += (fitti[i] - fitti[i - 1]).distance;
    // L'onda si spegne nei primi e negli ultimi 10 px: la freccia parte
    // dal giocatore ed entra nella punta senza scatti.
    final smorzamento = math.min(
      1.0,
      math.min(percorsa, totale - percorsa) / 10,
    );
    final spostamento =
        ampiezza *
        smorzamento *
        math.sin(2 * math.pi * percorsa / lunghezzaOnda);
    risultato.add(fitti[i] + _normale(fitti, i) * spostamento);
  }
  return risultato;
}

List<Offset> _ricampiona(List<Offset> punti, {required double passo}) {
  if (punti.length < 2) return punti;
  final risultato = <Offset>[punti.first];
  for (var i = 1; i < punti.length; i++) {
    final a = punti[i - 1];
    final b = punti[i];
    final n = math.max(1, ((b - a).distance / passo).ceil());
    for (var k = 1; k <= n; k++) {
      risultato.add(Offset.lerp(a, b, k / n)!);
    }
  }
  return risultato;
}

Path _trattini(
  List<Offset> punti, {
  required double pieno,
  required double vuoto,
}) {
  final path = Path();
  final fitti = _ricampiona(punti, passo: 1.5);
  var percorsa = 0.0;
  var disegnando = false;
  for (var i = 0; i < fitti.length; i++) {
    if (i > 0) percorsa += (fitti[i] - fitti[i - 1]).distance;
    final dentroTrattino = percorsa % (pieno + vuoto) < pieno;
    if (dentroTrattino && !disegnando) {
      path.moveTo(fitti[i].dx, fitti[i].dy);
      disegnando = true;
    } else if (dentroTrattino) {
      path.lineTo(fitti[i].dx, fitti[i].dy);
    } else {
      disegnando = false;
    }
  }
  return path;
}

/// La punta piena della freccia, con il vertice in [vertice] e rivolta
/// lungo [direzione].
Path puntaFreccia(
  Offset vertice,
  Offset direzione, {
  double lunghezza = 12,
  double semiApertura = 0.48,
}) {
  final angolo = direzione.direction;
  Offset lato(double delta) =>
      vertice -
      Offset(
        lunghezza * math.cos(angolo + delta),
        lunghezza * math.sin(angolo + delta),
      );
  final sinistro = lato(-semiApertura);
  final destro = lato(semiApertura);
  return Path()
    ..moveTo(vertice.dx, vertice.dy)
    ..lineTo(sinistro.dx, sinistro.dy)
    ..lineTo(destro.dx, destro.dy)
    ..close();
}
