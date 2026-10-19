import 'dart:typed_data';

/// Una segnalazione mandata con «Scrivimi»: il testo di chi scrive, quello
/// che l'app allega da sola (versione, pagina, dispositivo, schermo, la
/// schermata) e la risposta di chi la legge. [autore], [clubNome] e
/// [ruolo] li scrive il database.
class Segnalazione {
  const Segnalazione({
    required this.id,
    required this.creataIl,
    required this.userId,
    required this.testo,
    required this.versione,
    required this.risolta,
    this.clubId,
    this.autore,
    this.clubNome,
    this.ruolo,
    this.pagina,
    this.dispositivo,
    this.schermo,
    this.schermata,
    this.risposta,
    this.risoltaIl,
  });

  final String id;
  final DateTime creataIl;
  final String userId;
  final String? clubId;
  final String? autore;
  final String? clubNome;

  /// owner, coach, assistente.
  final String? ruolo;
  final String testo;
  final String versione;
  final String? pagina;
  final String? dispositivo;
  final String? schermo;

  /// Dove sta la schermata nello spazio `segnalazioni`; null senza.
  final String? schermata;
  final bool risolta;
  final String? risposta;
  final DateTime? risoltaIl;

  /// "Responsabile", "Allenatore", "Assistente".
  String? get ruoloLeggibile => switch (ruolo) {
    'owner' => 'Responsabile',
    'coach' => 'Allenatore',
    'assistente' => 'Assistente',
    _ => null,
  };

  factory Segnalazione.fromMap(Map<String, dynamic> map) => Segnalazione(
    id: map['id'] as String,
    creataIl: DateTime.parse(map['created_at'] as String),
    userId: map['user_id'] as String,
    clubId: map['club_id'] as String?,
    autore: map['autore'] as String?,
    clubNome: map['club_nome'] as String?,
    ruolo: map['ruolo'] as String?,
    testo: map['testo'] as String,
    versione: map['versione'] as String,
    pagina: map['pagina'] as String?,
    dispositivo: map['dispositivo'] as String?,
    schermo: map['schermo'] as String?,
    schermata: map['schermata'] as String?,
    risolta: map['stato'] == 'risolta',
    risposta: map['risposta'] as String?,
    risoltaIl: map['risolta_at'] == null
        ? null
        : DateTime.parse(map['risolta_at'] as String),
  );
}

/// Quello che l'app allega da sola a una segnalazione.
class ContestoSegnalazione {
  const ContestoSegnalazione({
    required this.versione,
    this.pagina,
    this.dispositivo,
    this.schermo,
    this.schermata,
  });

  final String versione;
  final String? pagina;
  final String? dispositivo;
  final String? schermo;

  /// La schermata in PNG; null se non si è riusciti a farla.
  final Uint8List? schermata;
}
