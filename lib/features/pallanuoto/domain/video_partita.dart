import 'dart:convert';

/// Il video YouTube (di solito non in elenco) di una partita: uno solo,
/// tutta la partita anche se tagliata fra un tempo e l'altro. Con almeno
/// un [Allineamento] ogni evento registrato dal vivo si ritrova nel video
/// e diventa una clip (vedi `clip_video.dart`).
class VideoPartita {
  const VideoPartita({
    required this.id,
    required this.clubId,
    required this.partitaId,
    required this.youtubeId,
    this.allineamenti = const [],
  });

  final String id;
  final String clubId;
  final String partitaId;
  final String youtubeId;
  final List<Allineamento> allineamenti;

  bool get allineato => allineamenti.isNotEmpty;

  String get link => 'https://youtu.be/$youtubeId';
}

/// Nel video, al secondo [secondo], succede l'evento registrato dal vivo
/// al [momento] (nel [periodo]). Il momento si tiene con il punto, non
/// solo l'evento: se poi l'evento si elimina, l'allineamento resta.
class Allineamento {
  const Allineamento({
    required this.secondo,
    required this.momento,
    this.periodo,
    this.eventoId,
  });

  final double secondo;
  final DateTime momento;
  final int? periodo;
  final String? eventoId;

  Map<String, dynamic> toJson() => {
    'secondo': double.parse(secondo.toStringAsFixed(2)),
    'momento': momento.toUtc().toIso8601String(),
    'periodo': periodo,
    'evento_id': eventoId,
  };

  factory Allineamento.fromJson(Map<String, dynamic> m) => Allineamento(
    secondo: (m['secondo'] as num).toDouble(),
    momento: DateTime.parse(m['momento'] as String),
    periodo: (m['periodo'] as num?)?.toInt(),
    eventoId: m['evento_id'] as String?,
  );
}

/// Dalla colonna `allineamenti` (lista JSON, dal server già decodificata
/// o dalla copia locale come testo). Un punto illeggibile si salta.
List<Allineamento> allineamentiDa(Object? valore) {
  final grezzo = valore is String ? jsonDecode(valore) : valore;
  if (grezzo is! List) return const [];
  return [
    for (final m in grezzo)
      if (m is Map<String, dynamic> && m['secondo'] is num)
        if (m['momento'] is String) Allineamento.fromJson(m),
  ];
}

/// Il secondo del video in cui succede un evento registrato al [momento]
/// nel [periodo]: si parte dal punto di allineamento dello stesso tempo
/// (l'ultimo prima dell'evento, o il primo dopo) e si aggiunge il tempo
/// passato. Senza un punto in quel tempo vale l'ultimo punto prima
/// (o il primo dopo): con un video unico ne basta uno per tutta la
/// partita, e dopo un taglio fra due tempi un secondo punto rimette a
/// posto quel tempo. Null senza punti.
double? secondoNelVideo(
  List<Allineamento> punti, {
  required DateTime momento,
  int? periodo,
}) {
  if (punti.isEmpty) return null;
  final stessoTempo = periodo == null
      ? const <Allineamento>[]
      : punti.where((p) => p.periodo == periodo).toList();
  final candidati = stessoTempo.isNotEmpty ? stessoTempo : punti;
  Allineamento? prima;
  Allineamento? dopo;
  for (final p in candidati) {
    if (!p.momento.isAfter(momento)) {
      if (prima == null || p.momento.isAfter(prima.momento)) prima = p;
    } else if (dopo == null || p.momento.isBefore(dopo.momento)) {
      dopo = p;
    }
  }
  final punto = prima ?? dopo!;
  return punto.secondo +
      momento.difference(punto.momento).inMilliseconds / 1000;
}

