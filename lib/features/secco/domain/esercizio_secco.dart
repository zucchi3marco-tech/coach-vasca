import '../../test/domain/massimale.dart';

/// Per che cosa è un esercizio a secco: la prevenzione della spalla prima
/// di tutto (la cuffia dei rotatori e le scapole del tiro), il core, le
/// gambe della bicicletta, la forza e la mobilità.
enum CategoriaEsercizio {
  spalla('Spalla'),
  scapole('Scapole'),
  core('Core'),
  gambe('Gambe'),
  forza('Forza'),
  mobilita('Mobilità'),
  altro('Altro');

  const CategoriaEsercizio(this.etichetta);

  final String etichetta;

  static CategoriaEsercizio daNome(String? nome) => values.firstWhere(
    (c) => c.name == nome,
    orElse: () => CategoriaEsercizio.altro,
  );
}

/// Si conta a ripetizioni o a tempo (un plank, un isometrico al muro).
enum MisuraEsercizio {
  ripetizioni('Ripetizioni'),
  tempo('A tempo');

  const MisuraEsercizio(this.etichetta);

  final String etichetta;

  static MisuraEsercizio daNome(String? nome) =>
      nome == 'tempo' ? MisuraEsercizio.tempo : MisuraEsercizio.ripetizioni;
}

/// Un esercizio dell'elenco del club: inventato dall'allenatore o preso
/// dall'elenco pronto ([modelliEsercizi]).
class EsercizioSecco {
  const EsercizioSecco({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.categoria,
    this.misura = MisuraEsercizio.ripetizioni,
    this.attrezzo,
    this.descrizione,
    this.modello,
    this.archiviato = false,
    this.videoYoutube,
    this.videoDaS,
  });

  final String id;
  final String clubId;
  final String nome;
  final CategoriaEsercizio categoria;
  final MisuraEsercizio misura;
  final String? attrezzo;

  /// Come si fa.
  final String? descrizione;

  /// La chiave dell'esercizio pronto da cui è nato, null per uno
  /// dell'allenatore.
  final String? modello;
  final bool archiviato;

  /// Il video di YouTube che mostra come si fa (l'id), e da che secondo
  /// parte: lo vede anche l'atleta.
  final String? videoYoutube;
  final int? videoDaS;

  bool get aTempo => misura == MisuraEsercizio.tempo;

  Map<String, dynamic> toPayload() => {
    'nome': nome.trim(),
    'categoria': categoria.name,
    'misura': misura.name,
    'attrezzo': _pieno(attrezzo),
    'descrizione': _pieno(descrizione),
    'modello': modello,
    'archiviato': archiviato,
    'video_youtube': videoYoutube,
    'video_da_s': videoYoutube == null ? null : videoDaS,
  };

  EsercizioSecco copyWith({bool? archiviato}) => EsercizioSecco(
    id: id,
    clubId: clubId,
    nome: nome,
    categoria: categoria,
    misura: misura,
    attrezzo: attrezzo,
    descrizione: descrizione,
    modello: modello,
    archiviato: archiviato ?? this.archiviato,
    videoYoutube: videoYoutube,
    videoDaS: videoDaS,
  );
}

/// Un esercizio dentro una seduta a secco: quante serie, ripetizioni o
/// tempo, con che carico ("8 kg", "elastico rosso"), quanto recupero.
class EsercizioSeduta {
  const EsercizioSeduta({
    required this.id,
    required this.allenamentoId,
    required this.clubId,
    required this.esercizioId,
    required this.ordine,
    this.serie = 3,
    this.ripetizioni,
    this.durataS,
    this.carico,
    this.recuperoS,
    this.note,
  });

  final String id;
  final String allenamentoId;
  final String clubId;
  final String esercizioId;
  final int ordine;
  final int serie;
  final int? ripetizioni;
  final int? durataS;
  final String? carico;
  final int? recuperoS;

  /// Per l'allenatore: all'atleta non arrivano, come le note delle serie.
  final String? note;

  Map<String, dynamic> toPayload() => {
    'ordine': ordine,
    'serie': serie,
    'ripetizioni': durataS == null ? ripetizioni : null,
    'durata_s': durataS,
    'carico': _pieno(carico),
    'recupero_s': recuperoS,
    'note': _pieno(note),
  };

