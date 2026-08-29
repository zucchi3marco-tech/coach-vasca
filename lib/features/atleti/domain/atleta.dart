class Atleta {
  const Atleta({
    required this.id,
    required this.clubId,
    required this.nome,
    required this.cognome,
    required this.dataNascita,
    this.sesso,
    required this.sport,
    this.gruppo,
    this.emailGenitore,
    this.telefonoGenitore,
    required this.consensoPrivacyFirmato,
    this.consensoPrivacyData,
    this.note,
    required this.attivo,
  });

  final String id;
  final String clubId;
  final String nome;
  final String cognome;
  final DateTime dataNascita;
  final String? sesso; // 'M' | 'F'
  final String sport; // 'nuoto' | 'pallanuoto'
  final String? gruppo;
  final String? emailGenitore;
  final String? telefonoGenitore;
  final bool consensoPrivacyFirmato;
  final DateTime? consensoPrivacyData;
  final String? note;
  final bool attivo;

  String get nomeCompleto => '$nome $cognome';

  factory Atleta.fromMap(Map<String, dynamic> map) {
    return Atleta(
      id: map['id'] as String,
      clubId: map['club_id'] as String,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      dataNascita: DateTime.parse(map['data_nascita'] as String),
      sesso: map['sesso'] as String?,
      sport: map['sport'] as String,
      gruppo: map['gruppo'] as String?,
      emailGenitore: map['email_genitore'] as String?,
      telefonoGenitore: map['telefono_genitore'] as String?,
      consensoPrivacyFirmato: map['consenso_privacy_firmato'] as bool,
      consensoPrivacyData: map['consenso_privacy_data'] == null
          ? null
          : DateTime.parse(map['consenso_privacy_data'] as String),
      note: map['note'] as String?,
      attivo: map['attivo'] as bool,
    );
  }
}
