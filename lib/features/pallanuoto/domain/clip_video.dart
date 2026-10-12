import 'evento_partita.dart';
import 'video_partita.dart';

/// Quali clip mostrare del video della partita.
enum FiltroClip {
  tutte('Tutte'),
  golFatti('Gol fatti'),
  golSubiti('Gol subiti'),
  tiri('Tiri'),
  superiorita('Superiorità'),
  inferiorita('Inferiorità'),
  rigori('Rigori'),
  pallePerse('Palle perse'),
  palleRecuperate('Palle recuperate'),
  note('Note');

  const FiltroClip(this.etichetta);

  final String etichetta;
}

/// Un pezzo del video da guardare: un evento registrato dal vivo, o una
/// nota dell'allenatore. [secondo] è dove succede l'evento (o il
/// fotogramma della nota); la clip va da [inizio] a [fine].
class ClipVideo {
  const ClipVideo({
    this.evento,
    this.nota,
    required this.secondo,
    required this.inizio,
    required this.fine,
  }) : assert((evento == null) != (nota == null));

  final EventoPartita? evento;
  final NotaVideo? nota;
  final double secondo;
  final double inizio;
  final double fine;

  String get id => evento?.id ?? nota!.id;
}

/// Quanto prima e quanto dopo il momento dell'evento parte e finisce la
/// clip. L'allenatore tocca l'evento dopo che è successo (e per un tiro
/// sceglie anche campo, calottina ed esito), quindi la clip parte qualche
/// secondo prima: l'azione che porta al tiro, il fallo prima
/// dell'espulsione. Una superiorità dura 20 secondi: la clip la contiene
/// tutta, dall'espulsione (o dall'inizio segnato) alla fine.
({double prima, double dopo}) _finestra(
  EventoPartita e,
  FiltroClip filtro, {
  required bool superioritaAInizio,
}) {
  final daSuperiorita =
      filtro == FiltroClip.superiorita || filtro == FiltroClip.inferiorita;
  return switch (e.tipo) {
    'espulsione' when daSuperiorita => (prima: 4, dopo: 24),
    'espulsione' => (prima: 8, dopo: 4),
    // Segnata a inizio superiorità (poi conclusa) o una volta sola alla
    // fine, con l'esito.
    'superiorita' when superioritaAInizio => (prima: 4, dopo: 24),
    'superiorita' => (prima: 24, dopo: 4),
    'palla_persa' || 'palla_recuperata' => (prima: 8, dopo: 3),
    _ => (prima: 10, dopo: 4),
  };
}

bool _diSuperiorita(EventoPartita e, {required bool nostra}) {
  if (e.tipo == 'superiorita') return (e.squadra == 'nostra') == nostra;
  // Una nostra superiorità nasce da un'espulsione avversaria (non da
  // rigore: quella dà un rigore).
  return e.tipo == 'espulsione' &&
      !e.espulsioneDaRigore &&
      (e.squadra == 'nostra') != nostra;
}

bool _nelFiltro(EventoPartita e, FiltroClip filtro) {
  final nostra = e.squadra == 'nostra';
  return switch (filtro) {
    FiltroClip.tutte => true,
    FiltroClip.golFatti => e.tipo == 'tiro' && nostra && e.esito == 'gol',
    FiltroClip.golSubiti => e.tipo == 'tiro' && !nostra && e.esito == 'gol',
    FiltroClip.tiri => e.tipo == 'tiro' && nostra,
    FiltroClip.superiorita => _diSuperiorita(e, nostra: true),
    FiltroClip.inferiorita => _diSuperiorita(e, nostra: false),
    FiltroClip.rigori =>
      (e.tipo == 'tiro' && e.contestoTiro == 'rigore') ||
          (e.tipo == 'espulsione' && e.espulsioneDaRigore),
    FiltroClip.pallePerse => e.tipo == 'palla_persa',
    FiltroClip.palleRecuperate => e.tipo == 'palla_recuperata',
    FiltroClip.note => false,
  };
}

