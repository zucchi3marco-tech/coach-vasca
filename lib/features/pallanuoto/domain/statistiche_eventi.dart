import 'evento_partita.dart';

/// Le voci che si contano dagli eventi dal vivo. Quelle "di squadra"
/// (superiorità, inferiorità, tiri subiti…) hanno senso solo per la
/// squadra; per un giocatore restano a zero.
enum VoceEvento {
  tiri,
  gol,
  golSuperiorita,
  golRigore,
  golControfuga,
  rigoriTirati,
  tiriSubiti,
  golSubiti,
  golSubitiSuperiorita,
  golSubitiRigore,
  golSubitiControfuga,

  /// Le superiorità avute: le espulsioni degli avversari (non da rigore),
  /// o le superiorità segnate in cronologia se sono di più.
  superiorita,

  /// I gol segnati in superiorità, mai più delle superiorità.
  golInSuperiorita,

  /// Le inferiorità: le nostre espulsioni (non da rigore), o le
  /// superiorità avversarie segnate in cronologia se sono di più.
  inferiorita,
  golSubitiInInferiorita,
  rigoriAvuti,
  rigoriConcessi,

  /// Espulsioni subite (di un nostro giocatore, anche da rigore).
  espulsioni,
  assist,
  pallePerse,
  palleRecuperate,
  espulsioniGuadagnate,
  rigoriGuadagnati,
}

/// Conteggi degli eventi dal vivo di una squadra o di un giocatore, in una
/// partita o in tante (si sommano con `+`).
class NumeriEventi {
  const NumeriEventi._(this._conteggi);

  static const zero = NumeriEventi._({});

  final Map<VoceEvento, int> _conteggi;

  int operator [](VoceEvento voce) => _conteggi[voce] ?? 0;

  NumeriEventi operator +(NumeriEventi altri) => NumeriEventi._({
    for (final v in VoceEvento.values)
      if (this[v] + altri[v] != 0) v: this[v] + altri[v],
  });

  int get tiri => this[VoceEvento.tiri];
  int get gol => this[VoceEvento.gol];
  int get golSuperiorita => this[VoceEvento.golSuperiorita];
  int get golRigore => this[VoceEvento.golRigore];
  int get golControfuga => this[VoceEvento.golControfuga];
  int get golAzione => gol - golSuperiorita - golRigore - golControfuga;
  int get rigoriTirati => this[VoceEvento.rigoriTirati];
  int get tiriSubiti => this[VoceEvento.tiriSubiti];
  int get golSubiti => this[VoceEvento.golSubiti];
  int get golSubitiControfuga => this[VoceEvento.golSubitiControfuga];
  int get superiorita => this[VoceEvento.superiorita];
  int get golInSuperiorita => this[VoceEvento.golInSuperiorita];
  int get inferiorita => this[VoceEvento.inferiorita];
  int get golSubitiInInferiorita => this[VoceEvento.golSubitiInInferiorita];
  int get rigoriAvuti => this[VoceEvento.rigoriAvuti];
  int get rigoriConcessi => this[VoceEvento.rigoriConcessi];
  int get espulsioni => this[VoceEvento.espulsioni];
  int get assist => this[VoceEvento.assist];
  int get pallePerse => this[VoceEvento.pallePerse];
  int get palleRecuperate => this[VoceEvento.palleRecuperate];
  int get espulsioniGuadagnate => this[VoceEvento.espulsioniGuadagnate];
  int get rigoriGuadagnati => this[VoceEvento.rigoriGuadagnati];

  /// C'è almeno un dato che si segna solo in modalità completa.
  bool get haEventiCompleti =>
      assist +
          pallePerse +
          palleRecuperate +
          espulsioniGuadagnate +
          rigoriGuadagnati +
          golControfuga +
          golSubitiControfuga >
      0;
}

/// I numeri di un insieme di eventi dal vivo: una partita o una stagione.
class StatisticheEventi {
  const StatisticheEventi({
    required this.partite,
    required this.squadra,
    required this.perAtleta,
  });

  static const vuote = StatisticheEventi(
    partite: 0,
    squadra: NumeriEventi.zero,
    perAtleta: {},
  );

  /// Le partite con almeno un evento.
  final int partite;
  final NumeriEventi squadra;
  final Map<String, NumeriEventi> perAtleta;

  NumeriEventi di(String atletaId) => perAtleta[atletaId] ?? NumeriEventi.zero;