  /// Come la vede l'atleta: senza le note dell'allenatore.
  EsercizioSeduta senzaNote() => EsercizioSeduta(
    id: id,
    allenamentoId: allenamentoId,
    clubId: clubId,
    esercizioId: esercizioId,
    ordine: ordine,
    serie: serie,
    ripetizioni: ripetizioni,
    durataS: durataS,
    carico: carico,
    recuperoS: recuperoS,
  );

  EsercizioSeduta copyWith({int? ordine}) => EsercizioSeduta(
    id: id,
    allenamentoId: allenamentoId,
    clubId: clubId,
    esercizioId: esercizioId,
    ordine: ordine ?? this.ordine,
    serie: serie,
    ripetizioni: ripetizioni,
    durataS: durataS,
    carico: carico,
    recuperoS: recuperoS,
    note: note,
  );
}

/// Un esercizio di una seduta come lo vede l'atleta: con nome e come si
/// fa, senza le note dell'allenatore (`esercizi_seduta_atleta`).
class EsercizioSedutaAtleta {
  const EsercizioSedutaAtleta({required this.esercizio, required this.riga});

  final EsercizioSecco esercizio;
  final EsercizioSeduta riga;

  factory EsercizioSedutaAtleta.fromMap(Map<String, dynamic> m) =>
      EsercizioSedutaAtleta(
        esercizio: EsercizioSecco(
          id: m['esercizio_id'] as String,
          clubId: '',
          nome: m['nome'] as String,
          categoria: CategoriaEsercizio.daNome(m['categoria'] as String?),
          misura: MisuraEsercizio.daNome(m['misura'] as String?),
          attrezzo: m['attrezzo'] as String?,
          descrizione: m['descrizione'] as String?,
          videoYoutube: m['video_youtube'] as String?,
          videoDaS: (m['video_da_s'] as num?)?.toInt(),
        ),
        riga: EsercizioSeduta(
          id: m['id'] as String,
          allenamentoId: m['allenamento_id'] as String,
          clubId: '',
          esercizioId: m['esercizio_id'] as String,
          ordine: (m['ordine'] as num).toInt(),
          serie: (m['serie'] as num).toInt(),
          ripetizioni: (m['ripetizioni'] as num?)?.toInt(),
          durataS: (m['durata_s'] as num?)?.toInt(),
          carico: m['carico'] as String?,
          recuperoS: (m['recupero_s'] as num?)?.toInt(),
        ),
      );
}

String? _pieno(String? t) => t == null || t.trim().isEmpty ? null : t.trim();

/// "30''", "1'", "1'30''".
String formattaSecondi(int secondi) {
  final m = secondi ~/ 60;
  final s = secondi % 60;
  if (m == 0) return "$s''";
  if (s == 0) return "$m'";
  return "$m'${s.toString().padLeft(2, '0')}''";
}

/// "3 × 12", "3 × 30''": serie per ripetizioni o tempo.
String volumeEsercizio(EsercizioSeduta e) {
  final quanto = e.durataS != null
      ? formattaSecondi(e.durataS!)
      : '${e.ripetizioni ?? 0}';
  return '${e.serie} × $quanto';
}

/// "3 × 12, elastico rosso · recupero 1'": quanto, con che carico e il
/// recupero fra le serie. Con il [massimale] di un atleta un carico in
/// percentuale diventa i suoi chili: "4 × 6, 56 kg (70%)".
String prescrizioneEsercizio(EsercizioSeduta e, {double? massimale}) => [
  [
    volumeEsercizio(e),
    ?_pieno(caricoPerAtleta(e.carico, massimale)),
  ].join(', '),
  if (e.recuperoS != null && e.recuperoS! > 0)
    'recupero ${formattaSecondi(e.recuperoS!)}',
].join(' · ');

/// Secondi per ripetizione nella stima della durata: un esercizio a
/// ripetizioni lente, come si fanno quelli di prevenzione.
const secondiPerRipetizione = 3;

