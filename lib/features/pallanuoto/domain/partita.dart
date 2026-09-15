class Partita {
  const Partita({
    required this.id,
    required this.clubId,
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
  });

  final String id;
  final String clubId;
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

  factory Partita.fromMap(Map<String, dynamic> map) {
    return Partita(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
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
    );
  }
}