  factory StatisticheEventi.da(Iterable<EventoPartita> eventi) {
    final perPartita = <String, List<EventoPartita>>{};
    for (final e in eventi) {
      perPartita.putIfAbsent(e.partitaId, () => []).add(e);
    }
    var squadra = NumeriEventi.zero;
    final perAtleta = <String, Map<VoceEvento, int>>{};
    void conta(String? atletaId, VoceEvento voce) {
      if (atletaId == null) return;
      final n = perAtleta.putIfAbsent(atletaId, () => {});
      n[voce] = (n[voce] ?? 0) + 1;
    }

    for (final lista in perPartita.values) {
      squadra = squadra + _squadraInUnaPartita(lista);
      for (final e in lista) {
        switch (e.tipo) {
          case 'tiro' when e.squadra == 'nostra':
            conta(e.atletaId, VoceEvento.tiri);
            if (e.esito != 'gol') break;
            conta(e.atletaId, VoceEvento.gol);
            final voce = _voceGol[e.contestoTiro];
            if (voce != null) conta(e.atletaId, voce);
            if (e.assistDi != e.atletaId) conta(e.assistDi, VoceEvento.assist);
          case 'espulsione' when e.squadra == 'nostra':
            conta(e.atletaId, VoceEvento.espulsioni);
          case 'espulsione':
            conta(
              e.guadagnataDa,
              e.espulsioneDaRigore
                  ? VoceEvento.rigoriGuadagnati
                  : VoceEvento.espulsioniGuadagnate,
            );
          case 'palla_persa':
            conta(e.atletaId, VoceEvento.pallePerse);
          case 'palla_recuperata':
            conta(e.atletaId, VoceEvento.palleRecuperate);
        }
      }
    }
    return StatisticheEventi(
      partite: perPartita.length,
      squadra: squadra,
      perAtleta: {
        for (final MapEntry(:key, :value) in perAtleta.entries)
          key: NumeriEventi._(value),
      },
    );
  }
}

const _voceGol = {
  'superiorita': VoceEvento.golSuperiorita,
  'rigore': VoceEvento.golRigore,
  'controfuga': VoceEvento.golControfuga,
};

const _voceGolSubito = {
  'superiorita': VoceEvento.golSubitiSuperiorita,
  'rigore': VoceEvento.golSubitiRigore,
  'controfuga': VoceEvento.golSubitiControfuga,
};

/// La superiorità e l'inferiorità si contano partita per partita: dalle
/// espulsioni, o dalle superiorità segnate a mano in cronologia quando
/// sono di più (chi le segna lì di solito non segna le espulsioni, e
/// sommarle conterebbe due volte la stessa situazione).
NumeriEventi _squadraInUnaPartita(List<EventoPartita> eventi) {
  final n = <VoceEvento, int>{};
  void piu(VoceEvento voce) => n[voce] = (n[voce] ?? 0) + 1;
  var espulsioniAvversari = 0;
  var espulsioniNostre = 0;
  var superioritaSegnate = 0;
  var superioritaSegnateGol = 0;
  var inferioritaSegnate = 0;
  var inferioritaSegnateGol = 0;

  for (final e in eventi) {
    final nostra = e.squadra == 'nostra';
    switch (e.tipo) {
      case 'tiro' when nostra:
        piu(VoceEvento.tiri);
        if (e.contestoTiro == 'rigore') piu(VoceEvento.rigoriTirati);
        if (e.esito != 'gol') break;
        piu(VoceEvento.gol);
        final voce = _voceGol[e.contestoTiro];
        if (voce != null) piu(voce);
        if (e.assistDi != null && e.assistDi != e.atletaId) {
          piu(VoceEvento.assist);
        }
      case 'tiro':
        piu(VoceEvento.tiriSubiti);
        if (e.esito != 'gol') break;
        piu(VoceEvento.golSubiti);
        final voce = _voceGolSubito[e.contestoTiro];
        if (voce != null) piu(voce);
      case 'espulsione' when nostra:
        piu(VoceEvento.espulsioni);
        if (e.espulsioneDaRigore) {
          piu(VoceEvento.rigoriConcessi);
        } else {
          espulsioniNostre++;
        }
      case 'espulsione':
        if (e.espulsioneDaRigore) {
          piu(VoceEvento.rigoriAvuti);
          if (e.guadagnataDa != null) piu(VoceEvento.rigoriGuadagnati);
        } else {
          espulsioniAvversari++;
          if (e.guadagnataDa != null) piu(VoceEvento.espulsioniGuadagnate);
        }
      case 'superiorita' when nostra:
        superioritaSegnate++;
        if (e.esito == 'gol') superioritaSegnateGol++;
      case 'superiorita':
        inferioritaSegnate++;
        if (e.esito == 'gol') inferioritaSegnateGol++;
      case 'palla_persa':
        piu(VoceEvento.pallePerse);
      case 'palla_recuperata':
        piu(VoceEvento.palleRecuperate);
    }
  }

  final golSup = _max(n[VoceEvento.golSuperiorita] ?? 0, superioritaSegnateGol);
  n[VoceEvento.golInSuperiorita] = golSup;
  n[VoceEvento.superiorita] = _max(
    _max(espulsioniAvversari, superioritaSegnate),
    golSup,
  );
  final golInf = _max(
    n[VoceEvento.golSubitiSuperiorita] ?? 0,
    inferioritaSegnateGol,
  );
  n[VoceEvento.golSubitiInInferiorita] = golInf;
  n[VoceEvento.inferiorita] = _max(
    _max(espulsioniNostre, inferioritaSegnate),
    golInf,
  );
  n.removeWhere((_, v) => v == 0);
  return NumeriEventi._(n);
}

int _max(int a, int b) => a > b ? a : b;

/// "3/7".
String rapporto(int fatti, int su) => '$fatti/$su';

/// "43%", null se non c'è niente su cui calcolarla.
String? percentuale(int fatti, int su) =>
    su > 0 ? '${(fatti / su * 100).round()}%' : null;