/// Quanto dura una seduta fatta di questi esercizi, in minuti: serie ×
/// (tempo o ripetizioni × [secondiPerRipetizione]) più i recuperi fra le
/// serie e mezzo minuto per passare al successivo. Una stima per proporre
/// la durata, non il carico (quello usa la durata della seduta).
int minutiStimati(Iterable<EsercizioSeduta> esercizi) {
  var secondi = 0;
  for (final e in esercizi) {
    final lavoro = e.durataS ?? (e.ripetizioni ?? 0) * secondiPerRipetizione;
    secondi += e.serie * lavoro;
    secondi += (e.serie - 1).clamp(0, 99) * (e.recuperoS ?? 0);
    secondi += 30;
  }
  return (secondi / 60).ceil();
}

/// Serie, ripetizioni o tempo e recupero proposti quando si aggiunge un
/// esercizio a una seduta: quelli dell'ultima volta che il club l'ha
/// usato, se no quelli dell'esercizio pronto, se no 3 × 12 (o 3 × 30'')
/// con un minuto di recupero.
({int serie, int? ripetizioni, int? durataS, int? recuperoS, String? carico})
prescrizioneProposta(EsercizioSecco esercizio, {EsercizioSeduta? ultima}) {
  if (ultima != null) {
    final aTempo = esercizio.aTempo;
    return (
      serie: ultima.serie,
      ripetizioni: aTempo ? null : (ultima.ripetizioni ?? 12),
      durataS: aTempo ? (ultima.durataS ?? 30) : null,
      recuperoS: ultima.recuperoS,
      carico: ultima.carico,
    );
  }
  final m = modelliEsercizi
      .where((m) => m.chiave == esercizio.modello)
      .firstOrNull;
  if (m != null && m.aTempo == esercizio.aTempo) {
    return (
      serie: m.serie,
      ripetizioni: m.ripetizioni,
      durataS: m.durataS,
      recuperoS: m.recuperoS,
      carico: null,
    );
  }
  return esercizio.aTempo
      ? (serie: 3, ripetizioni: null, durataS: 30, recuperoS: 45, carico: null)
      : (serie: 3, ripetizioni: 12, durataS: null, recuperoS: 60, carico: null);
}

/// Un esercizio dell'elenco pronto, con la prescrizione di partenza.
typedef ModelloEsercizio = ({
  String chiave,
  String nome,
  CategoriaEsercizio categoria,
  String? attrezzo,
  String descrizione,
  int serie,
  int? ripetizioni,
  int? durataS,
  int recuperoS,
});

extension ModelloEsercizioX on ModelloEsercizio {
  bool get aTempo => durataS != null;

  MisuraEsercizio get misura =>
      aTempo ? MisuraEsercizio.tempo : MisuraEsercizio.ripetizioni;
}

