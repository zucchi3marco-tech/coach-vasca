class Atleta {
  const Atleta({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.cognome,
    required this.dataNascita,
    this.sesso,
    required this.sport,
    this.gruppoId,
    this.emailGenitore,
    this.telefonoGenitore,
    required this.consensoPrivacyFirmato,
    this.consensoPrivacyData,
    this.note,
    required this.attivo,
    this.numeroTesseraFin,
    this.userId,
    this.visitaMedicaScadenza,
    this.ruolo,
    this.altroGruppoId,
    this.giorniAltroGruppo = const [],
  });

  final String id;
  final String clubId;
  final String nome;
  final String cognome;
  final DateTime dataNascita;
  final String? sesso; // 'M' | 'F'
  /// Com'è nel database ('pallanuoto', o 'nuoto' nelle righe vecchie):
  /// l'app non decide niente da qui, vedi `sportApp`.
  final String sport;
  final String? gruppoId;
  final String? emailGenitore;
  final String? telefonoGenitore;
  final bool consensoPrivacyFirmato;
  final DateTime? consensoPrivacyData;
  final String? note;
  final bool attivo;
  final String? numeroTesseraFin;

  /// Id in auth.users dell'account atleta collegato a questo record
  /// (FASE 9), null finche' l'invito non e' stato riscattato.
  final String? userId;

  /// Scadenza del certificato medico sportivo (facoltativa).
  final DateTime? visitaMedicaScadenza;

  /// Pallanuoto: 'portiere' | 'movimento' | 'centroboa' | 'marcatore' |
  /// 'esterno'; null se non indicato, conta come movimento (vedi
  /// `Destinatari`).
  final String? ruolo;

  /// L'altra squadra con cui si allena in giorni fissi (richiesta del
  /// coach 2026-10-15), e quei giorni (1 = lunedì … 7 = domenica, come
  /// `DateTime.weekday`). Vedi `SquadreAtleta`.
  final String? altroGruppoId;
  final List<int> giorniAltroGruppo;

  bool get portiere => ruolo == 'portiere';

  String get nomeCompleto => '$cognome $nome';

  bool get haAccountCollegato => userId != null;

  bool get visitaMedicaScaduta =>
      visitaMedicaScadenza != null &&
      visitaMedicaScadenza!.isBefore(DateTime.now());

  bool get visitaMedicaInScadenza =>
      visitaMedicaScadenza != null &&
      !visitaMedicaScaduta &&
      visitaMedicaScadenza!.isBefore(
        DateTime.now().add(const Duration(days: 30)),
      );

  factory Atleta.fromMap(Map<String, dynamic> map) {
    return Atleta(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      dataNascita: DateTime.parse(map['data_nascita'] as String),
      sesso: map['sesso'] as String?,
      sport: map['sport'] as String,
      gruppoId: map['gruppo_id'] as String?,
      emailGenitore: map['email_genitore'] as String?,
      telefonoGenitore: map['telefono_genitore'] as String?,
      consensoPrivacyFirmato: map['consenso_privacy_firmato'] as bool,
      consensoPrivacyData: map['consenso_privacy_data'] == null
          ? null
          : DateTime.parse(map['consenso_privacy_data'] as String),
      note: map['note'] as String?,
      attivo: map['attivo'] as bool,
      numeroTesseraFin: map['numero_tessera_fin'] as String?,
      userId: map['user_id'] as String?,
      visitaMedicaScadenza: map['visita_medica_scadenza'] == null
          ? null
          : DateTime.parse(map['visita_medica_scadenza'] as String),
      ruolo: map['ruolo'] as String?,
      altroGruppoId: map['altro_gruppo_id'] as String?,
      giorniAltroGruppo: leggiGiorni(map['giorni_altro_gruppo']),
    );
  }

  /// I giorni come arrivano dal database (una lista di numeri) o dalla
  /// copia locale ("2,4"), in ordine e senza doppioni.
  static List<int> leggiGiorni(Object? valore) {
    final giorni = switch (valore) {
      final List<dynamic> lista => [for (final g in lista) (g as num).toInt()],
      final String testo when testo.trim().isNotEmpty => [
        for (final g in testo.split(',')) ?int.tryParse(g.trim()),
      ],
      _ => const <int>[],
    };
    return ({...giorni.where((g) => g >= 1 && g <= 7)}.toList()..sort());
  }

  /// I giorni per la copia locale: "2,4"; null senza giorni.
  static String? scriviGiorni(List<int> giorni) =>
      giorni.isEmpty ? null : giorni.join(',');
}
