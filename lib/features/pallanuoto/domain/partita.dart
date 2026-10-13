class Partita {
  const Partita({
    required this.id,
    required this.clubId,
    this.gruppoId,
    required this.data,
    this.ora,
    this.luogo,
    this.campionato,
    this.coloreCalottina,
    required this.squadraCasa,
    required this.squadraTrasferta,
    required this.numeroMaxConvocati,
    this.note,
    this.dettaglioTiro = 'semplice',
    this.tracciaTempo = true,
    this.modalitaSuperiorita = 'singolo',
    this.nostraSquadra = 'casa',
    this.importanza = 'media',
    this.eventiLive = 'essenziale',
    this.ritrovoOra,
    this.ritrovoLuogo,
    this.rientroOra,
    this.daPortare,
    this.noteConvocazione,
    this.convocazioneInviataIl,
  });

  final String id;
  final String clubId;

  /// Gruppo di allenamento (squadra) a cui appartiene — null se
  /// condivisa con tutto il club.
  final String? gruppoId;
  final DateTime data;
  final String? ora;
  final String? luogo;
  final String? campionato;
  final String? coloreCalottina; // bianca | blu
  final String squadraCasa;
  final String squadraTrasferta;
  final int numeroMaxConvocati; // 14 | 15
  final String? note;
  final String dettaglioTiro; // semplice | dettagliato
  final bool tracciaTempo;
  final String modalitaSuperiorita; // singolo | inizio_fine
  final String nostraSquadra; // casa | trasferta

  /// bassa | media | alta — lo scarico pre-partita del generatore
  /// settimanale (FASE 3) scatta solo per "alta".
  final String importanza;

  /// essenziale | completa — in modalità completa dal vivo si segnano
  /// anche palle perse e recuperate, assist, gol in controfuga ed
  /// espulsioni o rigori guadagnati.
  final String eventiLive;

  /// La convocazione, nata dalla distinta: ritrovo ("HH:MM" e dove),
  /// rientro previsto, cosa portare e una nota per le famiglie.
  final String? ritrovoOra;
  final String? ritrovoLuogo;
  final String? rientroOra;
  final String? daPortare;
  final String? noteConvocazione;

  /// Quando l'allenatore l'ha inviata ai convocati (l'ultima volta):
  /// l'avviso agli atleti parte solo da qui.
  final DateTime? convocazioneInviataIl;

  bool get convocazioneInviata => convocazioneInviataIl != null;

  /// La stessa partita con la convocazione che si sta scrivendo (per
  /// l'anteprima del messaggio prima di salvare).
  Partita conConvocazione({
    String? ora,
    String? luogo,
    String? ritrovoOra,
    String? ritrovoLuogo,
    String? rientroOra,
    String? daPortare,
    String? noteConvocazione,
  }) => Partita(
    id: id,
    clubId: clubId,
    gruppoId: gruppoId,
    data: data,
    ora: ora,
    luogo: luogo,
    campionato: campionato,
    coloreCalottina: coloreCalottina,
    squadraCasa: squadraCasa,
    squadraTrasferta: squadraTrasferta,
    numeroMaxConvocati: numeroMaxConvocati,
    note: note,
    dettaglioTiro: dettaglioTiro,
    tracciaTempo: tracciaTempo,
    modalitaSuperiorita: modalitaSuperiorita,
    nostraSquadra: nostraSquadra,
    importanza: importanza,
    eventiLive: eventiLive,
    ritrovoOra: ritrovoOra,
    ritrovoLuogo: ritrovoLuogo,
    rientroOra: rientroOra,
    daPortare: daPortare,
    noteConvocazione: noteConvocazione,
    convocazioneInviataIl: convocazioneInviataIl,
  );

  bool get eventiCompleti => eventiLive == 'completa';

  bool get inCasa => nostraSquadra != 'trasferta';

  /// La squadra contro cui giochiamo: negli elenchi e' l'informazione
  /// che conta, mentre "Casa - Trasferta" per intero su telefono veniva
  /// troncato proprio prima del nome dell'avversario.
  String get avversario => inCasa ? squadraTrasferta : squadraCasa;

  factory Partita.fromMap(Map<String, dynamic> map) {
    return Partita(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      gruppoId: map['gruppo_id'] as String?,
      data: DateTime.parse(map['data'] as String),
      ora: map['ora'] as String?,
      luogo: map['luogo'] as String?,
      campionato: map['campionato'] as String?,
      coloreCalottina: map['colore_calottina'] as String?,
      squadraCasa: map['squadra_casa'] as String,
      squadraTrasferta: map['squadra_trasferta'] as String,
      numeroMaxConvocati: map['numero_max_convocati'] as int,
      note: map['note'] as String?,
      dettaglioTiro: map['dettaglio_tiro'] as String? ?? 'semplice',
      tracciaTempo: map['traccia_tempo'] as bool? ?? true,
      modalitaSuperiorita: map['modalita_superiorita'] as String? ?? 'singolo',
      nostraSquadra: map['nostra_squadra'] as String? ?? 'casa',
      importanza: map['importanza'] as String? ?? 'media',
      eventiLive: map['eventi_live'] as String? ?? 'essenziale',
      ritrovoOra: map['ritrovo_ora'] as String?,
      ritrovoLuogo: map['ritrovo_luogo'] as String?,
      rientroOra: map['rientro_ora'] as String?,
      daPortare: map['da_portare'] as String?,
      noteConvocazione: map['note_convocazione'] as String?,
      convocazioneInviataIl: map['convocazione_inviata_at'] == null
          ? null
          : DateTime.parse(map['convocazione_inviata_at'] as String).toLocal(),
    );
  }
}