/// L'elenco pronto: prevenzione della spalla e delle scapole (il gesto
/// del tiro), core, gambe per la bicicletta, mobilità e forza. Esercizi
/// comuni nella preparazione a secco degli sport di lancio e della
/// pallanuoto, da adattare all'età e al livello: nome, descrizione e
/// prescrizione si cambiano.
const modelliEsercizi = <ModelloEsercizio>[
  // Spalla
  (
    chiave: 'extrarotazione_elastico',
    nome: 'Extrarotazione con elastico',
    categoria: CategoriaEsercizio.spalla,
    attrezzo: 'Elastico',
    descrizione:
        'In piedi, gomito piegato a 90° e appoggiato al fianco (un asciugamano '
        'arrotolato fra gomito e fianco). Ruotare l\'avambraccio verso '
        'l\'esterno contro l\'elastico, lentamente, e tornare. Spalla bassa, '
        'senza ruotare il busto.',
    serie: 3,
    ripetizioni: 15,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'intrarotazione_elastico',
    nome: 'Intrarotazione con elastico',
    categoria: CategoriaEsercizio.spalla,
    attrezzo: 'Elastico',
    descrizione:
        'Come l\'extrarotazione, con l\'elastico dall\'altro lato: '
        'l\'avambraccio ruota verso la pancia. Gomito sempre al fianco.',
    serie: 3,
    ripetizioni: 15,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'extrarotazione_90',
    nome: 'Extrarotazione a 90° con elastico',
    categoria: CategoriaEsercizio.spalla,
    attrezzo: 'Elastico',
    descrizione:
        'Braccio alzato di lato all\'altezza della spalla, gomito a 90°, la '
        'mano verso il basso. Ruotare portando la mano verso l\'alto, come '
        'nel caricamento del tiro, e tornare piano.',
    serie: 3,
    ripetizioni: 12,
    durataS: null,
    recuperoS: 60,
  ),
  (
    chiave: 'extrarotazione_prono',
    nome: 'Extrarotazione da prono con manubrio',
    categoria: CategoriaEsercizio.spalla,
    attrezzo: 'Manubrio leggero',
    descrizione:
        'A pancia in giù su una panca, il braccio fuori con il gomito a 90°. '
        'Ruotare portando il manubrio in avanti e in alto fino all\'altezza '
        'della panca, e tornare piano.',
    serie: 3,
    ripetizioni: 12,
    durataS: null,
    recuperoS: 60,
  ),
  // Scapole
  (
    chiave: 'ytw_prono',
    nome: 'Y-T-W da prono',
    categoria: CategoriaEsercizio.scapole,
    attrezzo: null,
    descrizione:
        'A pancia in giù, fronte a terra, pollici in su. Alzare le braccia '
        'tese a forma di Y, poi di T, poi piegate a W, stringendo le scapole '
        'ogni volta. Una ripetizione è il giro completo.',
    serie: 3,
    ripetizioni: 8,
    durataS: null,
    recuperoS: 60,
  ),
  (
    chiave: 'rematore_elastico',
    nome: 'Rematore con elastico',
    categoria: CategoriaEsercizio.scapole,
    attrezzo: 'Elastico',
    descrizione:
        'Elastico fissato davanti all\'altezza del petto. Tirare portando i '
        'gomiti indietro vicini al corpo e stringendo le scapole, tenere un '
        'secondo e tornare.',
    serie: 3,
    ripetizioni: 15,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'face_pull',
    nome: 'Face pull con elastico',
    categoria: CategoriaEsercizio.scapole,
    attrezzo: 'Elastico',
    descrizione:
        'Elastico all\'altezza degli occhi. Tirare verso il viso aprendo i '
        'gomiti in fuori e ruotando le mani indietro, fino ad avere le mani '
        'accanto alle orecchie.',
    serie: 3,
    ripetizioni: 12,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'push_up_plus',
    nome: 'Push-up plus',
    categoria: CategoriaEsercizio.scapole,
    attrezzo: null,
    descrizione:
        'In posizione di piegamento (anche sulle ginocchia) a braccia tese: '
        'spingere il pavimento allontanando le scapole fra loro, senza '
        'piegare i gomiti, e tornare.',
    serie: 3,
    ripetizioni: 12,
    durataS: null,
    recuperoS: 45,
  ),
  // Core
  (
    chiave: 'plank_frontale',
    nome: 'Plank frontale',
    categoria: CategoriaEsercizio.core,
    attrezzo: null,
    descrizione:
        'Sugli avambracci e sulle punte dei piedi, il corpo in linea dalla '
        'testa ai talloni. Pancia e glutei contratti, senza far scendere il '
        'bacino.',
    serie: 3,
    ripetizioni: null,
    durataS: 40,
    recuperoS: 30,
  ),
  (
    chiave: 'plank_laterale',
    nome: 'Plank laterale',
    categoria: CategoriaEsercizio.core,
    attrezzo: null,
    descrizione:
        'Su un avambraccio, il gomito sotto la spalla, il corpo di fianco in '
        'linea. Tenere il bacino alto. Il tempo vale per lato.',
    serie: 3,
    ripetizioni: null,
    durataS: 30,
    recuperoS: 30,
  ),
  (
    chiave: 'dead_bug',
    nome: 'Dead bug',
    categoria: CategoriaEsercizio.core,
    attrezzo: null,
    descrizione:
        'A pancia in su, braccia verso il soffitto e ginocchia a 90°. '
        'Allungare insieme un braccio e la gamba opposta senza staccare la '
        'schiena da terra, tornare e cambiare lato.',
    serie: 3,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'pallof_press',
    nome: 'Pallof press con elastico',
    categoria: CategoriaEsercizio.core,
    attrezzo: 'Elastico',
    descrizione:
        'Di fianco al punto in cui è fissato l\'elastico, mani al petto. '
        'Spingere le mani in avanti a braccia tese senza farsi ruotare, '
        'tenere due secondi e tornare. Le ripetizioni valgono per lato.',
    serie: 3,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'hollow_hold',
    nome: 'Hollow hold',
    categoria: CategoriaEsercizio.core,
    attrezzo: null,
    descrizione:
        'A pancia in su, schiena incollata a terra, gambe e spalle sollevate '
        'con le braccia tese oltre la testa: il corpo a barchetta. Più '
        'facile con le ginocchia piegate.',
    serie: 3,
    ripetizioni: null,
    durataS: 25,
    recuperoS: 35,
  ),
  // Gambe (la bicicletta)
  (
    chiave: 'squat',
    nome: 'Squat a corpo libero',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'Piedi alla larghezza delle spalle, scendere come per sedersi '
        'tenendo il petto alto e le ginocchia nella direzione delle punte, '
        'fino alle cosce parallele a terra.',
    serie: 3,
    ripetizioni: 15,
    durataS: null,
    recuperoS: 60,
  ),
  (
    chiave: 'affondi',
    nome: 'Affondi',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'Un passo lungo in avanti, scendere fino a sfiorare terra con il '
        'ginocchio dietro, risalire. Alternare le gambe: le ripetizioni '
        'valgono per gamba.',
    serie: 3,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 60,
  ),
  (
    chiave: 'ponte_glutei',
    nome: 'Ponte per i glutei',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'A pancia in su, ginocchia piegate e piedi a terra. Sollevare il '
        'bacino stringendo i glutei fino ad avere il corpo in linea dalle '
        'spalle alle ginocchia, tenere un secondo e scendere.',
    serie: 3,
    ripetizioni: 15,
    durataS: null,
    recuperoS: 45,
  ),
  (
    chiave: 'squat_muro',
    nome: 'Squat isometrico al muro',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'Schiena appoggiata al muro, scendere fino alle cosce parallele a '
        'terra e restare fermi. La resistenza di gambe che serve alla '
        'bicicletta.',
    serie: 3,
    ripetizioni: null,
    durataS: 45,
    recuperoS: 60,
  ),
  (
    chiave: 'squat_jump',
    nome: 'Salti verticali (squat jump)',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'Da mezzo squat saltare più in alto possibile e atterrare morbidi '
        'tornando subito in mezzo squat. L\'esplosività dello stacco '
        'dall\'acqua.',
    serie: 4,
    ripetizioni: 6,
    durataS: null,
    recuperoS: 90,
  ),
  (
    chiave: 'fire_hydrant',
    nome: 'Rotazioni dell\'anca in quadrupedia',
    categoria: CategoriaEsercizio.gambe,
    attrezzo: null,
    descrizione:
        'A quattro zampe, sollevare di lato un ginocchio piegato (come un '
        'idrante), disegnare un cerchio con il ginocchio e tornare. Le '
        'ripetizioni valgono per lato. Muove l\'anca come la bicicletta.',
    serie: 2,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 30,
  ),
  // Mobilità
  (
    chiave: 'sleeper_stretch',
    nome: 'Sleeper stretch',
    categoria: CategoriaEsercizio.mobilita,
    attrezzo: null,
    descrizione:
        'Sdraiati sul fianco, braccio sotto a 90° davanti al corpo e gomito '
        'a 90°. Con l\'altra mano spingere piano l\'avambraccio verso terra '
        'fino a sentire tirare dietro la spalla. Mai dolore. Il tempo vale '
        'per lato.',
    serie: 2,
    ripetizioni: null,
    durataS: 30,
    recuperoS: 15,
  ),
  (
    chiave: 'open_book',
    nome: 'Rotazioni toraciche (open book)',
    categoria: CategoriaEsercizio.mobilita,
    attrezzo: null,
    descrizione:
        'Sdraiati sul fianco con le ginocchia piegate, braccia tese davanti. '
        'Aprire il braccio sopra come una pagina, ruotando il petto e '
        'seguendo la mano con lo sguardo, e tornare. Le ripetizioni valgono '
        'per lato.',
    serie: 2,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 15,
  ),
  (
    chiave: 'stretching_pettorali',
    nome: 'Stretching dei pettorali alla porta',
    categoria: CategoriaEsercizio.mobilita,
    attrezzo: null,
    descrizione:
        'Avambraccio appoggiato allo stipite di una porta, gomito all\'altezza '
        'della spalla. Fare un passo avanti fino a sentire tirare il petto. '
        'Il tempo vale per lato.',
    serie: 2,
    ripetizioni: null,
    durataS: 30,
    recuperoS: 15,
  ),
  // Forza
  (
    chiave: 'piegamenti',
    nome: 'Piegamenti sulle braccia',
    categoria: CategoriaEsercizio.forza,
    attrezzo: null,
    descrizione:
        'Mani poco più larghe delle spalle, corpo in linea. Scendere fino a '
        'sfiorare terra con il petto e risalire. Sulle ginocchia per chi '
        'comincia.',
    serie: 3,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 60,
  ),
  (
    chiave: 'trazioni',
    nome: 'Trazioni alla sbarra',
    categoria: CategoriaEsercizio.forza,
    attrezzo: 'Sbarra',
    descrizione:
        'Appesi alla sbarra, salire fino al mento sopra la sbarra e scendere '
        'fino alle braccia tese. Con un elastico di aiuto per chi non ne fa '
        'ancora.',
    serie: 3,
    ripetizioni: 6,
    durataS: null,
    recuperoS: 90,
  ),
  (
    chiave: 'rematore_manubrio',
    nome: 'Rematore con manubrio',
    categoria: CategoriaEsercizio.forza,
    attrezzo: 'Manubrio',
    descrizione:
        'Un ginocchio e una mano su una panca, schiena piatta. Tirare il '
        'manubrio verso l\'anca con il gomito vicino al corpo e scendere '
        'piano. Le ripetizioni valgono per lato.',
    serie: 3,
    ripetizioni: 10,
    durataS: null,
    recuperoS: 60,
  ),
  // Forza con il bilanciere: quelli dei massimali pronti
  // (`modelliMassimali`), per i ragazzi più grandi.
  (
    chiave: 'squat_bilanciere',
    nome: 'Squat con bilanciere',
    categoria: CategoriaEsercizio.forza,
    attrezzo: 'Bilanciere',
    descrizione:
        'Bilanciere sulle spalle, non sul collo, piedi alla larghezza delle '
        'spalle. Scendere con la schiena dritta fino alle cosce parallele a '
        'terra, ginocchia nella direzione delle punte, e risalire spingendo '
        'con i talloni. Con i carichi pesanti, sempre qualcuno che assiste.',
    serie: 4,
    ripetizioni: 6,
    durataS: null,
    recuperoS: 120,
  ),
  (
    chiave: 'panca_piana',
    nome: 'Panca piana',
    categoria: CategoriaEsercizio.forza,
    attrezzo: 'Bilanciere e panca',
    descrizione:
        'Sdraiati sulla panca, piedi a terra e scapole strette. Scendere con '
        'il bilanciere fino a sfiorare il petto, gomiti a circa 45° dal '
        'corpo, e spingere su. Sempre con qualcuno che assiste dietro la '
        'testa.',
    serie: 4,
    ripetizioni: 6,
    durataS: null,
    recuperoS: 120,
  ),
  (
    chiave: 'stacco_terra',
    nome: 'Stacco da terra',
    categoria: CategoriaEsercizio.forza,
    attrezzo: 'Bilanciere',
    descrizione:
        'Bilanciere sopra la metà del piede, presa appena fuori dalle gambe. '
        'Schiena dritta e petto in fuori: sollevare spingendo con le gambe e '
        'portando avanti le anche, il bilanciere vicino alle gambe, e '
        'scendere allo stesso modo.',
    serie: 4,
    ripetizioni: 5,
    durataS: null,
    recuperoS: 120,
  ),
];