/// Una nota su un fotogramma del video ([secondo]): frecce e cerchi
/// disegnati sopra e un testo, per tutta la squadra ([atletaId] null) o
/// per un convocato. [eventoId] è la clip da cui è nata, se c'è.
class NotaVideo {
  const NotaVideo({
    required this.id,
    required this.videoId,
    required this.partitaId,
    required this.clubId,
    required this.secondo,
    this.eventoId,
    this.atletaId,
    this.testo,
    this.disegno = const [],
    required this.creataIl,
    this.audioPath,
    this.audioSecondi,
  });

  final String id;
  final String videoId;
  final String partitaId;
  final String clubId;
  final double secondo;
  final String? eventoId;
  final String? atletaId;
  final String? testo;
  final List<SegnoVideo> disegno;
  final DateTime creataIl;

  /// Il commento a voce dell'allenatore (spazio privato `note_vocali`),
  /// registrato mentre la clip scorre da [secondo], e quanto dura.
  final String? audioPath;
  final double? audioSecondi;

  bool get perTutti => atletaId == null;

  bool get conVoce => audioPath != null;
}

enum FormaSegno { freccia, cerchio }

/// Un segno sul fotogramma, in coordinate 0-1 sul riquadro del video:
/// una freccia da [da] ad [a] (curva con [controllo]) o un cerchio
/// (un'ellisse) nel rettangolo fra [da] e [a]. [colore] è il nome di un
/// inchiostro della lavagna tattica (`ColoreLavagna`).
class SegnoVideo {
  const SegnoVideo({
    required this.forma,
    required this.colore,
    required this.da,
    required this.a,
    this.controllo,
  });

  final FormaSegno forma;
  final String colore;
  final (double, double) da;
  final (double, double) a;
  final (double, double)? controllo;

  Map<String, dynamic> toJson() => {
    'forma': forma.name,
    'colore': colore,
    'da': _punto(da),
    'a': _punto(a),
    if (controllo != null) 'controllo': _punto(controllo!),
  };

  static List<double> _punto((double, double) p) => [
    double.parse(p.$1.toStringAsFixed(4)),
    double.parse(p.$2.toStringAsFixed(4)),
  ];

  static (double, double)? _daLista(Object? v) =>
      v is List && v.length == 2 && v[0] is num && v[1] is num
      ? ((v[0] as num).toDouble(), (v[1] as num).toDouble())
      : null;

  /// Null se il segno non si legge (forma sconosciuta, punti mancanti).
  static SegnoVideo? fromJson(Map<String, dynamic> m) {
    final forma = FormaSegno.values.asNameMap()[m['forma']];
    final da = _daLista(m['da']);
    final a = _daLista(m['a']);
    if (forma == null || da == null || a == null) return null;
    return SegnoVideo(
      forma: forma,
      colore: m['colore'] as String? ?? 'giallo',
      da: da,
      a: a,
      controllo: _daLista(m['controllo']),
    );
  }
}

/// Dalla colonna `disegno` (lista JSON, decodificata o come testo).
List<SegnoVideo> segniDa(Object? valore) {
  final grezzo = valore is String ? jsonDecode(valore) : valore;
  if (grezzo is! List) return const [];
  return [
    for (final m in grezzo)
      if (m is Map<String, dynamic>) ?SegnoVideo.fromJson(m),
  ];
}

/// La risposta scritta di un giocatore a una nota del video (tabella
/// `risposte_note_video`): una per nota, che può correggere; la leggono
/// lui e lo staff del club.
class RispostaNota {
  const RispostaNota({
    required this.id,
    required this.notaId,
    required this.atletaId,
    required this.testo,
    required this.aggiornataIl,
  });

  factory RispostaNota.fromMap(Map<String, dynamic> m) => RispostaNota(
    id: m['id'] as String,
    notaId: m['nota_id'] as String,
    atletaId: m['atleta_id'] as String,
    testo: m['testo'] as String,
    aggiornataIl: DateTime.parse(m['updated_at'] as String).toLocal(),
  );

  final String id;
  final String notaId;
  final String atletaId;
  final String testo;
  final DateTime aggiornataIl;
}

/// Quanto può essere lunga la risposta a una nota.
const lunghezzaMassimaRispostaNota = 1000;