/// L'evento riguarda [atletaId]: l'ha fatto, ha fatto l'assist o ha
/// guadagnato l'espulsione.
bool coinvolge(EventoPartita e, String atletaId) =>
    e.atletaId == atletaId ||
    (e.assistDi == atletaId && e.esito == 'gol') ||
    e.guadagnataDa == atletaId;

/// Le clip del video per [filtro] (e, con [atletaId], solo quelle di quel
/// giocatore e le note per lui), in ordine di video. [fuoriDalVideo]
/// conta gli eventi che cadono prima dell'inizio o dopo la fine
/// ([durata], quando il lettore la conosce). Senza allineamento ci sono
/// solo le note.
///
/// Nelle superiorità, un'espulsione e la superiorità segnata a mano per
/// la stessa situazione (entro 30 secondi) sono una clip sola, come nelle
/// statistiche, dove non si contano due volte.
({List<ClipVideo> clip, int fuoriDalVideo}) clipVideo({
  required VideoPartita video,
  required List<EventoPartita> eventi,
  required List<NotaVideo> note,
  FiltroClip filtro = FiltroClip.tutte,
  String? atletaId,
  bool superioritaAInizio = false,
  double? durata,
}) {
  final clip = <ClipVideo>[];
  var fuori = 0;
  bool nelVideo(double s) => s >= 0 && (durata == null || s <= durata);

  final ordinati = [...eventi]
    ..sort((a, b) => a.creatoIl.compareTo(b.creatoIl));
  DateTime? ultimaEspulsione;
  for (final e in ordinati) {
    if (!_nelFiltro(e, filtro)) continue;
    if (atletaId != null && !coinvolge(e, atletaId)) continue;
    if (filtro == FiltroClip.superiorita || filtro == FiltroClip.inferiorita) {
      if (e.tipo == 'espulsione') {
        ultimaEspulsione = e.creatoIl;
      } else if (ultimaEspulsione != null &&
          e.creatoIl.difference(ultimaEspulsione).inSeconds <= 30) {
        continue;
      }
    }
    final s = secondoNelVideo(
      video.allineamenti,
      momento: e.creatoIl,
      periodo: e.periodo,
    );
    if (s == null) continue;
    if (!nelVideo(s)) {
      fuori++;
      continue;
    }
    final f = _finestra(e, filtro, superioritaAInizio: superioritaAInizio);
    clip.add(
      ClipVideo(
        evento: e,
        secondo: s,
        inizio: s - f.prima < 0 ? 0 : s - f.prima,
        fine: durata != null && s + f.dopo > durata ? durata : s + f.dopo,
      ),
    );
  }

  if (filtro == FiltroClip.tutte || filtro == FiltroClip.note) {
    for (final n in note) {
      if (atletaId != null && n.atletaId != atletaId) continue;
      clip.add(
        ClipVideo(
          nota: n,
          secondo: n.secondo,
          inizio: n.secondo - 5 < 0 ? 0 : n.secondo - 5,
          fine: n.secondo,
        ),
      );
    }
  }

  clip.sort((a, b) => a.secondo.compareTo(b.secondo));
  return (clip: clip, fuoriDalVideo: fuori);
}

/// I filtri che hanno almeno una clip (sempre "Tutte"): i chip vuoti non
/// si mostrano.
List<FiltroClip> filtriConClip({
  required VideoPartita video,
  required List<EventoPartita> eventi,
  required List<NotaVideo> note,
  String? atletaId,
}) => [
  for (final f in FiltroClip.values)
    if (f == FiltroClip.tutte ||
        clipVideo(
          video: video,
          eventi: eventi,
          note: note,
          filtro: f,
          atletaId: atletaId,
        ).clip.isNotEmpty)
      f,
];

/// "1:05:03" o "12:07": il punto del video.
String minutaggio(double secondi) {
  final totale = secondi < 0 ? 0 : secondi.floor();
  final ore = totale ~/ 3600;
  final minuti = (totale % 3600) ~/ 60;
  final sec = (totale % 60).toString().padLeft(2, '0');
  return ore > 0
      ? '$ore:${minuti.toString().padLeft(2, '0')}:$sec'
      : '$minuti:$sec';
}
